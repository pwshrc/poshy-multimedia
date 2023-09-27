#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


Get-ChildItem -Path "$PSScriptRoot/*.ps1" | ForEach-Object {
    . $_.FullName
    Export-ModuleMember -Function $_.BaseName
}


Set-Alias -Name d64 -Value decode64
Set-Alias -Name df64 -Value decodefile64
Set-Alias -Name e64 -Value encode64
Set-Alias -Name ef64 -Value encodefile64

# because upper case is like YELLING
Set-Alias -Name uuid -Value uuidl
Set-Alias -Name uuidgen -Value uuidl

Export-ModuleMember -Alias @(
    "d64",
    "df64",
    "e64",
    "ef64",
    "uuid",
    "uuidgen"
)
