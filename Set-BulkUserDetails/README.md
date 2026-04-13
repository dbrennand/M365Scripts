# Set-BulkUserDetails

Sets all users' `DisplayName` and `JobTitle` (role) from a CSV file. Useful for bulk-updating user details in a Microsoft 365 tenant.

## Prerequisites

* Required Microsoft Graph API permissions: `User.ReadWrite.All`
* A CSV file with the following columns:
  * `User Principle Name` — user's UPN (e.g. `john.doe@example.com`)
  * `Display Name` — the display name to set
  * `Role Name` — the job title to set

## Dependencies

`Microsoft.Graph >=2.28.0`:

```PowerShell
Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
```

## Usage

```PowerShell
Set-BulkUserDetails.ps1 -CsvFile "UserDetails.csv"
```

Preview changes without applying them (`-WhatIf`):

```PowerShell
Set-BulkUserDetails.ps1 -CsvFile "UserDetails.csv" -WhatIf
```

### CSV format

```csv
User Principle Name,Display Name,Role Name
john.doe@example.com,John Doe,Software Engineer
jane.smith@example.com,Jane Smith,Product Manager
```
