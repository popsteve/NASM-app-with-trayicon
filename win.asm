COLOR_WINDOW        EQU 5                       ; Constants
CS_BYTEALIGNWINDOW  EQU 2000h
CS_HREDRAW          EQU 2
CS_VREDRAW          EQU 1
CW_USEDEFAULT       EQU 80000000h
IDC_ARROW           EQU 7F00h
IDI_APPLICATION     EQU 7F00h
IMAGE_CURSOR        EQU 2
IMAGE_ICON          EQU 1
LR_SHARED           EQU 8000h
LR_LOADFROMFILE     EQU 10h
NULL                EQU 0
SW_SHOWNORMAL       EQU 1
WM_DESTROY          EQU 2
WM_ERASEBKGND       EQU 14h
WS_EX_COMPOSITED    EQU 2000000h
WS_OVERLAPPEDWINDOW EQU 0CF0000h
WM_PAINT            EQU 0Fh
NIM_ADD             EQU 0                         ; NotifyIcon messages
NIM_MODIFY          EQU 1
NIM_DELETE          EQU 2
NIF_MESSAGE         EQU 1                         ; NOTIFYICONDATA flags
NIF_ICON            EQU 2
NIF_TIP             EQU 4
WM_USER             EQU 0400h
WM_TRAYICON_MSG     EQU WM_USER + 1               ; Our custom tray icon message
WM_LBUTTONDOWN      EQU 0201h
WM_LBUTTONDBLCLK    EQU 0203h
WM_RBUTTONDOWN      EQU 0204h
SW_HIDE             EQU 0
WM_COMMAND          EQU 0111h                     ; Message for menu clicks
IDR_MYMENU          EQU 101                       ; Menu resource ID (example)
IDM_SHOW            EQU 102                       ; Menu item ID: Show (example)
IDM_EXIT            EQU 103                       ; Menu item ID: Exit (example)
IDI_MYICON          EQU 201                       ; Custom icon resource ID
TPM_LEFTALIGN       EQU 0
TPM_RIGHTBUTTON     EQU 2
TPM_RETURNCMD       EQU 100h
WM_TIMER            EQU 0113h
DT_CENTER           EQU 1
DT_VCENTER          EQU 4
DT_SINGLELINE       EQU 20h
SRCCOPY             EQU 00CC0020h


WindowWidth         EQU 420
WindowHeight        EQU 440

; Named constants (replaces magic numbers)
CLOCK_MARGIN         EQU 20
HOUR_HAND_RATIO_NUM  EQU 5
HOUR_HAND_RATIO_DEN  EQU 10
MIN_HAND_RATIO_NUM   EQU 75
MIN_HAND_RATIO_DEN   EQU 100
SEC_HAND_RATIO_NUM   EQU 9
SEC_HAND_RATIO_DEN   EQU 10
CENTER_DOT_RADIUS    EQU 6
TIMER_ID             EQU 1
TIMER_INTERVAL_MS    EQU 1000
TRAY_ICON_SIZE       EQU 16
TRAY_CENTER          EQU 8
TRAY_FACE_ORIGIN     EQU 1
TRAY_FACE_DIAM       EQU 14
TRAY_HAND_HOUR_LEN   EQU 3
TRAY_HAND_MIN_LEN    EQU 5
TRAY_HAND_SEC_LEN    EQU 6

extern CreateWindowExA                          ; Import external symbols
extern GetSystemMetrics
extern DefWindowProcA
extern DispatchMessageA
extern ExitProcess
extern GetMessageA
extern GetModuleHandleA
extern IsDialogMessageA
extern LoadImageA
extern PostQuitMessage
extern RegisterClassExA
extern ShowWindow
extern TranslateMessage
extern UpdateWindow
extern BeginPaint
extern EndPaint
extern Shell_NotifyIconA
extern LoadMenuA
extern GetSubMenu
extern TrackPopupMenuEx
extern SetForegroundWindow
extern GetCursorPos
extern DestroyMenu
extern IsWindowVisible
extern GetClientRect
extern SetTimer
extern GetLocalTime
extern InvalidateRect
extern SelectObject
extern DeleteObject
extern CreateSolidBrush
extern CreateCompatibleDC
extern CreateCompatibleBitmap
extern BitBlt
extern GdiplusStartup
extern GdiplusShutdown
extern GdipCreateFromHDC
extern GdipDeleteGraphics
extern GdipSetSmoothingMode
extern GdipCreatePen1
extern GdipDeletePen
extern GdipDrawLineI
extern GdipDrawEllipseI
extern GdipCreateSolidFill
extern GdipDeleteBrush
extern GdipFillEllipseI
extern GdipFillRectangleI
extern GdipSetPenWidth
extern GetDC
extern ReleaseDC
extern DeleteDC
extern CreateIconIndirect
extern DestroyIcon
extern CreateBitmap


global Start                                    ; Export symbols. The entry point

section .data                                   ; Initialized data segment
 WindowName  db "Clock", 0
 ClassName   db "Window", 0
 TrayToolTip db "My Tray Application", 0
 PAINTSTRUCT_SIZE EQU 72
 LogoPath    db "logo.ico", 0
 PS_SOLID    EQU 0
 HOUR_PEN_WIDTH   EQU 5
 MINUTE_PEN_WIDTH EQU 3
 SECOND_PEN_WIDTH EQU 1
 GdiplusVersion   EQU 1
 UnitPixel        EQU 2
 SmoothingAntiAlias EQU 4
 ; GdiplusStartupInput structure (20 bytes, padded to 24 on x64)
 align 8
 GdiplusStartupInputData:
  dd GdiplusVersion              ; GdiplusVersion = 1
  dd 0                           ; padding for 8-byte alignment
  dq 0                           ; DebugEventCallback = NULL (aligned)
  dd 0                           ; SuppressBackgroundThread = FALSE
  dd 0                           ; SuppressExternalCodecs = FALSE
 ; Float pen widths for GDI+ (REAL = single-precision float)
 fPenWidth1  dd 1.0
 fPenWidth2  dd 2.0
 fPenWidth3  dd 3.0
 fPenWidth5  dd 5.0
 fPenWidth7  dd 7.0

 ; SSE2 double-precision constants for hand-length ratios
 align 8
 kHourHandRatio  dq 0.5     ; HOUR_HAND_RATIO_NUM / DEN  (5/10)
 kMinHandRatio   dq 0.75    ; MIN_HAND_RATIO_NUM / DEN   (75/100)
 kSecHandRatio   dq 0.9     ; SEC_HAND_RATIO_NUM / DEN   (9/10)
 kOneOverTwelve  dq 0.08333333333333333  ; 1/12 for hour-hand interpolation
 kFive           dq 5.0

 ; Reference radius for pen-width scaling (default window 420×440 → radius 190)
 kRefRadius      dq 190.0
 ; Base pen widths at reference radius (doubles for SSE2 scaling)
 ; Hands are 3× the original widths; ticks/border scale proportionally
 kBaseWBorder    dq 2.0     ; border ring
 kBaseWMinTick   dq 1.0     ; 60 minute tick marks
 kBaseWHourTick  dq 3.0     ; 12 hour tick marks
 kBaseWHour      dq 21.0    ; hour hand   (7 × 3)
 kBaseWMinute    dq 9.0     ; minute hand (3 × 3)
 kBaseWSecond    dq 3.0     ; second hand (1 × 3)

 ; Precomputed sin/cos lookup table for 60 tick positions
 ; Layout: { sin(i*PI/30), cos(i*PI/30) }  — 16 bytes per entry, 960 bytes total
 ; Covers minute ticks, hour ticks (every 5th), minute hand, and second hand
 align 16
 TickSinCos:
  dq 0.00000000000000000e+00, 1.00000000000000000e+00  ; i= 0 (  0 deg)
  dq 1.04528463267653457e-01, 9.94521895368273290e-01  ; i= 1 (  6 deg)
  dq 2.07911690817759315e-01, 9.78147600733805689e-01  ; i= 2 ( 12 deg)
  dq 3.09016994374947396e-01, 9.51056516295153531e-01  ; i= 3 ( 18 deg)
  dq 4.06736643075800153e-01, 9.13545457642600867e-01  ; i= 4 ( 24 deg)
  dq 4.99999999999999944e-01, 8.66025403784438708e-01  ; i= 5 ( 30 deg)
  dq 5.87785252292473137e-01, 8.09016994374947451e-01  ; i= 6 ( 36 deg)
  dq 6.69130606358858238e-01, 7.43144825477394244e-01  ; i= 7 ( 42 deg)
  dq 7.43144825477394133e-01, 6.69130606358858238e-01  ; i= 8 ( 48 deg)
  dq 8.09016994374947451e-01, 5.87785252292473137e-01  ; i= 9 ( 54 deg)
  dq 8.66025403784438597e-01, 5.00000000000000111e-01  ; i=10 ( 60 deg)
  dq 9.13545457642600867e-01, 4.06736643075800375e-01  ; i=11 ( 66 deg)
  dq 9.51056516295153531e-01, 3.09016994374947451e-01  ; i=12 ( 72 deg)
  dq 9.78147600733805689e-01, 2.07911690817759232e-01  ; i=13 ( 78 deg)
  dq 9.94521895368273290e-01, 1.04528463267653457e-01  ; i=14 ( 84 deg)
  dq 1.00000000000000000e+00, 2.83276944882398981e-16  ; i=15 ( 90 deg)
  dq 9.94521895368273401e-01,-1.04528463267653332e-01  ; i=16 ( 96 deg)
  dq 9.78147600733805689e-01,-2.07911690817759343e-01  ; i=17 (102 deg)
  dq 9.51056516295153642e-01,-3.09016994374947340e-01  ; i=18 (108 deg)
  dq 9.13545457642600978e-01,-4.06736643075800097e-01  ; i=19 (114 deg)
  dq 8.66025403784438708e-01,-4.99999999999999778e-01  ; i=20 (120 deg)
  dq 8.09016994374947451e-01,-5.87785252292473026e-01  ; i=21 (126 deg)
  dq 7.43144825477394466e-01,-6.69130606358857905e-01  ; i=22 (132 deg)
  dq 6.69130606358858349e-01,-7.43144825477394133e-01  ; i=23 (138 deg)
  dq 5.87785252292473248e-01,-8.09016994374947340e-01  ; i=24 (144 deg)
  dq 4.99999999999999944e-01,-8.66025403784438708e-01  ; i=25 (150 deg)
  dq 4.06736643075800042e-01,-9.13545457642600978e-01  ; i=26 (156 deg)
  dq 3.09016994374947507e-01,-9.51056516295153531e-01  ; i=27 (162 deg)
  dq 2.07911690817759315e-01,-9.78147600733805689e-01  ; i=28 (168 deg)
  dq 1.04528463267653290e-01,-9.94521895368273401e-01  ; i=29 (174 deg)
  dq 5.66553889764797962e-16,-1.00000000000000000e+00  ; i=30 (180 deg)
  dq -1.04528463267653055e-01,-9.94521895368273401e-01 ; i=31 (186 deg)
  dq -2.07911690817759065e-01,-9.78147600733805689e-01 ; i=32 (192 deg)
  dq -3.09016994374947285e-01,-9.51056516295153642e-01 ; i=33 (198 deg)
  dq -4.06736643075800208e-01,-9.13545457642600867e-01 ; i=34 (204 deg)
  dq -4.99999999999999722e-01,-8.66025403784438819e-01 ; i=35 (210 deg)
  dq -5.87785252292473026e-01,-8.09016994374947451e-01 ; i=36 (216 deg)
  dq -6.69130606358858238e-01,-7.43144825477394244e-01 ; i=37 (222 deg)
  dq -7.43144825477394022e-01,-6.69130606358858460e-01 ; i=38 (228 deg)
  dq -8.09016994374947340e-01,-5.87785252292473248e-01 ; i=39 (234 deg)
  dq -8.66025403784438486e-01,-5.00000000000000444e-01 ; i=40 (240 deg)
  dq -9.13545457642600534e-01,-4.06736643075800930e-01 ; i=41 (246 deg)
  dq -9.51056516295153531e-01,-3.09016994374947562e-01 ; i=42 (252 deg)
  dq -9.78147600733805578e-01,-2.07911690817759787e-01 ; i=43 (258 deg)
  dq -9.94521895368273290e-01,-1.04528463267654234e-01 ; i=44 (264 deg)
  dq -1.00000000000000000e+00,-1.83697019872102969e-16 ; i=45 (270 deg)
  dq -9.94521895368273401e-01, 1.04528463267652985e-01 ; i=46 (276 deg)
  dq -9.78147600733805578e-01, 2.07911690817759426e-01 ; i=47 (282 deg)
  dq -9.51056516295153642e-01, 3.09016994374947229e-01 ; i=48 (288 deg)
  dq -9.13545457642601089e-01, 4.06736643075799764e-01 ; i=49 (294 deg)
  dq -8.66025403784438597e-01, 5.00000000000000111e-01 ; i=50 (300 deg)
  dq -8.09016994374947562e-01, 5.87785252292472915e-01 ; i=51 (306 deg)
  dq -7.43144825477394022e-01, 6.69130606358858460e-01 ; i=52 (312 deg)
  dq -6.69130606358858127e-01, 7.43144825477394244e-01 ; i=53 (318 deg)
  dq -5.87785252292473359e-01, 8.09016994374947340e-01 ; i=54 (324 deg)
  dq -4.99999999999999667e-01, 8.66025403784438819e-01 ; i=55 (330 deg)
  dq -4.06736643075800153e-01, 9.13545457642600978e-01 ; i=56 (336 deg)
  dq -3.09016994374947673e-01, 9.51056516295153531e-01 ; i=57 (342 deg)
  dq -2.07911690817758982e-01, 9.78147600733805689e-01 ; i=58 (348 deg)
  dq -1.04528463267653415e-01, 9.94521895368273290e-01 ; i=59 (354 deg)

 ; Monochrome mask bits for tray icon (16×16, all zeros = fully opaque)
 align 4
 TrayMaskBits: times 32 db 0


