<#Install-Module -Name VMware.PowerCLI -Scope CurrentUser
Get-Childitem -Path 'C:\Program Files\WindowsPowerShell\Modules\VMware*' -Recurse | Unblock-File
Get-Module -Name VMware.PowerCLI –ListAvailable
Import-Module VMware.VimAutomation.Core
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

Get-Cluster
Get-Datastore
Get-VMHost
Get–VM
Get-Template
Get-OSCustomizationSpec

Get-VM | Where {$_.ExtensionData.Guest.ToolsStatus -notlike "toolsOk"}| select name, @{Name='Tools Status';Expression={$_.ExtensionData.Guest.ToolsStatus}}
Get-VM | Where-Object {$_.PowerState –eq “PoweredOn”} | Get-CDDrive | FT Parent, IsoPath
Get-VM | Where-Object {$_.PowerState –eq “PoweredOn”} | Get-CDDrive | Set-CDDrive -NoMedia -Confirm:$False
Get-VM | Get-snapshot | select vm, name, sizegb | ft -AutoSize
#>

$cred=Get-Credential
Connect-Viserver –Server s706vs-vcsa6-r1.sibur.local -Credential $cred –SaveCredential

# Server information
$ServerName = "S706AS-Template2"
$TypeOS= "Linux"
$IPAddress = "10.68.64.110"
$SubnetMask = "255.255.255.0"
$DefaultGateway = "10.68.64.1"
$DNS = "10.68.64.40"
$VMHost="s706vs-esxi04.sibur.local"
$Datastore ="706_ESXI01_02_Vmotion"

#Template

switch ($TypeOS) {

"Windows" {
$Template="S706AS-TemplateWindows"
New-OSCustomizationSpec -Name CustSpec -ChangeSID -OSType $TypeOS -NamingScheme Fixed -NamingPrefix "$ServerName" -FullName "Sibur" -OrgName "POLIEF"-Workgroup WORKGROUP
Get-OSCustomizationSpec CustSpec| Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress $IPAddress -SubnetMask $SubnetMask -DefaultGateway $DefaultGateway -Dns $DNS  #-Domain "$domain" –DomainUsername "$DomainUser" –DomainPassword "$DomainPassword"
    }
"Linux" {
$Template="S706AS-TemplateLinux"
New-OSCustomizationSpec -Name CustSpec -OSType $TypeOS -Domain sibur.local -NamingScheme Fixed -NamingPrefix "$ServerName" -DnsServer $DNS
Get-OSCustomizationSpec CustSpec| Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress $IPAddress -SubnetMask $SubnetMask -DefaultGateway $DefaultGateway
    }
                }

#New VM from template with spec:
New-VM -Template $Template -OSCustomizationSpec CustSpec –Name $ServerName -VMHost $VMHost -Datastore $Datastore
Start-VM -VM $ServerName
Get-VMGuest $ServerName | Update-Tools
Remove-OSCustomizationSpec CustSpec

#Copy-VMGuestFile -VM $ServerName -Source C:\Temp\1.txt -Destination C:\Temp\ -LocalToGuest -GuestUser Administrator -GuestPassword 'pa$$'

