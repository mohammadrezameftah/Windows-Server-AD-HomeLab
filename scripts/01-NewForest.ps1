# ============================================================
# 01 - Promote DC01 to the first DC of a new forest
# Run on: DC01, elevated PowerShell, BEFORE anything else
# Reboot required afterwards
# ============================================================

$DomainName       = 'besatlab.local'
$DomainNetbios    = 'BESATLAB'
$ForestMode       = 'WinThreshold'   # Windows Server 2016
$DomainMode       = 'WinThreshold'

Write-Host '>>> Installing AD DS role...' -ForegroundColor Cyan
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

Write-Host ">>> Promoting $env:COMPUTERNAME to DC of new forest $DomainName" -ForegroundColor Cyan
$SafeModePassword = Read-Host 'DSRM (Safe Mode) password' -AsSecureString

Install-ADDSForest `
    -DomainName $DomainName `
    -DomainNetbiosName $DomainNetbios `
    -DomainMode $DomainMode `
    -ForestMode $ForestMode `
    -InstallDns `
    -CreateDnsDelegation:$false `
    -SafeModeAdministratorPassword $SafeModePassword `
    -NoRebootOnCompletion:$false `
    -Force

Write-Host '>>> Done. Rebooting now.' -ForegroundColor Green
Restart-Computer -Force
