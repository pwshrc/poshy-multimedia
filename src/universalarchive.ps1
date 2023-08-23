#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Archive files and directories using a given compression algorithm.
.PARAMETER format
    The archive format to use.
.PARAMETER files
    The files and directories to archive.
.EXAMPLE
    universalarchive tbz PKGBUILD
.NOTES
  Supported archive formats are:
  7z, bz2, gz, lzma, lzo, rar, tar, tbz (tar.bz2), tgz (tar.gz),
  tlz (tar.lzma), txz (tar.xz), tZ (tar.Z), xz, Z, zip, and zst."
#>
function universalarchive {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("7z", "bz2", "gz", "lzma", "lzo", "rar", "tar", "tbz", "tgz", "tlz", "txz", "tZ", "xz", "Z", "zip", "zst")]
        [string] $format,

        [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
        [ValidateCount(1, [int]::MaxValue)]
        [ValidateNotNullOrEmpty()]
        [ValidationScript({ Test-Path $_ -PathType LeafOrContainer })]
        [string[]] $files
    )
    # generate output file name
    [string] $output = $null
    if ($files.Count -gt 1) {
      # output="${file:h:t}"
      $output=(dirname $files[0])
    } elsif (Test-Path $file -PathType Leaf -ErrorAction SilentlyContinue) {
      $output=(basename $files[0] -replace "\.[^.]+$", "")
    } elseif (Test-Path $file -PathType Container -ErrorAction SilentlyContinue) {
      $output=(basename $files[0])
    }

    # if output file exists, generate a random name
    if (Test-Path "${output}.${format}" -ErrorAction SilentlyContinue) {
      $output=(mktemp "${output}_XXX")
      if ($LASTEXITCODE -ne 0) {
        throw "Failed to generate temporary file name."
      }
      Remove-Item $output
    }

    # add extension
    $output="${output}.${format}"

    # safety check
    if (Test-Path "$output" -ErrorAction SilentlyContinue) {
      throw "Output file '$output' already exists."
    }

    switch ($format) {
        "7z" {
            7z u $output @files
        }

        "bz2" {
            bzip2 -vcf @files > $output
        }

        "gz" {
            gzip -vcf @files > $output
        }

        "lzma" {
            lzma -vc -T0 @files > $output
        }

        "lzo" {
            lzop -vc @files > $output
        }

        "rar" {
            rar a $output @files
        }

        "tar" {
            tar -cvf $output @files
        }

        "tbz" {
            tar -cvjf $output @files
        }

        "tar.bz2" {
            tar -cvjf $output @files
        }

        "tgz" {
            tar -cvzf $output @files
        }

        "tar.gz" {
            tar -cvzf $output @files
        }

        "tlz" {
            xwith @{
                XZ_OPT = "-T0"
            }, {
                tar --lzma -cvf @args
            } @($output)+$files
        }

        "tar.lzma" {
            xwith @{
                XZ_OPT = "-T0"
            }, {
                tar --lzma -cvf @args
            } @($output)+$files
        }

        "txz" {
            xwith @{
                XZ_OPT = "-T0"
            }, {
                tar -cvJf @args
            } @($output)+$files
        }

        "tar.xz" {
            xwith @{
                XZ_OPT = "-T0"
            }, {
                tar -cvJf @args
            } @($output)+$files
        }

        "tZ" {
            tar -cvZf $output @files
        }

        "tar.Z" {
            tar -cvZf $output @files
        }

        "xz" {
            xz -vc -T0 @args > $output
        }

        "Z" {
            compress -vcf @files > $output
        }

        "zip" {
            zip -rull $output @files
        }

        "zst" {
            zstd -c -T0 @files > $output
        }

        default {
            throw "Unsupported archive format '$format'."
        }
    }
}
