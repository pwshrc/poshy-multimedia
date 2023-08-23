#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


if ($IsWindows) {
<#
.SYNOPSIS
    Creates a new .iso file
.DESCRIPTION
    The New-IsoFile cmdlet creates a new .iso file containing content from chosen folders
.EXAMPLE
    New-IsoFile "c:\tools","c:Downloads\utils"
    This command creates a .iso file in $env:temp folder (default location) that contains c:\tools and c:\downloads\utils folders.
    The folders themselves are included at the root of the .iso image.
.EXAMPLE
    New-IsoFile -FromClipboard -Verbose
    Before running this command, select and copy (Ctrl-C) files/folders in Explorer first.
.EXAMPLE
    dir c:\WinPE | New-IsoFile -Path c:\temp\WinPE.iso -BootFile "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\efisys.bin" -Media DVDPLUSR -Title "WinPE"
    This command creates a bootable .iso file containing the content from c:\WinPE folder, but the folder itself isn't included. Boot file etfsboot.com can be found in Windows ADK. Refer to IMAPI_MEDIA_PHYSICAL_TYPE enumeration for possible media types: http://msdn.microsoft.com/en-us/library/windows/desktop/aa366217(v=vs.85).aspx
.NOTES
    NAME: New-IsoFile AUTHOR: Chris Wu LASTEDIT: 03/23/2016 14:46:50
    Found at https://www.thelowercasew.com/create-an-iso-file-with-powershell.
#>
    function New-IsoFile {
        [CmdletBinding(DefaultParameterSetName = 'Source')]
        Param(
            [Parameter(Mandatory = $false, Position = 0)]
            [ValidateNotNullOrEmpty()]
            [string] $Title = (dirname $PWD),

            [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Source')]
            $Source = (Get-ChildItem $PWD),

            [Parameter(Position = 2)]
            [string] $Path = (Join-Path ((Get-Item $PWD).Parent) "${Title}.iso"),

            [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
            [string] $BootFile = $null,

            [ValidateSet('CDR', 'CDRW', 'DVDRAM', 'DVDPLUSR', 'DVDPLUSRW', 'DVDPLUSR_DUALLAYER', 'DVDDASHR', 'DVDDASHRW', 'DVDDASHR_DUALLAYER', 'DISK', 'DVDPLUSRW_DUALLAYER', 'BDR', 'BDRE')]
            [string] $Media = 'DVDPLUSRW_DUALLAYER',

            [switch] $Force,

            [Parameter(ParameterSetName = 'Clipboard')]
            [switch] $FromClipboard
        )

        Begin {
    ($cp = new-object System.CodeDom.Compiler.CompilerParameters).CompilerOptions = '/unsafe'
            if (!('ISOFile' -as [type])) {
                Add-Type -CompilerParameters $cp -TypeDefinition @'
public class ISOFile
{
  public unsafe static void Create(string Path, object Stream, int BlockSize, int TotalBlocks)
  {
    int bytes = 0;
    byte[] buf = new byte[BlockSize];
    var ptr = (System.IntPtr)(&bytes);
    var o = System.IO.File.OpenWrite(Path);
    var i = Stream as System.Runtime.InteropServices.ComTypes.IStream;

    if (o != null) {
      while (TotalBlocks-- > 0) {
        i.Read(buf, BlockSize, ptr); o.Write(buf, 0, bytes);
      }
      o.Flush(); o.Close();
    }
  }
}
'@
            }

            if ($BootFile) {
                if ('BDR', 'BDRE' -contains $Media) { Write-Warning "Bootable image doesn't seem to work with media type $Media" }
      ($Stream = New-Object -ComObject ADODB.Stream -Property @{Type = 1 }).Open()  # adFileTypeBinary
                $Stream.LoadFromFile((Get-Item -LiteralPath $BootFile).Fullname)
      ($Boot = New-Object -ComObject IMAPI2FS.BootOptions).AssignBootImage($Stream)
            }

            $MediaType = @('UNKNOWN', 'CDROM', 'CDR', 'CDRW', 'DVDROM', 'DVDRAM', 'DVDPLUSR', 'DVDPLUSRW', 'DVDPLUSR_DUALLAYER', 'DVDDASHR', 'DVDDASHRW', 'DVDDASHR_DUALLAYER', 'DISK', 'DVDPLUSRW_DUALLAYER', 'HDDVDROM', 'HDDVDR', 'HDDVDRAM', 'BDROM', 'BDR', 'BDRE')

            Write-Verbose -Message "Selected media type is $Media with value $($MediaType.IndexOf($Media))"
    ($Image = New-Object -com IMAPI2FS.MsftFileSystemImage -Property @{VolumeName = $Title }).ChooseImageDefaultsForMediaType($MediaType.IndexOf($Media))

            if (!($Target = New-Item -Path $Path -ItemType File -Force:$Force -ErrorAction SilentlyContinue)) { Write-Error -Message "Cannot create file $Path. Use -Force parameter to overwrite if the target file already exists."; break }
        }

        Process {
            if ($FromClipboard) {
                if ($PSVersionTable.PSVersion.Major -lt 5) { Write-Error -Message 'The -FromClipboard parameter is only supported on PowerShell v5 or higher'; break }
                $Source = Get-Clipboard -Format FileDropList
            }

            foreach ($item in $Source) {
                if ($item -isnot [System.IO.FileInfo] -and $item -isnot [System.IO.DirectoryInfo]) {
                    $item = Get-Item -LiteralPath $item
                }

                if ($item) {
                    Write-Verbose -Message "Adding item to the target image: $($item.FullName)"
                    try { $Image.Root.AddTree($item.FullName, $true) } catch { Write-Error -Message ($_.Exception.Message.Trim() + ' Try a different media type.') }
                }
            }
        }

        End {
            if ($Boot) { $Image.BootImageOptions = $Boot }
            $Result = $Image.CreateResultImage()
            [ISOFile]::Create($Target.FullName, $Result.ImageStream, $Result.BlockSize, $Result.TotalBlocks)
            Write-Verbose -Message "Target image ($($Target.FullName)) has been created"
            $Target
        }
    }
} # IsWindows
else {
    function New-IsoFile {
        param(
            [Parameter(Mandatory = $false, Position = 0)]
            [ValidateNotNullOrEmpty()]
            [string] $Title = (dirname $PWD),

            [Parameter(Mandatory = $true, Position = 1)]
            [ValidateNotNullOrEmpty()]
            [string] $OutputDirPath = ((Get-Item $PWD).Parent),

            [Parameter(Mandatory = $true, Position = 2)]
            [ValidateNotNullOrEmpty()]
            [string] $SourceDirPath = $PWD
        )
        Begin {
            if ((-not (Test-Command mkisofs)) -and (-not (Test-Command genisoimage))) {
                throw "Either 'mkisofs' or 'genisoimage' are required, but neither is installed."
            }
            [string] $finalIsoPath = Join-Path $OutputDirPath "${Title}.iso"
            if (Test-Path $finalIsoPath) {
                throw "'${finalIsoPath}' already exists."
            }
        }
        Process {
            Write-Debug "Writing '${Title}.iso' to '${OutputDirPath}' from '${SourceDirPath}'…"
            if (Test-Command mkisofs) {
                mkisofs -V "${Title}" -iso-level 3 -r -o "${finalIsoPath}" "${SourceDirPath}" | Out-Null
            } elseif (Test-Command genisoimage) {
                genisoimage -V "${Title}" -iso-level 3 -r -o "${finalIsoPath}" "${SourceDirPath}" | Out-Null
            }
            if (-not (Test-Path $finalIsoPath)) {
                throw "Failed to create '${finalIsoPath}'."
            }
            if ($LASTEXITCODE -eq 0) {
                Get-Item $finalIsoPath
            }
        }
    }
}
