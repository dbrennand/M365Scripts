# Set-BulkUserUPN

Sets all users primary UPN to a new domain. Used for migrating to a new Microsoft 365 domain.

## Prerequisites

* Custom domain registered on your Microsoft 365 tenant.
* Required Microsoft Graph API permissions: `User.ReadWrite.All, Domain.Read.All`

## Dependencies

`Microsoft.Graph >=2.28.0`:

```PowerShell
Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
```

## Usage

```PowerShell
./Set-BulkUserUPN.ps1 -Domain "example.com" -Verbose
```