section .bss                                    ; Uninitialized data segment
 alignb 8
 hInstance resq 1
 hMenu     resq 1                               ; Handle for the loaded menu
 pt        resq 1                               ; POINT structure for GetCursorPos (x, y as LONGs)
 SystemTime resb 16                             ; SYSTEMTIME structure
 gdiplusToken resq 1                            ; GDI+ startup token
 hBgBrush  resq 1                               ; Background brush handle (GDI, for WNDCLASS)
 ; Cached GDI+ brushes (created once, reused every frame)
 gBrushBg      resq 1                           ; 0xFF0D1117 — window background fill
 gBrushFace    resq 1                           ; 0xFF161B22 — clock face fill
 gBrushCenter  resq 1                           ; 0xFFF85149 — center dot fill
 ; Cached GDI+ pens (created once, reused every frame)
 gPenBorder    resq 1                           ; 0xFF30363D, 2px — clock border ring
 gPenMinTick   resq 1                           ; 0xFF484F58, 1px — 60 minute tick marks
 gPenHourTick  resq 1                           ; 0xFFC9D1D9, 3px — 12 hour tick marks
 gPenHour      resq 1                           ; 0xFFC9D1D9, 7px — hour hand
 gPenMinute    resq 1                           ; 0xFF58A6FF, 3px — minute hand
 gPenSecond    resq 1                           ; 0xFFF85149, 1px — second hand
 hDynTrayIcon  resq 1                           ; dynamically created tray icon for animation


section .text                                   ; Code segment
Start:
 sub   RSP, 8                                   ; Align stack pointer to 16 bytes

 ; Load Menu
 sub   RSP, 32                                  ; Shadow space
 xor   ECX, ECX                                 ; ECX = NULL for GetModuleHandleA(NULL)
 call  GetModuleHandleA
 mov   qword [REL hInstance], RAX
 mov   RCX, RAX                                 ; RCX = hInstance
 mov   EDX, IDR_MYMENU                          ; RDX = Menu resource name/ID
 call  LoadMenuA
 mov   qword [REL hMenu], RAX                   ; Store hMenu
 test  RAX, RAX                                 ; Check if LoadMenuA failed
 jnz   .LoadMenuOK
 mov   ECX, 97                                  ; Error code for menu load failure
 call  ExitProcess                              ; Exit if menu failed to load
.LoadMenuOK:
 add   RSP, 32                                  ; Remove shadow space

 ; hInstance already set at line 108

 call  WinMain

ExitWinMain:             ; Define the exit label here
 xor   ECX, ECX
 call  ExitProcess

WinMain:
 push  RBP                                      ; Set up a stack frame
 mov   RBP, RSP
 sub   RSP, 320                                 ; 168 (nid) + 80 (wc) + 48 (msg) + 8 (hWnd) + 8 (temp locals) + 8 (align) = 320 bytes.
                                                ; 320 is divisible by 16 (0x140) ensuring RSP alignment.

%define nid                RBP - 304            ; NOTIFYICONDATA structure, 168 bytes (up to szTip[128])
%define nid.cbSize         RBP - 304            ; DWORD (4 bytes)
%define nid.hWnd           RBP - 296            ; HWND (8 bytes)  (offset 8)
%define nid.uID            RBP - 288            ; UINT (4 bytes)  (offset 16)
%define nid.uFlags         RBP - 284            ; UINT (4 bytes)  (offset 20)
%define nid.uCallbackMessage RBP - 280          ; UINT (4 bytes)  (offset 24)
%define nid.hIcon          RBP - 272            ; HICON (8 bytes) (offset 32)
%define nid.szTip          RBP - 264            ; CHAR[128] (offset 40)

%define wc                 RBP - 136            ; WNDCLASSEX structure, 80 bytes
%define wc.cbSize          RBP - 136            ; 4 bytes. Start on an 8 byte boundary
%define wc.style           RBP - 132            ; 4 bytes
%define wc.lpfnWndProc     RBP - 128            ; 8 bytes
%define wc.cbClsExtra      RBP - 120            ; 4 bytes
%define wc.cbWndExtra      RBP - 116            ; 4 bytes
%define wc.hInstance       RBP - 112            ; 8 bytes
%define wc.hIcon           RBP - 104            ; 8 bytes
%define wc.hCursor         RBP - 96             ; 8 bytes
%define wc.hbrBackground   RBP - 88             ; 8 bytes
%define wc.lpszMenuName    RBP - 80             ; 8 bytes
%define wc.lpszClassName   RBP - 72             ; 8 bytes
%define wc.hIconSm         RBP - 64             ; 8 bytes. End on an 8 byte boundary

%define msg                RBP - 56             ; MSG structure, 48 bytes
%define msg.hwnd           RBP - 56             ; 8 bytes. Start on an 8 byte boundary
%define msg.message        RBP - 48             ; 4 bytes
%define msg.Padding1       RBP - 44             ; 4 bytes. Natural alignment padding
%define msg.wParam         RBP - 40             ; 8 bytes
%define msg.lParam         RBP - 32             ; 8 bytes
%define msg.time           RBP - 24             ; 4 bytes
%define msg.py.x           RBP - 20             ; 4 bytes
%define msg.pt.y           RBP - 16             ; 4 bytes
%define msg.Padding2       RBP - 12             ; 4 bytes. Structure length padding

%define hWnd               RBP - 8              ; 8 bytes
%define TempCenterXPos     RBP - 312            ; DWORD scratch for window centering
%define TempCenterYPos     RBP - 316            ; DWORD scratch for window centering

 mov   dword [wc.cbSize], 80                    ; [RBP - 136]
 mov   dword [wc.style], CS_HREDRAW | CS_VREDRAW | CS_BYTEALIGNWINDOW  ; [RBP - 132]
 lea   RAX, [REL WndProc]
 mov   qword [wc.lpfnWndProc], RAX              ; [RBP - 128]
 mov   dword [wc.cbClsExtra], NULL              ; [RBP - 120]
 mov   dword [wc.cbWndExtra], NULL              ; [RBP - 116]
 mov   RAX, qword [REL hInstance]               ; Global
 mov   qword [wc.hInstance], RAX                ; [RBP - 112]

 sub   RSP, 32 + 16                             ; Shadow space + 2 parameters
 mov   RCX, qword [REL hInstance]               ; RCX = hInstance (load from resource)
 mov   EDX, IDI_MYICON                          ; RDX = Resource ID 201
 mov   R8D, IMAGE_ICON
 xor   R9D, R9D
 mov   qword [RSP + 4 * 8], NULL
 mov   qword [RSP + 5 * 8], LR_SHARED
 call  LoadImageA                               ; Large program icon from resource
 test  RAX, RAX                                 ; Check if resource icon loaded
 jnz   .CustomIconLoaded1                       ; If loaded, use it
 ; Fallback to system icon
 xor   ECX, ECX
 mov   EDX, IDI_APPLICATION
 mov   R8D, IMAGE_ICON
 xor   R9D, R9D
 mov   qword [RSP + 4 * 8], NULL
 mov   qword [RSP + 5 * 8], LR_SHARED
 call  LoadImageA
