# ============================================================
# 03 - DHCP server: install, authorize, scope + reservations
# Run on: DC01, elevated PowerShell
# ============================================================

Write-Host '>>> Installing DHCP role...' -ForegroundColor Cyan
Install-WindowsFeature DHCP -IncludeManagementTools

# authorize in AD (post-reboot step done automatically by feature install,
# but we make it explicit / idempotent)
Add-DhcpServerInDC -DnsName 'dc01.besatlab.local' -IPAddress 192.168.100.10

# restart so the server is fully operational
Restart-Service dhcpserver

# ---------- scope ----------
if (-not (Get-DhcpServerv4Scope | Where-Object Name -eq 'LAN-Clients')) {
    Add-DhcpServerv4Scope -Name 'LAN-Clients' `
        -StartRange 192.168.100.50 -EndRange 192.168.100.200 `
        -SubnetMask 255.255.255.0 `
        -State Active `
        -LeaseDuration 08:00:00
    Write-Host 'Scope created: 192.168.100.50-200 /24' -ForegroundColor Green
}

# scope options
Set-DhcpServerv4OptionValue -ScopeId 192.168.100.0 `
    -DnsServer 192.168.100.10 `
    -DnsDomain 'besatlab.local' `
    -Router 192.168.100.1

# exclusion range for infrastructure (servers/printers stay outside the pool)
Add-DhcpServerv4ExclusionRange -ScopeId 192.168.100.0 `
    -StartRange 192.168.100.1 -EndRange 192.168.100.49 -ErrorAction SilentlyContinue

# ---------- printer reservations ----------
# (MAC addresses are lab examples; replace with your own VMs' MACs)
$reservations = @(
    @{ Name='PRN-Ward1';  IP='192.168.100.60'; MAC='AA-BB-CC-00-00-01' },
    @{ Name='PRN-Ward2';  IP='192.168.100.61'; MAC='AA-BB-CC-00-00-02' },
    @{ Name='PRN-Admin';  IP='192.168.100.62'; MAC='AA-BB-CC-00-00-03' }
)
foreach ($r in $reservations) {
    Add-DhcpServerv4Reservation -ScopeId 192.168.100.0 `
        -Name $r.Name -IPAddress $r.IP -ClientId $r.MAC `
        -Type Dhcp -ErrorAction SilentlyContinue
    Write-Host "Reservation: $($r.Name) -> $($r.IP)" -ForegroundColor Green
}

Get-DhcpServerv4ScopeStatistics -ScopeId 192.168.100.0
Write-Host '>>> DHCP ready.' -ForegroundColor Cyan
