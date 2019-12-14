; build with
; nasm -felf64 part1.asm
; ld part1.o -o compiler

; this will run the input file "program"
; and output the compiled result in the file "compiled"
; the output will be in a binary format representing the intcode
; every number string will be turned into a 32bit integer
; and the delimiters are removed since the boundaries are constant
; view the output with `hexdump`
; new: result will also be printed


%define   O_RDONLY  0x0
%define   O_WRONLY  0x1
%define   O_CREAT   0x64

%define   PROT_READ  0x1
%define   PROT_WRITE 0x2

%define   MAP_PRIVATE   0x2
%define   MAP_ANONYMOUS 0x20

global    _start

struc FSTAT
    .st_dev         resq 1
    .st_ino         resq 1
    .st_nlink       resq 1
    .st_mode        resd 1
    .st_uid         resd 1
    .st_gid         resd 1
    .pad0           resb 4
    .st_rdev        resq 1
    .st_size        resq 1
    .st_blksize     resq 1
    .st_blocks      resq 1
    .st_atime       resq 1
    .st_atime_nsec  resq 1
    .st_mtime       resq 1
    .st_mtime_nsec  resq 1
    .st_ctime       resq 1
    .st_ctime_nsec  resq 1
endstruc

struc PROG
    .start          resq 1
    .end            resq 1
    .size           resq 1
endstruc


          section   .bss
          fstat     resb FSTAT_size
          compiled  resb PROG_size
          raw       resb PROG_size
          output    resq 1


          section   .rodata
program_path:
          db        "program", 0
compiled_path:
          db        "compiled", 0
error_msg:
          db        "encountered unknown opcode", 10, 0
error_msg_sz: equ $-error_msg


          section   .text
initialize:
          enter     0,   0          ; prologue with 0 space for locals

          ; first we load the raw program into memory
          mov       rdi, program_path; *filename
          mov       rsi, O_RDONLY   ; flags
          xor       rdx, rdx        ; mode
          mov       rax, 0x2        ; sys_open
          syscall

          mov       rdi, rax        ; file descriptor
          mov       rsi, fstat      ; *statbuf
          mov       rax, 0x5        ; sys_fstat
          syscall

          mov       r8,  rdi        ; file descriptor
          xor       rdi, rdi        ; addr (null for auto assign)
          mov       rsi, [fstat + FSTAT.st_size] ; size
          mov       rdx, PROT_READ  ; protection
          mov       r10, MAP_PRIVATE ; flags
          xor       r9,  r9         ; offset
          mov       rax, 0x9        ; sys_mmap
          syscall

          ; next we initialize the raw program structure
          mov       [raw + PROG.start], rax ; store address the mapped file 
          mov       [raw + PROG.size], rsi ; save size for convenient access
          add       rsi, rax        ; calculate end of program
          mov       [raw + PROG.end], rsi

          ; program is in memory, descriptor not needed anymore
          mov       rdi, r8         ; file descriptor
          mov       rax, 0x3        ; sys_close
          syscall

          ; allocate memory for the compiled program
          ; some implementations require fd to be 0 for MAP_ANON
          mov       r8, 0
          xor       rdi, rdi        ; addr
          mov       rsi, [raw + PROG.size]
          shl       rsi, 2          ; program size * 4 (max possible size)
          mov       rdx, PROT_READ | PROT_WRITE ; protection
          mov       r10, MAP_ANONYMOUS | MAP_PRIVATE ; flags
          xor       r9, r9          ; offset
          mov       rax, 0x9        ; sys_mmap
          syscall

          ; save start addr. size and end are not known yet
          mov       [compiled + PROG.start], rax

          leave                     ; epilogue
          ret


compile_program:
          enter     0, 0

          ; compiled program counter
          mov       r9, [compiled + PROG.start]
          ; eax stores the current number
          xor       rax, rax
          mov       rsi, [raw + PROG.start]
          mov       rdi, [raw + PROG.end]
          xor       r8, r8
.loop_start:
          mov       r8b, byte [rsi] ; get current char
          inc       rsi
          cmp       r8b, ','        ; did we reach the delimiter yet?
          je        .delimiter

          sub       r8b, '0'
          imul      rax, 10
          add       rax, r8
          jmp       .continue

.delimiter:
          mov       dword [r9], eax
          add       r9, 4
          xor       rax, rax

