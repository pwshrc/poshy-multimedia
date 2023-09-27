#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function encode64 {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $text
    )
    return [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($text))
}
