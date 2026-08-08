# Regenerates launcher-icon + Android 12 splash sources from assets/logo.png.
# The crest PNG is transparent (alpha=0 outside the circle) — never bake a
# white/light fill behind it for splash icons (that shows as a white plate
# in dark mode).
#
# Re-run after replacing the logo:  powershell -File tool\generate_icons.ps1
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$logoPath = Join-Path $root 'assets\logo.png'
$outDir = Join-Path $root 'assets\icon'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function New-Composite {
    param(
        [string]$OutFile,
        [int]$Canvas,
        [int]$LogoSize,
        [string]$BackgroundHex
    )

    $logo = [System.Drawing.Image]::FromFile($logoPath)
    $bmp = New-Object System.Drawing.Bitmap($Canvas, $Canvas, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    if ($BackgroundHex) {
        $bg = [System.Drawing.ColorTranslator]::FromHtml($BackgroundHex)
        $g.Clear($bg)
    } else {
        $g.Clear([System.Drawing.Color]::Transparent)
    }

    $offset = [int](($Canvas - $LogoSize) / 2)
    $g.DrawImage($logo, $offset, $offset, $LogoSize, $LogoSize)

    $g.Dispose()
    $bmp.Save($OutFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    $logo.Dispose()
    Write-Host "wrote $OutFile"
}

# Legacy square launcher icon (homescreen — solid white is intentional here)
New-Composite -OutFile (Join-Path $outDir 'app_icon.png') -Canvas 1024 -LogoSize 856 -BackgroundHex '#FFFFFF'

# Adaptive-icon foreground: transparent around the crest
New-Composite -OutFile (Join-Path $outDir 'app_icon_foreground.png') -Canvas 1024 -LogoSize 596
