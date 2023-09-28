#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Opens the given target in the default application for its file type.
.PARAMETER Target
    The target to open.
.PARAMETER Rest
    Any additional arguments to pass to the open command.
#>
function open_command {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $target,

        [Parameter(Mandatory=$false, Position=1, ValueFromRemainingArguments=$true)]
        [string[]] $rest = @()
    )

    [string[]] $open_cmd = $null

    if ($Env:BROWSER) {
        [Uri] $targetAsUri = $null
        [Uri]::TryCreate($target, [ref] $targetAsUri)
        if ($targetAsUri -and $targetAsUri.Scheme -notin @("http", "https")) {
            $targetAsUri = $null
        }
    }

    # define the open command
    if ($targetAsUri) {
        $open_cmd = @($Env:BROWSER)
    } elseif ($IsWSL) {
        $open_cmd=@('cmd.exe', '/c', 'start', '""')
        if (Test-Path $target) {
            $target = (wslpath -w $target)
        }
    } elseif ($IsWindows) {
        $open_cmd=@('cmd.exe', '/c', 'start', '""')
    } elseif ($IsLinux) {
        if (Test-Command xdg-open) {
            $open_cmd=@('nohup', 'xdg-open')
        } elseif (Test-Command gvfs-open) {
            $open_cmd=@('nohup', 'gvfs-open')
        } elseif (Test-Command exo-open) {
            $open_cmd=@('nohup', 'exo-open')
        } elseif (Test-Command kde-open) {
            $open_cmd=@('nohup', 'kde-open')
        } else {
            throw [System.PlatformNotSupportedException]::new("No supported open command found. Please install one of xdg-open, gvfs-open, exo-open, or kde-open.")
        }
    } elseif ($IsMacOS) {
        $open_cmd=@('open')
    } else {
        throw [System.PlatformNotSupportedException]::new()
    }

    # add the target
    $open_cmd += @($target)

    # add the rest of the arguments
    if ($rest) {
        $open_cmd += @($rest)
    }

    # run the command
    &$x[0] $x[1..($x.Length-1)]
}
