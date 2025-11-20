# NASM Windows App with Tray Icon & Analog Clock

A lightweight Windows application written in x64 Assembly (NASM) featuring a system tray icon, context menu, and a GDI-based analog clock.

## Features

- **Analog Clock**: Displays the current system time using an analog clock face drawn with GDI. Hand angles are calculated using FPU instructions.
- **System Tray Icon**: Minimizes to the system tray.
- **Context Menu**: Right-click the tray icon to access a menu with "Show" and "Exit" options.
- **Window Management**: Can be minimized to the tray and restored.

## Prerequisites

To build this project, you need the following tools in your PATH:

- **NASM**: The Netwide Assembler (for assembling `win.asm`).
- **GoLink**: Linker for Windows (for linking `win.obj` and resources).
- **GoRC**: Resource Compiler (for compiling `resource.rc`).

## Build Instructions

A batch script is provided to automate the build process.

1.  Open a command prompt or PowerShell in the project directory.
2.  Run the build script:
    ```cmd
    .\build_auto.bat
    ```

This will compile the resources, assemble the code, and link the executable `win.exe`.

## Usage

1.  Run `win.exe`.
2.  The window will appear showing the analog clock.
3.  You can minimize the window to the system tray.
4.  Right-click the tray icon to Show the window or Exit the application.
