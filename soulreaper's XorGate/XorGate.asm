; The program asks for input two times, so let's check what it does with it.
; Interesting notice comes to instruction at 0x1207, it proceeds to write one byte of 0x23 into the stack at location near
; the rsp.

; ...
sub    rsp,0x460                    ; rbp-0x460
mov    rax,QWORD PTR fs:0x28

mov    QWORD PTR [rbp-0x8],rax
xor    eax,eax
mov    BYTE PTR [rbp-0x456],0x23    ; it puts the byte seemingly into an 4 byte, shifting right by one byte.

; The program proceeds then to read username and password. Temporary addresses:
;
;   Username string at: 0x7fffffffd320
;   Password string at: 0x7fffffffd320
;
; Then it proceeds to call strlen() on our password, and store it at rbp-0x430, and to zero out quad words at rbp-0x448
; and rbp-0x450, 8 byte aligned.
;
; The fun starts after the check wether a username was entered, starting at main+198:

lea    rdx,[rbp-0x410]              ; Loading the address of the username string into rdx
mov    rax,QWORD PTR [rbp-0x448]    ; Move zero to rax
add    rax,rdx                      ; Add address of the string and zero, store the same address to rax
movzx  eax,BYTE PTR [rax]           ; Move first dereferenced byte of the string into eax, zero out the rest of the register
xor    al,BYTE PTR [rbp-0x456]      ; xor the byte (at al) with the previously stored 0x23 at rbp-0x456

; Suppose we entered AAAABBBBCCCCDDD, the xor would result:
;   (0x41 ^ 0x23) = 0x62
; it will be stored in al.

mov    BYTE PTR [rbp-0x455],al      ; put al (0x62) into rbp-0x455
movzx  edx,BYTE PTR [rbp-0x455]     ; move [rbp-0x455] byte into edx, zero out the rest of the register
mov    eax,0x200                    ; move 0x200 to eax
sub    rax,QWORD PTR [rbp-0x450]    ; subtract rax with rbp-0x450, which is zero. rax is still 0x200

lea    rsi,[rbp-0x210]              ; lea rbp-0x210 to rsi
mov    rcx,QWORD PTR [rbp-0x450]    ; move zero to rcx
lea    rdi,[rsi+rcx*1]              ; lea rsi + rcx, indexing, which is just rsi[0], store result in rdi

lea    rsi,[rip+0xd47]              ; load string constant to rsi, "%02x", seems like a format for the upcoming snprintf call
mov    ecx,edx                      ; load untouched rdx (0x62) to ecx
mov    rdx,rsi                      ; load relevant index at rsi to rdx
mov    rsi,rax                      ; load rax (0x200 currently) to rsi
mov    eax,0x0                      ; load zero to eax
call   snprintf

; formally the snprintf call should look like snprintf(rdi, 0x200, "%02x", 0x62)
; effectively writing "62\0" starting at rdi.
;
; TBW, stopped at main+287
