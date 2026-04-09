# ASM Clock — Application Flow

## Startup & Initialization

```mermaid
graph TD
    Start["Start Application"] --> Init["GetModuleHandle<br/>LoadMenuA"]
    Init --> RegisterClass["RegisterClassExA<br/>(CS_HREDRAW | CS_VREDRAW)"]
    RegisterClass --> LoadIcons["LoadImageA × 2<br/>(large icon + 16×16 small icon)"]
    LoadIcons --> CreateBrush["CreateSolidBrush<br/>(dark background #0D1117)"]
    CreateBrush --> CenterCalc["GetSystemMetrics<br/>compute centered position"]
    CenterCalc --> CreateWindow["CreateWindowExA<br/>(WS_EX_COMPOSITED)"]
    CreateWindow --> GdipInit["GdiplusStartup"]
    GdipInit --> CacheBrushes["Cache 3 GDI+ Brushes<br/>• Background #0D1117<br/>• Clock face #161B22<br/>• Center dot #F85149"]
    CacheBrushes --> CachePens["Cache 6 GDI+ Pens<br/>• Border, MinTick, HourTick<br/>• Hour, Minute, Second"]
    CachePens --> ShowWin["ShowWindow + UpdateWindow"]
    ShowWin --> SetTimer["SetTimer (1000ms)"]
    SetTimer --> AddTray["Shell_NotifyIconA (NIM_ADD)"]
    AddTray --> MsgLoop
```

## Message Loop & Dispatch

```mermaid
graph TD
    MsgLoop{"Message Loop<br/>GetMessageA"} -- "returns 0 (WM_QUIT)" --> Exit["ExitProcess"]
    MsgLoop -- "returns non-zero" --> IsDialog{"IsDialogMessageA?"}
    IsDialog -- "Yes (handled)" --> MsgLoop
    IsDialog -- "No" --> Translate["TranslateMessage"]
    Translate --> Dispatch["DispatchMessageA → WndProc"]
    Dispatch --> MsgLoop
```

## WndProc Message Handling

```mermaid
graph TD
    WndProc{"WndProc<br/>Message Dispatch"} -- "WM_PAINT" --> Paint["WM_PAINT Handler"]
    WndProc -- "WM_TIMER" --> Timer["InvalidateRect(FALSE)"]
    WndProc -- "WM_ERASEBKGND" --> Erase["Return 1<br/>(suppress system erase)"]
    WndProc -- "WM_TRAYICON_MSG" --> Tray["Tray Icon Handler"]
    WndProc -- "WM_COMMAND" --> Cmd["Menu Command Handler"]
    WndProc -- "WM_DESTROY" --> Destroy["WM_DESTROY Handler"]
    WndProc -- "Other" --> DefProc["DefWindowProcA"]

    Timer --> Return0["Return 0"]
    Erase --> Return1["Return 1"]
```

## WM_PAINT — Rendering Pipeline

