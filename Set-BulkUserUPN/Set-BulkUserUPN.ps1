<#PSScriptInfo

.VERSION 1.0.0

.GUID 9b1a6f62-c4b3-47f0-b320-4503766514ef

.AUTHOR dbrennand [ 52419383+dbrennand@users.noreply.github.com ]

.TAGS Set Bulk User UPN

.LICENSEURI

.PROJECTURI https://github.com/dbrennand/M365Scripts

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

#>

<#
.SYNOPSIS
    Set all users primary User Principal Name (UPN) to a new domain.

.DESCRIPTION
    Sets all users primary UPN to a new domain. Used for migrating to a new Microsoft 365 domain.

.PARAMETER Domain
    The domain to set for all users primary UPN.

.EXAMPLE
    Set-BulkUserUPN.ps1 -Domain "example.com" -Verbose

.LINK
    https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph?view=graph-powershell-1.0
    https://learn.microsoft.com/en-us/powershell/microsoftgraph/get-started?view=graph-powershell-1.0
#>
#Requires -Version 7 -Modules @{ ModuleName = "Microsoft.Graph"; ModuleVersion = "2.28.0" }
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Domain
)

begin {
    #region Connect to Microsoft Graph
    $Scopes = "User.ReadWrite.All", "Domain.Read.All"
    try {
        Write-Verbose -Message "Connecting to Microsoft Graph with scopes: $($Scopes)."
        Connect-MgGraph -Scopes $Scopes -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction Stop
    }
    catch {
        Write-Error -Message "Failed to connect to Microsoft Graph:`n$($_.Exception.Message)"
        exit 1
    }
    #endregion

    #region Check the Domain is registered with the Microsoft 365 tenant
    try {
        Write-Verbose -Message "Checking if domain $($Domain) is registered with the Microsoft 365 tenant."
        $Domains = Get-MgDomain -All
        if ($Domain -notin $Domains.Id) {
            throw "Domain $($Domain) is not registered."
        }
    }
    catch {
        Write-Error -Message "Failed to get domain $($Domain) in the Microsoft 365 tenant:`n$($_.Exception.Message)"
        exit 1
    }
    #endregion
}

process {
    #region Collect all users
    try {
        Write-Verbose -Message "Collecting all users from the Microsoft 365 tenant."
        $Users = Get-MgUser -All -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction Stop
        Write-Output -InputObject "Found $($Users.Count) users in Microsoft 365 tenant."
    }
    catch {
        Write-Error -Message "Failed to connect all users from the Microsoft 365 tenant:`n$($_.Exception.Message)"
        exit 1
    }
    #endregion

    #region Change each users UPN to the new domain
    try {
        foreach ($User in $Users) {
            $UserName = ($User.UserPrincipalName -split "@")[0]
            $NewUserPrincipleName = "$($UserName)@$($Domain)"
            Write-Output -InputObject "Changing User Principle Name from $($User.UserPrincipalName) to $($NewUserPrincipleName)."
            Update-MgUser -UserId $User.Id -UserPrincipalName $NewUserPrincipleName -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction Stop
        }
    }
    catch {
        Write-Error -Message "Failed to modify User Principle Name for $($User.UserPrincipalName):`n$($_.Exception.Message)"
        exit 1
    }
    #endregion
}
