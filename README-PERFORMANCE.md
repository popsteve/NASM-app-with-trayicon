# Performance Comparison: Assembly vs C# Clock Application

This directory contains a comprehensive performance benchmarking framework to compare the Assembly (NASM) clock application with a functionally equivalent C# Windows Forms application.

## Overview

The benchmark suite measures and compares:

- **Startup time**: Process creation to window ready
- **Memory usage**: Working set, private bytes, virtual memory
- **CPU usage**: Total CPU time during execution
- **System resources**: Handle count, thread count
- **Executable size**: Binary size comparison

## Prerequisites

### Required Software

1. **Assembly Application**: `win.exe` (already built with NASM)
2. **.NET 8.0 SDK**: Download from [dotnet.microsoft.com](https://dotnet.microsoft.com/download/dotnet/8.0)
3. **PowerShell**: Version 5.1 or later (included with Windows)

### Verify Prerequisites

```powershell
# Check .NET SDK
dotnet --version

# Check PowerShell
$PSVersionTable.PSVersion
```

## Quick Start

### Automated Testing (Recommended)

Run the complete benchmark suite with one command:

```powershell
.\build-and-test.ps1
```

This will:

1. Verify Assembly executable exists
2. Build the C# application in Release mode
3. Benchmark the Assembly application (10 iterations)
4. Benchmark the C# application (10 iterations)
5. Generate a comparison report

**Output files:**

- `benchmark-asm.json` - Assembly benchmark results
- `benchmark-csharp.json` - C# benchmark results
- `performance-comparison.md` - Detailed comparison report

### Custom Options

```powershell
# Run with more iterations for better statistical accuracy
.\build-and-test.ps1 -Iterations 20

# Run with longer duration per iteration
.\build-and-test.ps1 -Duration 10

# Skip rebuild (use existing C# executable)
.\build-and-test.ps1 -SkipBuild

# Combine options
.\build-and-test.ps1 -Iterations 20 -Duration 10
```

## Manual Testing

### Step 1: Build C# Application

```powershell
cd ClockApp
dotnet restore
dotnet build -c Release
dotnet publish -c Release -r win-x64 /p:PublishSingleFile=true
```

The executable will be at: `ClockApp\bin\Release\net8.0-windows\win-x64\publish\ClockApp.exe`

### Step 2: Run Individual Benchmarks

**Assembly benchmark:**

```powershell
.\benchmark.ps1 -ExePath ".\win.exe" -AppName "Assembly" -Iterations 10 -OutputFile "benchmark-asm.json"
```

**C# benchmark:**

```powershell
.\benchmark.ps1 -ExePath ".\ClockApp\bin\Release\net8.0-windows\win-x64\publish\ClockApp.exe" -AppName "C#" -Iterations 10 -OutputFile "benchmark-csharp.json"
```

### Step 3: Generate Comparison Report

```powershell
.\compare-results.ps1 -AsmResultsFile "benchmark-asm.json" -CSharpResultsFile "benchmark-csharp.json" -OutputFile "performance-comparison.md"
```

## Understanding the Results

### Metrics Explained

| Metric              | Description                                 | Lower is Better? |
| ------------------- | ------------------------------------------- | ---------------- |
| **Startup Time**    | Time from process start to window ready     | ✓ Yes            |
| **Working Set**     | Physical RAM currently used                 | ✓ Yes            |
| **Private Memory**  | Memory committed by the process             | ✓ Yes            |
| **Virtual Memory**  | Total virtual address space used            | ✓ Yes            |
| **CPU Time**        | Total CPU seconds consumed                  | ✓ Yes            |
| **Handles**         | Number of OS handles (files, windows, etc.) | ✓ Yes            |
| **Threads**         | Number of active threads                    | ✓ Yes            |
| **Executable Size** | Size of the .exe file                       | ✓ Yes            |

### Expected Results

**Assembly (NASM) typically wins in:**

- Executable size (should be 10-100x smaller)
- Startup time (should be 2-5x faster)
- Memory usage (should use 5-10x less RAM)
- System resources (fewer handles and threads)

**C# (Windows Forms) advantages:**

- Development time (much faster to write and modify)
- Maintainability (easier to read and understand)
- Safety (memory-safe, type-safe)
- Ecosystem (rich .NET framework and libraries)

## Troubleshooting

### "Assembly executable not found"

Make sure `win.exe` is built and located in the same directory as the scripts.

### ".NET SDK not installed"

Download and install .NET 8.0 SDK from Microsoft's website.

### "Access denied" or permissions errors

Run PowerShell as Administrator, or adjust execution policy:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Processes not terminating

If benchmark processes hang, manually kill them:

```powershell
Get-Process | Where-Object { $_.Name -like "*Clock*" -or $_.Name -eq "win" } | Stop-Process -Force
```

### Inconsistent results

- Close other applications to reduce system noise
- Increase iterations: `.\build-and-test.ps1 -Iterations 20`
- Run multiple times and average results
- Disable antivirus temporarily (it may interfere with timing)

## Advanced Usage

### Build Variants

The C# application can be built with different optimizations:

**Standard (framework-dependent):**

```powershell
dotnet publish -c Release
```

**Self-contained (includes .NET runtime):**

```powershell
dotnet publish -c Release -r win-x64 --self-contained true
```

**ReadyToRun (AOT compilation):**

```powershell
dotnet publish -c Release -r win-x64 /p:PublishReadyToRun=true
```

Each variant will have different performance characteristics.

### Profiling with Additional Tools

For deeper analysis, use:

**Windows Performance Recorder:**

```powershell
# Start recording
wpr -start CPU -start FileIO

# Run benchmark
.\build-and-test.ps1

# Stop recording
wpr -stop performance.etl

# Analyze with Windows Performance Analyzer
wpa performance.etl
```

**Process Explorer (Sysinternals):**

- Download from Microsoft Sysinternals
- Monitor real-time resource usage
- Compare side-by-side execution

## Project Structure

```
ASM/
├── win.asm                  # Assembly source code
├── win.exe                  # Compiled Assembly executable
├── logo.ico                 # Application icon
├── ClockApp/                # C# application
│   ├── ClockApp.csproj      # Project file
│   ├── Program.cs           # Entry point
│   └── ClockForm.cs         # Main form with clock
├── benchmark.ps1            # Individual benchmark script
├── compare-results.ps1      # Comparison analysis script
├── build-and-test.ps1       # Automated test suite
└── README-PERFORMANCE.md    # This file
```

## Contributing

To modify the benchmark suite:

1. **Add new metrics**: Edit `benchmark.ps1` to capture additional performance data
2. **Change test parameters**: Modify `build-and-test.ps1` default values
3. **Customize report**: Edit `compare-results.ps1` markdown template

## FAQ

**Q: Why does C# use more memory?**
A: The .NET runtime (CLR), garbage collector, and framework libraries add overhead. This is the trade-off for developer productivity and safety.

**Q: Can Assembly always beat C# in performance?**
A: For simple applications, yes. However, as complexity grows, hand-optimized Assembly becomes impractical. Modern compilers (including C#'s JIT) can generate very efficient code.

**Q: Should I write my application in Assembly?**
A: Probably not. Assembly is only recommended for:

- Extreme performance requirements
- Minimal resource constraints (embedded systems)
- Educational purposes
- Specific performance-critical kernels within larger applications

For most applications, high-level languages like C# provide better productivity, maintainability, and are "fast enough."

**Q: How accurate are these benchmarks?**
A: The benchmarks provide a good relative comparison but aren't perfect. Factors like Windows updates, background processes, and antivirus can affect results. Run multiple iterations and look at trends rather than absolute values.

## License

This benchmarking framework is provided as-is for educational and comparison purposes.
