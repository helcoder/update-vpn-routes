$settings = Get-Content "$PSScriptRoot\settings.json" | ConvertFrom-Json
$items = $settings.items;
$hash = @{}
$fileHash = @{}

Write-Host "Resolving hosts..."

foreach ($item in $items) {
	$itemHash = @{}

	foreach ($hostsItem in $item.hosts) {
		$dns = Resolve-DnsName $hostsItem -Type A

		foreach ($dnsItem in $dns) {
			if ($dnsItem.Type -eq "A") {
				if ($hash.Keys -notcontains $dnsItem.IPAddress) {
					$hash[$dnsItem.IPAddress] = @()
				}

				$hash[$dnsItem.IPAddress] += $hostsItem

				$itemHash[$dnsItem.IPAddress] = $hash[$dnsItem.IPAddress]

				$text = "`n#$hostsItem`nroute $($dnsItem.IPAddress)"
				Write-Host $text -NoNewline
			}
		}
	}

	foreach ($file in $item.files) {
		if ($fileHash.Keys -notcontains $file) {
			$fileHash[$file] = @{}
		}

		foreach ($ip in $itemHash.Keys) {
			$fileHash[$file][$ip] = $itemHash[$ip]
		}
	}
}

foreach ($file in $fileHash.Keys) {
	$newRoutes = ""

	foreach ($ip in $fileHash[$file].Keys) {
		$item = ""

		foreach ($h in $fileHash[$file][$ip]) {
			$item += "`n#$h"
		}

		$item += "`nroute $ip"
		$newRoutes += $item
	}

	if (Test-Path $file) {
		(Get-Content $file -Raw) -replace '(?s)(#BEGINAUTOROUTES).*?(#ENDAUTOROUTES)', "`$1`n$newRoutes`n`n`$2" | Out-File $file -encoding utf8
		Write-Host "`n`n$file has been updated"
	} else {
		Write-Host "`n`nUnable to update $file because it doesn't exist"
	}
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
