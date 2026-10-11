# ============================================================
# 04 - Group Policy: password baseline + screen lock + RDP
# Run on: DC01, elevated PowerShell (needs GPO module from AD DS install)
# ============================================================

Import-Module GroupPolicy
Import-Module ActiveDirectory

# ---------- 1) domain password policy ----------
Set-ADDefaultDomainPasswordPolicy -Identity 'besatlab.local' `
    -ComplexityEnabled $true `
    -MinPasswordLength 12 `
    -MaxPasswordAge '90.00:00:00' `
    -MinPasswordAge '1.00:00:00' `
    -PasswordHistoryCount 10
Write-Host 'Password baseline: 12+ chars, complexity ON, 90d max age, history 10' -ForegroundColor Green

# ---------- 2) screen lock (user GPO) ----------
$gpoLock = 'C-Security-ScreenLock'
if (-not (Get-GPO -Name $gpoLock -ErrorAction SilentlyContinue)) {
    New-GPO -Name $gpoLock | Out-Null
}
# 10 min inactivity -> password-protected screensaver
Set-GPRegistryValue -Name $gpoLock -Type User `
    -Key 'HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop' `
    -ValueName ScreenSaveTimeOut  -Value 600   -Type DWord | Out-Null
Set-GPRegistryValue -Name $gpoLock -Type User `
    -Key 'HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop' `
    -ValueName ScreenSaveIsSecure -Value 1     -Type DWord | Out-Null
Set-GPRegistryValue -Name $gpoLock -Type User `
    -Key 'HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop' `
    -ValueName SCRNSAVE.EXE       -Value 'scrnsave.scr' -Type String | Out-Null

# link to the Users OU
$userOu = 'OU=Users,OU=HQ,DC=besatlab,DC=local'
if (-not (Get-GPLink -Name $gpoLock -Target $userOu -ErrorAction SilentlyContinue)) {
    New-GPLink -Name $gpoLock -Target $userOu -LinkEnabled Yes -Order 1 | Out-Null
}
Write-Host "$gpoLock -> linked to $userOu" -ForegroundColor Green

# ---------- 3) RDP for IT (computer GPO) ----------
$gpoRdp = 'C-RemoteDesktop-IT'
if (-not (Get-GPO -Name $gpoRdp -ErrorAction SilentlyContinue)) {
    New-GPO -Name $gpoRdp | Out-Null
}
Set-GPRegistryValue -Name $gpoRdp -Type Computer `
    -Key 'HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server' `
    -ValueName fDenyTSConnections -Value 0 -Type DWord | Out-Null

# firewall rule inside same GPO (pre-built Windows rule store)
Set-GPRegistryValue -Name $gpoRdp -Type Computer `
    -Key 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' `
    -ValueName fAllowUnlistedRemotePrograms -Value 0 -Type DWord | Out-Null

$srvOu = 'OU=Servers,OU=Computers,OU=HQ,DC=besatlab,DC=local'
if (-not (Get-GPLink -Name $gpoRdp -Target $srvOu -ErrorAction SilentlyContinue)) {
    New-GPLink -Name $gpoRdp -Target $srvOu -LinkEnabled Yes -Order 1 | Out-Null
}

# restrict who can RDP: local Administrators + G-RDP-Operators
# (done via restricted-groups; here we document the manual step:
#  GPMC -> C-RemoteDesktop-IT -> Computer Config -> Policies -> Windows Settings
#  -> Restricted Groups -> Add 'BESATLAB\G-RDP-Operators' to 'Remote Desktop Users')

Write-Host "$gpoRdp -> linked to $srvOu" -ForegroundColor Green
Write-Host '>>> GPO baseline complete. Run gpupdate /force on clients.' -ForegroundColor Cyan
