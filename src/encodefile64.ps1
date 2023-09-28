#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Converts the binary content of a file to base64 and writes the resulting text to a file.
.PARAMETER LiteralPath
    Path to the file to encode.
.PARAMETER Encoding
    The text encoding to use when writing the result to a file. Defaults to UTF8.
.PARAMETER OutFile
    Path to the file to write the encoded content to. If not specified, it will be the same as the input file with the extension ".txt" appended.
.OUTPUTS
    System.IO.FileInfo
#>
function encodefile64 {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string] $LiteralPath,

        [Parameter(Mandatory=$false, Position=1)]
        [ValidateNotNullOrEmpty()]
        [Encoding] $Encoding = [System.Text.Encoding]::UTF8,

        [Parameter(Mandatory=$false, Position=2)]
        [ValidateNotNullOrEmpty()]
        [string] $OutFile = ($LiteralPath + ".txt")
    )
    Begin {
        if (Test-Path $OutFile -ErrorAction SilentlyContinue) {
            throw "The file already exists: ${OutFile}"
        }
    }
    Process {
        [string] $encoded = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($LiteralPath))
        [System.IO.File]::WriteAllText($OutFile, $encoded, $Encoding)
        return (Get-Item -LiteralPath $OutFile)
    }
    End {
    }
}
