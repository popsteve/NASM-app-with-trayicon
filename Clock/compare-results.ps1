# Compare benchmark results between ASM and C# applications
# Generates a markdown report with comparison tables

param(
    [string]$AsmResultsFile = "benchmark-asm.json",
    [string]$CSharpResultsFile = "benchmark-csharp.json",
    [string]$OutputFile = "performance-comparison.md"
)

function Get-PercentageDifference {
    param($Value1, $Value2)
    if ($Value2 -eq 0) { return 0 }
    return [math]::Round((($Value1 - $Value2) / $Value2) * 100, 1)
}

function Get-Winner {
    param($AsmValue, $CSharpValue, $LowerIsBetter = $true)
    
    if ($LowerIsBetter) {
        if ($AsmValue -lt $CSharpValue) { return "ASM" }
        else { return "C#" }
    }
    else {
        if ($AsmValue -gt $CSharpValue) { return "ASM" }
        else { return "C#" }
    }
}

# Load benchmark results
if (-not (Test-Path $AsmResultsFile)) {
    Write-Host "Error: ASM results file not found: $AsmResultsFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $CSharpResultsFile)) {
    Write-Host "Error: C# results file not found: $CSharpResultsFile" -ForegroundColor Red
    exit 1
}

Write-Host "Loading benchmark results..." -ForegroundColor Cyan
$asmData = Get-Content $AsmResultsFile | ConvertFrom-Json
$csharpData = Get-Content $CSharpResultsFile | ConvertFrom-Json

# Generate markdown report
$report = @"
# Performance Comparison: Assembly vs C#

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Executive Summary

This report compares the performance characteristics of an analog clock application implemented in:
- **Assembly (NASM)**: Direct Win32 API calls, compiled to native x64 executable
- **C# (Windows Forms)**: .NET 8.0 application using Windows Forms framework

---

## Executable Size

| Application | Size (KB) | Difference |
|-------------|-----------|------------|
| Assembly    | $($asmData.ExecutableSize_KB) | Baseline |
| C#          | $($csharpData.ExecutableSize_KB) | +$([math]::Round($csharpData.ExecutableSize_KB - $asmData.ExecutableSize_KB, 2)) KB (+$(Get-PercentageDifference $csharpData.ExecutableSize_KB $asmData.ExecutableSize_KB)%) |

**Winner:** $(if ($asmData.ExecutableSize_KB -lt $csharpData.ExecutableSize_KB) { "Assembly" } else { "C#" }) ✓

---

## Startup Time

| Metric | Assembly (ms) | C# (ms) | Difference | Winner |
|--------|---------------|---------|------------|--------|
"@

# Add startup time comparison
$asmStartup = ($asmData.Summary | Where-Object { $_.Metric -eq "StartupTime_ms" }).Average
$csStartup = ($csharpData.Summary | Where-Object { $_.Metric -eq "StartupTime_ms" }).Average
$startupDiff = Get-PercentageDifference $csStartup $asmStartup
$startupWinner = Get-Winner $asmStartup $csStartup -LowerIsBetter $true

$report += @"

| Average    | $asmStartup | $csStartup | $(if ($startupDiff -gt 0) { "+" })$startupDiff% | $startupWinner ✓ |
| Min        | $(($asmData.Summary | Where-Object { $_.Metric -eq "StartupTime_ms" }).Min) | $(($csharpData.Summary | Where-Object { $_.Metric -eq "StartupTime_ms" }).Min) | - | - |
| Max        | $(($asmData.Summary | Where-Object { $_.Metric -eq "StartupTime_ms" }).Max) | $(($csharpData.Summary | Where-Object { $_.Metric -eq "StartupTime_ms" }).Max) | - | - |

---

## Memory Usage

### Average Working Set

| Metric | Assembly (MB) | C# (MB) | Difference | Winner |
|--------|---------------|---------|------------|--------|
"@

# Add memory comparison
$asmMemory = ($asmData.Summary | Where-Object { $_.Metric -eq "AvgWorkingSet_MB" }).Average
$csMemory = ($csharpData.Summary | Where-Object { $_.Metric -eq "AvgWorkingSet_MB" }).Average
$memoryDiff = Get-PercentageDifference $csMemory $asmMemory
$memoryWinner = Get-Winner $asmMemory $csMemory -LowerIsBetter $true

