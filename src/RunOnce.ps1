#########################################
# Load the Server Manager Module
#########################################
Import-Module ServerManager;


#########################################
# Update the PowerShell Execution policy 
# to allow your own scripts to be run
#########################################
Set-ExecutionPolicy Unrestricted -Force -Confirm:$false;
Write-Host "Updated the PowerShell Execution Policy to Unrestricted." -ForegroundColor Green;


#########################################
# Disable the windows firewall
#########################################
Get-NetFirewallProfile | Set-NetFirewallProfile –Enabled False;
Write-Host "The Windows Firewall has been disabled." -ForegroundColor Green;


#########################################
# Enable PS Remoting (WinRM)
# Source: http://technet.microsoft.com/en-us/library/hh849694.aspx
#########################################
Enable-PSRemoting -Force -Confirm:$false;
Write-Host "PowerShell Remoting (WinRM) has been enabled." -ForegroundColor Green;


#########################################
# Enable Remote Desktop
#########################################
$rdp = Get-WmiObject -Class Win32_TerminalServiceSetting -Namespace root\CIMV2\TerminalServices -Computer localhost -Authentication 6 -ErrorAction Stop;
$rdp.SetAllowTsConnections(1,1);
Write-Host "Windows has been updated to allow Remote Desktop Connections." -ForegroundColor Green;


#########################################
# Windows Power Options
#########################################
Write-Host "Setting Powerplan to High performance" 
$guid = (Get-WmiObject -Class win32_powerplan -Namespace root\cimv2\power -Filter "ElementName='High performance'").InstanceID.tostring();
$regex = [regex]"{(.*?)}$";
powercfg -S $regex.Match($guid).groups[1].value;
Write-Host "The Windows Power Options have been updated to High Performance." -ForegroundColor Green;


#########################################
# Disable IE Enhanced security mode
#########################################
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}";
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}";
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0;
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0;
Stop-Process -Name Explorer;
Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green;


#########################################
# Disable UAC
#########################################
Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -Value 0;
Write-Host "User Account Control (UAC) has been disabled." -ForegroundColor Green;


#########################################
# Set filesystem label on C disk
#########################################
Set-Volume -NewFileSystemLabel "OS" -DriveLetter "C";
Write-Host "The OS Partition has been labelled as: OS" -ForegroundColor Green;


#########################################
# Change Drive Letter on DVD Drive to Z
#########################################
gwmi Win32_Volume -Filter "DriveType = '5'" | swmi -Arguments @{DriveLetter = "Z:"};
Write-Host "The CD.DVD Drive has been relabelled to Z:." -ForegroundColor Green;


#########################################
# Make all offline disks online:
#########################################
Get-Disk | ? IsOffline –eq $true | Set-Disk –IsOffline $false; 
Write-Host "All offline disks have been brought online." -ForegroundColor Green;


#########################################
# Initialize all disks with RAW partition
#########################################
Get-Disk | Where-Object PartitionStyle –eq "RAW" | Initialize-Disk –PartitionStyle "MBR";
Write-Host "All RAW disks have been initialised with MBR partitions." -ForegroundColor Green;


#########################################
# List all disks without any partitions
#########################################
Write-Host "The following disks have no partitions:" -ForegroundColor Green;
Get-Disk | Where-Object NumberOfPartitions -eq 0;


#########################################
# Create partition on the disks, change DiskNumber and other paramters, examples
#########################################
$unpartitionedDisks = Get-Disk | Where-Object NumberOfPartitions -eq 0;
foreach($disk in $unpartitionedDisks)
{
    $partition = New-Partition –DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter; 
    $partition | Format-Volume -NewFileSystemLabel "Data" -FileSystem NTFS -Confirm:$false;
}
Write-Host "All disks have been partitioned with a single partition using all available space." -ForegroundColor Green;


#########################################
# Rename the network adapters
# This is based on what is available in the order below
#########################################
"netsh interface set interface name=`"Ethernet`" newname=`"Private Network Connection`"",
"netsh interface set interface name=`"Ethernet 2`" newname=`"Management Network Connection`"",
"netsh interface set interface name=`"Ethernet 3`" newname=`"Public Internet Connection`""
Write-Host "The network adapters have been renamed." -ForegroundColor Green;


#########################################
# Disable network discovery
#########################################
# Todo:


#########################################
# Disable Windows Updates
# http://support.microsoft.com/kb/328010
#########################################
$regkey1 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate";
$regkey2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU";

