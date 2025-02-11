
$CdriveStatus = Get-BitLockerVolume -MountPoint 'c:'
if ($CdriveStatus.volumeStatus -eq 'FullyDecrypted') {
    C:\Windows\System32\manage-bde.exe -on c: -recoverypassword -skiphardwaretest
}

$BLV = Get-BitLockerVolume -MountPoint 'c:'
if ($BLV.volumeStatus -eq 'FullyDecrypted') {
    Add-BitLockerKeyProtector -MountPoint 'c:' -RecoveryPasswordProtector
    Enable-Bitlocker -MountPoint 'c:' -TpmProtector
}
