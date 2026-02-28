# Performance Benchmarking Script for ASM vs C# Clock Application
# Measures startup time, memory usage, CPU usage, and other metrics

param(
    [string]$ExePath = "",
    [string]$AppName = "Unknown",
    [int]$Iterations = 10,
    [int]$RunDurationSeconds = 5,
    [string]$OutputFile = ""
)

function Measure-AppStartup {
    param(
        [string]$Path,
        [int]$Iterations,
        [int]$Duration
    )
    
    $results = @()
    
    Write-Host "Running $Iterations iterations for: $Path" -ForegroundColor Cyan
    
    for ($i = 1; $i -le $Iterations; $i++) {
        Write-Host "  Iteration $i/$Iterations..." -NoNewline
        
        # Measure startup time
        $startupTime = Measure-Command {
            $process = Start-Process -FilePath $Path -PassThru -WindowStyle Normal
            
            # Wait for process to initialize (up to 2 seconds)
            $timeout = 2000
            $elapsed = 0
            $interval = 50
            while ($elapsed -lt $timeout) {
                Start-Sleep -Milliseconds $interval
                $elapsed += $interval
                
                # Check if process is responsive
                if (-not $process.Responding) {
                    continue
                }
                break
            }
        }
        
        # Get process object
        try {
            $proc = Get-Process -Id $process.Id -ErrorAction Stop
        }
        catch {
            Write-Host " FAILED (process not found)" -ForegroundColor Red
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            continue
        }
        
        # Initial metrics
        $initialMetrics = @{
            WorkingSet = $proc.WorkingSet64
            PrivateMemory = $proc.PrivateMemorySize64
            VirtualMemory = $proc.VirtualMemorySize64
            Handles = $proc.HandleCount
            Threads = $proc.Threads.Count
        }
        
        # Monitor during execution
        $samples = @()
        $sampleCount = $Duration * 2  # Sample every 500ms
        
        for ($s = 0; $s -lt $sampleCount; $s++) {
            Start-Sleep -Milliseconds 500
            
            try {
                $proc = Get-Process -Id $process.Id -ErrorAction Stop
                $cpu = $proc.CPU
                
                $samples += [PSCustomObject]@{
                    Time = $s * 0.5
                    CPU = $cpu
                    WorkingSet = $proc.WorkingSet64
                    PrivateMemory = $proc.PrivateMemorySize64
                }
            }
            catch {
                # Process terminated
                break
            }
        }
        
        # Final metrics
        try {
            $proc = Get-Process -Id $process.Id -ErrorAction Stop
            $finalMetrics = @{
                WorkingSet = $proc.WorkingSet64
                PrivateMemory = $proc.PrivateMemorySize64
                VirtualMemory = $proc.VirtualMemorySize64
                Handles = $proc.HandleCount
                Threads = $proc.Threads.Count
                TotalCPU = $proc.CPU
            }
        }
        catch {
            $finalMetrics = $initialMetrics.Clone()
            $finalMetrics.TotalCPU = 0
        }
        
        # Stop the process
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        
        # Calculate statistics
        $avgWorkingSet = ($samples | Measure-Object -Property WorkingSet -Average).Average
        $maxWorkingSet = ($samples | Measure-Object -Property WorkingSet -Maximum).Maximum
        $avgPrivateMemory = ($samples | Measure-Object -Property PrivateMemory -Average).Average
        
        $result = [PSCustomObject]@{
            Iteration = $i
            StartupTime_ms = [math]::Round($startupTime.TotalMilliseconds, 2)
            InitialWorkingSet_MB = [math]::Round($initialMetrics.WorkingSet / 1MB, 2)
            InitialPrivateMemory_MB = [math]::Round($initialMetrics.PrivateMemory / 1MB, 2)
            AvgWorkingSet_MB = [math]::Round($avgWorkingSet / 1MB, 2)
            MaxWorkingSet_MB = [math]::Round($maxWorkingSet / 1MB, 2)
            AvgPrivateMemory_MB = [math]::Round($avgPrivateMemory / 1MB, 2)
            FinalWorkingSet_MB = [math]::Round($finalMetrics.WorkingSet / 1MB, 2)
            FinalPrivateMemory_MB = [math]::Round($finalMetrics.PrivateMemory / 1MB, 2)
            VirtualMemory_MB = [math]::Round($finalMetrics.VirtualMemory / 1MB, 2)
            Handles = $finalMetrics.Handles
            Threads = $finalMetrics.Threads
            TotalCPU_sec = [math]::Round($finalMetrics.TotalCPU, 2)
        }
        
        $results += $result
        Write-Host " OK" -ForegroundColor Green
    }
    
    return $results
}

function Get-Summary {
    param($Results, $Metric)
    
    $values = $Results | Select-Object -ExpandProperty $Metric
    $avg = ($values | Measure-Object -Average).Average
    $min = ($values | Measure-Object -Minimum).Minimum
    $max = ($values | Measure-Object -Maximum).Maximum
    
    # Calculate standard deviation
    $variance = ($values | ForEach-Object { [math]::Pow($_ - $avg, 2) } | Measure-Object -Average).Average
    $stdDev = [math]::Sqrt($variance)
    
    return [PSCustomObject]@{
        Metric = $Metric
        Average = [math]::Round($avg, 2)
        Min = [math]::Round($min, 2)
        Max = [math]::Round($max, 2)
        StdDev = [math]::Round($stdDev, 2)
    }
}

# Main execution
if (-not $ExePath -or -not (Test-Path $ExePath)) {
    Write-Host "Error: Invalid executable path: $ExePath" -ForegroundColor Red
    exit 1
}

$ExePath = Resolve-Path $ExePath
Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Performance Benchmark: $AppName" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Executable: $ExePath"
Write-Host "Iterations: $Iterations"
Write-Host "Run Duration: $RunDurationSeconds seconds"
Write-Host ""

# Get executable size
$fileInfo = Get-Item $ExePath
$fileSize = [math]::Round($fileInfo.Length / 1KB, 2)
Write-Host "Executable Size: $fileSize KB" -ForegroundColor Cyan
Write-Host ""

# Run benchmark
$results = Measure-AppStartup -Path $ExePath -Iterations $Iterations -Duration $RunDurationSeconds

if ($results.Count -eq 0) {
    Write-Host "`nNo successful iterations!" -ForegroundColor Red
    exit 1
}

# Display detailed results
Write-Host "`nDetailed Results:" -ForegroundColor Green
$results | Format-Table -AutoSize

# Display summary
Write-Host "`nSummary Statistics:" -ForegroundColor Green
$summaryMetrics = @(
    "StartupTime_ms",
    "AvgWorkingSet_MB",
    "MaxWorkingSet_MB",
    "AvgPrivateMemory_MB",
    "TotalCPU_sec",
    "Handles",
    "Threads"
)

$summary = @()
foreach ($metric in $summaryMetrics) {
    $summary += Get-Summary -Results $results -Metric $metric
}
$summary | Format-Table -AutoSize

# Save results to file if specified
if ($OutputFile) {
    $output = @{
        AppName = $AppName
        ExecutablePath = $ExePath.ToString()
        ExecutableSize_KB = $fileSize
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Iterations = $Iterations
        RunDuration = $RunDurationSeconds
        Results = $results
        Summary = $summary
    }
    
    $output | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputFile
    Write-Host "`nResults saved to: $OutputFile" -ForegroundColor Cyan
}

Write-Host "`nBenchmark completed!" -ForegroundColor Green
