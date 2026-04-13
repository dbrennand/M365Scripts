<#PSScriptInfo

.VERSION 1.0.0

.GUID 2b0f2c1d-7d2a-4d0a-9a4e-7b1b5d2f1c6e

.AUTHOR Daniel Brennand [ 52419383+dbrennand@users.noreply.github.com ] with assistance from GPT-5.

.TAGS Get Users Never Signed In

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
    Get users who have never signed in (no sign-in activity recorded).

.DESCRIPTION
    Retrieves Microsoft 365 users where Microsoft Graph reports no sign-in activity.
    Due to Microsoft Graph data availability, signInActivity reflects only recent activity
    (typically up to the last 30 days). Users returned by this script either never signed in
    or have no sign-ins within the Graph retention window.

.PARAMETER ExportCsv
    Optional path to export Results as CSV.

.PARAMETER CreatedWithinDays
    Optional filter: only include users created within the specified number of days.
    Useful to approximate "never signed in" for newly provisioned accounts.

.EXAMPLE
    Get-NeverSignedInUsers.ps1 -Verbose

.EXAMPLE
    Get-NeverSignedInUsers.ps1 -CreatedWithinDays 30 -ExportCsv "NeverSignedIn.csv" -Verbose

.LINK
    https://learn.microsoft.com/graph/api/resources/signinactivity
    https://learn.microsoft.com/powershell/module/microsoft.graph.users/get-mguser
#>
#Requires -Version 7 -Modules @{ ModuleName = "Microsoft.Graph"; ModuleVersion = "2.28.0" }
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String]
    $ExportCsv,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 3650)]
    [Int]
    $CreatedWithinDays
)

begin {
    #region Connect to Microsoft Graph
    $Scopes = "User.Read.All", "AuditLog.Read.All"
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
    #region Collect all users (including signInActivity)
    $SelectProperties = "id,displayName,userPrincipalName,userType,accountEnabled,createdDateTime,signInActivity"
    try {
        Write-Verbose -Message "Collecting users with properties: $($SelectProperties)."
        $Users = Get-MgUser -All -Property $SelectProperties -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction Stop
        Write-Output -InputObject "Retrieved $($Users.Count) users from Microsoft Graph."
    }
    catch {
        Write-Error -Message "Failed to collect users from Microsoft Graph:`n$($_.Exception.Message)"
        exit 1
    }
    #endregion

    #region Filter users with no recorded sign-in activity
    try {
        $NeverSignedIn = $Users |
            Where-Object -FilterScript {
                -not $_.SignInActivity -or (
                    -not $_.SignInActivity.LastSignInDateTime -and -not $_.SignInActivity.LastNonInteractiveSignInDateTime
                )
            }

        if ($PSBoundParameters.ContainsKey("CreatedWithinDays")) {
            $CutOff = [DateTimeOffset]::UtcNow.AddDays(-1 * $CreatedWithinDays)
            Write-Verbose -Message "Applying CreatedWithinDays filter: created after $($CutOff)."
            $NeverSignedIn = $NeverSignedIn | Where-Object -FilterScript { $_.CreatedDateTime -ge $CutOff }
        }

        $Result = $NeverSignedIn | Select-Object -Property `
            Id, `
            DisplayName, `
            UserPrincipalName, `
            UserType, `
            AccountEnabled, `
            CreatedDateTime, `
            @{ Name = "LastSignInDateTime"; Expression = { $_.SignInActivity.LastSignInDateTime } }, `
            @{ Name = "LastNonInteractiveSignInDateTime"; Expression = { $_.SignInActivity.LastNonInteractiveSignInDateTime } }

        Write-Output -InputObject "Users with no recorded sign-in activity found: $($Result.Count)."
    }
    catch {
        Write-Error -Message "Failed to filter users without sign-in activity:`n$($_.Exception.Message)"
        exit 1
    }
    #endregion

    #region Output or export results
    try {
        if ($PSBoundParameters.ContainsKey("ExportCsv")) {
            Write-Verbose -Message "Exporting results to CSV: $($ExportCsv)."
            $Result | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
            Write-Output -InputObject "Exported results to: $($ExportCsv)."
        }
        else {
            $Result
        }
    }
    catch {
        Write-Error -Message "Failed to export results:`n$($_.Exception.Message)"
        exit 1
    }
    #endregion
}
