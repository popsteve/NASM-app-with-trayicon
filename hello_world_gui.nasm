; hello_world_gui.nasm 
; NASM program to create a simple Win64 GUI window displaying "Hello, World!" in the title.

extern  GetModuleHandleA
extern  ExitProcess
extern  RegisterClassExA
extern  CreateWindowExA
extern  DefWindowProcA
extern  ShowWindow
extern  UpdateWindow
extern  GetMessageA
extern  TranslateMessage
extern  DispatchMessageA
extern  PostQuitMessage

section .data
    className       db 'winclass',0
    windowName      db 'Hello, World!',0
    wndClass        WNDCLASSEXA
    msg             MSG
    hInstance       dq 0

section .text
global main
main:
    ; Get the instance handle of the application
    call    GetModuleHandleA
    mov     [hInstance], rax

    ; Fill in the WNDCLASSEX structure
    mov     [wndClass.cbSize],         dq WNDCLASSEX_size
    mov     [wndClass.style],          dq CS_HREDRAW or CS_VREDRAW
    mov     [wndClass.lpfnWndProc],    DefWindowProcA
    mov     [wndClass.cbClsExtra],     dq 0
    mov     [wndClass.cbWndExtra],     dq 0
    mov     rax, [hInstance]
    mov     [wndClass.hInstance],      rax
    mov     [wndClass.hbrBackground],  dq COLOR_WINDOW+1
    mov     [wndClass.lpszMenuName],   dq 0
    mov     [wndClass.lpszClassName],  className
    mov     [wndClass.hIcon],          dq 0
    mov     [wndClass.hCursor],        dq 0
    mov     [wndClass.hIconSm],        dq 0

    ; Register the window class
    lea     rcx, [wndClass]
    call    RegisterClassExA

    ; Create the window
    mov     r9, 0
    mov     r8, className
    mov     rdx, windowName
    mov     rcx, 0
    call    CreateWindowExA

    ; Show and update the window
    mov     rdx, SW_SHOW
    mov     rcx, rax
    call    ShowWindow
    call    UpdateWindow

    ; Main message loop
msg_loop:
    lea     rcx, [msg]
    call    GetMessageA
    test    rax, rax
    jz      exit_loop
    lea     rcx, [msg]
    call    TranslateMessage
    lea     rcx, [msg]
    call    DispatchMessageA
    jmp     msg_loop

exit_loop:
    mov     rcx, [msg.wParam]
    call    ExitProcess

section .bss
    WNDCLASSEXA  resb  48  ; Size of WNDCLASSEX structure in bytes
    MSG          resb  48  ; Size of MSG structure in bytes