.CustomIconLoaded1:
 mov   qword [wc.hIcon], RAX                    ; [RBP - 104]
 add   RSP, 48                                  ; Remove the 48 bytes

 sub   RSP, 32 + 16                             ; Shadow space + 2 parameters
 xor   ECX, ECX
 mov   EDX, IDC_ARROW
 mov   R8D, IMAGE_CURSOR
 xor   R9D, R9D
 mov   qword [RSP + 4 * 8], NULL
 mov   qword [RSP + 5 * 8], LR_SHARED
 call  LoadImageA                               ; Cursor
 mov   qword [wc.hCursor], RAX                  ; [RBP - 96]
 add   RSP, 48                                  ; Remove the 48 bytes

 ; Create dark background brush (COLORREF is BGR: #0D1117 -> 0x0017110D)
 sub   RSP, 32
 mov   ECX, 0x0017110D
 call  CreateSolidBrush
 mov   qword [REL hBgBrush], RAX
 add   RSP, 32
 mov   qword [wc.hbrBackground], RAX            ; [RBP - 88] dark background

 mov   qword [wc.lpszMenuName], NULL            ; [RBP - 80]
 lea   RAX, [REL ClassName]
 mov   qword [wc.lpszClassName], RAX            ; [RBP - 72]

 sub   RSP, 32 + 16                             ; Shadow space + 2 parameters
 mov   RCX, qword [REL hInstance]               ; RCX = hInstance (load from resource)
 mov   EDX, IDI_MYICON                          ; RDX = Resource ID 201
 mov   R8D, IMAGE_ICON
 mov   R9D, 16                                  ; Desired width = 16 (small icon)
 mov   qword [RSP + 4 * 8], 16                  ; Desired height = 16
 mov   qword [RSP + 5 * 8], LR_SHARED
 call  LoadImageA                               ; Small program icon from resource
 test  RAX, RAX                                 ; Check if resource icon loaded
 jnz   .CustomIconLoaded2                       ; If loaded, use it
 ; Fallback to system icon
 xor   ECX, ECX
 mov   EDX, IDI_APPLICATION
 mov   R8D, IMAGE_ICON
 xor   R9D, R9D
 mov   qword [RSP + 4 * 8], NULL
 mov   qword [RSP + 5 * 8], LR_SHARED
 call  LoadImageA
.CustomIconLoaded2:
 mov   qword [wc.hIconSm], RAX                  ; [RBP - 64]
 test  RAX, RAX                                 ; Check if LoadImageA for hIconSm failed
 jnz   .LoadIconSmOK                            ; If not zero (success), continue
 ; LoadImageA for hIconSm failed, exit for debugging
 mov   ECX, 98                                  ; Error code for small icon load failure
 call  ExitProcess
.LoadIconSmOK:
 add   RSP, 48                                  ; Remove the 48 bytes

 sub   RSP, 32                                  ; 32 bytes of shadow space
 lea   RCX, [wc]                                ; [RBP - 136]
 call  RegisterClassExA
 test  RAX, RAX                                 ; Check if registration failed
 jz    .Done                                      ; Exit if failed (restore stack frame)
 add   RSP, 32                                  ; Remove the 32 bytes

 ; Get screen size and compute centered position
 sub   RSP, 32
 xor   ECX, ECX                                 ; SM_CXSCREEN = 0
 call  GetSystemMetrics
 sub   EAX, WindowWidth
 shr   EAX, 1                                   ; X = (screenW - winW) / 2
 mov   dword [TempCenterXPos], EAX              ; dedicated local variable
 add   RSP, 32

 sub   RSP, 32
 mov   ECX, 1                                   ; SM_CYSCREEN = 1
 call  GetSystemMetrics
 sub   EAX, WindowHeight
 shr   EAX, 1                                   ; Y = (screenH - winH) / 2
 mov   dword [TempCenterYPos], EAX              ; dedicated local variable
 add   RSP, 32

 sub   RSP, 32 + 64                             ; Shadow space + 8 parameters
 mov   ECX, WS_EX_COMPOSITED
 lea   RDX, [REL ClassName]                     ; Global
 lea   R8, [REL WindowName]                     ; Global
 mov   R9D, WS_OVERLAPPEDWINDOW
 mov   EAX, dword [TempCenterXPos]              ; retrieve centered X
 mov   dword [RSP + 4 * 8], EAX
 mov   EAX, dword [TempCenterYPos]              ; retrieve centered Y
 mov   dword [RSP + 5 * 8], EAX
 mov   dword [RSP + 6 * 8], WindowWidth
 mov   dword [RSP + 7 * 8], WindowHeight
 mov   qword [RSP + 8 * 8], NULL
 mov   qword [RSP + 9 * 8], NULL
 mov   RAX, qword [REL hInstance]               ; Global
 mov   qword [RSP + 10 * 8], RAX
 mov   qword [RSP + 11 * 8], NULL
 call  CreateWindowExA
 test  RAX, RAX                                 ; Check if window creation failed
 jz    .Done                                      ; Exit if failed (restore stack frame)
 mov   qword [hWnd], RAX                        ; [RBP - 8]
 add   RSP, 96                                  ; Remove the 96 bytes

  ; Initialize GDI+ (must happen BEFORE ShowWindow so the first WM_PAINT can draw)
  sub   RSP, 32
  lea   RCX, [REL gdiplusToken]                  ; &token
  lea   RDX, [REL GdiplusStartupInputData]        ; &input struct
  xor   R8D, R8D                                 ; output = NULL
  call  GdiplusStartup
  add   RSP, 32
  test  EAX, EAX                                 ; Check GDI+ status
  jz    .GdiplusOK
  mov   ECX, 96                                  ; Error code
  call  ExitProcess
.GdiplusOK:

  ; =========================================================
  ;  Pre-cache GDI+ brushes & pens (created once, reused every frame)
  ; =========================================================
  ; --- Brushes ---
  sub   RSP, 32
  mov   ECX, 0xFF0D1117
  lea   RDX, [REL gBrushBg]
  call  GdipCreateSolidFill
  add   RSP, 32

  sub   RSP, 32
  mov   ECX, 0xFF161B22
  lea   RDX, [REL gBrushFace]
  call  GdipCreateSolidFill
  add   RSP, 32

  sub   RSP, 32
  mov   ECX, 0xFFF85149
  lea   RDX, [REL gBrushCenter]
  call  GdipCreateSolidFill
  add   RSP, 32

  ; --- Pens ---
  sub   RSP, 32
  mov   ECX, 0xFF30363D
  movss XMM1, [REL fPenWidth2]
  mov   R8D, UnitPixel
  lea   R9, [REL gPenBorder]
  call  GdipCreatePen1
  add   RSP, 32

  sub   RSP, 32
  mov   ECX, 0xFF484F58
  movss XMM1, [REL fPenWidth1]
  mov   R8D, UnitPixel
  lea   R9, [REL gPenMinTick]
  call  GdipCreatePen1
  add   RSP, 32

  sub   RSP, 32
  mov   ECX, 0xFFC9D1D9
  movss XMM1, [REL fPenWidth3]
  mov   R8D, UnitPixel
  lea   R9, [REL gPenHourTick]
  call  GdipCreatePen1
  add   RSP, 32

  sub   RSP, 32
  mov   ECX, 0xFFC9D1D9
  movss XMM1, [REL fPenWidth7]
  mov   R8D, UnitPixel
  lea   R9, [REL gPenHour]
  call  GdipCreatePen1
  add   RSP, 32

  sub   RSP, 32
  mov   ECX, 0xFF58A6FF
  movss XMM1, [REL fPenWidth3]
  mov   R8D, UnitPixel
  lea   R9, [REL gPenMinute]
  call  GdipCreatePen1
  add   RSP, 32

  sub   RSP, 32
  mov   ECX, 0xFFF85149
  movss XMM1, [REL fPenWidth1]
  mov   R8D, UnitPixel
  lea   R9, [REL gPenSecond]
  call  GdipCreatePen1
  add   RSP, 32

  sub   RSP, 32                                  ; 32 bytes of shadow space
  mov   RCX, qword [hWnd]                        ; [RBP - 8]
  mov   EDX, SW_SHOWNORMAL                       ; Show window on startup
  call  ShowWindow
  add   RSP, 32                                  ; Remove the 32 bytes

 sub   RSP, 32                                  ; 32 bytes of shadow space
 mov   RCX, qword [hWnd]                        ; [RBP - 8]
 call  UpdateWindow
 add   RSP, 32                                  ; Remove the 32 bytes

 ; Start Timer
 sub   RSP, 32 + 16
 mov   RCX, qword [hWnd]
 mov   RDX, TIMER_ID                            ; IDEvent
 mov   R8, TIMER_INTERVAL_MS                    ; Elapse
 mov   R9, NULL
 call  SetTimer
 add   RSP, 48

  ; Zero out the NOTIFYICONDATA structure before use for NIM_ADD
  push  RDI                                    ; Save RDI (non-volatile in Win64 ABI)
  lea   RDI, [nid]                             ; RDI = address of nid
  mov   RCX, 168 / 8                            ; Count = 21 qwords (168 bytes)
  xor   RAX, RAX                               ; RAX = 0
  rep   stosq                                  ; Zero out the structure
  pop   RDI                                    ; Restore RDI

 ; Add Tray Icon
 mov   dword [nid.cbSize], 168                 ; Size of NOTIFYICONDATAA
 mov   RAX, qword [hWnd]                      ; Main window handle from [RBP - 8]
 mov   qword [nid.hWnd], RAX
 mov   dword [nid.uID], 0                     ; Icon ID
 mov   dword [nid.uFlags], NIF_ICON | NIF_MESSAGE | NIF_TIP ; Restore NIF_MESSAGE and NIF_TIP
 mov   dword [nid.uCallbackMessage], WM_TRAYICON_MSG
 mov   RAX, qword [wc.hIconSm]                ; Small icon handle from [RBP - 64]
 mov   qword [nid.hIcon], RAX

  ; Copy ToolTip string (max 127 chars + null terminator)
  push  RDI
  push  RSI
  lea   RDI, [nid.szTip]                       ; RDI = destination address (&nid.szTip)
  lea   RSI, [REL TrayToolTip]                 ; RSI = source address (&TrayToolTip)
  mov   RCX, 127                              ; Max chars to copy (leave room for null)
.CopyToolTipLoop:
  lodsb                                       ; AL = [RSI], RSI++
  stosb                                       ; [RDI] = AL, RDI++
  test  AL, AL                                ; Was it the null terminator?
  jz    .CopyToolTipDone                      ; Yes — string fully copied
  dec   RCX
  jnz   .CopyToolTipLoop                      ; Continue if room remains
  mov   byte [RDI], 0                         ; Force null-terminate on truncation
.CopyToolTipDone:
  pop   RSI
  pop   RDI

 sub   RSP, 32                                  ; Shadow space
 mov   ECX, NIM_ADD
 lea   RDX, [nid]
 call  Shell_NotifyIconA
 test  RAX, RAX                                 ; Check if Shell_NotifyIconA succeeded (RAX != 0)
 jnz   .ShellNotifyAddOK                        ; If not zero (TRUE), it's OK
 ; Shell_NotifyIconA for NIM_ADD failed, exit for debugging
 mov   ECX, 99                                  ; Error code for tray icon add failure
 call  ExitProcess
.ShellNotifyAddOK:
 add   RSP, 32                                  ; Remove shadow space

.MessageLoop:
 sub   RSP, 32                                  ; 32 bytes of shadow space
 lea   RCX, [msg]                               ; [RBP - 56]
 xor   EDX, EDX
 xor   R8D, R8D
 xor   R9D, R9D
 call  GetMessageA
 add   RSP, 32                                  ; Remove the 32 bytes
 cmp   RAX, 0
 je    .Done

 sub   RSP, 32                                  ; 32 bytes of shadow space
 mov   RCX, qword [hWnd]                        ; [RBP - 8]
 lea   RDX, [msg]                               ; [RBP - 56]
 call  IsDialogMessageA                         ; For keyboard strokes
 add   RSP, 32                                  ; Remove the 32 bytes
 cmp   RAX, 0
 jne   .MessageLoop                             ; Skip TranslateMessage and DispatchMessageA

 sub   RSP, 32                                  ; 32 bytes of shadow space
 lea   RCX, [msg]                               ; [RBP - 56]
 call  TranslateMessage
 add   RSP, 32                                  ; Remove the 32 bytes

 sub   RSP, 32                                  ; 32 bytes of shadow space
 lea   RCX, [msg]                               ; [RBP - 56]
 call  DispatchMessageA
 add   RSP, 32                                  ; Remove the 32 bytes
 jmp   .MessageLoop

.Done:
 mov   RSP, RBP                                 ; Remove the stack frame
 pop   RBP
 xor   EAX, EAX
 ret

WndProc:
    push  RBP
    mov   RBP, RSP
    sub   RSP, 384 ; Extended for double-buffer + tray icon locals (24*16, keeps 16-byte alignment)

    ; Stack layout
    %define temp_nid           RBP - 208
    %define temp_nid.cbSize    RBP - 208
    %define temp_nid.hWnd      RBP - 200
    %define temp_nid.uID       RBP - 192
    %define temp_nid.uFlags    RBP - 188
    %define temp_nid.hIcon     RBP - 176
    %define ps                 RBP - 120 ; PAINTSTRUCT (72 bytes)
    %define hdc                RBP - 48  ; HDC (8 bytes)
    %define rect               RBP - 144 ; RECT structure (16 bytes)
    %define rect.left          RBP - 144
    %define rect.top           RBP - 140
    %define rect.right         RBP - 136
    %define rect.bottom        RBP - 132
    %define CenterX            RBP - 148
    %define CenterY            RBP - 152
    %define Radius             RBP - 156
    %define HandX              RBP - 160
    %define HandY              RBP - 164
    %define hGraphics          RBP - 176   ; GpGraphics* (8 bytes)
    %define hGdipPen           RBP - 184   ; GpPen*      (8 bytes)
    %define hGdipBrush         RBP - 216   ; GpBrush*    (8 bytes)
    %define TickX1             RBP - 220   ; outer X
    %define TickY1             RBP - 224   ; outer Y
    %define TickX2             RBP - 228   ; inner X
    %define TickY2             RBP - 232   ; inner Y
    %define TickCount          RBP - 236   ; loop counter
    %define TickInnerR         RBP - 240   ; inner radius for ticks
    %define TickDiv            RBP - 244   ; divisor scratch
    %define hMemDC             RBP - 256   ; memory DC for double-buffering (8 bytes)
    %define hMemBitmap         RBP - 264   ; compatible bitmap (8 bytes)
    %define hOldBitmap         RBP - 272   ; old bitmap to restore (8 bytes)
    %define PenScale           RBP - 280   ; double: pen width scale factor
    %define hMaskBmp           RBP - 288   ; monochrome mask for tray icon creation (8 bytes)
    %define TrayIconInfo       RBP - 320   ; ICONINFO structure (32 bytes)

    ; Save parameters (passed in RCX, RDX, R8, R9)
    mov   qword [RBP + 16], RCX    ; hWnd
    mov   qword [RBP + 24], RDX    ; uMsg
    mov   qword [RBP + 32], R8     ; wParam
    mov   qword [RBP + 40], R9     ; lParam

    ; Message handling
    cmp   RDX, WM_DESTROY
    je    WMDESTROY

    cmp   RDX, WM_PAINT
    je    WMPAINT

    cmp   RDX, WM_ERASEBKGND
    je    WMERASEBKGND

    cmp   RDX, WM_TRAYICON_MSG
    je    WMTRAYICON

    cmp   RDX, WM_COMMAND
    je    WCOMMANDHANDLER

    cmp   RDX, WM_TIMER
    je    WMTIMER

DefaultMessage:
    sub   RSP, 32                  ; 32 bytes of shadow space (for DefWindowProcA)
    mov   RCX, qword [RBP + 16]    ; hWnd
    mov   RDX, qword [RBP + 24]    ; uMsg
    mov   R8, qword [RBP + 32]     ; wParam
    mov   R9, qword [RBP + 40]     ; lParam
    call  DefWindowProcA
    add   RSP, 32                  ; Remove the 32 bytes

    mov   RSP, RBP                 ; Remove the stack frame
    pop   RBP
    ret

WMPAINT:
    ; =========================================================
    ;  BeginPaint
    ; =========================================================
    sub   RSP, 32
    mov   RCX, qword [RBP + 16]
    lea   RDX, [ps]
    call  BeginPaint
    mov   qword [hdc], RAX
    add   RSP, 32

    ; GetClientRect
    sub   RSP, 32
    mov   RCX, qword [RBP + 16]
    lea   RDX, [rect]
    call  GetClientRect
    add   RSP, 32

    ; =========================================================
    ;  Create off-screen double-buffer (memory DC + bitmap)
    ; =========================================================
    mov   qword [hMemDC], 0              ; init to NULL for safe cleanup
    mov   qword [hMemBitmap], 0
    mov   qword [hOldBitmap], 0
    mov   qword [hGraphics], 0

    sub   RSP, 32
    mov   RCX, qword [hdc]              ; source DC
    call  CreateCompatibleDC
    test  RAX, RAX
    jz    .SkipGdipPaint                ; bail on failure
    mov   qword [hMemDC], RAX
    add   RSP, 32

    sub   RSP, 32
    mov   RCX, qword [hdc]
    mov   EDX, dword [rect.right]
    mov   R8D, dword [rect.bottom]
    call  CreateCompatibleBitmap
    test  RAX, RAX
    jz    .SkipGdipPaint                ; bail on failure
    mov   qword [hMemBitmap], RAX
    add   RSP, 32

    sub   RSP, 32
    mov   RCX, qword [hMemDC]
    mov   RDX, qword [hMemBitmap]
    call  SelectObject
    mov   qword [hOldBitmap], RAX        ; save old bitmap for cleanup
    add   RSP, 32

    ; Calculate Center and Radius
    mov   EAX, dword [rect.right]
    shr   EAX, 1
    mov   dword [CenterX], EAX
    mov   EAX, dword [rect.bottom]
    shr   EAX, 1
    mov   dword [CenterY], EAX
    mov   ECX, dword [CenterX]
    cmp   ECX, dword [CenterY]
    cmovg ECX, dword [CenterY]
    sub   ECX, CLOCK_MARGIN         ; margin
    cmp   ECX, 20                   ; minimum usable radius
    jl    .SkipGdipPaint            ; window too small, skip drawing
    mov   dword [Radius], ECX

    ; =========================================================
    ;  Create GDI+ Graphics from MEMORY DC (not screen DC)
    ; =========================================================
    sub   RSP, 32
    mov   RCX, qword [hMemDC]            ; draw to off-screen buffer
    lea   RDX, [hGraphics]
    call  GdipCreateFromHDC
    add   RSP, 32
    test  EAX, EAX                      ; GDI+ Status: 0 = Ok
    jnz   .SkipGdipPaint                ; Skip all GDI+ drawing on failure

    sub   RSP, 32
    mov   RCX, qword [hGraphics]
    mov   RDX, SmoothingAntiAlias
    call  GdipSetSmoothingMode
    add   RSP, 32

    ; =========================================================
    ;  Scale all pen widths to match current Radius
    ;  scale = Radius / 190.0  (reference: default 420×440 window)
    ; =========================================================
    cvtsi2sd XMM0, dword [Radius]
    divsd    XMM0, qword [REL kRefRadius]  ; XMM0 = scale factor
    movsd    qword [PenScale], XMM0        ; save for reuse

    ; --- gPenBorder ---
    movsd  XMM0, qword [REL kBaseWBorder]
    mulsd  XMM0, qword [PenScale]
    cvtsd2ss XMM1, XMM0                    ; GDI+ wants REAL (float)
    sub    RSP, 32
    mov    RCX, qword [REL gPenBorder]
    call   GdipSetPenWidth
    add    RSP, 32

    ; --- gPenMinTick ---
    movsd  XMM0, qword [REL kBaseWMinTick]
    mulsd  XMM0, qword [PenScale]
    cvtsd2ss XMM1, XMM0
    sub    RSP, 32
    mov    RCX, qword [REL gPenMinTick]
    call   GdipSetPenWidth
    add    RSP, 32

    ; --- gPenHourTick ---
    movsd  XMM0, qword [REL kBaseWHourTick]
    mulsd  XMM0, qword [PenScale]
    cvtsd2ss XMM1, XMM0
    sub    RSP, 32
    mov    RCX, qword [REL gPenHourTick]
    call   GdipSetPenWidth
    add    RSP, 32

    ; --- gPenHour (hour hand, 3× base) ---
    movsd  XMM0, qword [REL kBaseWHour]
    mulsd  XMM0, qword [PenScale]
    cvtsd2ss XMM1, XMM0
    sub    RSP, 32
    mov    RCX, qword [REL gPenHour]
    call   GdipSetPenWidth
    add    RSP, 32

    ; --- gPenMinute (minute hand, 3× base) ---
    movsd  XMM0, qword [REL kBaseWMinute]
    mulsd  XMM0, qword [PenScale]
    cvtsd2ss XMM1, XMM0
    sub    RSP, 32
    mov    RCX, qword [REL gPenMinute]
    call   GdipSetPenWidth
    add    RSP, 32

    ; --- gPenSecond (second hand, 3× base) ---
    movsd  XMM0, qword [REL kBaseWSecond]
    mulsd  XMM0, qword [PenScale]
    cvtsd2ss XMM1, XMM0
    sub    RSP, 32
    mov    RCX, qword [REL gPenSecond]
    call   GdipSetPenWidth
    add    RSP, 32

    ; =========================================================
    ;  1. Fill entire background  (dark: 0xFF0D1117)  [cached brush]
    ; =========================================================
    sub   RSP, 48
    mov   RCX, qword [hGraphics]
    mov   RDX, qword [REL gBrushBg]
    xor   R8D, R8D
    xor   R9D, R9D
    mov   EAX, dword [rect.right]
    mov   dword [RSP + 32], EAX
    mov   EAX, dword [rect.bottom]
    mov   dword [RSP + 40], EAX
    call  GdipFillRectangleI
    add   RSP, 48

    ; =========================================================
    ;  2. Fill clock face circle  (0xFF161B22)  [cached brush]
    ; =========================================================
    ; Precompute ellipse bounds (reuse TickX1/Y1/X2 as scratch)
    mov   EAX, dword [CenterX]
    sub   EAX, dword [Radius]
    mov   dword [TickX1], EAX      ; left
    mov   EAX, dword [CenterY]
    sub   EAX, dword [Radius]
    mov   dword [TickY1], EAX      ; top
    mov   EAX, dword [Radius]
    shl   EAX, 1
    mov   dword [TickX2], EAX      ; diameter

    sub   RSP, 48
    mov   RCX, qword [hGraphics]
    mov   RDX, qword [REL gBrushFace]
    mov   R8D, dword [TickX1]
    mov   R9D, dword [TickY1]
    mov   EAX, dword [TickX2]
    mov   dword [RSP + 32], EAX
    mov   dword [RSP + 40], EAX
    call  GdipFillEllipseI
    add   RSP, 48

    ; =========================================================
    ;  3. Draw clock border ring (0xFF30363D, 2px)  [cached pen]
    ; =========================================================
    sub   RSP, 48
    mov   RCX, qword [hGraphics]
    mov   RDX, qword [REL gPenBorder]
    mov   R8D, dword [TickX1]
    mov   R9D, dword [TickY1]
    mov   EAX, dword [TickX2]
    mov   dword [RSP + 32], EAX
    mov   dword [RSP + 40], EAX
    call  GdipDrawEllipseI
    add   RSP, 48

    ; =========================================================
    ;  4. Draw 60 minute tick marks  (dim gray, 1px)  [cached pen]
    ; =========================================================

    ; TickInnerR = Radius * 93 / 100
    mov   EAX, dword [Radius]
    imul  EAX, 93
    mov   ECX, 100
    cdq
    idiv  ECX
    mov   dword [TickInnerR], EAX

    mov   dword [TickCount], 0
.MinuteTickLoop:
    cmp   dword [TickCount], 60
    jge   .MinuteTickDone

    ; --- SSE2 table lookup: sin/cos for tick position ---
    mov   EAX, dword [TickCount]
    shl   EAX, 4                       ; *16 (each entry = 2 doubles)
    lea   RCX, [REL TickSinCos]
    movsd XMM0, qword [RCX + RAX]      ; XMM0 = sin(angle)
    movsd XMM1, qword [RCX + RAX + 8]  ; XMM1 = cos(angle)

    ; OuterX = CenterX + Radius * sin
    cvtsi2sd XMM2, dword [Radius]
    movsd XMM3, XMM0
    mulsd XMM3, XMM2
    cvtsi2sd XMM4, dword [CenterX]
    addsd XMM3, XMM4
    cvttsd2si EAX, XMM3
    mov   dword [TickX1], EAX

    ; OuterY = CenterY - Radius * cos
    movsd XMM3, XMM1
    mulsd XMM3, XMM2
    cvtsi2sd XMM4, dword [CenterY]
    subsd XMM4, XMM3
    cvttsd2si EAX, XMM4
    mov   dword [TickY1], EAX

    ; InnerX = CenterX + TickInnerR * sin
    cvtsi2sd XMM2, dword [TickInnerR]
    movsd XMM3, XMM0
    mulsd XMM3, XMM2
    cvtsi2sd XMM4, dword [CenterX]
    addsd XMM3, XMM4
    cvttsd2si EAX, XMM3
    mov   dword [TickX2], EAX

    ; InnerY = CenterY - TickInnerR * cos
    movsd XMM3, XMM1
    mulsd XMM3, XMM2
    cvtsi2sd XMM4, dword [CenterY]
    subsd XMM4, XMM3
    cvttsd2si EAX, XMM4
    mov   dword [TickY2], EAX

    sub   RSP, 48
    mov   RCX, qword [hGraphics]
    mov   RDX, qword [REL gPenMinTick]
    mov   R8D, dword [TickX1]
    mov   R9D, dword [TickY1]
    mov   EAX, dword [TickX2]
    mov   dword [RSP + 32], EAX
    mov   EAX, dword [TickY2]
    mov   dword [RSP + 40], EAX
    call  GdipDrawLineI
    add   RSP, 48

    inc   dword [TickCount]
    jmp   .MinuteTickLoop
.MinuteTickDone:

    ; =========================================================
    ;  5. Draw 12 hour tick marks  (light, 3px, longer)  [cached pen]
    ; =========================================================

    ; TickInnerR = Radius * 82 / 100
    mov   EAX, dword [Radius]
    imul  EAX, 82
    mov   ECX, 100
    cdq
    idiv  ECX
    mov   dword [TickInnerR], EAX

    mov   dword [TickCount], 0
.HourTickLoop:
    cmp   dword [TickCount], 12
    jge   .HourTickDone

    ; --- SSE2 table lookup: hour ticks at index = TickCount * 5 ---
    mov   EAX, dword [TickCount]
    imul  EAX, 5                       ; hour tick at every 5th minute position
    shl   EAX, 4                       ; *16 bytes per entry
    lea   RCX, [REL TickSinCos]
    movsd XMM0, qword [RCX + RAX]      ; sin
    movsd XMM1, qword [RCX + RAX + 8]  ; cos

    ; OuterX = CenterX + Radius * sin
    cvtsi2sd XMM2, dword [Radius]
    movsd XMM3, XMM0
    mulsd XMM3, XMM2
    cvtsi2sd XMM4, dword [CenterX]
    addsd XMM3, XMM4
    cvttsd2si EAX, XMM3
    mov   dword [TickX1], EAX

    ; OuterY = CenterY - Radius * cos
    movsd XMM3, XMM1
    mulsd XMM3, XMM2
    cvtsi2sd XMM4, dword [CenterY]
    subsd XMM4, XMM3
    cvttsd2si EAX, XMM4
    mov   dword [TickY1], EAX

    ; InnerX = CenterX + TickInnerR * sin
    cvtsi2sd XMM2, dword [TickInnerR]
    movsd XMM3, XMM0
    mulsd XMM3, XMM2
    cvtsi2sd XMM4, dword [CenterX]
    addsd XMM3, XMM4
    cvttsd2si EAX, XMM3
    mov   dword [TickX2], EAX

    ; InnerY = CenterY - TickInnerR * cos
    movsd XMM3, XMM1
    mulsd XMM3, XMM2
    cvtsi2sd XMM4, dword [CenterY]
    subsd XMM4, XMM3
    cvttsd2si EAX, XMM4
    mov   dword [TickY2], EAX

    sub   RSP, 48
    mov   RCX, qword [hGraphics]
    mov   RDX, qword [REL gPenHourTick]
    mov   R8D, dword [TickX1]
    mov   R9D, dword [TickY1]
    mov   EAX, dword [TickX2]
    mov   dword [RSP + 32], EAX
    mov   EAX, dword [TickY2]
    mov   dword [RSP + 40], EAX
    call  GdipDrawLineI
    add   RSP, 48

    inc   dword [TickCount]
    jmp   .HourTickLoop
.HourTickDone:

    ; =========================================================
    ;  Get current time
    ; =========================================================
    sub   RSP, 32
    lea   RCX, [REL SystemTime]
    call  GetLocalTime
    add   RSP, 32

    ; =========================================================
    ;  6. Draw Hour Hand  (7px, off-white 0xFFC9D1D9, 50% radius)  [cached pen]
    ; =========================================================

    ; --- SSE2 hour hand: interpolated table lookup ---
    ; Fractional table index = (hour%12)*5 + minute/12
    movzx EAX, word [REL SystemTime + 8]  ; Hour (0-23)
    xor   EDX, EDX
    mov   ECX, 12
    div   ECX                            ; EDX = hour % 12
    imul  EDX, 5                          ; (hour%12) * 5
    cvtsi2sd XMM0, EDX                    ; XMM0 = base index
    movzx EAX, word [REL SystemTime + 10] ; Minute (0-59)
    cvtsi2sd XMM1, EAX                    ; XMM1 = minute
    mulsd XMM1, qword [REL kOneOverTwelve]; minute / 12
    addsd XMM0, XMM1                      ; fractional index (0.0 .. 59.917)

    ; Floor index and fraction
    cvttsd2si EAX, XMM0                   ; EAX = floor(index)
    cvtsi2sd XMM1, EAX                    ; XMM1 = floor as double
    subsd XMM0, XMM1                      ; XMM0 = frac (0.0 .. 0.999)

    ; Ceil index with wrap-around at 60
    mov   ECX, EAX
    inc   ECX
    cmp   ECX, 60
    jl    .HourNoWrap
    xor   ECX, ECX
.HourNoWrap:

    ; Load table entries for interpolation
    shl   EAX, 4                          ; floor * 16
    lea   RDX, [REL TickSinCos]
    movsd XMM2, qword [RDX + RAX]         ; sin[floor]
    movsd XMM3, qword [RDX + RAX + 8]     ; cos[floor]
    shl   ECX, 4                          ; ceil * 16
    movsd XMM4, qword [RDX + RCX]         ; sin[ceil]
    movsd XMM5, qword [RDX + RCX + 8]     ; cos[ceil]

    ; Linear interpolation: result = floor_val + frac * (ceil_val - floor_val)
    subsd XMM4, XMM2                      ; sin_delta
    mulsd XMM4, XMM0                      ; * frac
    addsd XMM2, XMM4                      ; XMM2 = sin_interp
    subsd XMM5, XMM3                      ; cos_delta
    mulsd XMM5, XMM0                      ; * frac
    addsd XMM3, XMM5                      ; XMM3 = cos_interp
    ; XMM2 = sin(hour_angle), XMM3 = cos(hour_angle)

    ; HandX = CenterX + Radius * ratio * sin
    cvtsi2sd XMM4, dword [Radius]
    mulsd XMM4, qword [REL kHourHandRatio]; Radius * 0.5
    movsd XMM5, XMM4                      ; save scaled radius
    mulsd XMM4, XMM2                      ; * sin
    cvtsi2sd XMM6, dword [CenterX]
    addsd XMM4, XMM6
    cvttsd2si EAX, XMM4
    mov   dword [HandX], EAX

    ; HandY = CenterY - Radius * ratio * cos
    mulsd XMM5, XMM3                      ; scaled_radius * cos
    cvtsi2sd XMM6, dword [CenterY]
    subsd XMM6, XMM5
    cvttsd2si EAX, XMM6
    mov   dword [HandY], EAX

    sub   RSP, 48
    mov   RCX, qword [hGraphics]
    mov   RDX, qword [REL gPenHour]
    mov   R8D, dword [CenterX]
    mov   R9D, dword [CenterY]
    mov   EAX, dword [HandX]
    mov   dword [RSP + 32], EAX
    mov   EAX, dword [HandY]
    mov   dword [RSP + 40], EAX
    call  GdipDrawLineI
    add   RSP, 48

    ; =========================================================
    ;  7. Draw Minute Hand  (3px, blue 0xFF58A6FF, 75% radius)  [cached pen]
    ; =========================================================

    ; --- SSE2 minute hand: direct table lookup by minute index ---
    movzx EAX, word [REL SystemTime + 10] ; Minute (0-59)
    shl   EAX, 4                          ; *16
    lea   RCX, [REL TickSinCos]
    movsd XMM0, qword [RCX + RAX]         ; sin
    movsd XMM1, qword [RCX + RAX + 8]     ; cos

    ; HandX = CenterX + Radius * ratio * sin
    cvtsi2sd XMM2, dword [Radius]
    mulsd XMM2, qword [REL kMinHandRatio] ; Radius * 0.75
    movsd XMM3, XMM2                      ; save scaled radius
    mulsd XMM2, XMM0                      ; * sin
    cvtsi2sd XMM4, dword [CenterX]
    addsd XMM2, XMM4
    cvttsd2si EAX, XMM2
    mov   dword [HandX], EAX

    ; HandY = CenterY - Radius * ratio * cos
    mulsd XMM3, XMM1                      ; scaled_radius * cos
    cvtsi2sd XMM4, dword [CenterY]
    subsd XMM4, XMM3
    cvttsd2si EAX, XMM4
    mov   dword [HandY], EAX

    sub   RSP, 48
    mov   RCX, qword [hGraphics]
    mov   RDX, qword [REL gPenMinute]
    mov   R8D, dword [CenterX]
    mov   R9D, dword [CenterY]
    mov   EAX, dword [HandX]
    mov   dword [RSP + 32], EAX
    mov   EAX, dword [HandY]
    mov   dword [RSP + 40], EAX
    call  GdipDrawLineI
    add   RSP, 48

    ; =========================================================
    ;  8. Draw Second Hand  (1px, red 0xFFF85149, 90% radius)  [cached pen]
    ; =========================================================

    ; --- SSE2 second hand: direct table lookup by second index ---
    movzx EAX, word [REL SystemTime + 12] ; Second (0-59)
    shl   EAX, 4                          ; *16
    lea   RCX, [REL TickSinCos]
    movsd XMM0, qword [RCX + RAX]         ; sin
    movsd XMM1, qword [RCX + RAX + 8]     ; cos

    ; HandX = CenterX + Radius * ratio * sin
    cvtsi2sd XMM2, dword [Radius]
    mulsd XMM2, qword [REL kSecHandRatio] ; Radius * 0.9
    movsd XMM3, XMM2                      ; save scaled radius
    mulsd XMM2, XMM0                      ; * sin
    cvtsi2sd XMM4, dword [CenterX]
    addsd XMM2, XMM4
    cvttsd2si EAX, XMM2
    mov   dword [HandX], EAX

    ; HandY = CenterY - Radius * ratio * cos
    mulsd XMM3, XMM1                      ; scaled_radius * cos
    cvtsi2sd XMM4, dword [CenterY]
    subsd XMM4, XMM3
    cvttsd2si EAX, XMM4
    mov   dword [HandY], EAX

    sub   RSP, 48
    mov   RCX, qword [hGraphics]
    mov   RDX, qword [REL gPenSecond]
    mov   R8D, dword [CenterX]
    mov   R9D, dword [CenterY]
    mov   EAX, dword [HandX]
    mov   dword [RSP + 32], EAX
    mov   EAX, dword [HandY]
    mov   dword [RSP + 40], EAX
    call  GdipDrawLineI
    add   RSP, 48

    ; =========================================================
    ;  9. Draw center dot  (diameter = hour hand width + 3px)  [cached brush]
    ; =========================================================
    ; Compute: diameter = scaledHourWidth + 3, radius = diameter / 2
    movsd  XMM0, qword [REL kBaseWHour]    ; 21.0
    mulsd  XMM0, qword [PenScale]          ; scaled hour hand width
    mov    EAX, 3
    cvtsi2sd XMM1, EAX
    addsd  XMM0, XMM1                      ; + 3
    cvttsd2si ECX, XMM0                    ; ECX = diameter (int)
    mov    EAX, ECX
    shr    EAX, 1                           ; EAX = radius (diameter / 2)
    mov    dword [TickDiv], ECX             ; save diameter
    mov    dword [TickCount], EAX           ; save radius

    sub   RSP, 48
    mov   RCX, qword [hGraphics]
    mov   RDX, qword [REL gBrushCenter]
    mov   R8D, dword [CenterX]
    sub   R8D, dword [TickCount]
    mov   R9D, dword [CenterY]
    sub   R9D, dword [TickCount]
    mov   EAX, dword [TickDiv]
    mov   dword [RSP + 32], EAX
    mov   dword [RSP + 40], EAX
    call  GdipFillEllipseI
    add   RSP, 48

    ; =========================================================
    ;  Cleanup GDI+ Graphics, then EndPaint
    ; =========================================================
.SkipGdipPaint:
    ; Entered here on success (after drawing) or on GDI+ init failure
    mov   RCX, qword [hGraphics]
    test  RCX, RCX
    jz    .SkipGdipDelete
    sub   RSP, 32
    call  GdipDeleteGraphics
    add   RSP, 32
.SkipGdipDelete:

    ; =========================================================
    ;  BitBlt: copy finished off-screen buffer to screen DC
    ; =========================================================
    mov   RCX, qword [hMemDC]
    test  RCX, RCX
    jz    .SkipBlit                       ; no memory DC, skip blit
    sub   RSP, 80                        ; 9 args: 4 in regs + 5 on stack
    mov   RCX, qword [hdc]              ; dest DC (screen)
    xor   EDX, EDX                       ; destX = 0
    xor   R8D, R8D                       ; destY = 0
    mov   R9D, dword [rect.right]        ; width
    mov   EAX, dword [rect.bottom]
    mov   dword [RSP + 32], EAX          ; height
    mov   RAX, qword [hMemDC]
    mov   qword [RSP + 40], RAX          ; source DC
    mov   dword [RSP + 48], 0            ; srcX = 0
    mov   dword [RSP + 56], 0            ; srcY = 0
    mov   dword [RSP + 64], SRCCOPY      ; raster op
    call  BitBlt
    add   RSP, 80
.SkipBlit:

    ; =========================================================
    ;  Cleanup: restore old bitmap, delete memory bitmap & DC
    ;  (null-safe: each handle is checked before use)
    ; =========================================================
    mov   RCX, qword [hOldBitmap]
    test  RCX, RCX
    jz    .SkipRestoreBmp
    sub   RSP, 32
    mov   RCX, qword [hMemDC]
    mov   RDX, qword [hOldBitmap]
    call  SelectObject
    add   RSP, 32
.SkipRestoreBmp:

    mov   RCX, qword [hMemBitmap]
    test  RCX, RCX
    jz    .SkipDeleteBmp
    sub   RSP, 32
    call  DeleteObject
    add   RSP, 32
.SkipDeleteBmp:

    mov   RCX, qword [hMemDC]
    test  RCX, RCX
    jz    .SkipDeleteMemDC
    sub   RSP, 32
    call  DeleteObject
    add   RSP, 32
.SkipDeleteMemDC:

    sub   RSP, 32
    mov   RCX, qword [RBP + 16]
    lea   RDX, [ps]
    call  EndPaint
    add   RSP, 32

    xor   EAX, EAX                 ; Return 0
    mov   RSP, RBP
    pop   RBP
    ret

WMTRAYICON:                        ; Handler for our tray icon message
    mov   RAX, qword [RBP + 40]    ; RAX = mouse message (lParam)
    cmp   RAX, WM_LBUTTONDBLCLK
    je    .TrayDblClick
    cmp   RAX, WM_RBUTTONDOWN
    je    .TrayRightClick
    jmp   .TrayUnhandled

.TrayDblClick:
    ; Toggle visibility: if visible → hide, if hidden → show + foreground
    sub   RSP, 32
    mov   RCX, qword [RBP + 16]    ; hWnd
    call  IsWindowVisible
    add   RSP, 32
    test  RAX, RAX
    jz    .TrayShow                 ; not visible → show it
    ; Visible → hide it
    sub   RSP, 32
    mov   RCX, qword [RBP + 16]
    mov   EDX, SW_HIDE
    call  ShowWindow
    add   RSP, 32
    jmp   .TrayHandled
.TrayShow:
    sub   RSP, 32
    mov   RCX, qword [RBP + 16]
    mov   EDX, SW_SHOWNORMAL
    call  ShowWindow
    add   RSP, 32
    sub   RSP, 32
    mov   RCX, qword [RBP + 16]
    call  SetForegroundWindow
    add   RSP, 32
    jmp   .TrayHandled

.TrayRightClick:
    sub   RSP, 32                      ; Shadow space for GetCursorPos
    lea   RCX, [REL pt]                ; RCX = address of POINT structure
    call  GetCursorPos
    add   RSP, 32                      ; Clean up shadow space

    sub   RSP, 32                      ; Shadow space for SetForegroundWindow
    mov   RCX, qword [RBP + 16]        ; RCX = hWnd
    call  SetForegroundWindow
    add   RSP, 32

    mov   RCX, qword [REL hMenu]
    test  RCX, RCX
    jz    .TrayHandled                 ; Exit if menu handle is null

    sub   RSP, 32                      ; Reserve shadow space for GetSubMenu
    mov   EDX, 0                       ; EDX = uIndex of the submenu
    call  GetSubMenu                   ; Returns submenu handle in RAX
    add   RSP, 32                      ; Clean up shadow space

    test  RAX, RAX
    jz    .TrayHandled                 ; Exit if it failed

    mov   RCX, RAX                     ; RCX = hSubMenu
    mov   EDX, TPM_LEFTALIGN | TPM_RIGHTBUTTON ; RDX = Flags
    mov   R8D, dword [REL pt]          ; R8D = pt.x
    mov   R9D, dword [REL pt + 4]      ; R9D = pt.y
    
    sub   RSP, 48                      ; 32 shadow + 16 for two 8-byte params
    mov   RAX, qword [RBP + 16]        ; Load hWnd into RAX first
    mov   qword [RSP + 32], RAX        ; Param 5: HWND to post messages to
    mov   qword [RSP + 40], NULL       ; Param 6: Reserved, must be NULL
    call  TrackPopupMenuEx
    add   RSP, 48                      ; Clean up stack

    jmp   .TrayHandled

.TrayUnhandled:
.TrayHandled:
    xor   EAX, EAX                 ; Return 0, indicating message was handled
    mov   RSP, RBP
    pop   RBP
    ret

WCOMMANDHANDLER:
    mov   RAX, qword [RBP + 32]    ; RAX = wParam
    movzx EAX, AX                  ; EAX = LOWORD(wParam) = Menu Item ID

    cmp   EAX, IDM_SHOW
    je    .MenuShow
    cmp   EAX, IDM_EXIT
    je    .MenuExit
    jmp   .MenuUnhandled

.MenuShow:
    sub   RSP, 32                  ; Shadow space
    mov   RCX, qword [RBP + 16]    ; hWnd
    call  IsWindowVisible
    add   RSP, 32
    test  RAX, RAX
    jnz   .MenuShowBringToFront
    sub   RSP, 32                  ; Shadow space
    mov   RCX, qword [RBP + 16]    ; hWnd
    mov   EDX, SW_SHOWNORMAL
    call  ShowWindow
    add   RSP, 32
.MenuShowBringToFront:
    sub   RSP, 32                  ; Shadow space
    mov   RCX, qword [RBP + 16]    ; hWnd
    call  SetForegroundWindow
    add   RSP, 32
    jmp   .MenuHandled

.MenuExit:
    sub   RSP, 32                  ; Shadow space for PostQuitMessage
    xor   ECX, ECX                 ; ECX = nExitCode (0)
    call  PostQuitMessage
    add   RSP, 32
    jmp   .MenuHandled

.MenuUnhandled:
.MenuHandled:
    xor   EAX, EAX                 ; Return 0, indicating message was handled
    mov   RSP, RBP
    pop   RBP
    ret

WMTIMER:
    ; =========================================================
    ;  Animated tray icon: render a mini analog clock into a
    ;  16×16 bitmap, convert to icon, and update the system
    ;  tray via NIM_MODIFY every second.
    ; =========================================================

    ; Initialize handles to NULL for safe cleanup on failure
    mov   qword [hdc], 0
    mov   qword [hMemDC], 0
    mov   qword [hMemBitmap], 0
    mov   qword [hOldBitmap], 0
    mov   qword [hGraphics], 0
    mov   qword [hMaskBmp], 0

    ; 1. Get current system time
    sub   RSP, 32
    lea   RCX, [REL SystemTime]
    call  GetLocalTime
    add   RSP, 32

    ; 2. Obtain screen DC for bitmap compatibility
    sub   RSP, 32
    xor   ECX, ECX                          ; NULL = entire screen
    call  GetDC
    test  RAX, RAX
    jz    .TrayDone
    mov   qword [hdc], RAX
    add   RSP, 32

    ; 3. Create memory DC
    sub   RSP, 32
    mov   RCX, qword [hdc]
    call  CreateCompatibleDC
    test  RAX, RAX
    jz    .TrayCleanup
    mov   qword [hMemDC], RAX
    add   RSP, 32

    ; 4. Create 16×16 color bitmap
    sub   RSP, 32
    mov   RCX, qword [hdc]
    mov   EDX, TRAY_ICON_SIZE
    mov   R8D, TRAY_ICON_SIZE
    call  CreateCompatibleBitmap
    test  RAX, RAX
    jz    .TrayCleanup
    mov   qword [hMemBitmap], RAX
    add   RSP, 32

    ; 5. Select bitmap into memory DC
    sub   RSP, 32
    mov   RCX, qword [hMemDC]
    mov   RDX, qword [hMemBitmap]
    call  SelectObject
    mov   qword [hOldBitmap], RAX
    add   RSP, 32

    ; 6. Create GDI+ graphics from memory DC
    sub   RSP, 32
    mov   RCX, qword [hMemDC]
    lea   RDX, [hGraphics]
    call  GdipCreateFromHDC
    test  EAX, EAX
    jnz   .TrayCleanup
    add   RSP, 32

    ; 7. Enable anti-aliasing
    sub   RSP, 32
    mov   RCX, qword [hGraphics]
    mov   RDX, SmoothingAntiAlias
    call  GdipSetSmoothingMode
    add   RSP, 32

    ; ---- Draw the mini clock ----

    ; 8. Fill background  (0xFF0D1117)
    sub   RSP, 48
    mov   RCX, qword [hGraphics]
    mov   RDX, qword [REL gBrushBg]
    xor   R8D, R8D
    xor   R9D, R9D
    mov   dword [RSP + 32], TRAY_ICON_SIZE
    mov   dword [RSP + 40], TRAY_ICON_SIZE
    call  GdipFillRectangleI
    add   RSP, 48

    ; 9. Fill clock face circle  (0xFF161B22)
    sub   RSP, 48
    mov   RCX, qword [hGraphics]
    mov   RDX, qword [REL gBrushFace]
    mov   R8D, TRAY_FACE_ORIGIN
    mov   R9D, TRAY_FACE_ORIGIN
    mov   dword [RSP + 32], TRAY_FACE_DIAM
    mov   dword [RSP + 40], TRAY_FACE_DIAM
    call  GdipFillEllipseI
    add   RSP, 48

    ; 10. Draw border ring  (1px)
    sub   RSP, 32
    mov   RCX, qword [REL gPenBorder]
    movss XMM1, [REL fPenWidth1]
    call  GdipSetPenWidth
    add   RSP, 32

    sub   RSP, 48
    mov   RCX, qword [hGraphics]
    mov   RDX, qword [REL gPenBorder]
    mov   R8D, TRAY_FACE_ORIGIN
    mov   R9D, TRAY_FACE_ORIGIN
    mov   dword [RSP + 32], TRAY_FACE_DIAM
    mov   dword [RSP + 40], TRAY_FACE_DIAM
    call  GdipDrawEllipseI
    add   RSP, 48

    ; Set up center for hand calculations
    mov   dword [CenterX], TRAY_CENTER
    mov   dword [CenterY], TRAY_CENTER

    ; ---- 11. Hour hand (length 3px, pen 2px) ----
    ; Fractional index = (hour%12)*5 + minute/12
    movzx EAX, word [REL SystemTime + 8]    ; wHour
    xor   EDX, EDX
    mov   ECX, 12
    div   ECX                                ; EDX = hour % 12
    imul  EDX, 5
    cvtsi2sd XMM0, EDX
    movzx EAX, word [REL SystemTime + 10]   ; wMinute
    cvtsi2sd XMM1, EAX
    mulsd XMM1, qword [REL kOneOverTwelve]
    addsd XMM0, XMM1                        ; fractional table index

    ; Floor and fraction
    cvttsd2si EAX, XMM0
    cvtsi2sd XMM1, EAX
    subsd XMM0, XMM1                        ; XMM0 = frac

    ; Ceil index (wrap at 60)
    mov   ECX, EAX
    inc   ECX
    cmp   ECX, 60
    jl    .TrayHourNoWrap
    xor   ECX, ECX
.TrayHourNoWrap:

    ; Interpolate sin/cos from lookup table
    shl   EAX, 4
    lea   RDX, [REL TickSinCos]
    movsd XMM2, qword [RDX + RAX]          ; sin[floor]
    movsd XMM3, qword [RDX + RAX + 8]      ; cos[floor]
    shl   ECX, 4
    movsd XMM4, qword [RDX + RCX]          ; sin[ceil]
    movsd XMM5, qword [RDX + RCX + 8]      ; cos[ceil]

    subsd XMM4, XMM2
    mulsd XMM4, XMM0
    addsd XMM2, XMM4                       ; XMM2 = sin(hour_angle)
    subsd XMM5, XMM3
    mulsd XMM5, XMM0
    addsd XMM3, XMM5                       ; XMM3 = cos(hour_angle)

    ; HandX = CenterX + TRAY_HAND_HOUR_LEN * sin
    mov   EAX, TRAY_HAND_HOUR_LEN
    cvtsi2sd XMM4, EAX
    movsd XMM5, XMM4
    mulsd XMM4, XMM2
    cvtsi2sd XMM6, dword [CenterX]
    addsd XMM4, XMM6
    cvttsd2si EAX, XMM4
    mov   dword [HandX], EAX

    ; HandY = CenterY - TRAY_HAND_HOUR_LEN * cos
    mulsd XMM5, XMM3
    cvtsi2sd XMM6, dword [CenterY]
    subsd XMM6, XMM5
    cvttsd2si EAX, XMM6
    mov   dword [HandY], EAX

    ; Set hour pen width for tray (2px)
    sub   RSP, 32
    mov   RCX, qword [REL gPenHour]
    movss XMM1, [REL fPenWidth2]
    call  GdipSetPenWidth
    add   RSP, 32

    ; Draw hour hand
    sub   RSP, 48
    mov   RCX, qword [hGraphics]
    mov   RDX, qword [REL gPenHour]
    mov   R8D, TRAY_CENTER
    mov   R9D, TRAY_CENTER
    mov   EAX, dword [HandX]
    mov   dword [RSP + 32], EAX
    mov   EAX, dword [HandY]
    mov   dword [RSP + 40], EAX
    call  GdipDrawLineI
    add   RSP, 48

    ; ---- 12. Minute hand (length 5px, pen 1px) ----
    movzx EAX, word [REL SystemTime + 10]   ; wMinute
    shl   EAX, 4
    lea   RCX, [REL TickSinCos]
    movsd XMM0, qword [RCX + RAX]          ; sin
    movsd XMM1, qword [RCX + RAX + 8]      ; cos

    mov   EAX, TRAY_HAND_MIN_LEN
    cvtsi2sd XMM2, EAX
    movsd XMM3, XMM2
    mulsd XMM2, XMM0
    cvtsi2sd XMM4, dword [CenterX]
    addsd XMM2, XMM4
    cvttsd2si EAX, XMM2
    mov   dword [HandX], EAX

    mulsd XMM3, XMM1
    cvtsi2sd XMM4, dword [CenterY]
    subsd XMM4, XMM3
    cvttsd2si EAX, XMM4
    mov   dword [HandY], EAX

    ; Set minute pen width for tray (1px)
    sub   RSP, 32
    mov   RCX, qword [REL gPenMinute]
    movss XMM1, [REL fPenWidth1]
    call  GdipSetPenWidth
    add   RSP, 32

    ; Draw minute hand
    sub   RSP, 48
    mov   RCX, qword [hGraphics]
    mov   RDX, qword [REL gPenMinute]
    mov   R8D, TRAY_CENTER
    mov   R9D, TRAY_CENTER
    mov   EAX, dword [HandX]
    mov   dword [RSP + 32], EAX
    mov   EAX, dword [HandY]
    mov   dword [RSP + 40], EAX
    call  GdipDrawLineI
    add   RSP, 48

    ; ---- 13. Second hand (length 6px, pen 1px) ----
    movzx EAX, word [REL SystemTime + 12]   ; wSecond
    shl   EAX, 4
    lea   RCX, [REL TickSinCos]
    movsd XMM0, qword [RCX + RAX]          ; sin
    movsd XMM1, qword [RCX + RAX + 8]      ; cos

    mov   EAX, TRAY_HAND_SEC_LEN
    cvtsi2sd XMM2, EAX
    movsd XMM3, XMM2
    mulsd XMM2, XMM0
    cvtsi2sd XMM4, dword [CenterX]
    addsd XMM2, XMM4
    cvttsd2si EAX, XMM2
    mov   dword [HandX], EAX

    mulsd XMM3, XMM1
    cvtsi2sd XMM4, dword [CenterY]
    subsd XMM4, XMM3
    cvttsd2si EAX, XMM4
    mov   dword [HandY], EAX

    ; Set second pen width for tray (1px)
    sub   RSP, 32
    mov   RCX, qword [REL gPenSecond]
    movss XMM1, [REL fPenWidth1]
    call  GdipSetPenWidth
    add   RSP, 32

    ; Draw second hand
    sub   RSP, 48
    mov   RCX, qword [hGraphics]
    mov   RDX, qword [REL gPenSecond]
    mov   R8D, TRAY_CENTER
    mov   R9D, TRAY_CENTER
    mov   EAX, dword [HandX]
    mov   dword [RSP + 32], EAX
    mov   EAX, dword [HandY]
    mov   dword [RSP + 40], EAX
    call  GdipDrawLineI
    add   RSP, 48

    ; ---- 14. Convert bitmap to icon ----

    ; Delete GDI+ graphics (must release before bitmap extraction)
    sub   RSP, 32
    mov   RCX, qword [hGraphics]
    call  GdipDeleteGraphics
    add   RSP, 32
    mov   qword [hGraphics], 0

    ; Deselect bitmap from memory DC
    sub   RSP, 32
    mov   RCX, qword [hMemDC]
    mov   RDX, qword [hOldBitmap]
    call  SelectObject
    add   RSP, 32
    mov   qword [hOldBitmap], 0

    ; Create monochrome mask bitmap (all zeros = fully opaque)
    sub   RSP, 48
    mov   ECX, TRAY_ICON_SIZE
    mov   EDX, TRAY_ICON_SIZE
    mov   R8D, 1                            ; planes
    mov   R9D, 1                            ; bits per pixel
    lea   RAX, [REL TrayMaskBits]
    mov   qword [RSP + 32], RAX            ; lpBits → all zeros
    call  CreateBitmap
    test  RAX, RAX
    jz    .TrayCleanup
    mov   qword [hMaskBmp], RAX
    add   RSP, 48

    ; Fill ICONINFO structure on stack
    lea   RCX, [TrayIconInfo]
    mov   dword [RCX], 1                    ; fIcon = TRUE
    mov   dword [RCX + 4], 0               ; xHotspot
    mov   dword [RCX + 8], 0               ; yHotspot
    mov   dword [RCX + 12], 0              ; padding
    mov   RAX, qword [hMaskBmp]
    mov   qword [RCX + 16], RAX            ; hbmMask
    mov   RAX, qword [hMemBitmap]
    mov   qword [RCX + 24], RAX            ; hbmColor

    ; CreateIconIndirect
    sub   RSP, 32
    lea   RCX, [TrayIconInfo]
    call  CreateIconIndirect
    test  RAX, RAX
    jz    .TrayCleanup
    add   RSP, 32

    ; Save new icon handle temporarily (hGdipBrush slot is safe from nid zeroing)
    mov   qword [hGdipBrush], RAX

    ; ---- 15. Update tray icon via NIM_MODIFY ----
    ; Zero temp_nid area (48 bytes covering all fields through hIcon)
    xor   EAX, EAX
    mov   qword [RBP - 208], RAX           ; cbSize + pad
    mov   qword [RBP - 200], RAX           ; hWnd
    mov   qword [RBP - 192], RAX           ; uID + uFlags
    mov   qword [RBP - 184], RAX           ; uCallbackMessage + pad
    mov   qword [RBP - 176], RAX           ; hIcon
    mov   qword [RBP - 168], RAX           ; szTip[0:7]

    ; Fill required fields
    mov   dword [temp_nid.cbSize], 168
    mov   RAX, qword [RBP + 16]            ; hWnd (WndProc argument)
    mov   qword [temp_nid.hWnd], RAX
    mov   dword [temp_nid.uID], 0
    mov   dword [temp_nid.uFlags], NIF_ICON
    mov   RAX, qword [hGdipBrush]          ; retrieve hNewIcon
    mov   qword [temp_nid.hIcon], RAX

    sub   RSP, 32
    mov   ECX, NIM_MODIFY
    lea   RDX, [temp_nid]
    call  Shell_NotifyIconA
    add   RSP, 32

    ; Destroy previous dynamic tray icon (if any)
    mov   RCX, qword [REL hDynTrayIcon]
    test  RCX, RCX
    jz    .TrayNoOldIcon
    sub   RSP, 32
    call  DestroyIcon
    add   RSP, 32
.TrayNoOldIcon:

    ; Store new icon as current dynamic tray icon
    mov   RAX, qword [hGdipBrush]          ; hNewIcon
    mov   qword [REL hDynTrayIcon], RAX

    ; IMPORTANT: temp_nid.hIcon and hGraphics share [RBP-176].
    ; The icon handle written to temp_nid.hIcon above has overwritten
    ; hGraphics with a non-zero value.  Clear it so the cleanup below
    ; does not call GdipDeleteGraphics on an HICON.
    mov   qword [hGraphics], 0

    ; ---- 16. Cleanup all GDI resources ----
.TrayCleanup:
    ; Delete GDI+ graphics (if still alive)
    mov   RCX, qword [hGraphics]
    test  RCX, RCX
    jz    .TraySkipGfx
    sub   RSP, 32
    call  GdipDeleteGraphics
    add   RSP, 32
.TraySkipGfx:

    ; Restore old bitmap in memory DC
    mov   RCX, qword [hOldBitmap]
    test  RCX, RCX
    jz    .TraySkipRestore
    sub   RSP, 32
    mov   RCX, qword [hMemDC]
    mov   RDX, qword [hOldBitmap]
    call  SelectObject
    add   RSP, 32
.TraySkipRestore:

    ; Delete mask bitmap
    mov   RCX, qword [hMaskBmp]
    test  RCX, RCX
    jz    .TraySkipMask
    sub   RSP, 32
    call  DeleteObject
    add   RSP, 32
.TraySkipMask:

    ; Delete color bitmap
    mov   RCX, qword [hMemBitmap]
    test  RCX, RCX
    jz    .TraySkipBmp
    sub   RSP, 32
    call  DeleteObject
    add   RSP, 32
.TraySkipBmp:

    ; Delete memory DC (use DeleteDC, not DeleteObject)
    mov   RCX, qword [hMemDC]
    test  RCX, RCX
    jz    .TraySkipDC
    sub   RSP, 32
    call  DeleteDC
    add   RSP, 32
.TraySkipDC:

    ; Release screen DC
    mov   RCX, qword [hdc]
    test  RCX, RCX
    jz    .TraySkipScreen
    sub   RSP, 32
    xor   ECX, ECX                          ; hWnd = NULL
    mov   RDX, qword [hdc]
    call  ReleaseDC
    add   RSP, 32
.TraySkipScreen:

.TrayDone:
    ; Invalidate main window for clock repaint
    sub   RSP, 32
    mov   RCX, qword [RBP + 16]            ; hWnd
    mov   RDX, NULL
    mov   R8, 0                             ; FALSE — no erase
    call  InvalidateRect
    add   RSP, 32

    xor   EAX, EAX
    mov   RSP, RBP
    pop   RBP
    ret

WMERASEBKGND:
    mov   EAX, 1                 ; Return 1 — tell Windows we handled the erase
    mov   RSP, RBP
    pop   RBP
    ret

WMDESTROY:
    ; Delete cached GDI+ pens
    sub   RSP, 32
    mov   RCX, qword [REL gPenBorder]
    call  GdipDeletePen
    add   RSP, 32
    sub   RSP, 32
    mov   RCX, qword [REL gPenMinTick]
    call  GdipDeletePen
    add   RSP, 32
    sub   RSP, 32
    mov   RCX, qword [REL gPenHourTick]
    call  GdipDeletePen
    add   RSP, 32
    sub   RSP, 32
    mov   RCX, qword [REL gPenHour]
    call  GdipDeletePen
    add   RSP, 32
    sub   RSP, 32
    mov   RCX, qword [REL gPenMinute]
    call  GdipDeletePen
    add   RSP, 32
    sub   RSP, 32
    mov   RCX, qword [REL gPenSecond]
    call  GdipDeletePen
    add   RSP, 32

    ; Delete cached GDI+ brushes
    sub   RSP, 32
    mov   RCX, qword [REL gBrushBg]
    call  GdipDeleteBrush
    add   RSP, 32
    sub   RSP, 32
    mov   RCX, qword [REL gBrushFace]
    call  GdipDeleteBrush
    add   RSP, 32
    sub   RSP, 32
    mov   RCX, qword [REL gBrushCenter]
    call  GdipDeleteBrush
    add   RSP, 32

    ; Shutdown GDI+
    sub   RSP, 32
    mov   RCX, qword [REL gdiplusToken]
    call  GdiplusShutdown
    add   RSP, 32

    ; Delete background brush
    mov   RCX, qword [REL hBgBrush]
    test  RCX, RCX
    jz    .SkipDeleteBrush
    sub   RSP, 32
    call  DeleteObject
    add   RSP, 32
.SkipDeleteBrush:

    mov   RCX, qword [REL hMenu]
    test  RCX, RCX
    jz    .SkipDestroyMenu
    sub   RSP, 32                  ; Shadow space for DestroyMenu
    call  DestroyMenu
    add   RSP, 32
.SkipDestroyMenu:

    ; Destroy dynamically created tray icon
    mov   RCX, qword [REL hDynTrayIcon]
    test  RCX, RCX
    jz    .SkipDestroyDynIcon
    sub   RSP, 32
    call  DestroyIcon
    add   RSP, 32
.SkipDestroyDynIcon:

    mov   dword [temp_nid.cbSize], 168
    mov   RAX, qword [RBP + 16]        ; hWnd from WndProc's argument
    mov   qword [temp_nid.hWnd], RAX
    mov   dword [temp_nid.uID], 0      ; Icon ID we used

    sub   RSP, 32                      ; Shadow space for Shell_NotifyIconA
    mov   ECX, NIM_DELETE
    lea   RDX, [temp_nid]
    call  Shell_NotifyIconA
    add   RSP, 32                      ; Remove shadow space

    sub   RSP, 32                      ; 32 bytes of shadow space
    xor   ECX, ECX
    call  PostQuitMessage
    add   RSP, 32                      ; Remove the 32 bytes

    xor   EAX, EAX                 ; Return 0
    mov   RSP, RBP
    pop   RBP
    ret