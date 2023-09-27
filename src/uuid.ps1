#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function uuidu {
    return [guid]::NewGuid().ToString().ToUpper()
}

function uuidl {
    return [guid]::NewGuid().ToString().ToLower()
}

