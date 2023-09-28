#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Outputs the URL-encoded text from a string.
#>
function urlencode {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string] $text
    )
    [System.Web.HttpUtility]::UrlEncode($text)
}
