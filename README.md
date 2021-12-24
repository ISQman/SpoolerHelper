Mini service, written on powershell (minimum v2), which checking printer status and compare if it accessible. If printer accessible but have status offline - restarts spooler to renew all statuses.
Clear code in SpoolerHelper.ps1 but You can install from exe.
Installer contains nssm.exe to make this script as a service.