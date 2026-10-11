# ============================================================
# 02 - OU hierarchy, sample users, security groups
# Run on: DC01, elevated PowerShell, AFTER 01 + reboot
# ============================================================

Import-Module ActiveDirectory

$root = 'DC=besatlab,DC=local'

# ---------- OU structure ----------
$ous = @(
    'OU=HQ,' + $root,
    'OU=Users,OU=HQ,' + $root,
    'OU=Computers,OU=HQ,' + $root,
    'OU=Groups,OU=HQ,' + $root
)
foreach ($dept in 'IT','HR','Finance','Nursing') {
    $ous += "OU=$dept,OU=Users,OU=HQ,$root"
}
foreach ($type in 'Servers','Workstations') {
    $ous += "OU=$type,OU=Computers,OU=HQ,$root"
}

foreach ($ou in $ous) {
    $name = ($ou -split ',')[0] -replace 'OU=',''
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ou'")) {
        New-ADOrganizationalUnit -Name $name -Path (($ou -split ',') | Select-Object -Skip 1) -JoinString ','
        Write-Host "OU created:  $ou" -ForegroundColor Green
    } else {
        Write-Host "OU exists:   $ou" -ForegroundColor Yellow
    }
}

# ---------- sample users ----------
# LAB-ONLY initial password -> forced change recommended on first logon
$labPassword = ConvertTo-SecureString 'ChangeMe#123' -AsPlainText -Force

$users = @(
    @{ First='MohammadReza'; Last='Meftah';  User='r.meftah';   Dept='IT' },
    @{ First='Sara';         Last='Ahmadi';  User='s.ahmadi';  Dept='HR' },
    @{ First='Ali';          Last='Karimi';  User='a.karimi';  Dept='Finance' },
    @{ First='Niloofar';     Last='Rezaei';  User='n.rezaei';  Dept='Nursing' },
    @{ First='Hassan';       Last='Moradi';  User='h.moradi';  Dept='IT' }
)

foreach ($u in $users) {
    $ouPath = "OU=$($u.Dept),OU=Users,OU=HQ,$root"
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$($u.User)'")) {
        New-ADUser -Name "$($u.First) $($u.Last)" `
                   -GivenName $u.First -Surname $u.Last `
                   -SamAccountName $u.User `
                   -UserPrincipalName "$($u.User)@besatlab.local" `
                   -Path $ouPath `
                   -AccountPassword $labPassword `
                   -ChangePasswordAtLogon $true `
                   -Enabled $true
        Write-Host "User created: $($u.User) ($($u.Dept))" -ForegroundColor Green
    } else {
        Write-Host "User exists:  $($u.User)" -ForegroundColor Yellow
    }
}

# ---------- security groups (RBAC) ----------
$groups = @(
    'G-FileShare-HR', 'G-FileShare-Common', 'G-RDP-Operators', 'G-Print-Managers'
)
foreach ($g in $groups) {
    if (-not (Get-ADGroup -Filter "Name -eq '$g'")) {
        New-ADGroup -Name $g -GroupScope Global -GroupCategory Security -Path "OU=Groups,OU=HQ,$root"
        Write-Host "Group created: $g" -ForegroundColor Green
    }
}

# memberships
Add-ADGroupMember -Identity 'G-FileShare-HR'      -Members 's.ahmadi'
Add-ADGroupMember -Identity 'G-FileShare-Common'  -Members 's.ahmadi','r.meftah','a.karimi','n.rezaei'
Add-ADGroupMember -Identity 'G-RDP-Operators'     -Members 'r.meftah','h.moradi'

Write-Host '>>> OU/user/group provisioning complete.' -ForegroundColor Cyan
