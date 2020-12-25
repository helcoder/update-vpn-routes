$settings = Get-Content "$PSScriptRoot\settings.json" | ConvertFrom-Json

[string]$connName = $settings.connName
[string[]]$hosts = $settings.hosts

if (!$connName) {
	Write-Host "connName must be specified in settings.json"
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	exit
}

Write-Host "Connection name: $connName"

if (!$hosts || !$hosts.Length) {
	Write-Host "Hosts: none were specified in settings.json`n"
} else {
	Write-Host "Hosts: $hosts`n"
}

$conn = Get-VpnConnection -ConnectionName $connName

foreach ($route in $conn.routes) {
	Write-Host "Removing $($route.DestinationPrefix)"
	Remove-VpnConnectionRoute -ConnectionName $connName -DestinationPrefix $route.DestinationPrefix
}

Write-Host

foreach ($hostsItem in $hosts) {
	$dns = Resolve-DnsName $hostsItem -Type A

	foreach ($dnsItem in $dns) {
		if ($dnsItem.Type -eq "A") {
			Write-Host "Adding $hostsItem $($dnsItem.IPAddress)"
			Add-VpnConnectionRoute -ConnectionName $connName -DestinationPrefix "$($dnsItem.IPAddress)/32"
		}
	}
}

Write-Host "`nNote that your VPN connection has to be reconnected`n"

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')