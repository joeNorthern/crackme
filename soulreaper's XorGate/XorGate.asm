/*
The program asks for input two times, so let's check what it does with it.
Interesting notice comes to instruction at 0x1207, it proceeds to write one byte of 0x23 into the stack at location near
the rsp.
*/

/* ... */
sub    rsp,0x460				 /* rbp-0x460 */
mov    rax,QWORD PTR fs:0x28

mov    QWORD PTR [rbp-0x8],rax
xor    eax,eax
mov    BYTE PTR [rbp-0x456],0x23 /* it puts the byte seemingly into an 4 byte, shifting right by one byte. */

/*
The program proceeds then to read username and password. Temporary addresses:

Username string at: 0x7fffffffd320 
Password string at: 0x7fffffffd320

Then it proceeds to call strlen() on our password, and store it at rbp-0x430, and to zero out quad words at rbp-0x448
and rbp-0x450, 8 byte aligned.

The fun starts after the check wether a password was entered, starting at main+198:

Loading the address of the password string into rdx
Move zero to rax
Add address of the string and zero, store the same address to rax
Move first dereferenced byte of the string into eax, zero out the rest of the register
xor the byte (at al) with the previously stored 0x23 at rbp-0x456

Suppose we entered AAAABBBBCCCCDDD, the xor would result:
	(0x41 ^ 0x23) = 0x62
it will be stored in al.

put al (0x62) into rbp-0x455
move [rbp-0x455] byte into edx, zero out the rest of the register
move 0x200 to eax
subtract rax with rbp-0x450, which is zero. rax is still 0x200

lea rbp-0x210 to rsi
move zero to rcx
lea rsi + rcx, indexing, which is just rsi[0], store result in rdi

load string constant to rsi, "%02x", seems like a format for the upcoming snprintf call
load untouched rdx (0x62) to ecx
load relevant index at rsi to rdx
load rax (0x200 currently) to rsi
load zero to eax

formally the snprintf call should look like snprintf(rdi, 0x200, "%02x", 0x62)
effectively writing "68\0" starting at rdi.

TBW, stopped at main+287
*/
