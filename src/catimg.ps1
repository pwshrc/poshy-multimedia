#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Output the content of an image to the stdout using the 256 colors of the terminal.
.PARAMETER Width
    Width of the output in characters. If not specified, it will be the width of the terminal.
.PARAMETER Char
    Character to use to display the image. If not specified, it will be two spaces.
.PARAMETER File
    Path to the image to display.
.EXAMPLE
    catimg image.png
.EXAMPLE
    catimg -Width 80 -Char "  " image.png
.EXAMPLE
    catimg -Width 80 -Char "  " -File image.png
.EXAMPLE
    catimg -Width 80 -Char "  " -File image.png | less -R
.LINK
    https://github.com/posva/catimg
.NOTES
    This script requires ImageMagick to be installed.
.DESCRIPTION
    catimg script by Eduardo San Martin Morote aka Posva
#>
function catimg {
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateRange(1, [int]::MaxValue)]
        [Nullable[int]] $Width = $null,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateLength(1, 2)]
        [ValidateNotNullOrEmpty()]
        [string] $Char = "  ",

        [Parameter(Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [ValidateNotNullOrEmpty()]
        [string] $File,

        [Parameter(Mandatory = $false, Position = 3)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [ValidateNotNullOrEmpty()]
        [string] $ColorFile = (Join-Path (Split-Path $MyInvocation.MyCommand.Path) ../shell/oh-my-zsh/plugins/catimg/colors.png)
    )
    Begin {
        [bool] $imageMagickInstalled = (Test-Command convert) -and (
            (convert --version 2> $null) -like "*ImageMagick*"
        )
        if ($imageMagickInstalled) {
            throw "The 'convert' command is not available. Please install ImageMagick."
        }
        if (-not $Width) {
            $Cols = $Host.UI.RawUI.WindowSize.Width / $Char.Length
        } else {
            $Cols = $Width / $Char.Length
        }
        [string] $platformNullFilePath = if ($IsWindows) { "NUL" } else { "/dev/null" }
        if (-not (Get-Module poshy-colors -ErrorAction SilentlyContinue)) {
            Import-Module poshy-colors -DisableNameChecking
        }
    }
    Process {

        [int] $WIDTH=(convert $File -print "%w\n" $platformNullFilePath)
        if ( $WIDTH -gt $COLS ) {
            $WIDTH=$COLS
        }

        [string[]] $REMAP=@()

        # Test compatibility with -remap.
        convert "$File" -resize "${COLS}\>" +dither -remap $COLOR_FILE $platformNullFilePath 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $REMAP=@("-remap", $COLOR_FILE)
        } else {
            Write-Warning "The version of convert is too old, don't expect good results :("
            #convert "$File" -colors 256 PNG8:tmp.png
            #File="tmp.png"
        }

        # Display the image
        $I=0
        [string[]] $convertOutput = (convert "$File" -resize "${COLS}\>" +dither @REMAP txt:- 2> $null)
        $convertOutput = $convertOutput | Select-Object -Skip 1

        [PSCustomObject[]] $pixels = (
            $convertOutput `
            | ForEach-Object { (($_ -replace "\s+","`t") -replace ":`t","`t") -replace "[(),]","`t" -replace "`t`t","`t" } `
            | ConvertFrom-Csv -Delimiter "`t" -Header col,row,rgb16R,rgb16B,rgb16G,rgb8hex,nameKind,nameArg1,nameArg2,nameArg3
            | ForEach-Object { [PSCustomObject]@{ col=[int]$_.col; row=[int]$_.row; rgb16R=$_.rgb16R; rgb16G=$_.rgb16G; rgb16B=$_.rgb16B } } `
            | Sort-Object -Property row,col
        )

        $lastRowNumber = 0
        [StringBuilder] $output = [StringBuilder]::new()
        [string] $fmtReset = (fmtReset)
        foreach ($pixel in $pixels) {
            if ($pixel.row -ne $lastRowNumber) {
                $lastRowNumber = $pixel.row
                $output = $output.AppendLine($fmtReset)
            }
            $lastRowNumber = $pixel.row

            if ($pixel.rgb16R -ne "none") {
                [byte] $r = [byte]($pixel.rgb16R / 65535)
                [byte] $g = [byte]($pixel.rgb16G / 65535)
                [byte] $b = [byte]($pixel.rgb16B / 65535)
                $fgRgb = (fgRgb $r $g $b)
                $bgRgb = (bgRgb $r $g $b)
                $output = $output.Append("${fgRgb}${bgRgb}${CHAR}")
            } else {
                $output = $output.Append("${fmtReset}${CHAR}")
            }
        }
        $output.ToString()
        $output.Clear() | Out-Null
    }
}
