#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function decodefile64 {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $encodedFile
    )
    [string] $decoded = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String([System.IO.File]::ReadAllText($encodedFile)))
    [string] $decodedFile = $encodedFile.Replace(".txt", "")
    [System.IO.File]::WriteAllText($decodedFile, $decoded)
    Write-Host "${encodedFile}'s content decoded from base64 and saved as ${decodedFile}"
}
Set-Alias -Name df64 -Value decodefile64
