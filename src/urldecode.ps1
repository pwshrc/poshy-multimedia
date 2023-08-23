#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function urldecode {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string] $text
    )
    [System.Web.HttpUtility]::UrlDecode($text)
}
