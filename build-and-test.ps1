# Build and Test Script - Automates the entire benchmark process
# Builds C# application and runs performance comparisons

param(
    [int]$Iterations = 10,
    [int]$Duration = 5,
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ASM vs C# Performance Comparison Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Paths
$scriptDir = $PSScriptRoot
$asmExe = Join-Path $scriptDir "win.exe"
$csharpProject = Join-Path $scriptDir "ClockApp\ClockApp.csproj"
$csharpExe = Join-Path $scriptDir "ClockApp\bin\Release\net8.0-windows\win-x64\publish\ClockApp.exe"
$benchmarkScript = Join-Path $scriptDir "benchmark.ps1"
$compareScript = Join-Path $scriptDir "compare-results.ps1"

# Step 1: Verify Assembly executable exists
Write-Host "[1/5] Checking Assembly executable..." -ForegroundColor Yellow
if (-not (Test-Path $asmExe)) {
    Write-Host "  ERROR: Assembly executable not found: $asmExe" -ForegroundColor Red
    Write-Host "  Please build the Assembly program first using NASM and linker." -ForegroundColor Red
    exit 1
}
$asmSize = [math]::Round((Get-Item $asmExe).Length / 1KB, 2)
Write-Host "  Found: $asmExe ($asmSize KB)" -ForegroundColor Green

# Step 2: Build C# application
if (-not $SkipBuild) {
    Write-Host "`n[2/5] Building C# application..." -ForegroundColor Yellow
    
    if (-not (Test-Path $csharpProject)) {
        Write-Host "  ERROR: C# project not found: $csharpProject" -ForegroundColor Red
        exit 1
    }
    
    Push-Location (Split-Path $csharpProject -Parent)
    
    try {
        Write-Host "  Restoring dependencies..." -ForegroundColor Cyan
        dotnet restore | Out-Null
        
        Write-Host "  Building Release configuration..." -ForegroundColor Cyan
        dotnet build -c Release --no-restore | Out-Null
        
        Write-Host "  Publishing optimized build..." -ForegroundColor Cyan
        dotnet publish -c Release -r win-x64 --no-build /p:PublishSingleFile=true /p:PublishReadyToRun=true | Out-Null
        
        Write-Host "  Build completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "  ERROR: Build failed: $_" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Host "`n[2/5] Skipping C# build (using existing executable)..." -ForegroundColor Yellow
}

# Verify C# executable
if (-not (Test-Path $csharpExe)) {
    Write-Host "  ERROR: C# executable not found: $csharpExe" -ForegroundColor Red
    Write-Host "  Try running without -SkipBuild flag." -ForegroundColor Red
    exit 1
}
$csSize = [math]::Round((Get-Item $csharpExe).Length / 1KB, 2)
Write-Host "  Found: $csharpExe ($csSize KB)" -ForegroundColor Green

# Step 3: Benchmark Assembly application
Write-Host "`n[3/5] Benchmarking Assembly application..." -ForegroundColor Yellow
$asmResults = Join-Path $scriptDir "benchmark-asm.json"

try {
    & $benchmarkScript -ExePath $asmExe -AppName "Assembly (NASM)" -Iterations $Iterations -RunDurationSeconds $Duration -OutputFile $asmResults
    if ($LASTEXITCODE -ne 0) { throw "Benchmark failed" }
}
catch {
    Write-Host "  ERROR: Assembly benchmark failed: $_" -ForegroundColor Red
    exit 1
}

# Step 4: Benchmark C# application
Write-Host "`n[4/5] Benchmarking C# application..." -ForegroundColor Yellow
$csResults = Join-Path $scriptDir "benchmark-csharp.json"

try {
    & $benchmarkScript -ExePath $csharpExe -AppName "C# (Windows Forms)" -Iterations $Iterations -RunDurationSeconds $Duration -OutputFile $csResults
    if ($LASTEXITCODE -ne 0) { throw "Benchmark failed" }
}
catch {
    Write-Host "  ERROR: C# benchmark failed: $_" -ForegroundColor Red
    exit 1
}

# Step 5: Generate comparison report
Write-Host "`n[5/5] Generating comparison report..." -ForegroundColor Yellow
$reportFile = Join-Path $scriptDir "performance-comparison.md"

try {
    & $compareScript -AsmResultsFile $asmResults -CSharpResultsFile $csResults -OutputFile $reportFile
    if ($LASTEXITCODE -ne 0) { throw "Comparison failed" }
}
catch {
    Write-Host "  ERROR: Comparison report generation failed: $_" -ForegroundColor Red
    exit 1
}

# Summary
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Benchmark Completed Successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Results:" -ForegroundColor Cyan
Write-Host "  Assembly results: $asmResults"
Write-Host "  C# results:       $csResults"
Write-Host "  Comparison:       $reportFile"
Write-Host ""
Write-Host "Open the comparison report to see detailed performance analysis:" -ForegroundColor Yellow
Write-Host "  $reportFile" -ForegroundColor White
Write-Host ""
