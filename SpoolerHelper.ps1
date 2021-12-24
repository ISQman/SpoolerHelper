#config
$Sleep = 60
 
function Test-Connection($hostname, $port) {
    # Default state
    $State = $true
    #write-host "checking ip $hostname with port $port"
    $t = New-Object Net.Sockets.TcpClient
    # Try to connect
    Try { $t.Connect($hostname,$port) }
    # If false - change state
    Catch { $State = $false }
    # Return state
    return $State
}
 
function Get-WSDPrinterAvailable {
    Param ( [string] $PrinterName )
    # Get Bin data from Registry
    $BinFromRegistry = (Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers\$PrinterName\PnPData")."DeviceContainerId"
    $RAWID=@()
    # Converting from decimal to hex
    $BinFromRegistry | ForEach{ $RAWID += '{0:X2}' -f $_ }
    # Getting only last 6 parts
    $SearchQ = (-join ($RAWID[-6..-1])).ToLower()
    # Searching a hive
    $PrinterHive = (Get-Childitem -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\SWD\DAFWSDProvider" | Where {$_.Name -like "*$SearchQ"}).Name
    # Getting url
    $PrinterURL = (Get-ItemProperty -Path "Registry::$PrinterHive")."LocationInformation"
    Test-Connection ([System.Uri]$PrinterURL).Host ([System.Uri]$PrinterURL).Port
}
 
while ($true) {
    $Errors = 0
    # List port names of offline printers
    $Printers = Get-WmiObject -class Win32_Printer | where {$_.PrinterStatus -ne 3} | select Name,PortName
    foreach ($Printer in $Printers) {
        if ($Printer.PortName -like "WSD*") {
            if (Get-WSDPrinterAvailable $Printer.Name -eq $true) {
                $Errors += 1
            }
        } else {
            $PrinterDetails = $(Get-WmiObject -class  win32_tcpipprinterport | where {$_.Name -eq $Printer.PortName} | select HostAddress,PortNumber)
            #write-host $PrinterDetails
            if ((Test-Connection $PrinterDetails.HostAddress $PrinterDetails.PortNumber) -eq $true) {
                $Errors += 1
            }
        }
        #write-host $Errors
    }
    if ($Errors -gt 0) {
        #Write-Host "Restarting spooler"
        Restart-Service -Name Spooler
    }
    Start-Sleep -Seconds $Sleep
}
