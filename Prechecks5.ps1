
function routeprint {
$routeprinttemp = route print
$routeprinttemp | out-file "C:\Serverinfo\details\routeprint_Pre.txt"
}




function Get-IPconfig {
$Ipconfig = Ipconfig /all
$Ipconfig | out-file "C:\Serverinfo\details\Ipconfig_Pre.txt"
}




Function IPdetails($servername)
{

    $IPAddress1 = ""
    $IPAddress = (Get-WmiObject -ComputerName $servername Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -ne $null }) | foreach {

        $IPAddress2 = $_.IPAddress
        $IPAddress1 = "$IPAddress2 | "
                
        $IPAddress1

    }
    $DNSDomain1 = ""
    $DNSDomain = (Get-WmiObject -ComputerName $servername Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -ne $null }) | foreach {


        $DNSDomain2 = $_.DNSDomain
        $DNSDomain1 = "$DNSDomain2 | "
        $DNSDomain1

    }
    $IPSubnet1 
    $IPSubnet = (Get-WmiObject -ComputerName $servername Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -ne $null }) | foreach {

         $IPSubnet2 = $_.IPSubnet

         $IPSubnet1 = "$IPSubnet2 | "
         $IPSubnet1
    }
    $DefaultIPGateway1
    $DefaultIPGateway = (Get-WmiObject -ComputerName $servername Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -ne $null }) | foreach {


        $DefaultIPGateway2 = $_.DefaultIPGateway
        $DefaultIPGateway1 = "$DefaultIPGateway2 | "
        $DefaultIPGateway1

    }

    $IPObj = New-Object psobject
    $IPObj | Add-Member NoteProperty "IPAddress" $IPAddress
    $IPObj | Add-Member NoteProperty "DNSDomain" $DNSDomain
    $IPObj | Add-Member NoteProperty "IPSubnet" $IPSubnet
    $IPObj | Add-Member NoteProperty "DefaultIPGateway" $DefaultIPGateway


   
    return $IPObj

}



Function Get-dotnetversion ($servername){


$installdotnet3 = [System.Collections.ArrayList]@()

$installdotnet4 = [System.Collections.ArrayList]@()


$Reg1 = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $server)
if($? -eq $true)
{
     $key1 = $Reg1.OpenSubKey("SOFTWARE\Microsoft\NET Framework Setup\NDP").GetSubKeyNames()
    foreach($key in $key1)
    {
        $Reg2 = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $server)
        if($? -eq $true)
        {
            $key2 = $Reg2.OpenSubKey("SOFTWARE\Microsoft\NET Framework Setup\NDP\$key")
            $regvalue = $key2.getvalue("Install")
            
           if ($regvalue -eq 1)
            {
                $installdotnet1 = $key
                $add = $installdotnet3.Add($installdotnet1)

            }
            if($regvalue -eq $null)
            {
                 $key2 = $Reg2.OpenSubKey("SOFTWARE\Microsoft\NET Framework Setup\NDP\$key\client")
                 
                 $regvalue = $key2.getvalue("Install")
                 if($? -eq $true)
                 {
                    
                    
                    $Versionregvalue = $key2.getvalue("Version")
                    
                    if($regvalue -eq 1)
                    {
                        $installdotnet2 = $regvalue
                       $add1=$installdotnet4.Add($Versionregvalue)
                    }
                    

                 }
                 

            }
            else
            {
                Clear-Variable installdotnet1
            }
        }
      

        


    }


    


      $dotnetStr1 = ""
    foreach($dotnet1 in $installdotnet3)
    {
        

        $dotnetStr1 += "$dotnet1|"
    }

       $dotnetStr2 = ""
    foreach($dotnet2 in $installdotnet4)
    {
        

        $dotnetStr2 += "$dotnet2|"
    }

    $dotnet = "$dotnetStr1 $dotnetStr2 "
    New-Object -Type PSCustomObject -Property @{
                                        
                                        Info         = "Installed Dotnet Versions"
                                        Dotnet_vesrions            = $dotnet
                                        
                                 }
   
}
else
{
   
}


}

