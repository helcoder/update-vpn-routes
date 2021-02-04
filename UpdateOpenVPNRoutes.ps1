$settings = Get-Content "$PSScriptRoot\settings.json" | ConvertFrom-Json
$OVPNFile = $settings.OVPNFile
[string[]]$hosts = $settings.hosts
$newRoutes = ""

Write-Host "Resolving hosts..."

foreach ($hostsItem in $hosts) {
	$dns = Resolve-DnsName $hostsItem -Type A

	foreach ($dnsItem in $dns) {
		if ($dnsItem.Type -eq "A") {
			$item = "`n#$hostsItem`nroute $($dnsItem.IPAddress)"
			$newRoutes += $item
			Write-Host $item -NoNewline
		}
	}
}

if (Test-Path $OVPNFile) {
	(Get-Content $OVPNFile -Raw) -replace '(?s)(#BEGINAUTOROUTES).*?(#ENDAUTOROUTES)', "`$1`n$newRoutes`n`n`$2" | Out-File $OVPNFile
	Write-Host "`n`n$OVPNFile has been updated"
} else {
	Write-Host "`n`nUnable to update $OVPNFile because it doesn't exist"
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
