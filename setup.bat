@echo off
REM ExtractIPA Project Setup Script for Windows
REM This script prepares the project for building on a Mac or cloud

setlocal enabledelayedexpansion

color 0B
cls

echo ========================================
echo   ExtractIPA Windows Setup
echo ========================================
echo.

REM Check if Git is installed
echo [1/4] Checking Git installation...
git --version >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo ERROR: Git not found. Please install Git from https://git-scm.com/
    pause
    exit /b 1
)
color 0A
echo [OK] Git found
echo.

REM Initialize Git repository if not exists
echo [2/4] Initializing Git repository...
if not exist ".git" (
    git init
    git config user.email "harsh@example.com"
    git config user.name "Harsh Dhamaniya"

    if %errorlevel% neq 0 (
        color 0C
        echo ERROR: Failed to initialize Git
        pause
        exit /b 1
    )
)
color 0A
echo [OK] Git repository ready
echo.

REM Add files to Git
echo [3/4] Staging project files...
git add *.swift *.md *.plist *.entitlements Package.swift build.sh Dockerfile 2>nul
git add .github\workflows\*.yml 2>nul

if %errorlevel% neq 0 (
    echo [WARNING] Some files could not be staged
) else (
    color 0A
    echo [OK] Files staged
)
echo.

REM Create initial commit
echo [4/4] Creating initial commit...
git status >nul
for /f %%A in ('git status --porcelain') do (
    if not "%%A"=="" (
        git commit -m "Initial ExtractIPA project - Ready for iOS build" 2>nul
        color 0A
        echo [OK] Initial commit created
        goto:next
    )
)

:next
echo.
color 0B
echo ========================================
echo   Setup Complete!
echo ========================================
echo.
echo NEXT STEPS:
echo.
echo Option 1: Build Locally on Mac
echo   1. Transfer files to Mac via:
echo      scp -r .\* user@mac:/path/to/ExtractIPA
echo   2. On Mac, run: chmod +x build.sh && ./build.sh
echo.
echo Option 2: Cloud Build via GitHub
echo   1. Push to GitHub:
echo      git remote add origin https://github.com/USERNAME/ExtractIPA.git
echo      git push -u origin main
echo   2. GitHub Actions will auto-build (see Actions tab)
echo.
echo Option 3: Generate Build Report
echo   1. Run: python build_report.py
echo   2. Review build configurations
echo.
echo For detailed build instructions, see BUILD.md
echo.
pause
