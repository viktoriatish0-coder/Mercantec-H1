# Script 1: Serverinfo-rapport
# Formål: Viser OS, seneste opdatering, netværk og kørende services.

Write-Host "=== OS Information ===" -ForegroundColor Cyan
# Henter OS info
$os = Get-CimInstance -ClassName Win32_OperatingSystem
Write-Host "OS Navn: $($os.Caption)"
Write-Host "Version: $($os.Version)"

Write-Host "`n=== Seneste Windows Update ===" -ForegroundColor Cyan
# Henter hotfixes, sorterer efter dato, og tager den nyeste
$lastUpdate = Get-HotFix | Sort-Object -Property InstalledOn -Descending | Select-Object -First 1
Write-Host "Opdatering: $($lastUpdate.HotFixID) installeret den $($lastUpdate.InstalledOn)"

Write-Host "`n=== Netværkskonfiguration ===" -ForegroundColor Cyan
# Henter netværkskort, filtrerer dem der har en gateway (er aktive) og vælger specifikke felter
Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null } | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway

Write-Host "`n=== Kørende Services ===" -ForegroundColor Cyan
# Henter alle services, filtrerer kun de kørende, sorterer alfabetisk og viser som tabel
Get-Service | Where-Object { $_.Status -eq 'Running' } | Sort-Object -Property Name | Select-Object Name, DisplayName | Format-Table
