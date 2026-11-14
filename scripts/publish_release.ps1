<#
.SYNOPSIS
  Publishes a new CampusVibe Android release APK to GitHub Releases for Over-The-Air (OTA) updates.

.DESCRIPTION
  Builds the release APK using Flutter, computes its SHA-256 checksum, tags the release,
  and uploads the APK to GitHub Releases. The in-app OtaUpdateService will detect this release
  and allow one-tap background download & native installer launch.

.PARAMETER Version
  The version string (e.g., '1.0.12'). Default comes from pubspec.yaml.

.PARAMETER ReleaseTitle
  Optional release title. Defaults to 'School Manager v<Version> — ...'.

.PARAMETER ReleaseNotes
  Changelog / Release notes text.

.PARAMETER NotesFile
  Path to markdown file containing release notes.

.PARAMETER RepoOwner
  GitHub repository owner or organization (default: 'RishabhSihag08').

.PARAMETER RepoName
  GitHub repository name (default: 'school-manager').

.PARAMETER DryRun
  If set, builds the APK and validates metadata without uploading to GitHub.

.PARAMETER SkipBuild
  If set, skips 'flutter build apk --release' and re-uses existing build artifact.
#>

param(
    [string]$Version = "",
    [string]$ReleaseTitle = "",
    [string]$ReleaseNotes = "",
    [string]$NotesFile = "",
    [string]$RepoOwner = "RishabhSihag08",
    [string]$RepoName = "school-manager",
    [switch]$DryRun,
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

# Resolve directories safely
$flutterDir = if (Test-Path (Join-Path $PSScriptRoot "..\pubspec.yaml")) {
    (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
} elseif (Test-Path (Join-Path (Split-Path -Parent $PSScriptRoot) "school_manager\pubspec.yaml")) {
    Join-Path (Split-Path -Parent $PSScriptRoot) "school_manager"
} else {
    $PSScriptRoot
}

# Auto-detect version if not passed
$pubspecPath = Join-Path $flutterDir "pubspec.yaml"
if ([string]::IsNullOrWhiteSpace($Version) -and (Test-Path $pubspecPath)) {
    $pubspecContent = Get-Content $pubspecPath -Raw
    if ($pubspecContent -match 'version:\s*([0-9]+\.[0-9]+\.[0-9]+)') {
        $Version = $matches[1]
    }
}
if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = "1.0.12"
}

# Load notes from file if provided
if (-not [string]::IsNullOrWhiteSpace($NotesFile) -and (Test-Path $NotesFile)) {
    $ReleaseNotes = Get-Content $NotesFile -Raw
} elseif ([string]::IsNullOrWhiteSpace($ReleaseNotes)) {
    $ReleaseNotes = "✨ School Manager v$Version Release with Instant Auto-Refresh on Launch, Offline Barrier Screen & Performance Improvements."
}

if ([string]::IsNullOrWhiteSpace($ReleaseTitle)) {
    $ReleaseTitle = "School Manager v$Version — Instant Sync & Offline Protection"
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " CampusVibe / School Manager OTA Release Publisher (v$Version)" -ForegroundColor Cyan
Write-Host " Target: https://github.com/$RepoOwner/$RepoName" -ForegroundColor Cyan
Write-Host " Working Dir: $flutterDir" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$apkPath = Join-Path $flutterDir "build\app\outputs\flutter-apk\app-release.apk"
$targetApkName = "school-manager-v$Version.apk"
$targetApkPath = Join-Path $flutterDir "build\app\outputs\flutter-apk\$targetApkName"
$altApkName = "campusvibe-v$Version.apk"
$altApkPath = Join-Path $flutterDir "build\app\outputs\flutter-apk\$altApkName"

# 1. Build release APK
if (-not $SkipBuild) {
    Write-Host "`n[1/3] Building release APK (flutter build apk --release)..." -ForegroundColor Yellow
    Push-Location $flutterDir
    try {
        flutter build apk --release
    }
    finally {
        Pop-Location
    }
} else {
    Write-Host "`n[1/3] Skipping build as requested (-SkipBuild)" -ForegroundColor DarkGray
}

if (-not (Test-Path $apkPath)) {
    Write-Warning "Release APK not found at: $apkPath"
    if ($DryRun) {
        Write-Host "[DRY RUN] Simulating release packaging..." -ForegroundColor Magenta
    } else {
        throw "Build failed or APK not found at $apkPath"
    }
} else {
    Copy-Item -Path $apkPath -Destination $targetApkPath -Force
    Copy-Item -Path $apkPath -Destination $altApkPath -Force
    $fileHash = Get-FileHash -Path $targetApkPath -Algorithm SHA256
    $fileSizeMB = [math]::Round((Get-Item $targetApkPath).Length / 1MB, 2)
    Write-Host "APK Created successfully:" -ForegroundColor Green
    Write-Host "  Path: $targetApkPath"
    Write-Host "  Size: $fileSizeMB MB"
    Write-Host "  SHA-256: $($fileHash.Hash)"
}

# 2. Check GitHub Release Tag
$tag = "v$Version"
Write-Host "`n[2/3] Preparing GitHub Release tag '$tag'..." -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "[DRY RUN] Would publish release '$ReleaseTitle' with tag '$tag' to '$RepoOwner/$RepoName'." -ForegroundColor Magenta
    Write-Host "Notes:`n$ReleaseNotes"
    Write-Host "`n[DRY RUN] Completed successfully. No changes pushed to GitHub." -ForegroundColor Green
    exit 0
}

# 3. Publish to GitHub Releases
Write-Host "`n[3/3] Uploading release to GitHub..." -ForegroundColor Yellow

$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
if ($ghInstalled) {
    Write-Host "Using GitHub CLI (gh)..." -ForegroundColor Cyan
    
    # Check if git tag exists locally/remotely
    Push-Location $flutterDir
    try {
        $tagExists = git tag -l $tag
        if (-not $tagExists) {
            git tag -a $tag -m "Release $tag"
            git push origin $tag
        }
    } catch {
        Write-Warning "Git tag push notice: $_"
    } finally {
        Pop-Location
    }

    $releaseExists = $false
    try {
        $oldEAP = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
        $null = & gh release view $tag --repo "$RepoOwner/$RepoName" 2>&1
        if ($LASTEXITCODE -eq 0) {
            $releaseExists = $true
        }
    } finally {
        $ErrorActionPreference = $oldEAP
    }

    if ($releaseExists) {
        Write-Host "Release $tag already exists. Updating release..." -ForegroundColor Yellow
        if (-not [string]::IsNullOrWhiteSpace($NotesFile) -and (Test-Path $NotesFile)) {
            & gh release edit $tag --repo "$RepoOwner/$RepoName" --title $ReleaseTitle --notes-file $NotesFile
        } else {
            & gh release edit $tag --repo "$RepoOwner/$RepoName" --title $ReleaseTitle --notes $ReleaseNotes
        }
        & gh release upload $tag $targetApkPath --repo "$RepoOwner/$RepoName" --clobber
    } else {
        if (-not [string]::IsNullOrWhiteSpace($NotesFile) -and (Test-Path $NotesFile)) {
            & gh release create $tag $targetApkPath `
                --repo "$RepoOwner/$RepoName" `
                --title $ReleaseTitle `
                --notes-file $NotesFile
        } else {
            & gh release create $tag $targetApkPath `
                --repo "$RepoOwner/$RepoName" `
                --title $ReleaseTitle `
                --notes $ReleaseNotes
        }
    }
    Write-Host "`nSuccessfully published GitHub Release $tag!" -ForegroundColor Green
    Write-Host "Direct APK Download URL: https://github.com/$RepoOwner/$RepoName/releases/download/$tag/$targetApkName" -ForegroundColor Cyan
} else {
    $token = $env:GITHUB_TOKEN
    if ([string]::IsNullOrWhiteSpace($token)) {
        Write-Warning "Neither 'gh' CLI nor '$env:GITHUB_TOKEN' found. Release artifact ready locally at $targetApkPath"
        Write-Host "You can manually attach this APK to GitHub Releases tag '$tag'." -ForegroundColor Yellow
    } else {
        Write-Host "Uploading release via GitHub REST API..." -ForegroundColor Cyan
        $releaseBody = @{
            tag_name = $tag
            name = $ReleaseTitle
            body = $ReleaseNotes
            draft = $false
            prerelease = $false
        } | ConvertTo-Json

        $headers = @{
            "Authorization" = "Bearer $token"
            "Accept" = "application/vnd.github.v3+json"
            "User-Agent" = "CampusVibe-Release-Publisher"
        }

        $createReleaseUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/releases"
        $releaseResponse = Invoke-RestMethod -Uri $createReleaseUrl -Method Post -Headers $headers -Body $releaseBody -ContentType "application/json"
        
        $uploadUrlTemplate = $releaseResponse.upload_url -replace '\{\?name,label\}', "?name=$targetApkName"
        $apkBytes = [System.IO.File]::ReadAllBytes($targetApkPath)
        
        $uploadHeaders = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/vnd.android.package-archive"
            "User-Agent" = "CampusVibe-Release-Publisher"
        }
        
        Invoke-RestMethod -Uri $uploadUrlTemplate -Method Post -Headers $uploadHeaders -Body $apkBytes | Out-Null
        Write-Host "`nSuccessfully uploaded release asset via GitHub API!" -ForegroundColor Green
    }
}

Write-Host "`nOTA Release Pipeline Complete! CampusVibe apps will now detect v$Version." -ForegroundColor Green
