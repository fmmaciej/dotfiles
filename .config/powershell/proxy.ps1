$ProxyConfigPath = Join-Path $HOME '.config/powershell/proxy.local.psd1'

function Get-ProxyConfig {
    if (-not (Test-Path $ProxyConfigPath)) {
        throw "Missing proxy config: $ProxyConfigPath"
    }

    $config = Import-PowerShellDataFile -Path $ProxyConfigPath

    if (-not $config.ContainsKey('ProxyUrl') -or [string]::IsNullOrWhiteSpace($config.ProxyUrl)) {
        throw "Proxy config must define non-empty 'ProxyUrl'"
    }

    if (-not $config.ContainsKey('VpnNamePattern') -or [string]::IsNullOrWhiteSpace($config.VpnNamePattern)) {
        throw "Proxy config must define non-empty 'VpnNamePattern'"
    }

    if (-not $config.ContainsKey('NoProxy')) {
        $config.NoProxy = @()
    }

    return $config
}

function Test-VpnConnected {
    $config = Get-ProxyConfig

    $vpnAdapter = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
        $_.Status -eq 'Up' -and (
            $_.Name -match $config.VpnNamePattern -or
            $_.InterfaceDescription -match $config.VpnNamePattern
        )
    } | Select-Object -First 1

    return [bool]$vpnAdapter
}

function proxy-on {
    if (-not (Test-VpnConnected)) {
        Write-Host 'VPN not detected, proxy not enabled'
        return
    }

    $config = Get-ProxyConfig

    $env:HTTP_PROXY  = $config.ProxyUrl
    $env:HTTPS_PROXY = $config.ProxyUrl
    $env:NO_PROXY    = ($config.NoProxy -join ',')

    Write-Host "Proxy enabled: $($config.ProxyUrl)"
}

function proxy-off {
    Remove-Item Env:HTTP_PROXY  -ErrorAction SilentlyContinue
    Remove-Item Env:HTTPS_PROXY -ErrorAction SilentlyContinue
    Remove-Item Env:NO_PROXY    -ErrorAction SilentlyContinue

    Write-Host 'Proxy disabled'
}

function proxy-refresh {
    if (Test-VpnConnected) {
        proxy-on
    } else {
        proxy-off
    }
}

function proxy-status {
    [pscustomobject]@{
        VpnConnected = Test-VpnConnected
        HTTP_PROXY   = $env:HTTP_PROXY
        HTTPS_PROXY  = $env:HTTPS_PROXY
        NO_PROXY     = $env:NO_PROXY
    }
}