function get-dsk ($servername)
       {
             get-WmiObject Win32_DiskDrive -ComputerName $servername | % {
                    $disk = $_
                    $partitions = "ASSOCIATORS OF " +
                    "{Win32_DiskDrive.DeviceID='$($disk.DeviceID)'} " +
                    "WHERE AssocClass = Win32_DiskDriveToDiskPartition"
                    Get-WmiObject -ComputerName $servername -Query $partitions | % {
                           $partition = $_
                           $drives = "ASSOCIATORS OF " +
                           "{Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} " +
                           "WHERE AssocClass = Win32_LogicalDiskToPartition"
                           Get-WmiObject -ComputerName $servername -Query $drives | % {
                                 $part1 = $partition.Name
                                 $part2 = $part1 -split ', ' `
                                 -split ','
                                 $diskid = ($part2[0]) -replace '#', ''
                                 $part = ($part2[1]) -replace '#', ''
                                 New-Object -Type PSCustomObject -Property @{
                                        
                                        
                                        Disk         = $disk.DeviceID
                                        TotalSize    = $disk.Size
                                        DiskModel    = $disk.Model
                                        DiskID      = $diskid
                                        Partition    = $part
                                        RawSize           = $partition.Size
                                        DriveLetter  = $_.DeviceID
                                        VolumeName   = $_.VolumeName
                                        Size         = $_.Size
                                        FreeSpace    = $_.FreeSpace
                                 }
                           }
                    }
             }
       }
       
       
       
       

function Server-details{
<#
.CREATED BY:
    Sunil Chaudhari
.CREATED ON:
    18\08\2020
.SYNOPSIS
    Creates an HTML file on the Desktop of the local machine full of detailed system information.
.DESCRIPTION
    Server-details utilizes WMI to retrieve information related to the physical hardware of the machine(s), the available `
    disk space, when the machine(s) last restarted and bundles all that information up into a colored HTML report.
.EXAMPLE
   Server-details -Computername localhost, SRV-2012R2, DC-01, DC-02
   This will create an HTML file on your desktop with information gathered from as many computers as you can access remotely
#>
      [CmdletBinding(SupportsShouldProcess=$True)]
param([Parameter(Mandatory=$false,
      ValueFromPipeline=$true)]
      #[string]$FilePath = "C:\users\$env:USERNAME\desktop\Write-HTML.html",
      [string]$FilePath = "C:\Serverinfo\details\details.html",
      [string[]]$Computername = $env:COMPUTERNAME,

$Css='<style>table{margin:auto; width:98%}
              Body{background-color:LightSeaGreen; Text-align:Center;}
                th{background-color:DarkOrange; color:white;}
                td{background-color:Lavender; color:Black; Text-align:Center;}
     </style>' )

Begin{ Write-Verbose "HTML report will be saved $FilePath" 

if(!(Test-Path "C:\Serverinfo\details"))
{
md C:\Serverinfo\details
#md C:\Serverinfo\pServerinfoheck
#Write-Host "Path not exist"

}
Else {
#Write-Host "path exist"
}

}

Process{ 

$Hardware = Get-WmiObject -class Win32_ComputerSystem -ComputerName $Computername | 
         Select-Object Name,Domain,Manufacturer,Model,NumberOfLogicalProcessors,
         @{ Name = "Installed Memory (GB)" ; Expression = { "{0:N0}" -f( $_.TotalPhysicalMemory / 1gb ) } } |
         ConvertTo-Html -Fragment -As Table -PreContent "<h2>Hardware</h2>" | 
         Out-String

$Hardware1=Get-WmiObject -class Win32_ComputerSystem -ComputerName $Computername | 
         Select-Object Name,Domain,Manufacturer,Model,NumberOfLogicalProcessors,
         @{ Name = "Installed Memory (GB)" ; Expression = { "{0:N0}" -f( $_.TotalPhysicalMemory / 1gb ) } }

$Hardware1 | epcsv C:\Serverinfo\details\Hardware_Pre.Csv -NoTypeInformation 

$diskinfo = get-dsk -servername $Computername | select DiskID, Partition, DriveLetter, @{ name = 'Size'; E = { "{0:N2}" -f ($_.Size /1gb) } }, @{ Name = 'FreeSpace'; e = { "{0:N2}" -f ($_.FreeSpace/1GB) } },@{ Name = "Percent Free" ; Expression = { "{0:P0}" -f( $_.FreeSpace / $_.Size ) } } | Sort-Object DriveLetter | ConvertTo-Html -Fragment -As Table -PreContent "<h2>Available Disk Space</h2>" | 
               Out-String
       
       

$diskinfo1 = get-dsk -servername $Computername | select DiskID, Partition, DriveLetter, @{ name = 'Size'; E = { "{0:N2}" -f ($_.Size /1gb) } }, @{ Name = 'FreeSpace'; e = { "{0:N2}" -f ($_.FreeSpace/1GB) } },@{ Name = "Percent Free" ; Expression = { "{0:P0}" -f( $_.FreeSpace / $_.Size ) } } | Sort-Object DriveLetter | Export-Csv C:\Serverinfo\details\Disk_Pre.Csv -NoTypeInformation 



$Patches = Get-WmiObject Win32_QuickFixEngineering -computername $Computername | Where-object  { $_.InstalledOn -gt (get-date).AddDays(-20) }|
            Select-Object HotFixID,Description,InstalledBy,InstalledOn |
            ConvertTo-Html -Fragment -As Table -PreContent "<h2>Patch Details</h2>" | 
            Out-String


$auto_Services = Get-WmiObject win32_service -ComputerName $Computername | Where-Object { $_.State -eq "Running" } | 
                  select-object SystemName,Name,DisplayName,Processid,Startmode,state|
                  ConvertTo-Html -Fragment -As Table -PreContent "<h2>Runing Services</h2>" |
                  Out-String
                  
$auto_Services1 = Get-WmiObject win32_service -ComputerName $Computername | Where-Object { $_.State -eq "Running" } | 
                  select-object SystemName,Name,DisplayName,Processid,Startmode,state

$auto_Services1 |epcsv C:\Serverinfo\details\Services_Pre.Csv -NoTypeInformation

    
$Restarted = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computername | Select-Object CSName,Caption,
             @{ Name = "Last Restarted On" ; Expression = { $_.Converttodatetime( $_.LastBootUpTime ) } } |
             ConvertTo-Html -Fragment -As Table -PreContent "<h2>Last Boot Up Time</h2>" | 
             Out-String



[string]$Target=(Get-WmiObject Win32_NetworkAdapterConfiguration -EA Stop | where {$_.IPEnabled -eq $true}).DefaultIPGateway
   
    $PacketCount='4'


        $Target = $Target.Trim(' ')
        $i=1
        $networkinfo = $Target | %{
        $name = $_; Test-Connection $Target -Count $PacketCount| `
        Measure-Object ResponseTime -Maximum -minimum | select @{name='Source Computer';expression={$Computername}},`
        @{name='Target Computer';expression={$Target}},  @{name='Packet Count';expression={$_.count}},`
        @{name='Maximum Time(ms)';expression={$_.Maximum}}, @{name='Minimum Time(ms)';expression={$_.Minimum}} 
        $i++
        }
    
    $networkinfo | Export-Csv C:\Serverinfo\details\network_Pre.csv -NoTypeInformation


    #$networkinfohtml = $networkinfo | ConvertTo-Html -Fragment -As Table -PreContent "<h2>Gateway Latency</h2>" | Out-String

    [string]$Target=@((Get-WmiObject Win32_NetworkAdapterConfiguration  -EA Stop | ? {$_.IPEnabled}).DNSServerSearchOrder)
$PacketCount='4'
$dnsinfo=@()

foreach ($var in $Target.Split(' '))
{
    
        $i=1
        $dnsinfo += $var | %{
        $name = $_; Test-Connection $var -Count $PacketCount| Measure-Object ResponseTime -Maximum -minimum | select @{name='Source Computer';expression={$Computername}},@{name='Target Computer';expression={$var}},  @{name='Packet Count';expression={$_.count}},@{name='Maximum Time(ms)';expression={$_.Maximum}}, @{name='Minimum Time(ms)';expression={$_.Minimum}} 
        $i++
        }

}
#$dnsinfo | Export-Csv C:\Serverinfo\details\DNS_Pre.csv -NoTypeInformation
#$dnsinfohtml = $dnsinfo | ConvertTo-Html -Fragment -As Table -PreContent "<h2>DNS Latency</h2>" | Out-String


$ComputerName=$env:COMPUTERNAME

foreach ($Computer in $ComputerName) 
   { 
          
                $hostdns = [System.Net.DNS]::GetHostEntry($Computer)
                $IPAddress = ([System.Net.Dns]::GetHostByName($Computer).AddressList[0]).IpAddressToString
                $ComputerSystemInfo = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $Computer 
                $OS= Get-WmiObject -Class Win32_operatingsystem
                switch ($ComputerSystemInfo.Model)
                 { 
       
                    "Virtual Machine" { 
                        $MachineType="Hyper-v" 
                        } 

                    "VMware Virtual Platform" { 
                        $MachineType="VMWare" 
                        } 
                    "VirtualBox" { 
                        $MachineType="VirtualBOx" 
                        } 

                    default { 
                        $MachineType= $ComputerSystemInfo.Model 
                        } 
                 } 
                 
                     if($MachineType -eq "Hyper-v")
                     {  
                                    $key = 'SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters'
                                    $valuename = 'HostName'
                                    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
	                                $regkey = $reg.opensubkey($key)
	                                $Global:Hypervisor=$regkey.getvalue($valuename)

                                    $ComputerName=$env:COMPUTERNAME
                                    $IP=$IPAddress
                                    $Type=$MachineType
                                    $Hypervisor=$Global:Hypervisor
                                    $OS= $os.caption
                                    $Manufacturer=$ComputerSystemInfo.Manufacturer 
                                    $Model=$ComputerSystemInfo.Model         

                     }
                     elseIf($MachineType -eq "VMWare")
                     {
                                    $ComputerName=$env:COMPUTERNAME
                                    $IP=$IPAddress
                                    $Type=$MachineType
                                    $Hypervisor= "VMware"
                                    $OS= $os.caption
                                    $Manufacturer=$ComputerSystemInfo.Manufacturer 
                                    $Model=$ComputerSystemInfo.Model     
                     }
                     else
                     {                     
                                    $ComputerName=$env:COMPUTERNAME
                                    $IP=$IPAddress
                                    $Type=$MachineType
                                    $Hypervisor= "Others"
                                    $OS= $os.caption
                                    $Manufacturer=$ComputerSystemInfo.Manufacturer 
                                    $Model=$ComputerSystemInfo.Model 
                     }
 
    }

  


$ipdata= IPdetails $Computername |select @{n="IPAddress";e={[string]$_.IPAddress}},@{n="DNSDomain";e={[string]$_.DNSDomain}},@{n="IPSubnet";e={[string]$_.IPSubnet}},@{n="DefaultIPGateway";e={[string]$_.DefaultIPGateway}}|
         ConvertTo-Html -Fragment -As Table -PreContent "<h2>Server IP Details</h2>" | 
         Out-String

$ipdata1= IPdetails $Computername |select @{n="IPAddress";e={[string]$_.IPAddress}},@{n="DNSDomain";e={[string]$_.DNSDomain}},@{n="IPSubnet";e={[string]$_.IPSubnet}},@{n="DefaultIPGateway";e={[string]$_.DefaultIPGateway}}

$ipdata1|epcsv C:\Serverinfo\details\IpDetails_Pre.Csv -NoTypeInformation 



$avData= AVInfo $Computername| select Version,@{Name = "AV Update Date" ; Expression = { $_.Update} } |
        ConvertTo-Html -Fragment -As Table -PreContent "<h2>Anti-Virus Version & Update Date</h2>" |
        Out-String

$avData1=AVInfo $Computername| select Version,@{Name = "AV Update Date" ; Expression = { $_.Update} }

$avData1 |epcsv C:\Serverinfo\details\AVDetails_Pre.Csv -NoTypeInformation 
 
 $dtnetvrsion = Get-dotnetversion -servername $Computername |select info,Dotnet_vesrions | ConvertTo-Html -Fragment -As Table -PreContent "<h2>DotNet Version </h2>" |
        Out-String

     $dtnetvrsion1 =  Get-dotnetversion -servername $Computername |select info,Dotnet_vesrions | Export-Csv C:\Serverinfo\details\dotnet_Pre.Csv -NoTypeInformation


$fileShare= filesharesinfo $Computername|select Name,Path,Description,Permissions|
            ConvertTo-Html -Fragment -As Table -PreContent "<h2>File Share Details</h2>" |
            Out-String

$fileShare1= filesharesinfo $Computername|select Name,Path,Description,Permissions| Export-Csv C:\Serverinfo\details\share_Pre.Csv -NoTypeInformation
$tooldetails = get-tools -servername $Computername | select DisplayName,Name,Status | ConvertTo-Html -Fragment -As Table -PreContent "<h2>Installed Tools </h2>" |
        Out-String

$tooldetails1 = get-tools -servername $Computername | select DisplayName,Name,Status | Export-Csv C:\Serverinfo\details\tools_Pre.Csv -NoTypeInformation





########################################################
# Added new features in html file
########################################################


           Function Get-LocalGroupMembers
           {
                 param (
                        [Parameter(ValuefromPipeline = $true)]
                        [array]$server = $env:computername,
                        $GroupName = $null
                 )
                 PROCESS
                 {
                        $finalresult = @()
                        $computer = [ADSI]"WinNT://$server"
                    
                        if (!($groupName))
                        {
                               $Groups = $computer.psbase.Children | Where { $_.psbase.schemaClassName -eq "group" } | select -expand name
                        }
                        else
                        {
                               $groups = $groupName
                        }
                        $CurrentDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().GetDirectoryEntry() | select name, objectsid
                        $domain = $currentdomain.name
                        $SID = $CurrentDomain.objectsid
                        $DomainSID = (New-Object System.Security.Principal.SecurityIdentifier($sid[0], 0)).value
                    
                    
                        foreach ($group in $groups)
                        {
                    
                               $gmembers = $null
                               $LocalGroup = [ADSI]("WinNT://$server/$group,group")
                           
                           
                               $GMembers = $LocalGroup.psbase.invoke("Members")
                               $GMemberProps = @{ Server = "$server"; "Local Group" = $group; Name = ""; Type = ""; ADSPath = ""; Domain = ""; SID = "" }
                               $MemberResult = @()
                           
                           
                               if ($gmembers)
                               {
                                     foreach ($gmember in $gmembers)
                                     {
                            
                                            $membertable = new-object psobject -Property $GMemberProps
                                            $name = $gmember.GetType().InvokeMember("Name", 'GetProperty', $null, $gmember, $null)
                                            $sid = $gmember.GetType().InvokeMember("objectsid", 'GetProperty', $null, $gmember, $null)
                                            $UserSid = New-Object System.Security.Principal.SecurityIdentifier($sid, 0)
                                            $class = $gmember.GetType().InvokeMember("Class", 'GetProperty', $null, $gmember, $null)
                                            $ads = $gmember.GetType().InvokeMember("adspath", 'GetProperty', $null, $gmember, $null)
                                            $MemberTable.name = "$name"
                                            $MemberTable.type = "$class"
                                            $MemberTable.adspath = "$ads"
                                            $membertable.sid = $usersid.value
                                        
                                        
                                            if ($userSID -like "$domainsid*")
                                            {
                                                   $MemberTable.domain = "$domain"
                                            }
                                        
                                            $MemberResult += $MemberTable
                                     }
                                 
                               }
                               $finalresult += $MemberResult
                        }
                        $finalresult | select server, "local group", name, type, domain
                 }
           }
       
           $luserinfo = Get-LocalGroupMembers
$luserinfo | Export-Csv C:\Serverinfo\details\UserGroup_pre.csv -NoTypeInformation
$user_group_html=$luserinfo |ConvertTo-Html -Fragment -As Table -PreContent "<h2>USER GROUP DETAILS</h2>" | Out-String



#############################################################################################################


$Report = ConvertTo-Html -Title "$Computername" `
                         -Head "<h1>Script by Sunil Chaudhari<br><br>$Computername</h1><br>This report was ran: $(Get-Date)" `
                         -Body "$Hardware  $diskinfo $Restarted $Patches $avData $ipdata $networkinfohtml $dnsinfohtml $VLANhtml $fileShare $licenses12 $auto_Services $Css $dtnetvrsion $tooldetails $scheduled_html $user_group_html $pagefile_html" 


                       
                       
}

End{ $Report | Out-File $Filepath ; Invoke-Expression $FilePath }

}
Server-details
Write-Host "Route Print details are not available for remote computer."
routeprint
Get-IPconfig