.continue:
          cmp       rsi, rdi
          jne       .loop_start
          ; last number doesnt have a delim
          mov       [r9], eax
          add       r9, 4

          mov       [compiled + PROG.end], r9
          sub       r9, [compiled + PROG.start]
          mov       [compiled + PROG.size], r9

          leave
          ret


write_compiled:
          enter     0, 0

          ; open target file
          mov       rdi, compiled_path ; *filename
          mov       rsi, O_WRONLY | O_CREAT ; flags
          mov       rdx, 0q664    ; mode
          mov       rax, 0x2      ; sys_open
          syscall

          mov       r8, rax       ; save fd
          mov       rdi, rax      ; fd
          mov       rsi, [compiled + PROG.start] ; *buffer
          mov       rdx, [compiled + PROG.size] ; count
          mov       rax, 0x1      ; sys_write
          syscall

          mov       rdi, r8       ; fd
          mov       rax, 0x3      ; sys_close
          syscall

          leave
          ret


run_program:
          enter     0, 0

          mov       rax, rax
          mov       rsi, [compiled + PROG.start]
          mov       rcx, rsi
          mov       rdi, [compiled + PROG.end]

.loop_start:
          mov       eax, [rcx] ; current opcode
          add       rcx, 4
          cmp       eax, 1 ; opcode 1?
          jne       .check_op2
          ; opcode 1 logic
          xor       r8, r8
          xor       r9, r9
          xor       r10, r10

          mov       r8d, dword [rcx]
          mov       r8d, dword [rsi + r8 * 4]
          add       rcx, 4

          mov       r9d, dword [rcx]
          add       r8d, dword [rsi + r9 * 4]
          add       rcx, 4
  
          mov       r10d, dword [rcx]
          mov       [rsi + r10 * 4], r8d
          add       rcx, 4
          jmp       .continue

.check_op2:
          cmp       eax, 2
          jne       .check_op99
          ; opcode 2 logic
          xor       r8, r8
          xor       r9, r9
          xor       r10, r10

          mov       r8d, dword [rcx]
          mov       r8d, dword [rsi + r8 * 4]
          add       rcx, 4

          mov       r9d, dword [rcx]
          imul      r8d, dword [rsi + r9 * 4]
          add       rcx, 4
  
          mov       r10d, dword [rcx]
          mov       [rsi + r10 * 4], r8d
          add       rcx, 4
          jmp       .continue

.check_op99:
          cmp       eax, 99
          jne       .default
          jmp       .end

.default:
          ; opcode error
          push      rsi
          push      rdi
          push      rax

          mov       rdi, 1        ; fd (stdout)
          mov       rsi, error_msg ; string to output
          mov       rdx, error_msg_sz
          mov       rax, 1        ; sys_write
          syscall

          pop       rax
          pop       rdi
          pop       rsi
          jmp       .continue

.continue:
          cmp       rcx, rdi
          jne       .loop_start

.end:
          mov       [compiled + PROG.end], rcx
          sub       rcx, rsi
          mov       [compiled + PROG.size], rcx

          leave
          ret


; thanks to this dude
; https://codereview.stackexchange.com/questions/142842/integer-to-ascii-algorithm-x86-assembly
print_result:
          xor       rax, rax
          mov       rbx, [compiled + PROG.start]
          mov       eax, dword [rbx]
          xor       rbx, rbx
          xor       ecx, ecx
          mov       ebx, 0xCCCCCCCD
          xor       rdi, rdi

.loop_start:
          mov       ecx, eax      ; save original number

          mul       ebx           ; divide by 10 using agner fog's 'magic number'
          shr       edx, 3        ;

          mov       eax, edx      ; store quotient for next loop

          lea       edx, [edx * 4 + edx] ; multiply by 10
          shl       rdi, 8        ; make room for byte
          lea       edx, [edx * 2 - '0'] ; finish *10 and convert to ascii
          sub       ecx, edx      ; subtract from original number to get remainder

          lea       rdi, [rdi + rcx] ; store next byte

          test      eax, eax
          jnz       .loop_start 

          mov       [output], rdi
          mov       rdi, 1        ; fd (stdout)
          mov       rsi, output   ; string to output
          mov       rdx, 8
          mov       rax, 1        ; sys_write
          syscall

          ret


_start:
          call      initialize
          call      compile_program
          call      run_program
          call      print_result
          call      write_compiled

          xor       rdi, rdi      ; exit code
          mov       rax, 60       ; sys_exit
          syscall