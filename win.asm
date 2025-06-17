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
NULL                EQU 0
SW_SHOWNORMAL       EQU 1
WM_DESTROY          EQU 2
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
WM_RBUTTONDOWN      EQU 0204h
WM_COMMAND          EQU 0111h                     ; Message for menu clicks
IDR_MYMENU          EQU 101                       ; Menu resource ID (example)
IDM_SHOW            EQU 102                       ; Menu item ID: Show (example)
IDM_EXIT            EQU 103                       ; Menu item ID: Exit (example)
TPM_LEFTALIGN       EQU 0
TPM_RIGHTBUTTON     EQU 2
TPM_RETURNCMD       EQU 100h

WindowWidth         EQU 640
WindowHeight        EQU 480

extern CreateWindowExA                          ; Import external symbols
extern DefWindowProcA                           ; Windows API functions, not decorated
extern DispatchMessageA
extern ExitProcess
extern GetMessageA
extern GetModuleHandleA
extern IsDialogMessageA
extern LoadImageA
extern PostQuitMessage
extern PostMessageA
extern RegisterClassExA
extern ShowWindow
extern TranslateMessage
extern UpdateWindow
extern BeginPaint
extern EndPaint
extern Ellipse
extern Shell_NotifyIconA
extern LoadMenuA
extern GetSubMenu
extern TrackPopupMenuEx
extern TrackPopupMenu
extern SetForegroundWindow
extern GetCursorPos
extern DestroyMenu
extern IsWindowVisible

global Start                                    ; Export symbols. The entry point

section .data                                   ; Initialized data segment
 WindowName  db "Basic Window 64", 0
 ClassName   db "Window", 0
 TrayToolTip db "My Tray Application", 0
 PAINTSTRUCT_SIZE EQU 72

section .bss                                    ; Uninitialized data segment
 alignb 8
 hInstance resq 1
 hMenu     resq 1                               ; Handle for the loaded menu
 pt        resq 1                               ; POINT structure for GetCursorPos (x, y as LONGs)

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

 sub   RSP, 32                                  ; 32 bytes of shadow space for the original GetModuleHandleA call
 xor   ECX, ECX
 call  GetModuleHandleA
 mov   qword [REL hInstance], RAX               ; This GetModuleHandle is actually for WNDCLASSEX.hInstance, ensure it's correct.
 add   RSP, 32                                  ; Remove the 32 bytes

 call  WinMain

ExitWinMain:             ; Define the exit label here
 xor   ECX, ECX
 call  ExitProcess

WinMain:
 push  RBP                                      ; Set up a stack frame
 mov   RBP, RSP
 sub   RSP, 304                                 ; 168 (nid) + 80 (wc) + 48 (msg) + 8 (hWnd) = 304 bytes.
                                                ; 304 is divisible by 16 (0x130) ensuring RSP alignment.

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

 mov   dword [wc.cbSize], 80                    ; [RBP - 136]
 mov   dword [wc.style], CS_HREDRAW | CS_VREDRAW | CS_BYTEALIGNWINDOW  ; [RBP - 132]
 lea   RAX, [REL WndProc]
 mov   qword [wc.lpfnWndProc], RAX              ; [RBP - 128]
 mov   dword [wc.cbClsExtra], NULL              ; [RBP - 120]
 mov   dword [wc.cbWndExtra], NULL              ; [RBP - 116]
 mov   RAX, qword [REL hInstance]               ; Global
 mov   qword [wc.hInstance], RAX                ; [RBP - 112]

 sub   RSP, 32 + 16                             ; Shadow space + 2 parameters
 xor   ECX, ECX
 mov   EDX, IDI_APPLICATION
 mov   R8D, IMAGE_ICON
 xor   R9D, R9D
 mov   qword [RSP + 4 * 8], NULL
 mov   qword [RSP + 5 * 8], LR_SHARED
 call  LoadImageA                               ; Large program icon
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

 mov   qword [wc.hbrBackground], COLOR_WINDOW + 1  ; [RBP - 88]
 mov   qword [wc.lpszMenuName], NULL            ; [RBP - 80]
 lea   RAX, [REL ClassName]
 mov   qword [wc.lpszClassName], RAX            ; [RBP - 72]

 sub   RSP, 32 + 16                             ; Shadow space + 2 parameters
 xor   ECX, ECX
 mov   EDX, IDI_APPLICATION
 mov   R8D, IMAGE_ICON
 xor   R9D, R9D
 mov   qword [RSP + 4 * 8], NULL
 mov   qword [RSP + 5 * 8], LR_SHARED
 call  LoadImageA                               ; Small program icon
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
 jz    ExitWinMain                                ; Exit if failed
 add   RSP, 32                                  ; Remove the 32 bytes

 sub   RSP, 32 + 64                             ; Shadow space + 8 parameters
 mov   ECX, WS_EX_COMPOSITED
 lea   RDX, [REL ClassName]                     ; Global
 lea   R8, [REL WindowName]                     ; Global
 mov   R9D, WS_OVERLAPPEDWINDOW
 mov   dword [RSP + 4 * 8], CW_USEDEFAULT
 mov   dword [RSP + 5 * 8], CW_USEDEFAULT
 mov   dword [RSP + 6 * 8], WindowWidth
 mov   dword [RSP + 7 * 8], WindowHeight
 mov   qword [RSP + 8 * 8], NULL
 mov   qword [RSP + 9 * 8], NULL
 mov   RAX, qword [REL hInstance]               ; Global
 mov   qword [RSP + 10 * 8], RAX
 mov   qword [RSP + 11 * 8], NULL
 call  CreateWindowExA
 test  RAX, RAX                                 ; Check if window creation failed
 jz    ExitWinMain                                ; Exit if failed
 mov   qword [hWnd], RAX                        ; [RBP - 8]
 add   RSP, 96                                  ; Remove the 96 bytes

 sub   RSP, 32                                  ; 32 bytes of shadow space
 mov   RCX, qword [hWnd]                        ; [RBP - 8]
 mov   EDX, SW_SHOWNORMAL
 call  ShowWindow
 add   RSP, 32                                  ; Remove the 32 bytes

 sub   RSP, 32                                  ; 32 bytes of shadow space
 mov   RCX, qword [hWnd]                        ; [RBP - 8]
 call  UpdateWindow
 add   RSP, 32                                  ; Remove the 32 bytes

 ; Zero out the NOTIFYICONDATA structure before use for NIM_ADD
 lea   RDI, [nid]                             ; RDI = address of nid
 mov   RCX, 168 / 8                            ; Count = 21 qwords (168 bytes)
 xor   RAX, RAX                               ; RAX = 0
 rep   stosq                                  ; Zero out the structure

 ; Add Tray Icon
 mov   dword [nid.cbSize], 168                 ; Size of NOTIFYICONDATAA
 mov   RAX, qword [hWnd]                      ; Main window handle from [RBP - 8]
 mov   qword [nid.hWnd], RAX
 mov   dword [nid.uID], 0                     ; Icon ID
 mov   dword [nid.uFlags], NIF_ICON | NIF_MESSAGE | NIF_TIP ; Restore NIF_MESSAGE and NIF_TIP
 mov   dword [nid.uCallbackMessage], WM_TRAYICON_MSG
 mov   RAX, qword [wc.hIconSm]                ; Small icon handle from [RBP - 64]
 mov   qword [nid.hIcon], RAX

 ; Copy ToolTip string
 lea   RDI, [nid.szTip]                       ; RDI = destination address (&nid.szTip)
 lea   RSI, [REL TrayToolTip]                 ; RSI = source address (&TrayToolTip)
 mov   RCX, 128                              ; Max bytes to copy (size of nid.szTip)
