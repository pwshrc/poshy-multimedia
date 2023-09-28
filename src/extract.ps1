#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Extracts the content of an archive file.
.PARAMETER File
    The archive file to extract.
#>
function extract {
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromRemainingArguments=$true)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [ValidateNotNullOrEmpty()]
        [string[]] $File
    )

    [string] $verbose = $VerbosePreference -eq "Continue" ? "v" : ""

    foreach ($file_entry in $File) {
        [string] $filename = (basename $file_entry)
        [string] $filedirname = (dirname $file_entry)

        [string[]] $sufficesNotInOutputDirName = @(
            ".tar.bz2",
            ".tbz",
            ".tbz2",
            ".tar.gz",
            ".tgz",
            ".tar",
            ".tar.xz",
            ".txz",
            ".tar.Z",
            ".7z",
            ".nupkg",
            ".zip",
            ".war",
            ".jar"
        )
        [string] $targetdirname = $filename
        foreach ($suffix in $sufficesNotInOutputDirName) {
            if ($filename -like "*${suffix}") {
                $targetdirname = $filename -replace "${suffix}$", ""
                break
            }
        }
        if ($filename -eq $targetdirname) {
            # archive type either not supported or it doesn't need dir creation
            $targetdirname=""
        } else {
            mkdir -v "$filedirname/$targetdirname"
        }

        [hashtable] $filenameMatcherActions = @{}
        if (Test-Command tar) {
            $filenameMatcherActions+=@{
                "*.tar.bz2|*.tbz|*.tbz2"={
                    tar "x${verbose}jf" "$filename" -C "$filedirname/$targetdirname"
                }

                "*.tar.gz|*.tgz"={
                    tar "x${verbose}zf" "$filename" -C "$filedirname/$targetdirname"
                }

                "*.tar.xz|*.txz"={
                    tar "x${verbose}Jf" "$filename" -C "$filedirname/$targetdirname"
                }

                "*.tar.Z"={
                    tar "x${verbose}Zf" "$filename" -C "$filedirname/$targetdirname"
                }
            }
        }
        if (Test-Command bunzip2) {
            $filenameMatcherActions+=@{
                "*.bz2"={
                    bunzip2 "$filename"
                }
            }
        }
        if (Test-Command dpkg-deb) {
            $filenameMatcherActions+=@{
                "*.deb"={
                    dpkg-deb -x${verbose} $filename $filename.Substring(0, $filename.Length - 4)
                }
            }
        }
        if (Test-Command gunzip) {
            $filenameMatcherActions+=@{
                "*.pax.gz"={
                    gunzip $filename # ; set -- "$@" "${filename:0:-3}"
                }

                "*.gz"={
                    gunzip $filename
                }
            }
        }
        if (Test-Command pax) {
            $filenameMatcherActions+=@{
                "*.pax"={
                    pax -r -f $filename
                }
            }
        }
        if (Test-Command pkgutil) {
            $filenameMatcherActions+=@{
                "*.pkg"={
                    pkgutil --expand $filename $filename.Substring(0, $filename.Length - 4)
                }
            }
        }
        if (Test-Command unrar) {
            $filenameMatcherActions+=@{
                "*.rar"={
                    unrar x "$filename"
                }
            }
        }
        if (Test-Command rpm2cpio) {
            $filenameMatcherActions+=@{
                "*.rpm"={
                    rpm2cpio "$filename" | cpio -idm${verbose}
                }
            }
        }
        if (Test-Command tar) {
            $filenameMatcherActions+=@{
                "*.tar"={
                    tar "x${verbose}f" "$filename" -C "$filedirname/$targetdirname"
                }
            }
        }
        if (Test-Command xz) {
            $filenameMatcherActions+=@{
                "*.xz"={
                    xz --decompress "$filename"
                }
            }
        }
        if (Test-Command unzip) {
            $filenameMatcherActions+=@{
                "*.zip|*.war|*.jar|*.nupkg"={
                    unzip "$filename" -d "$filedirname/$targetdirname"
                }
            }
        }
        if (Test-Command uncompress) {
            $filenameMatcherActions+=@{
                "*.Z"={
                    uncompress "$filename"
                }
            }
        }
        if (Test-Command 7za) {
            $filenameMatcherActions+=@{
                "*.7z"={
                    7za x -o"$filedirname/$targetdirname" "$filename"
                }
            }
        }

        [bool] $matched = $false
        foreach ($matcher in $filenameMatcherActions.Keys) {
            [string[]] $matchers = $matcher -split "\|"
            foreach ($match in $matchers) {
                if ($filename -like $match) {
                    $matched = $true
                    & $filenameMatcherActions[$matcher] $file_entry
                    break
                }
            }
        }
        if (-not $matched) {
            Write-Error "'$filename' cannot be extracted via extract"
        }
    }
}
