#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function urlencode {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string] $text
    )
    [System.Web.HttpUtility]::UrlEncode($text)
}
