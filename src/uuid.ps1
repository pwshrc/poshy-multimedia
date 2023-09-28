#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Outputs a new UUID, in uppercase.
#>
function uuidu {
    return [guid]::NewGuid().ToString().ToUpper()
}

<#
.SYNOPSIS
    Outputs a new UUID, in lowercase.
#>
function uuidl {
    return [guid]::NewGuid().ToString().ToLower()
}

