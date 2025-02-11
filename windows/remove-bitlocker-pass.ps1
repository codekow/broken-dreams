<#
    .SYNOPSIS
    Remove-BitLockerPass.ps1

    .DESCRIPTION
    Remove old BitLocker Recovery Passwords from Active Directory for all computers.

    .LINK
    www.alitajran.com/remove-old-bitlocker-recovery-passwords/

    .NOTES
    Written by: ALI TAJRAN
    Website:    alitajran.com
    X:          x.com/alitajran
    LinkedIn:   linkedin.com/in/alitajran

    .CHANGELOG
    V1.00, 10/06/2024 - Initial version
#>

# Fetching computers from Active Directory
$Computers = Get-ADComputer -Filter 'ObjectClass -eq "computer"' -Property Name, DistinguishedName, OperatingSystem | Sort-Object Name

foreach ($computer in $Computers) {
    $params = @{
        Filter     = 'objectclass -eq "msFVE-RecoveryInformation"'
        SearchBase = $computer.DistinguishedName
        Properties = 'msFVE-RecoveryPassword', 'whencreated'
    }

    # Get BitLocker recovery information
    $bitlockerInfos = Get-ADObject @params | Sort-Object -Property WhenCreated -Descending

    if ($bitlockerInfos) {
        # Keep only the latest recovery password
        $latestRecoveryInfo = $bitlockerInfos[0]
        Write-Host "BitLocker Recovery information found for $($computer.Name)" -ForegroundColor Cyan

        # Check if there are more than one recovery keys to process
        if ($bitlockerInfos.Count -gt 1) {
            # Remove all but the latest recovery information
            foreach ($info in $bitlockerInfos[1..($bitlockerInfos.Count - 1)]) {
                try {
                    Remove-ADObject -Identity $info.DistinguishedName -Confirm:$false
                    Write-Host "Removed old BitLocker Recovery key for $($computer.Name) created on $($info.whencreated)" -ForegroundColor Green
                }
                catch {
                    Write-Host "Failed to remove old BitLocker Recovery key for $($computer.Name): $_" -ForegroundColor Red
                }
            }
        }
        else {
            Write-Host "Only one BitLocker Recovery key found for $($computer.Name). No action required." -ForegroundColor Cyan
        }
    }
    else {
        Write-Host "No BitLocker Recovery information found for $($computer.Name)" -ForegroundColor Cyan
    }
}
