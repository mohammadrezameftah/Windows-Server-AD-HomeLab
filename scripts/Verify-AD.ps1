# ============================================================
# Health check: run on DC01, elevated PowerShell
# ============================================================

Import-Module ActiveDirectory, DhcpServer

$ok = 0; $bad = 0
function Check($label, $condition) {
    if ($condition) { Write-Host "[PASS] $label" -ForegroundColor Green; $script:ok++ }
    else            { Write-Host "[FAIL] $label" -ForegroundColor Red;   $script:bad++ }
}

Write-Host '=== AD Domain Services ===' -ForegroundColor Cyan
$domain = Get-ADDomain
Check "Domain: $($domain.DNSRoot)" ($domain.DNSRoot -eq 'besatlab.local')
$dc = Get-ADDomainController -Discover
Check "DC reachable: $($dc.HostName)" ($null -ne $dc)

Write-Host "`n=== dcdiag (core tests) ===" -ForegroundColor Cyan
$dcdiag = dcdiag /s:dc01 | Select-String 'passed test|failed test'
$dcdiag | ForEach-Object { $_.Line.Trim() }
Check 'dcdiag has no failed tests' (-not ($dcdiag | Select-String 'failed test'))

Write-Host "`n=== DNS ===" -ForegroundColor Cyan
$soa = Get-DnsServerResourceRecord -ZoneName 'besatlab.local' -RRType Soa
Check 'SOA record present' ($null -ne $soa)

Write-Host "`n=== DHCP ===" -ForegroundColor Cyan
$scope = Get-DhcpServerv4Scope -ScopeId 192.168.100.0 -ErrorAction SilentlyContinue
Check 'Scope 192.168.100.0 active' ($scope.State -eq 'Active')
Get-DhcpServerv4ScopeStatistics -ScopeId 192.168.100.0 |
    Format-Table ScopeId, Free, InUse, PercentageInUse

Write-Host "`n=== Users per OU ===" -ForegroundColor Cyan
foreach ($dept in 'IT','HR','Finance','Nursing') {
    $n = (Get-ADUser -Filter * -SearchBase "OU=$dept,OU=Users,OU=HQ,DC=besatlab,DC=local").Count
    Write-Host ("  {0,-10} {1} user(s)" -f $dept, $n)
}

Write-Host "`n=== Groups ===" -ForegroundColor Cyan
Get-ADGroup -Filter 'Name -like "G-*"' -SearchBase 'OU=Groups,OU=HQ,DC=besatlab,DC=local' |
    Select-Object Name, GroupScope | Format-Table

Write-Host "`n=== File shares ===" -ForegroundColor Cyan
Get-SmbShare | Where-Object Name -in 'HR$','Common' | Format-Table Name, Path

Write-Host "`n=== GPOs ===" -ForegroundColor Cyan
Get-GPO -All | Where-Object DisplayName -like 'C-*' | Format-Table DisplayName, GpoStatus

Write-Host "`nRESULT: $ok passed, $bad failed" -ForegroundColor $(if ($bad -eq 0) {'Green'} else {'Red'})