.CopyToolTipLoop:
 cmp   RCX, 0
 je    .CopyToolTipDone_Full                  ; If counter is 0, buffer is full
 mov   AL, byte [RSI]
 mov   byte [RDI], AL
 inc   RSI
 inc   RDI
 dec   RCX
 cmp   AL, 0                                ; Check for null terminator
 jne   .CopyToolTipLoop                     ; If not null, continue loop
 jmp   .CopyToolTipDone_NullFound           ; Null terminator found and copied
.CopyToolTipDone_Full:
 ; Buffer is full, ensure last byte is null if string was too long
 mov   byte [RDI-1], 0
.CopyToolTipDone_NullFound:
 ; Null terminator was copied, szTip is properly terminated.

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
    sub   RSP, 208 ; Shadow space (32) + NOTIFYICONDATA (168) = 200, rounded up to 208 bytes (16-byte aligned)

    ; Stack layout for NOTIFYICONDATA in WndProc (used for NIM_DELETE)
    %define temp_nid           RBP - 208
    %define temp_nid.cbSize    RBP - 208            ; DWORD (4 bytes)
    %define temp_nid.hWnd      RBP - 200            ; HWND (8 bytes)
    %define temp_nid.uID       RBP - 192            ; UINT (4 bytes)

    ; Save parameters (passed in RCX, RDX, R8, R9)
    mov   qword [RBP + 16], RCX    ; hWnd
    mov   qword [RBP + 24], RDX    ; uMsg
    mov   qword [RBP + 32], R8     ; wParam
    mov   qword [RBP + 40], R9     ; lParam

    ; Message handling
    cmp   RDX, WM_DESTROY
    je    WMDESTROY

    cmp   RDX, WM_TRAYICON_MSG
    je    WMTRAYICON

    cmp   RDX, WM_COMMAND
    je    WCOMMANDHANDLER

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

WMTRAYICON:                        ; Handler for our tray icon message
    ; RBP + 16 = hWnd
    ; RBP + 24 = uMsg (WM_TRAYICON_MSG)
    ; RBP + 32 = wParam (uID of icon = 0)
    ; RBP + 40 = lParam (mouse message, e.g., WM_LBUTTONDOWN)

    mov   RAX, qword [RBP + 40]    ; RAX = mouse message (lParam)
    cmp   RAX, WM_LBUTTONDOWN
    je    .TrayLeftClick
    cmp   RAX, WM_RBUTTONDOWN
    je    .TrayRightClick
    jmp   .TrayUnhandled

