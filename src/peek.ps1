#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function peek() {
    # TODO: Make this not break. Maybe temporarily change preference variable.
    $input | Tee-Object -Variable _ | Write-Error
    $_
}
