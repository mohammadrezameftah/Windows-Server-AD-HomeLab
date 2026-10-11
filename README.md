# Windows Server / Active Directory Home Lab

An automated Active Directory environment that mirrors the kind of IT landscape I
administer in a hospital: one central identity, DNS and DHCP source, departmental
structure, Group Policy hardening, and controlled file services.

> The organization, hostnames and sample users are fictional; the design patterns
> (departmental OUs, guest-free segmentation, reservation printing, GPO baseline)
> come from real day-to-day operations.

## 🏗️ Lab Architecture

| Server | Role | IP |
|---|---|---|
| **DC01** | AD DS (forest root), DNS, DHCP, File Server | `192.168.100.10` |
| **Client01** *(optional)* | Windows 10/11 domain client | DHCP (`192.168.100.x`) |

- Network: host-only / internal `192.168.100.0/24`, gateway `192.168.100.1`
- Forest/domain: `besatlab.local` (functional level Windows Server 2016)
- Host: any machine running Windows Server 2019/2022 (Eval ISO is fine) in
  VirtualBox / VMware Workstation / Hyper-V

## 📁 What's Automated

| Script | Purpose |
|---|---|
| `scripts/01-NewForest.ps1` | Installs AD DS and promotes DC01 as forest root `besatlab.local` |
| `scripts/02-OUs-Users-Groups.ps1` | OU hierarchy (IT / HR / Finance / Nursing), sample users, security groups |
| `scripts/03-DHCP.ps1` | DHCP install + authorization, scope `192.168.100.0/24`, printer reservations |
| `scripts/04-GPO.ps1` | Domain password policy + screen-lock GPO + RDP-for-IT GPO |
| `scripts/05-FileShare.ps1` | SMB shares with group-based NTFS permissions |
| `scripts/Verify-AD.ps1` | One-shot health check: DCdiag, DNS, DHCP, shares, user count |

## 🚀 Build Order

1. Deploy **DC01** (Windows Server 2019/2022), static IP `192.168.100.10/24`,
   DNS pointing to itself.
2. Run `01-NewForest.ps1` → reboot.
3. Run `02-OUs-Users-Groups.ps1` (edit sample user list to taste).
4. Run `03-DHCP.ps1`.
5. Run `04-GPO.ps1`.
6. Run `05-FileShare.ps1`.
7. (Optional) Join **Client01** to `besatlab.local`, log in as a sample user, run
   `scripts/Verify-AD.ps1` on DC01.

### Manual step (GUI only)
Drive-map Group Policy Preferences can't be fully scripted: in GPMC edit
`C-MappedDrives` → **User Configuration → Preferences → Windows Settings →
Drive Maps** → New → Mapped Drive:
`H:` → `\\DC01\\HR$` → Action: Replace → Item-level target: group
`BESATLAB\\G-FileShare-HR`.

## ✅ Verification

Run `scripts/Verify-AD.ps1` on DC01 — it checks:

- `dcdiag` core tests (Services, Replication, SYSVOL) — **PASS**
- Domain/forest functional level + DC role
- DHCP scope statistics (addresses in use after clients join)
- SMB shares + NTFS group assignments
- Per-OU user counts, group memberships
- GPOs linked to `OU=HQ,OU=Users` and their registry payload

Sample users use a lab-only initial password (`ChangeMe#123`) — **must** be
changed at first logon; the domain password policy enforces 12+ chars, history 10,
complexity on, max age 90d.

## 🎯 Skills Demonstrated

AD DS forest deployment · DNS · DHCP (scopes, reservations, options) · OU design ·
RBAC via security groups · Group Policy (security baseline, screen lock, RDP) ·
SMB file services with NTFS ACLs · PowerShell automation · lab documentation.
