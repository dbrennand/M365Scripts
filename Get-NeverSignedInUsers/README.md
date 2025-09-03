# Get-NeverSignedInUsers

Gets Microsoft 365 users who have no recorded sign-in activity (via Microsoft Graph `signInActivity`). Useful for identifying newly provisioned or inactive accounts. Note: `signInActivity` reflects recent history (typically ~30 days), so results include users who never signed in or have no sign-ins within that window.

## Prerequisites

* Required Microsoft Graph API permissions: `User.Read.All, AuditLog.Read.All`

## Dependencies

`Microsoft.Graph >=2.28.0`:

```PowerShell
Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
```

## Usage

```PowerShell
Get-NeverSignedInUsers.ps1 -Verbose
```

Export results to CSV:

```PowerShell
Get-NeverSignedInUsers.ps1 -ExportCsv "NeverSignedIn.csv" -Verbose
```

Limit to users created within the last 30 days (approximate "never" for new accounts):

```PowerShell
Get-NeverSignedInUsers.ps1 -CreatedWithinDays 30 -ExportCsv "NeverSignedIn.csv" -Verbose
```
