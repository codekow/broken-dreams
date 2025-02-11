@echo off
REM Run as Administrator
REM Manage-bde.exe -protectors -disable c:
set test /a = "qrz"
for /F "tokens=3 delims= " %%A in ('manage-bde -status %systemdrive% ^| findstr "    Encryption Method:"') do (
	echo %%A
	set test = %%A
	if "%%A"=="None" goto :activate
	)
rem goto end
:activate
echo in activate
for /F %%A in ('wmic /namespace:\\root\cimv2\security\microsofttpm path win32_tpm get IsEnabled_InitialValue ^| findstr "TRUE"') do (
if "%%A"=="TRUE" goto :bitlock
)
powershell Initialize-Tpm
:bitlock

:end
manage-bde -protectors -disable %systemdrive% 
REM next two lines disables system restore to help prevent bitlocker recovery key request
bcdedit /set {default} recoveryenabled No 
bcdedit /set {default} bootstatuspolicy ignoreallfailures
manage-bde -protectors -delete %systemdrive% -type RecoveryPassword
manage-bde -protectors -add %systemdrive% -RecoveryPassword
for /F "tokens=2 delims=: " %%A in ('manage-bde -protectors -get C: -type recoverypassword ^| findstr "       ID:"') do (
	echo %%A
	manage-bde -protectors -adbackup %systemdrive% -id %%A
)
manage-bde -protectors -enable %systemdrive%

rem  \\lib-fs\lib-gpo\BDEChangeID.bat
rem  manage-bde -status %systemdrive%
