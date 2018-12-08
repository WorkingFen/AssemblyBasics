;--------------------------------------------------
;   void func(char* word){
;       char* j = word;
;       
;       for(int i = 0; *(word+i) != '\0'; i++){
;           if(*(word+i)<'0' || *(word+i)>'8' || *(word+i)%2 != 0){
;               *(j) = *(word+i);
;               *(j++);    
;           }
;       }
;       while(*(word+i)!=*(j)){
;           *(j)= '\0';
;           *(j++);
;       }
;   }
;--------------------------------------------------

section .text
global func

func:
    push    ebp         ;push "calling procedure" frame pointer
    mov     ebp, esp    ;set new frame pointer

    mov     edi, [ebp+8]    ;save copy of string begin pointer
    mov     esi, edi

    mov     dl, [edi]   ;load byte
    cmp     dl, 0       ;cmp will set ZERO flag if dl is zero
    jz      end         ;jump if ZERO

loop:
    mov     dl, [esi]
    cmp     dl, 0
    jz      clean
    cmp     dl, '0'
    jl      write
    cmp     dl, '8'
    jg      write
    mov     al, dl
    sar     al, 1
    sal     al, 1
    cmp     al, dl
    jnz     write
    inc     esi

    jmp     loop

write:
    mov     [edi], dl
    inc     edi
    inc     esi
    jmp     loop

clean:
    cmp     edi, esi
    jge     end
    mov     BYTE [edi], 0
    inc     edi

end:
    mov     esp, ebp
    pop     ebp
    ret