```mermaid
graph TD
    PaintStart["BeginPaint"] --> GetRect["GetClientRect"]
    GetRect --> InitNull["Init hMemDC / hMemBitmap /<br/>hOldBitmap / hGraphics = NULL"]
    InitNull --> CreateDC["CreateCompatibleDC"]
    CreateDC -- "NULL?" --> SkipPaint["→ Skip to Cleanup"]
    CreateDC -- "OK" --> CreateBmp["CreateCompatibleBitmap"]
    CreateBmp -- "NULL?" --> SkipPaint
    CreateBmp -- "OK" --> SelectBmp["SelectObject(hMemDC, hMemBitmap)"]
    SelectBmp --> CalcRadius["Calculate Center, Radius<br/>min(W/2, H/2) - 20"]
    CalcRadius -- "Radius < 20" --> SkipPaint
    CalcRadius -- "Radius ≥ 20" --> GdipCreate["GdipCreateFromHDC(hMemDC)"]
    GdipCreate -- "Failed" --> SkipPaint
    GdipCreate -- "OK" --> Smooth["GdipSetSmoothingMode(AntiAlias)"]
    Smooth --> ScalePens["Scale 6 pen widths<br/>scale = Radius / 190.0<br/>GdipSetPenWidth × 6"]
    ScalePens --> Draw
    
    subgraph Draw["Drawing (off-screen buffer)"]
        D1["1. FillRectangle (background)"] --> D2["2. FillEllipse (clock face)"]
        D2 --> D3["3. DrawEllipse (border ring)"]
        D3 --> D4["4. 60× Minute Ticks (SSE2 LUT)"]
        D4 --> D5["5. 12× Hour Ticks (LUT[i×5])"]
        D5 --> D6["6. Hour Hand (interpolated LUT)"]
        D6 --> D7["7. Minute Hand (LUT[minute])"]
        D7 --> D8["8. Second Hand (LUT[second])"]
        D8 --> D9["9. Center Dot (diameter = hourW + 3)"]
    end

    Draw --> SkipPaint
    SkipPaint --> DeleteGfx["GdipDeleteGraphics (if non-null)"]
    DeleteGfx --> Blit{"hMemDC != NULL?"}
    Blit -- "Yes" --> BitBlt["BitBlt(screen ← memDC, SRCCOPY)"]
    Blit -- "No" --> Cleanup
    BitBlt --> Cleanup
    
    subgraph Cleanup["Cleanup (null-safe)"]
        C1["SelectObject(restore old bitmap)"] --> C2["DeleteObject(hMemBitmap)"]
        C2 --> C3["DeleteObject(hMemDC)"]
    end

    Cleanup --> EndPaint["EndPaint → Return 0"]
```

## SSE2 Lookup Table Architecture

```mermaid
graph LR
    subgraph LUT["TickSinCos[60] — 960 bytes"]
        E0["[0] sin=0.000 cos=1.000"]
        E1["[1] sin=0.105 cos=0.995"]
        E2["..."]
        E59["[59] sin=-0.105 cos=0.995"]
    end

    MinTick["Minute Ticks"] -- "index = i (0..59)" --> LUT
    HourTick["Hour Ticks"] -- "index = i×5 (0,5,10..55)" --> LUT
    MinHand["Minute Hand"] -- "index = minute (0..59)" --> LUT
    SecHand["Second Hand"] -- "index = second (0..59)" --> LUT
    HourHand["Hour Hand"] -- "index = (hour%12)×5 + min/12<br/>lerp(floor, ceil, frac)" --> LUT
```

## Tray Icon Interactions

```mermaid
graph TD
    TrayMsg{"Tray Icon Message<br/>lParam"} -- "WM_LBUTTONDBLCLK" --> DblClick{"IsWindowVisible?"}
    DblClick -- "Visible" --> Hide["ShowWindow(SW_HIDE)"]
    DblClick -- "Hidden" --> Show["ShowWindow(SW_SHOWNORMAL)<br/>SetForegroundWindow"]
    
    TrayMsg -- "WM_RBUTTONDOWN" --> RClick["GetCursorPos<br/>SetForegroundWindow<br/>TrackPopupMenuEx"]
    RClick --> MenuChoice{"Menu Selection"}
    MenuChoice -- "IDM_SHOW" --> Show
    MenuChoice -- "IDM_EXIT" --> PostQuit["PostQuitMessage(0)"]

    Hide --> Done["Return 0"]
    Show --> Done
    PostQuit --> Done
```

## WM_DESTROY — Shutdown Sequence

```mermaid
graph TD
    Destroy["WM_DESTROY"] --> DelPens["GdipDeletePen × 6"]
    DelPens --> DelBrushes["GdipDeleteBrush × 3"]
    DelBrushes --> GdipShutdown["GdiplusShutdown"]
    GdipShutdown --> DelTray["Shell_NotifyIconA(NIM_DELETE)"]
    DelTray --> DelMenu["DestroyMenu"]
    DelMenu --> PostQuit["PostQuitMessage(0)"]
    PostQuit --> Return["Return 0"]
```