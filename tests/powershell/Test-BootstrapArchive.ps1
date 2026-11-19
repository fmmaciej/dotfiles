# Archive-only regression checks. No installation, network, or live configuration.
$ErrorActionPreference = 'Stop'
$Repository = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

$Tokens = $null
$ParseErrors = $null
$Ast = [Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $Repository 'bootstrap.ps1'), [ref] $Tokens, [ref] $ParseErrors)
Assert-True ($ParseErrors.Count -eq 0) 'Bootstrap must parse'
Assert-True ($Ast.Extent.Text -notmatch 'api\.github\.com|Invoke-RestMethod') 'Bootstrap must not use the GitHub REST API'

# Load only the archive reader and remote acquisition block, never the installer.
$ReaderAst = $Ast.Find({ param($Node)
    $Node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $Node.Name -eq 'Get-GitHubArchiveRevision'
}, $true)
. ([scriptblock]::Create($ReaderAst.Extent.Text))
$RemoteAst = $Ast.Find({ param($Node)
    $Node -is [Management.Automation.Language.IfStatementAst] -and
    $Node.Clauses[0].Item1.Extent.Text -eq '-not $Source'
}, $true)
Assert-True ($null -ne $RemoteAst) 'Remote acquisition block not found'
$BlockText = $RemoteAst.Clauses[0].Item2.Extent.Text
$ArchiveBlock = [scriptblock]::Create($BlockText.Substring(1, $BlockText.Length - 2))

Add-Type -AssemblyName System.IO.Compression.FileSystem
$Fixture = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-archive-test-' + [guid]::NewGuid().ToString('N'))
$script:Requests = [Collections.Generic.List[string]]::new()
$Commit = 'a' * 40

function New-ArchiveFixture {
    param([string] $Directory, [string] $Comment, [switch] $MissingHelper)
    $Root = Join-Path $Fixture ([guid]::NewGuid().ToString('N'))
    $Source = Join-Path $Root $Directory
    New-Item -ItemType Directory -Path (Join-Path $Source 'scripts/windows') -Force | Out-Null
    foreach ($Relative in @('bootstrap.ps1', 'scripts/windows/tools.ps1', 'scripts/windows/dotfiles.ps1')) {
        if ($MissingHelper -and $Relative -eq 'scripts/windows/tools.ps1') { continue }
        Set-Content -LiteralPath (Join-Path $Source $Relative) -Value '# synthetic; never executed'
    }
    $Zip = "$Root.zip"
    [IO.Compression.ZipFile]::CreateFromDirectory($Root, $Zip)
    # Add the same ZIP comment GitHub writes, using only standard .NET APIs.
    $Stream = [IO.File]::OpenWrite($Zip)
    try {
        $null = $Stream.Seek(-2, [IO.SeekOrigin]::End)
        $Writer = [IO.BinaryWriter]::new($Stream)
        $Bytes = [Text.Encoding]::ASCII.GetBytes($Comment)
        $Writer.Write([uint16] $Bytes.Length)
        $Writer.Write($Bytes)
        $Writer.Flush()
    } finally { $Stream.Dispose() }
    return $Zip
}

function Invoke-WebRequest {
    param([string] $Uri, [switch] $UseBasicParsing, [string] $OutFile)
    Assert-True ($Uri -like 'https://github.com/fmmaciej/dotfiles/archive/*') 'Unexpected download host/path'
    $script:Requests.Add($Uri)
    Copy-Item -LiteralPath $script:ArchiveFixture -Destination $OutFile
}

function Invoke-ArchiveFixture {
    param([string] $RequestedRevision)
    $Revision = $RequestedRevision
    $Source = $null
    $DownloadRoot = $null
    try {
        . $ArchiveBlock
        return [pscustomobject]@{
            Revision = $Revision
            Directory = Split-Path -Leaf $Source
            HelperExists = Test-Path -LiteralPath (Join-Path $Source 'scripts/windows/tools.ps1')
        }
    } finally {
        if ($DownloadRoot -and (Test-Path -LiteralPath $DownloadRoot)) {
            Remove-Item -LiteralPath $DownloadRoot -Recurse -Force
        }
    }
}

try {
    New-Item -ItemType Directory -Path $Fixture | Out-Null
    $script:ArchiveFixture = New-ArchiveFixture -Directory 'dotfiles-windows-next' -Comment $Commit
    $Result = Invoke-ArchiveFixture
    Assert-True ($script:Requests.Count -eq 1 -and $script:Requests[0] -eq 'https://github.com/fmmaciej/dotfiles/archive/refs/heads/windows-next.zip') 'Default bootstrap must download the branch once'
    Assert-True ($Result.Revision -eq $Commit -and $Result.Directory -eq 'dotfiles-windows-next' -and $Result.HelperExists) 'Branch archive SHA or source directory was lost'

    $script:ArchiveFixture = New-ArchiveFixture -Directory "dotfiles-$Commit" -Comment $Commit
    $Result = Invoke-ArchiveFixture -RequestedRevision $Commit
    Assert-True ($script:Requests[1] -eq "https://github.com/fmmaciej/dotfiles/archive/$Commit.zip") 'Explicit revision must download the pinned archive'
    Assert-True ($Result.Revision -eq $Commit -and $Result.Directory -eq "dotfiles-$Commit") 'Pinned archive extraction changed'

    $Rejected = $false
    try { Invoke-ArchiveFixture -RequestedRevision ('b' * 40) } catch {
        $Rejected = $_.Exception.Message -like '*does not match*'
    }
    Assert-True $Rejected 'A mismatched archive revision must stop setup'

    $RequestCount = $script:Requests.Count
    $Rejected = $false
    try { Invoke-ArchiveFixture -RequestedRevision '../invalid' } catch {
        $Rejected = $_.Exception.Message -eq 'Expected a full Git commit SHA.'
    }
    Assert-True ($Rejected -and $script:Requests.Count -eq $RequestCount) 'Invalid revisions must fail before downloading'

    foreach ($Comment in @('', ('x' * 40), ('a' * 39), ('a' * 41))) {
        $script:ArchiveFixture = New-ArchiveFixture -Directory 'dotfiles-windows-next' -Comment $Comment
        $Rejected = $false
        try { Invoke-ArchiveFixture } catch { $Rejected = $_.Exception.Message -like 'GitHub archive has no*' }
        Assert-True $Rejected 'Missing or malformed archive SHA must stop setup'
    }

    $script:ArchiveFixture = New-ArchiveFixture -Directory 'dotfiles-windows-next' -Comment $Commit
    $Bytes = [IO.File]::ReadAllBytes($script:ArchiveFixture)
    $Bytes[$Bytes.Length - 62] = 0
    [IO.File]::WriteAllBytes($script:ArchiveFixture, $Bytes)
    $Rejected = $false
    try { Invoke-ArchiveFixture } catch { $Rejected = $_.Exception.Message -like 'GitHub archive has no*' }
    Assert-True $Rejected 'A SHA without a valid ZIP end record must be rejected'

    foreach ($Directory in @('dotfiles-windows-next', 'unexpected-root')) {
        $script:ArchiveFixture = New-ArchiveFixture -Directory $Directory -Comment $Commit -MissingHelper
        $Rejected = $false
        try { Invoke-ArchiveFixture } catch { $Rejected = $_.Exception.Message -like 'GitHub archive is missing*' }
        Assert-True $Rejected 'Missing helpers or an unexpected root must stop setup'
    }

    Write-Output 'PASS: API-free branch/pinned downloads, archive SHA, extraction paths, revision mismatch and malformed archive rejection'
} finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -LiteralPath $Fixture -Recurse -Force }
}
