<#PSScriptInfo

.VERSION 1.0.0

.GUID 5eb214e0-3e61-40aa-80e4-12ddee39c919

.AUTHOR dbrennand [ 52419383+dbrennand@users.noreply.github.com ]

.TAGS Set Bulk User Details

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
    Set all users' details (DisplayName and Title).

.DESCRIPTION
    Set all users' details (DisplayName and Title) from a CSV file.

.PARAMETER CsvFile
    Absolute or relative path to the CSV input file.

.EXAMPLE
    Set-BulkUserDetails.ps1 -CsvFile "UserDetails.csv"
#>
#Requires -Version 7 -Modules @{ ModuleName = "Microsoft.Graph"; ModuleVersion = "2.28.0" }
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [String]
    $CsvFile
)

begin {
    #region Load the CSV file
    try {
        $Csv = Import-Csv -Path $CsvFile -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction Stop
    }
    catch {
        Write-Error -Message "Failed to load CSV file ""$($CsvFile)"":`n$($_.Exception.Message)"
        exit 1
    }
    #endregion

    #region Connect to Microsoft Graph
    $Scopes = "User.ReadWrite.All"
    try {
        Write-Verbose -Message "Connecting to Microsoft Graph with scopes: $($Scopes)."
        Connect-MgGraph -Scopes $Scopes -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction Stop
    }
    catch {
        Write-Error -Message "Failed to connect to Microsoft Graph:`n$($_.Exception.Message)"
        exit 1
    }
    #endregion
}

process {
    #region Find each user and modify their details
    foreach ($Row in $Csv) {
        $UserPrincipalName = $Row."User Principle Name"
        $RoleName = $Row."Role Name"
        $DisplayName = $Row."Display Name"
        try {
            Write-Verbose -Message "Retrieving user using UPN ""$($UserPrincipalName)""."
            $User = Get-MgUser -ConsistencyLevel "eventual" -Search "userPrincipalName:$($UserPrincipalName)" -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction Stop
            if (-not $User) {
                throw "User not found."
            }
            Write-Output -InputObject "Found user using UPN ""$($User.UserPrincipalName)""."
        }
        catch {
            Write-Error -Message "Failed to retrieve user with UPN ""$($UserPrincipalName)"":`n$($_.Exception.Message)"
            exit 1
        }
        # Set the user's Title and DisplayName properties
        Write-Output -InputObject "Setting user with UPN ""$($User.UserPrincipalName)"" | Role title ""$($RoleName)"" | Display Name ""$($DisplayName)""."
        if ($PSCmdlet.ShouldProcess($User.UserPrincipalName, "Modify")) {
            $User | Set-MgUser -JobTitle $RoleName -DisplayName $DisplayName -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction Stop
        }
    }
    #endregion
}
