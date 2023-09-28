#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Converts the content of a file from base64 and writes the resulting binary data to a file.
.PARAMETER LiteralPath
    Path to the file to decode.
.PARAMETER Encoding
    The text encoding to use when writing the result to a file. Defaults to UTF8.
.PARAMETER OutFile
    Path to the file to write the decoded content to. If not specified, it will be the same as the input file without the extension.
.OUTPUTS
    System.IO.FileInfo
#>
function decodefile64 {
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string] $LiteralPath,

        [Parameter(Mandatory=$false, Position=1)]
        [ValidateNotNullOrEmpty()]
        [Encoding] $Encoding = [System.Text.Encoding]::UTF8,

        [Parameter(Mandatory=$false, Position=2)]
        [ValidateNotNullOrEmpty()]
        [string] $OutFile = [System.IO.Path]::GetFileNameWithoutExtension($LiteralPath)
    )
    Begin {
        if (Test-Path $OutFile -ErrorAction SilentlyContinue) {
            throw "The file already exists: ${OutFile}"
        }
    }
    Process {
        [byte[]] $decoded = [Convert]::FromBase64String([System.IO.File]::ReadAllText($LiteralPath, $Encoding))
        [System.IO.File]::WriteAllBytes($OutFile, $decoded)
        return (Get-Item -LiteralPath $OutFile)
    }
    End {
    }
}