$report += @"

| Average    | $asmMemory | $csMemory | $(if ($memoryDiff -gt 0) { "+" })$memoryDiff% | $memoryWinner ✓ |
| Min        | $(($asmData.Summary | Where-Object { $_.Metric -eq "AvgWorkingSet_MB" }).Min) | $(($csharpData.Summary | Where-Object { $_.Metric -eq "AvgWorkingSet_MB" }).Min) | - | - |
| Max        | $(($asmData.Summary | Where-Object { $_.Metric -eq "AvgWorkingSet_MB" }).Max) | $(($csharpData.Summary | Where-Object { $_.Metric -eq "AvgWorkingSet_MB" }).Max) | - | - |

### Peak Working Set

| Metric | Assembly (MB) | C# (MB) | Difference | Winner |
|--------|---------------|---------|------------|--------|
"@

$asmMaxMemory = ($asmData.Summary | Where-Object { $_.Metric -eq "MaxWorkingSet_MB" }).Average
$csMaxMemory = ($csharpData.Summary | Where-Object { $_.Metric -eq "MaxWorkingSet_MB" }).Average
$maxMemoryDiff = Get-PercentageDifference $csMaxMemory $asmMaxMemory
$maxMemoryWinner = Get-Winner $asmMaxMemory $csMaxMemory -LowerIsBetter $true

$report += @"

| Average    | $asmMaxMemory | $csMaxMemory | $(if ($maxMemoryDiff -gt 0) { "+" })$maxMemoryDiff% | $maxMemoryWinner ✓ |

### Private Memory (Committed)

| Metric | Assembly (MB) | C# (MB) | Difference | Winner |
|--------|---------------|---------|------------|--------|
"@

$asmPrivate = ($asmData.Summary | Where-Object { $_.Metric -eq "AvgPrivateMemory_MB" }).Average
$csPrivate = ($csharpData.Summary | Where-Object { $_.Metric -eq "AvgPrivateMemory_MB" }).Average
$privateDiff = Get-PercentageDifference $csPrivate $asmPrivate
$privateWinner = Get-Winner $asmPrivate $csPrivate -LowerIsBetter $true

$report += @"

| Average    | $asmPrivate | $csPrivate | $(if ($privateDiff -gt 0) { "+" })$privateDiff% | $privateWinner ✓ |

---

## CPU Usage

| Metric | Assembly (sec) | C# (sec) | Difference | Winner |
|--------|----------------|----------|------------|--------|
"@

$asmCPU = ($asmData.Summary | Where-Object { $_.Metric -eq "TotalCPU_sec" }).Average
$csCPU = ($csharpData.Summary | Where-Object { $_.Metric -eq "TotalCPU_sec" }).Average
$cpuDiff = Get-PercentageDifference $csCPU $asmCPU
$cpuWinner = Get-Winner $asmCPU $csCPU -LowerIsBetter $true

$report += @"

| Average    | $asmCPU | $csCPU | $(if ($cpuDiff -gt 0) { "+" })$cpuDiff% | $cpuWinner ✓ |

---

## System Resources

### Handles

| Metric | Assembly | C# | Difference | Winner |
|--------|----------|-------|------------|--------|
"@

$asmHandles = ($asmData.Summary | Where-Object { $_.Metric -eq "Handles" }).Average
$csHandles = ($csharpData.Summary | Where-Object { $_.Metric -eq "Handles" }).Average
$handlesDiff = Get-PercentageDifference $csHandles $asmHandles
$handlesWinner = Get-Winner $asmHandles $csHandles -LowerIsBetter $true

$report += @"

| Average    | $asmHandles | $csHandles | $(if ($handlesDiff -gt 0) { "+" })$handlesDiff% | $handlesWinner ✓ |

### Threads

| Metric | Assembly | C# | Difference | Winner |
|--------|----------|-------|------------|--------|
"@

$asmThreads = ($asmData.Summary | Where-Object { $_.Metric -eq "Threads" }).Average
$csThreads = ($csharpData.Summary | Where-Object { $_.Metric -eq "Threads" }).Average
$threadsDiff = Get-PercentageDifference $csThreads $asmThreads
$threadsWinner = Get-Winner $asmThreads $csThreads -LowerIsBetter $true

