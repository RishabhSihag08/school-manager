<#
.SYNOPSIS
  Publishes a new CampusVibe Android release APK to GitHub Releases for Over-The-Air (OTA) updates.

.DESCRIPTION
  Builds the release APK using Flutter, computes its SHA-256 checksum, tags the release,
  and uploads the APK to GitHub Releases. The in-app OtaUpdateService will detect this release
  and allow one-tap background download & native installer launch.

.PARAMETER Version
  The version string (e.g., '1.0.1'). Default comes from pubspec.yaml.

.PARAMETER ReleaseTitle
  Optional release title. Defaults to 'CampusVibe v<Version>'.

.PARAMETER ReleaseNotes
  Changelog / Release notes text.

.PARAMETER RepoOwner
  GitHub repository owner or organization (default: 'school-org').

.PARAMETER RepoName
  GitHub repository name (default: 'school-manager').

.PARAMETER DryRun
  If set, builds the APK and validates metadata without uploading to GitHub.

.PARAMETER SkipBuild
  If set, skips 'flutter build apk --release' and re-uses existing build artifact.
#>

param(
    [string]$Version = "1.0.1",
    [string]$ReleaseTitle = "",
    [string]$ReleaseNotes = "✨ CampusVibe Indian School Management System Release with OTA updates, 6-char Class Code join, Attendance, Timetable, Syllabus vault, and Excel exam import.",
    [string]$RepoOwner = "school-org",
    [string]$RepoName = "school-manager",
    [switch]$DryRun,
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " CampusVibe OTA Release Publisher (v$Version)" -ForegroundColor Cyan
Write-Host " Target: https://github.com/$RepoOwner/$RepoName" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if ([string]::IsNullOrWhiteSpace($ReleaseTitle)) {
    $ReleaseTitle = "CampusVibe v$Version"
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$flutterDir = Join-Path $projectRoot "school_manager"
$apkPath = Join-Path $flutterDir "build\app\outputs\flutter-apk\app-release.apk"
$targetApkName = "campusvibe-v$Version.apk"
$targetApkPath = Join-Path $flutterDir "build\app\outputs\flutter-apk\$targetApkName"

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
    gh release create $tag $targetApkPath `
        --repo "$RepoOwner/$RepoName" `
        --title $ReleaseTitle `
        --notes $ReleaseNotes
    Write-Host "`nSuccessfully created GitHub Release $tag!" -ForegroundColor Green
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