.TrayLeftClick:
    ; TODO: Implement left-click action (e.g., show/hide window)
    ; For now, let's make left-click show the window if it's hidden or bring to front
    mov   RCX, qword [RBP + 16] ; hWnd
    call  IsWindowVisible
    test  RAX, RAX
    jnz   .BringToFront     ; If visible, just bring to front
    ; If not visible, show it
    mov   RCX, qword [RBP + 16] ; hWnd
    mov   EDX, SW_SHOWNORMAL
    call  ShowWindow
.BringToFront:
    mov   RCX, qword [RBP + 16] ; hWnd
    call  SetForegroundWindow
    jmp   .TrayHandled

.TrayRightClick:
    ; Get the cursor position first
    sub   RSP, 32                      ; Shadow space for GetCursorPos
    lea   RCX, [REL pt]                ; RCX = address of POINT structure
    call  GetCursorPos
    add   RSP, 32                      ; Clean up shadow space

    ; To display a menu for a notification icon, the application must make its window the foreground window
    mov   RCX, qword [RBP + 16]        ; RCX = hWnd
    call  SetForegroundWindow

    ; --- Get the submenu handle ---
    ; Load the main menu bar handle into RCX
    mov   RCX, qword [REL hMenu]
    test  RCX, RCX
    jz    .TrayHandled                 ; Exit if menu handle is null

    ; Get the first (and only) submenu from the menu bar
    sub   RSP, 32                      ; Reserve shadow space for GetSubMenu
    mov   EDX, 0                       ; EDX = uIndex of the submenu
    call  GetSubMenu                   ; Returns submenu handle in RAX
    add   RSP, 32                      ; Clean up shadow space

    ; Check if GetSubMenu returned a valid handle
    test  RAX, RAX
    jz    .TrayHandled                 ; Exit if it failed

    ; --- Display the popup menu ---
    ; Now RAX holds the handle to the actual popup menu we want to show
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
    ; Pass to DefWindowProc or handle as 0 if not interested
.TrayHandled:
    xor   EAX, EAX                 ; Return 0, indicating message was handled
    mov   RSP, RBP                 ; Remove the stack frame
    pop   RBP
    ret

WCOMMANDHANDLER:                       ; Handles WM_COMMAND messages
    ; RBP + 16 = hWnd
    ; RBP + 24 = uMsg (WM_COMMAND)
    ; RBP + 32 = wParam (HIWORD: notification code, LOWORD: item ID/control ID)
    ; RBP + 40 = lParam (control handle or 0)

    mov   RAX, qword [RBP + 32]    ; RAX = wParam
    movzx EAX, AX                  ; EAX = LOWORD(wParam) = Menu Item ID

    cmp   EAX, IDM_SHOW
    je    .MenuShow
    cmp   EAX, IDM_EXIT
    je    .MenuExit
    jmp   .MenuUnhandled

.MenuShow:
    mov   RCX, qword [RBP + 16]    ; hWnd
    call  IsWindowVisible
    test  RAX, RAX
    jnz   .MenuShowBringToFront
    ; If not visible, show it
    mov   RCX, qword [RBP + 16]    ; hWnd
    mov   EDX, SW_SHOWNORMAL
    call  ShowWindow
.MenuShowBringToFront:
    mov   RCX, qword [RBP + 16]    ; hWnd
    call  SetForegroundWindow
    jmp   .MenuHandled

.MenuExit:
    sub   RSP, 32                  ; Shadow space for PostQuitMessage
    xor   ECX, ECX                 ; ECX = nExitCode (0)
    call  PostQuitMessage
    add   RSP, 32
    jmp   .MenuHandled

.MenuUnhandled:
    ; If not one of our menu items, could be from a control, or unhandled.
    ; For now, just fall through to returning 0, as if handled.
.MenuHandled:
    xor   EAX, EAX                 ; Return 0, indicating message was handled
    mov   RSP, RBP
    pop   RBP
    ret

WMDESTROY:
    ; Destroy Menu if loaded
    mov   RCX, qword [REL hMenu]
    test  RCX, RCX
    jz    .SkipDestroyMenu
    sub   RSP, 32                  ; Shadow space for DestroyMenu
    call  DestroyMenu
    add   RSP, 32
.SkipDestroyMenu:

    ; Remove tray icon before exiting
    mov   dword [temp_nid.cbSize], 168
    mov   RAX, qword [RBP + 16]        ; hWnd from WndProc's argument
    mov   qword [temp_nid.hWnd], RAX
    mov   dword [temp_nid.uID], 0      ; Icon ID we used

    sub   RSP, 32                      ; Shadow space for Shell_NotifyIconA
    mov   ECX, NIM_DELETE
    lea   RDX, [temp_nid]
    call  Shell_NotifyIconA
    add   RSP, 32                      ; Remove shadow space

    ; Original WM_DESTROY actions
    sub   RSP, 32                      ; 32 bytes of shadow space
    xor   ECX, ECX
    call  PostQuitMessage
    add   RSP, 32                      ; Remove the 32 bytes

    xor   EAX, EAX                 ; Return 0
    mov   RSP, RBP                 ; Remove the stack frame
    pop   RBP
    ret