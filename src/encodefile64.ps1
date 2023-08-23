#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function encodefile64 {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $file
    )
    [string] $encoded = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($file))
    [string] $encodedFile = "${file}.txt"
    [System.IO.File]::WriteAllText($encodedFile, $encoded)
    Write-Host "${file}'s content encoded in base64 and saved as ${encodedFile}"
}
Set-Alias -Name ef64 -Value encodefile64
