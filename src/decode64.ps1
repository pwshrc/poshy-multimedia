#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Outputs the decoded text from a base64 encoded string.
.PARAMETER EncodedText
    The base64 encoded string to decode.
.PARAMETER AsBytes
    If specified, the output will be a byte array instead of a string.
.PARAMETER Encoding
    The encoding to use when converting the binary data to text. Defaults to UTF8.
.OUTPUTS
    System.String
    System.Byte[]
.EXAMPLE
    decode64 "SGVsbG8gV29ybGQh"
#>
function decode64 {
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ParameterSetName="Text")]
        [ValidateNotNullOrEmpty()]
        [string] $EncodedText,

        [Parameter(Mandatory=$false, Position=1, ParameterSetName="Bytes")]
        [switch] $AsBytes,

        [Parameter(Mandatory=$false, Position=1, ParameterSetName="Text")]
        [ValidateNotNullOrEmpty()]
        [Encoding] $Encoding = [System.Text.Encoding]::UTF8
    )
    [byte[]] $bytes = [Convert]::FromBase64String($EncodedText)
    if ($AsBytes) {
        return $bytes
    } else {
        return $Encoding.GetString($bytes)
    }
}
