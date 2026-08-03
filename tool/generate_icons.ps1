# Regenerates the launcher-icon / splash source images from assets/logo.png.
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

# Legacy square launcher icon: crest on white, small breathing room.
New-Composite -OutFile (Join-Path $outDir 'app_icon.png') -Canvas 1024 -LogoSize 856 -BackgroundHex '#FFFFFF'

# Adaptive-icon foreground: transparent, crest kept inside the 66% safe zone
# so the launcher's circle/squircle mask never clips the "ISLAMABAD" banner.
New-Composite -OutFile (Join-Path $outDir 'app_icon_foreground.png') -Canvas 1024 -LogoSize 596

# Android 12+ splash icon. Canvas is filled with #F8F9FA (not transparent) so
# OEMs that ignore windowSplashScreenBackground (notably MIUI) still show a
# light plate behind the crest instead of the system dark wallpaper.
# Logo stays inside the 768px safe circle (~66% of 1152).
New-Composite -OutFile (Join-Path $outDir 'splash_logo_android12.png') -Canvas 1152 -LogoSize 660 -BackgroundHex '#F8F9FA'

# Pre-Android-12 splash. Treated as xxxhdpi by flutter_native_splash → 132dp,
# matching SplashScreen.logoSize so the crest does not resize on handoff.
New-Composite -OutFile (Join-Path $outDir 'splash_logo.png') -Canvas 528 -LogoSize 528
