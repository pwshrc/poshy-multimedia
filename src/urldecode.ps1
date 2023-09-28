#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Outputs the URL-decoded text from a URL-encoded string.
#>
function urldecode {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string] $text
    )
    [System.Web.HttpUtility]::UrlDecode($text)
}
