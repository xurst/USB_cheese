<#
.SYNOPSIS
    USB-based per-system log folder manager using PsInfo.

.DESCRIPTION
    determines the current USB folder (where the module lives),
    runs PsInfo.exe from a PSTools folder,
    extracts the system name, and creates a per-system folder
    on the USB to store logs and other files.

#>

function Get-PCLogFolder {
    [CmdletBinding()]
    param(
        [switch]$CreateIfMissing
    )

    $USBRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

    $PsInfoPath = Join-Path $USBRoot "PSTools\PsInfo.exe"

    $BaseLogDir = $USBRoot
    $SysName = $null

    if (Test-Path $PsInfoPath) {
        try {
            $Output = & $PsInfoPath | Out-String
            if ($Output -match 'System information for \\\\([^:]+):') {
                $SysName = $Matches[1].Trim()
            }

            if ($SysName) {
                $BaseLogDir = Join-Path $USBRoot $SysName
                if ($CreateIfMissing -and -not (Test-Path $BaseLogDir)) {
                    New-Item -ItemType Directory -Path $BaseLogDir | Out-Null
                }
            } else {
                Write-Verbose "Could not extract system name from PsInfo output."
            }
        }
        catch {
            Write-Warning "Failed to query PsInfo: $_"
        }
    } else {
        Write-Warning "PsInfo.exe not found at $PsInfoPath"
    }

    return $BaseLogDir
}

Export-ModuleMember -Function Get-PCLogFolder
