;--------------------------------------------------
;   void func(char* word){
;       while(*(word+i) != '\0'){
;           *(word+i) |= 0x20;
;           *(word+i+2) |= 0x20;
;           *(word+i+3) &= 0xDF;
;           i++;
;       }
;   }
;--------------------------------------------------

section .text
global  func

func:
    push    ebp         ;push "calling procedure" frame pointer
    mov     ebp, esp    ;set new frame pointer

    mov     edi, [ebp+8]

    mov     dl, [edi]   ;load byte
    cmp     dl, 0       ;cmp will set ZERO flag if dl is zero
    jz      end         ;jump if ZERO

loop:
    mov     dl, [edi]
    cmp     dl, 0
    jz      end

    and     BYTE [edi], 0DFh
    inc     edi 

    inc     edi

    and     BYTE [edi], 0DFh
    inc     edi

    or      BYTE [edi], 020h   
    inc     edi

    jmp     loop

end:
    mov     esp, ebp
    pop     ebp
    ret