$report += @"

| Average    | $asmThreads | $csThreads | $(if ($threadsDiff -gt 0) { "+" })$threadsDiff% | $threadsWinner ✓ |

---

## Overall Analysis

### Assembly Advantages
- **Smaller executable**: $(if ($asmData.ExecutableSize_KB -lt $csharpData.ExecutableSize_KB) { "Yes (" + [math]::Abs(Get-PercentageDifference $csharpData.ExecutableSize_KB $asmData.ExecutableSize_KB) + "% smaller)" } else { "No" })
- **Faster startup**: $(if ($asmStartup -lt $csStartup) { "Yes (" + [math]::Abs($startupDiff) + "% faster)" } else { "No" })
- **Lower memory usage**: $(if ($asmMemory -lt $csMemory) { "Yes (" + [math]::Abs($memoryDiff) + "% less)" } else { "No" })
- **Fewer system resources**: $(if ($asmHandles -lt $csHandles -and $asmThreads -lt $csThreads) { "Yes" } else { "Varies" })
- **No runtime dependencies**: Yes (native executable)
- **Direct hardware control**: Yes

### C# Advantages
- **Development time**: Significantly faster
- **Code maintainability**: Much easier to read and modify
- **Built-in features**: Rich framework library (GDI+, Windows Forms)
- **Safety**: Memory-safe, type-safe language
- **Debugging**: Superior debugging experience
- **Cross-platform potential**: With .NET MAUI or Avalonia
- **Modern tooling**: IntelliSense, refactoring, etc.

### Conclusion

The Assembly version demonstrates superior runtime performance characteristics across nearly all metrics:
- **$(if ($asmStartup -lt $csStartup) { [math]::Abs($startupDiff) } else { 0 })%** faster startup
- **$(if ($asmMemory -lt $csMemory) { [math]::Abs($memoryDiff) } else { 0 })%** less memory usage
- **$(if ($asmData.ExecutableSize_KB -lt $csharpData.ExecutableSize_KB) { [math]::Round((1 - $asmData.ExecutableSize_KB / $csharpData.ExecutableSize_KB) * 100, 1) } else { 0 })%** smaller executable

However, the C# version offers dramatically better developer productivity and maintainability. For most applications, the C# approach is recommended unless:
- Absolute minimum resource usage is critical
- No runtime dependencies are acceptable
- Maximum performance is required
- The application is extremely simple (like this clock example)

---

## Test Configuration

**Assembly Application:**
- **Path:** $($asmData.ExecutablePath)
- **Test Date:** $($asmData.Timestamp)
- **Iterations:** $($asmData.Iterations)

**C# Application:**
- **Path:** $($csharpData.ExecutablePath)
- **Test Date:** $($csharpData.Timestamp)
- **Iterations:** $($csharpData.Iterations)

**Test Environment:**
- **OS:** Windows
- **PowerShell:** $($PSVersionTable.PSVersion)
- **Framework:** .NET 8.0 (for C# application)

"@

# Save report
$report | Set-Content -Path $OutputFile
Write-Host "`nComparison report generated: $OutputFile" -ForegroundColor Green

# Display summary to console
Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Performance Comparison Summary" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Startup Time:    ASM: ${asmStartup}ms | C#: ${csStartup}ms | Diff: $startupDiff% | Winner: $startupWinner"
Write-Host "Memory (Avg):    ASM: ${asmMemory}MB | C#: ${csMemory}MB | Diff: $memoryDiff% | Winner: $memoryWinner"
Write-Host "Memory (Max):    ASM: ${asmMaxMemory}MB | C#: ${csMaxMemory}MB | Diff: $maxMemoryDiff% | Winner: $maxMemoryWinner"
Write-Host "CPU Usage:       ASM: ${asmCPU}s | C#: ${csCPU}s | Diff: $cpuDiff% | Winner: $cpuWinner"
Write-Host "Executable Size: ASM: $($asmData.ExecutableSize_KB)KB | C#: $($csharpData.ExecutableSize_KB)KB"
Write-Host "========================================`n" -ForegroundColor Yellow
