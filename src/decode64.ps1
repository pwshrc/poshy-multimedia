#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function decode64 {
    param(
        [Parameter(Mandatory=$false, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $encodedText
    )
    return [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encodedText))
}
