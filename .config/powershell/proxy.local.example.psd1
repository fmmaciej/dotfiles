@{
    ProxyUrl       = 'http://proxy.company.local:8080'
    VpnNamePattern = 'Cisco|AnyConnect|GlobalProtect|Forti|Pulse|Zscaler|VPN'
    NoProxy        = @(
        'localhost'
        '127.0.0.1'
        '::1'
    )
}

