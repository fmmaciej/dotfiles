# Mocked module installation and interactive setup; no Gallery, profiles or history.
$ErrorActionPreference = 'Stop'
$Repository = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $Repository 'scripts/windows/tools.ps1')

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

$script:AvailableModules = @{ PSReadLine = $true; CompletionPredictor = $false }
$script:GalleryCalls = [Collections.Generic.List[object]]::new()
$script:Imports = [Collections.Generic.List[string]]::new()
$script:KeyHandlers = @{}
$script:PredictionOptions = $null
$script:GalleryFails = $false
$script:SkimAvailable = $true

function Get-Module {
    param([string] $Name, [switch] $ListAvailable)
    if ($script:AvailableModules[$Name]) { [pscustomobject]@{ Name = $Name } }
}

function Install-PSResource {
    [CmdletBinding()]
    param([string] $Name, [string] $Repository, [string] $Scope, [switch] $TrustRepository, [switch] $Quiet)
    $script:GalleryCalls.Add([pscustomobject]@{ Action = 'install'; Parameters = @{} + $PSBoundParameters })
    if ($script:GalleryFails) { throw 'synthetic Gallery failure' }
    $script:AvailableModules[$Name] = $true
}

function Update-PSResource {
    [CmdletBinding()]
    param([string] $Name, [string] $Repository, [string] $Scope, [switch] $TrustRepository, [switch] $Quiet)
    $script:GalleryCalls.Add([pscustomobject]@{ Action = 'update'; Parameters = @{} + $PSBoundParameters })
    if ($script:GalleryFails) { throw 'synthetic Gallery failure' }
}

function Import-Module {
    param([string] $Name)
    $script:Imports.Add($Name)
}

function Set-PSReadLineOption {
    param([string] $PredictionSource, [string] $PredictionViewStyle)
    $script:PredictionOptions = @{} + $PSBoundParameters
}

function Set-PSReadLineKeyHandler {
    param([string] $Chord, [string] $Function, [string] $BriefDescription, [string] $LongDescription, [scriptblock] $ScriptBlock)
    $script:KeyHandlers[$Chord] = @{} + $PSBoundParameters
}

function Get-Command {
    param([string] $Name, [object] $ErrorAction)
    if ($Name -eq 'sk' -and $script:SkimAvailable) { [pscustomobject]@{ Name = $Name } }
}

Ensure-CompletionPredictor
Assert-True ($script:GalleryCalls[0].Action -eq 'install') 'Missing predictor must be installed'
Ensure-CompletionPredictor
Ensure-CompletionPredictor
Assert-True (($script:GalleryCalls.Action -join ',') -eq 'install,update,update') 'Installed/current modules must use the updater, not reinstall'
foreach ($Call in $script:GalleryCalls) {
    Assert-True ($Call.Parameters.Name -eq 'CompletionPredictor' -and $Call.Parameters.Repository -eq 'PSGallery') 'Only the requested Gallery module may be installed/updated'
    Assert-True ($Call.Parameters.Scope -eq 'CurrentUser' -and $Call.Parameters.TrustRepository) 'Use current-user scope and per-operation trust'
    Assert-True ($Call.Parameters.Quiet -and $Call.Parameters.ErrorAction -eq 'Stop') 'Gallery failures must not be ignored'
}

$script:GalleryFails = $true
foreach ($Installed in @($false, $true)) {
    $script:AvailableModules.CompletionPredictor = $Installed
    $Rejected = $false
    try { Ensure-CompletionPredictor } catch { $Rejected = $_.Exception.Message -eq 'synthetic Gallery failure' }
    Assert-True $Rejected 'Install/update errors must stop bootstrap'
}
$script:GalleryFails = $false
$script:AvailableModules.CompletionPredictor = $true
$GalleryCallCount = $script:GalleryCalls.Count

$ReadLine = Join-Path $Repository 'powershell/.config/powershell/15-readline.ps1'
$Skim = Join-Path $Repository 'powershell/.config/powershell/20-skim.ps1'
. $ReadLine
. $Skim
Assert-True ($script:Imports -contains 'PSReadLine' -and $script:Imports -contains 'CompletionPredictor') 'Both modules must load'
Assert-True ($script:PredictionOptions.PredictionSource -eq 'HistoryAndPlugin' -and $script:PredictionOptions.PredictionViewStyle -eq 'ListView') 'Enable completion/history suggestions in list view'
Assert-True ($script:KeyHandlers['Tab'].Function -eq 'MenuComplete') 'Tab must open the completion menu'
Assert-True ($script:KeyHandlers['Ctrl+r'].BriefDescription -eq 'SkimHistory') 'Ctrl+R must stay assigned to skim'
Assert-True ($script:KeyHandlers['Ctrl+t'].BriefDescription -eq 'SkimFiles') 'Ctrl+T must stay assigned to skim'
Assert-True (-not $script:KeyHandlers.ContainsKey('F2')) 'Leave the native prediction-view toggle intact'

$script:SkimAvailable = $false
$script:KeyHandlers.Clear()
$script:PredictionOptions = $null
. $ReadLine
. $Skim
Assert-True ($script:PredictionOptions.PredictionSource -eq 'HistoryAndPlugin') 'Predictions must not depend on skim'
Assert-True ($script:KeyHandlers.Count -eq 1 -and $script:KeyHandlers.ContainsKey('Tab')) 'Missing skim must not alter predictor setup'

$script:AvailableModules.CompletionPredictor = $false
$script:Imports.Clear()
. $ReadLine
Assert-True ($script:PredictionOptions.PredictionSource -eq 'History') 'Before installation, retain local history predictions'
Assert-True (-not ($script:Imports -contains 'CompletionPredictor')) 'Do not import a missing predictor'

$script:AvailableModules.PSReadLine = $false
$script:Imports.Clear()
$script:KeyHandlers.Clear()
$script:PredictionOptions = $null
. $ReadLine
Assert-True ($script:Imports.Count -eq 0 -and $script:KeyHandlers.Count -eq 0 -and $null -eq $script:PredictionOptions) 'Missing PSReadLine should leave the shell usable'
Assert-True ($script:GalleryCalls.Count -eq $GalleryCallCount) 'Profile startup must never install/update modules'

$Bootstrap = Get-Content -LiteralPath (Join-Path $Repository 'bootstrap.ps1') -Raw
Assert-True ($Bootstrap.IndexOf('Ensure-CompletionPredictor') -gt $Bootstrap.IndexOf('if ($PSVersionTable.PSVersion.Major -lt 7)')) 'Install the predictor only after PowerShell 7 re-entry'
Write-Output 'PASS: predictor install/update/failure, list/history options, Tab menu, skim shortcuts, missing modules, and no startup installation'