if (!(Test-Path $regkey1))
{ 
    New-Item HKLM:\SOFTWARE\Policies\Microsoft\Windows -Name WindowsUpdate;
}

if (!(Test-Path $regkey2))
{ 
    New-Item HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate -Name AU;
}

$regkey3 = Get-ItemProperty $regkey2 "NoAutoUpdate" -ErrorAction SilentlyContinue;

if ($regkey3 -eq $null)
{ 
    New-ItemProperty $regkey2 -Name "NoAutoUpdate" -Value 1;
}
else
{
    Set-ItemProperty $regkey2 -Name "NoAutoUpdate" -Value 1;
}
Write-Host "Windows updates have been disabled." -ForegroundColor Green;


#########################################
# Create a Tools directory
#########################################
$toolsDirectory = "c:\Tools";

if (!(Test-Path $toolsDirectory))
{ 
    New-Item -ItemType directory -Path $toolsDirectory;
}
Write-Host "A Tools directory has been created at: $toolsDirectory." -ForegroundColor Green;


#########################################
# Download 7Zip
#########################################
# $7ZipDirectory = "$toolsDirectory\7-Zip";
# 
# if (!(Test-Path $7ZipDirectory))
# { 
    # New-Item -ItemType directory -Path $7ZipDirectory;
# }
# 
# $7zipSource = "http://downloads.sourceforge.net/sevenzip/7z920.exe";
# 
# $webClient = New-Object System.Net.WebClient;
# $7ZipDestination = "$7ZipDirectory\7z.exe";
# $webClient.DownloadFile($7zipSource,$7ZipDestination)


#########################################
# Add BGInfo to local machine
#
#Install and run BGInfo at startup using registry method as described here:
#http://forum.sysinternals.com/bginfo-at-startup_topic2081.html
#Setup 
#1. Download BgInfo http://technet.microsoft.com/en-us/sysinternals/bb897557
#2. Create a bginfo folder and copy bginfo.exe
#3. Create a bginfo.bgi file by running bginfo.exe and saving a bginfo.bgi file and placing in same directory as bginfo
#########################################
$bgInfoDestination = "$toolsDirectory\BgInfo";
$bgInfoExe = "https://www.dropbox.com/s/kkb5zownrq9d98d/Bginfo.exe?dl=1";
$bgInfoExePath = $bgInfoDestination + "\BgInfo.exe";
$bgInfoTemplate = "https://www.dropbox.com/s/fsf0inwwusouipu/config.bgi?dl=1";
$bgInfoTemplatePath = $bgInfoDestination + "\BgInfo.bgi";


if (!(Test-Path $bgInfoDestination))
{ 
    New-Item -ItemType directory -Path $bgInfoDestination;
}

# Download the BgInfo Exe and Template
$webClient = New-Object System.Net.WebClient;
$webClient.DownloadFile($bgInfoExe, "$bgInfoDestination\BgInfo.exe");
$webClient.DownloadFile($bgInfoTemplate, "$bgInfoDestination\BgInfo.bgi");
Write-Host "BgInfo has been downloaded." -ForegroundColor Green;


# Unblock the files
Unblock-File $bgInfoExePath;
Unblock-File $bgInfoTemplatePath;
Write-Host "BgInfo files have been unblocked." -ForegroundColor Green;


Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -name "BgInfo" -value "$bgInfoExePath $bgInfoTemplatePath /TIMER:0 /NOLICPROMPT";
Write-Host "BgInfo has been set to run." -ForegroundColor Green;


#########################################
# RE-ARM Windows Activation
# This should be removed for licensed installations
#
# OPTIONS:
# Install product keys with the –ipk option
# Activate Windows with the –ato option
# Reactive a Windows evaluation license with the –rearm option
# Use the –xpr option to see how much time you have remaining
# Use -dli to display license information
#########################################
$slc = Get-WmiObject -ComputerName localhost -Query "SELECT * FROM SoftwareLicensingService";
$slc.ReArmWindows();
Write-Host "Windows has been re-armed." -ForegroundColor Green;
Write-Host "This should give you another 10 days before you have to license the OS." -ForegroundColor Green;


#########################################
# Restart the VM
#########################################
Write-Host "Now it's time to restart this VM." -ForegroundColor Green;
Start-Sleep -s 5;
Write-Host "Shutting down..." -ForegroundColor Green;
Start-Sleep -s 2;
Restart-Computer -Force -Confirm:$false;





#########################################
# Todo:
#########################################
# Reset Admin Password
# Reset Administrator Password
# Disable other accounts
# Turn Network Discovery Off
