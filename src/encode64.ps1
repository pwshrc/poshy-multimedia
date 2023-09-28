#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Outputs the given text or binary data as base64-encoded text.
.PARAMETER Text
    The text to encode.
.PARAMETER Data
    The binary data to encode.
.PARAMETER Encoding
    The encoding to use when converting the text to binary data. Defaults to UTF8.
.OUTPUTS
    System.String
.EXAMPLE
    encode64 "Hello World!"
#>
function encode64 {
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ParameterSetName="Text")]
        [ValidateNotNullOrEmpty()]
        [string] $Text,

        [Parameter(Mandatory=$false, Position=0, ValueFromPipeline=$true, ParameterSetName="Data")]
        [ValidateNotNullOrEmpty()]
        [byte[]] $Data,

        [Parameter(Mandatory=$false, Position=1, ParameterSetName="Text")]
        [ValidateNotNullOrEmpty()]
        [Encoding] $Encoding = [System.Text.Encoding]::UTF8
    )
    if ($text) {
        return [Convert]::ToBase64String($Encoding.GetBytes($Text))
    } else {
        return [Convert]::ToBase64String($Data)
    }
}
