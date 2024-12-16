#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
#Requires -Modules @{ ModuleName = "poshy-lucidity"; RequiredVersion = "0.4.1" }


if ($IsWindows) {
<#
.SYNOPSIS
    Creates a new .iso file
.DESCRIPTION
    The New-IsoFile cmdlet creates a new .iso file containing content from the chosen folder(s).
.PARAMETER SourceDir
    The directory containing the content which will be included in the resulting .iso.
    Defaults to the current directory.
.PARAMETER OutDir
    The directory to which the resulting .iso file will be written.
    Defaults to the parent directory of `SourceDir`.
.PARAMETER TITLE
    The basename of the resulting .iso file.
    Defaults to the basename of `SourceDir`.
.PARAMETER BootFile
    The path to the executable file to be used as the boot image for the resulting .iso.
.PARAMETER Media
    The type of media to be used for the resulting .iso.
    Defaults to `DVDPLUSRW_DUALLAYER`.
    Refer to IMAPI_MEDIA_PHYSICAL_TYPE enumeration for possible media types: http://msdn.microsoft.com/en-us/library/windows/desktop/aa366217(v=vs.85).aspx
.PARAMETER Force
    Overwrite the target file if it already exists.
.PARAMETER FromClipboard
    Use the contents of the clipboard as the source directory(s).
    This parameter is only supported on PowerShell v5 or higher.
.EXAMPLE
    New-IsoFile -FromClipboard -Verbose
    Before running this command, select and copy (Ctrl-C) files/folders in Explorer first.
.EXAMPLE
    New-IsoFile c:\WinPE -OutDir c:\temp\WinPE.iso -BootFile "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\efisys.bin" -Media DVDPLUSR -Title "WinPE"
    This command creates a bootable .iso file containing the content from c:\WinPE folder, but the folder itself isn't included.
    Boot file etfsboot.com can be found in Windows ADK.
.NOTES
    NAME: New-IsoFile AUTHOR: Chris Wu LASTEDIT: 03/23/2016 14:46:50
    Found at https://www.thelowercasew.com/create-an-iso-file-with-powershell.
#>
    function New-IsoFile {
        [CmdletBinding(DefaultParameterSetName = 'SourceDir')]
        Param(
            [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'SourceDir')]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({ Test-Path $_ -PathType Container })]
            [System.IO.DirectoryInfo[]] $SourceDir = @(Get-Item .),

            [Parameter(Mandatory = $true, Position = 1)]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({ Test-Path $_ -PathType Container })]
            [System.IO.DirectoryInfo] $OutDir = $SourceDir[0].Parent,

            [Parameter(Mandatory = $false)]
            [ValidateNotNullOrEmpty()]
            [string] $Title = $SourceDir[0].Name,

            [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
            [ValidateNotNullOrEmpty()]
            [System.IO.FileInfo] $BootFile = $null,

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

            $Path = Join-Path -Path $OutDir -ChildPath "${Title}.iso"
            if (!($Target = New-Item -Path $Path -ItemType File -Force:$Force -ErrorAction SilentlyContinue)) { Write-Error -Message "Cannot create file $Path. Use -Force parameter to overwrite if the target file already exists."; break }
        }

        Process {
            if ($FromClipboard) {
                if ($PSVersionTable.PSVersion.Major -lt 5) { Write-Error -Message 'The -FromClipboard parameter is only supported on PowerShell v5 or higher'; break }
                $SourceDir = (Get-Clipboard -Format FileDropList | Get-Item)
            }

            foreach ($item in ($SourceDir | Get-ChildItem)) {
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
<#
.SYNOPSIS
    Creates a new .iso file
.DESCRIPTION
    The New-IsoFile cmdlet creates a new .iso file containing content from the chosen folder.
#>
    function New-IsoFile {
        param(
            [Parameter(Mandatory = $true, Position = 0)]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({ Test-Path $_ -PathType Container })]
            [System.IO.DirectoryInfo] $SourceDir = (Get-Item .),

            [Parameter(Mandatory = $true, Position = 1)]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({ Test-Path $_ -PathType Container })]
            [System.IO.DirectoryInfo] $OutDir = $SourceDir.Parent,

            [Parameter(Mandatory = $false)]
            [ValidateNotNullOrEmpty()]
            [string] $Title = $SourceDir.Name
        )
        Begin {
            if ((-not (Test-Command mkisofs)) -and (-not (Test-Command genisoimage))) {
                throw "Either 'mkisofs' or 'genisoimage' are required, but neither is installed."
            }
            [string] $finalIsoPath = Join-Path $OutDir "${Title}.iso"
            if (Test-Path $finalIsoPath) {
                throw "'${finalIsoPath}' already exists."
            }
        }
        Process {
            Write-Debug "Writing '${Title}.iso' to '${OutDir}' from '${SourceDir}'…"
            if (Test-Command mkisofs) {
                mkisofs -V "${Title}" -iso-level 3 -r -o "${finalIsoPath}" "${SourceDir}" | Out-Null
                if (-not (Test-Path $finalIsoPath -ErrorAction SilentlyContinue)) {
                    throw "Failed to create '${finalIsoPath}' - 'mkisofs' did not create the file and exited with code $LASTEXITCODE."
                }
            } elseif (Test-Command genisoimage) {
                genisoimage -V "${Title}" -iso-level 3 -r -o "${finalIsoPath}" "${SourceDir}" | Out-Null
                if (-not (Test-Path $finalIsoPath -ErrorAction SilentlyContinue)) {
                    throw "Failed to create '${finalIsoPath}' - 'genisoimage' did not create the file and exited with code $LASTEXITCODE."
                }
            }
            if ($LASTEXITCODE -eq 0) {
                Get-Item $finalIsoPath
            }
        }
    }
}
