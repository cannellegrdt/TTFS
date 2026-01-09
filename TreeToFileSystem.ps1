#
# lankley, 01-09-2026
# TreeToFS, PowerShell version
#

param (
    [Parameter(Mandatory=$true)]
    [string]$File,
    [string]$Destination = "."
)

if (!(Test-Path $File)) {
    Write-Error "Input file not found: $File"
    return
}

if (!(Test-Path $Destination)) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}

$Paths = @()
$IndentSize = 0

Get-Content $File | ForEach-Object {
    $line = $_

    if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line) -or $line -match '\d+ (directories|files)') {
        return
    }

    # 1. Dynamic indentation detection
    $prefixMatch = [regex]::Match($line, "^[│ ├└─]*")
    $prefixPart = $prefixMatch.Value
    
    if ($IndentSize -eq 0 -and $prefixPart.Length -gt 0) {
        $IndentSize = $prefixPart.Length
    }

    # 4. Determine depth
    $depth = 0
    if ($IndentSize -gt 0) {
        $depth = [math]::Floor($prefixPart.Length / $IndentSize)
    }

    # 5. Extract and clean Name
    $rawName = $line.Substring($prefixPart.Length).Trim()
    
    $isDir = $rawName.EndsWith("/") -or $rawName.EndsWith("\")
    
    $cleanName = $rawName.TrimEnd('/','\','*','@')

    # 6. Update hierarchy array
    if ($Paths.Count -le $depth) {
        $Paths += $cleanName
    } else {
        $Paths[$depth] = $cleanName
    }

    # 7. Path construction
    $subPath = $Paths[0..$depth] -join [IO.Path]::DirectorySeparatorChar
    $fullPath = Join-Path $Destination $subPath

    # 8. Creation logic
    if ($isDir) {
        if (!(Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        }
    } else {
        $parentDir = Split-Path $fullPath -Parent
        if (!(Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        if (!(Test-Path $fullPath)) {
            New-Item -ItemType File -Path $fullPath -Force | Out-Null
        }
    }
}

Write-Host "File system structure created successfully in: $Destination" -ForegroundColor Green
