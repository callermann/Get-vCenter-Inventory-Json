Param (
    [Parameter(Mandatory=$true)]
    [string]$Server,
    [Parameter(Mandatory=$true)]
    [string]$User,
    [Parameter(Mandatory=$true)]
    [string]$Password,
    [string]$Cluster = $null
)

$vCenter_connection = Connect-VIServer -Server $Server -User $user -Password $Password

If($Cluster -ne $null) {
    $vms = Get-Cluster $vc_cluster | Get-VM    
}
Else {
    $vms = Get-VM
}

$vms_parsed = @()

ForEach($vm in $vms) {

    $vmObject = New-Object System.Object
    $vmObject | Add-Member -Type NoteProperty -Name Name -Value $vm.Name
    $vmObject | Add-Member -Type NoteProperty -Name Cluster -Value ((Get-Cluster -VM $vm.Name).Name)
    $vmObject | Add-Member -Type NoteProperty -Name PowerState  -Value $vm.PowerState
    $vmObject | Add-Member -Type NoteProperty -Name Notes  -Value $vm.Notes
    $vmObject | Add-Member -Type NoteProperty -Name NumCpu  -Value $vm.NumCpu
    $vmObject | Add-Member -Type NoteProperty -Name CoresPerSocket  -Value $vm.CoresPerSocket
    $vmObject | Add-Member -Type NoteProperty -Name MemoryMB  -Value $vm.MemoryMB
    $vmObject | Add-Member -Type NoteProperty -Name MemoryGB  -Value $vm.MemoryGB
    $vmObject | Add-Member -Type NoteProperty -Name VMHost  -Value $vm.VMHost.Name
    $vmObject | Add-Member -Type NoteProperty -Name Version  -Value $vm.Version
    $vmObject | Add-Member -Type NoteProperty -Name UsedSpaceGB  -Value $vm.UsedSpaceGB
    $vmObject | Add-Member -Type NoteProperty -Name ProvisionedSpaceGB  -Value $vm.ProvisionedSpaceGB
    $vmObject | Add-Member -Type NoteProperty -Name Id  -Value $vm.Id

    $vmObject | Add-Member -Type NoteProperty -Name Guest -Value (New-Object System.Object)
    $vmObject.Guest | Add-Member -Type NoteProperty -Name OSFullName -Value $vm.Guest.OSFullName
    $vmObject.Guest | Add-Member -Type NoteProperty -Name State -Value $vm.Guest.State
    $vmObject.Guest | Add-Member -Type NoteProperty -Name Hostname -Value $vm.Guest.HostName
    $vmObject.Guest | Add-Member -Type NoteProperty -Name GuestFamily -Value $vm.Guest.GuestFamily
    $vmObject.Guest | Add-Member -Type NoteProperty -Name Nics -Value @()
        
    $nics_parsed  = @()
    ForEach($nic in $vm.Guest.Nics) {
        $nicObject = New-Object System.Object
        $nicObject | Add-Member -Type NoteProperty -Name Device -Value $nic.Device.Name
        $nicObject | Add-Member -Type NoteProperty -Name Connected -Value $nic.Connected
        $nicObject | Add-Member -Type NoteProperty -Name MacAddress -Value $nic.MacAddress
        
        $nicObject | Add-Member -Type NoteProperty -Name Ips -Value @()        
        ForEach($ip in $Vm.Guest.Nics.IPAddress) {
            If( $ip -ne $null) {    
                $ipObject = New-Object System.Object
                $ipObject | Add-Member -Type NoteProperty -Name IP -Value ([IPAddress]$ip).IPAddressToString
                $ipObject | Add-Member -Type NoteProperty -Name Family -Value ([IPAddress]$ip).AddressFamily.ToString()

                If($ipObject.Family -eq "InterNetwork") { $ipObject.Family = "IPv4" }
                ElseIf($ipObject.Family -eq "InterNetworkV6") { $ipObject.Family = "IPv6" }
            
                $nicObject.Ips += $ipObject
            }
        }
        
        $vmObject.Guest.Nics += $nicObject

    }
  
    $vms_parsed += $vmObject

}

$vms_parsed | ConvertTo-Json -Depth 6
