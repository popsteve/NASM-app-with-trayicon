# ASM Native Clock

A high-performance, lightweight Windows analog clock application written entirely in x64 Assembly (NASM). It features a system tray icon, context menu, and a premium anti-aliased UI rendered via GDI+.

## ✨ Features & Optimizations

- **High-Quality Rendering (GDI+)**: Fully anti-aliased clock hands, tick marks, and background.
- **SSE2 Vectorization**: All x87 FPU instructions have been completely eliminated. The application uses a custom 60-entry precomputed `sin`/`cos` lookup table, combined with sub-tick linear interpolation for the hour hand, achieving high precision using purely `mulsd`/`addsd`/`cvttsd2si` SSE2 instructions.
- **Zero-Flicker Double Buffering**: Implements a manual off-screen memory DC (`CreateCompatibleDC` + `CreateCompatibleBitmap`). Every frame is rendered entirely in memory and pushed to the screen via a single `BitBlt`, eliminating window-maximize flicker.
- **GDI+ Object Caching**: Bypasses the expensive per-frame handle allocation (Heap Alloc/Free) by pre-caching 6 pens and 3 brushes globally at application initialization.
- **System Tray Integration**: Quietly minimizes to the taskbar system tray with a right-click context menu.

## 🛠 Prerequisites

To build this project, you need the following tools in your `PATH`:

1. **NASM**: The Netwide Assembler (`nasm`) for assembling the `win.asm` code.
2. **GoLink**: Lightweight Linker for Windows to bind the `obj` file with Windows API DLLs.
3. **GoRC**: Resource Compiler to compile the icon and menu resources (`resource.rc`).

## 🚀 Build Instructions

A batch script (`build_auto.bat`) is provided to fully automate the build process.

1. Open a Command Prompt or PowerShell in the project directory.
2. Run the build script:
   ```cmd
   .\build_auto.bat
   ```

### Manual Compilation Pipeline

If you prefer to compile it manually, the exact pipeline is:

1. **Compile Resources**: 
   ```cmd
   GoRC.Exe /r resource.rc
   ```
2. **Assemble Code**:
   ```cmd
   nasm -f win64 win.asm -o win.obj
   ```
3. **Link Executable**:
   ```cmd
   GoLink.Exe /console win.obj resource.res kernel32.dll user32.dll gdi32.dll gdiplus.dll shell32.dll
   ```

## 🎮 Usage

1. Run the generated `win.exe`.
2. The window will display the real-time analog clock.
3. Minimize the window to hide it into the system tray.
4. Right-click the tray icon to **Show** the window or **Exit** the application.
