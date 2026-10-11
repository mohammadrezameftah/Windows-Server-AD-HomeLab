# ============================================================
# 05 - File services: folders, SMB shares, group-based NTFS ACLs
# Run on: DC01 (file server role on same box for the lab), elevated
# ============================================================

$root = 'D:\\Shares'   # adjust drive letter if needed
New-Item -Path $root -ItemType Directory -Force | Out-Null

$shares = @(
    @{ Name='HR$';     Path="$root\\HR";     Group='G-FileShare-HR' },
    @{ Name='Common';  Path="$root\\Common";  Group='G-FileShare-Common' }
)

foreach ($s in $shares) {
    New-Item -Path $s.Path -ItemType Directory -Force | Out-Null

    # NTFS: grant Modify to the group, remove inheritance with copy
    icacls $s.Path /inheritance:r /grant:r `
        "BESATLAB\$($s.Group):(OI)(CI)M" `
        'BESATLAB\Domain Admins:(OI)(CI)F' `
        'SYSTEM:(OI)(CI)F' | Out-Null

    if (-not (Get-SmbShare -Name $s.Name -ErrorAction SilentlyContinue)) {
        New-SmbShare -Name $s.Name -Path $s.Path `
            -FullAccess 'BESATLAB\Domain Admins' `
            -ChangeAccess "BESATLAB\$($s.Group)" `
            -ReadAccess 'BESATLAB\Domain Users' | Out-Null
    }
    Write-Host "Share: \\DC01\$($s.Name) -> $($s.Path)  (group: $($s.Group))" -ForegroundColor Green
}

Get-SmbShare | Format-Table Name, Path, Description
Write-Host '>>> File services ready.' -ForegroundColor Cyan
