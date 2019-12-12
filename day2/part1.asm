; build with
; nasm part1.asm
; gcc -static part1.o


%define   O_RDONLY  0

%define   PROT_READ 1
%define   PROT_WRITE 2

%define   MAP_PRIVATE 2

          global    main
          extern    puts
          extern    printf

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


          section   .bss
          fstat     resb 0x90
          program   resq 0x01
          prog_size resq 0x01
          pc        resq 0x01


          section   .rodata
welcome_msg:
          db        "loading program file in memory...", 0
program_path:
          db        "program", 0
instruction_format:
          db        "inst: %d", 10, 0


          section   .text


load_program:
          enter     0,   0          ; prologue with 0 space for locals

          mov       rdi, program_path; *filename
          xor       rsi, rsi        ; flags
          mov       rdx, O_RDONLY   ; mode
          mov       rax, 0x2        ; sys_open
          syscall

          mov       rdi, rax        ; file descriptor
          mov       rsi, fstat      ; *statbuf
          mov       rax, 0x5        ; sys_fstat
          syscall

          mov       r8,  rdi        ; file descriptor
          xor       rdi, rdi        ; addr (null for auto assign)
          mov       rsi, [fstat + FSTAT.st_size] ; size
          mov       [prog_size], rsi ; save size for later
          mov       rdx, PROT_READ | PROT_WRITE; protection
          mov       r10, MAP_PRIVATE ; flags
          xor       r9,  r9         ; offset
          mov       rax, 0x9
          syscall

          mov       [program], rax  ; store address the mapped file 

          mov       rdi, r8         ; file descriptor
          mov       rax, 0x3        ; sys_close
          syscall

          leave                     ; epilogue
          ret


; parses the opcode at the current [pc]
; calls the appropriate function to handle the opcode
scan_opcode:
          enter     0, 0
          mov       r12, [pc]       ; dereference pc into r12
          cmp       byte [r12], '1' ; check if current opcode is opcode '1'
          jnz       .check_op2
          mov       rdi, instruction_format
          mov       rsi, 1
          xor       rax, rax
          call printf
.check_op2:
          cmp       byte [r12], '2'
          jnz       .check_op99
          mov       rdi, instruction_format
          mov       rsi, 2
          xor       rax, rax
          call printf
.check_op99:
          cmp       word [r12], '99'
          jnz       .end
          mov       rdi, instruction_format
          mov       rsi, 99
          xor       rax, rax
          call printf
.end:
          leave
          ret


; calculate the remaining program bytes (bytes not yet executed)
calc_remaining:
          enter     0, 0

          mov       rax, [program]       ; deref start of prog memory
          mov       r8,  [prog_size]     ; deref prog size
          lea       rax, [rax + r8]      ; find end of prog in memory
          sub       rax, [pc]            ; diff pc - end of prog
          dec       rax                  ; not counting the byte were at

          leave
          ret


; progresses the program counter until after the next delimiter
; returns how far we moved
progress_delimiter:
          enter     0, 0

          call      calc_remaining
          mov       rcx, rax             ; remaining bytes into rcx
          mov       rax, ','             ; find next occurence of ';'
          mov       rdi, [pc]            ; starting from pc
          mov       r8, rdi              ; save current pc
          repne     scasb                ; inc rdi until [rdi] = ','
          mov       [pc], rdi
          sub       r8, rdi
          mov       rax, r8              ; return how far we moved

          leave
          ret


; parses a string number to an x64 integer
; rdi should hold the size of the string
; rsi should hold the start of the string
parse_number:
          enter     0, 0
          xor       rax                  ; result will be in rax
          mov       rcx, rdi             ; loop count needs to be in rcx

.loop_start:
          mov       r9, rdi              ; safe string size
          sub       r9, rcx              ; how often did we loop yet?
          mov       r8, '0'              ; start of ascii number range
          sub       r8, [rsi + r9]       ; r8 now holds the int
          imul      rax, 10              ; make sum space for the new number
          add       rax, r8

          loop      .loop_start          ; loops rcx times

          leave
          ret


; processes the opcode 1
process_op1:
          enter     0, 0

          mov       r12, [pc]            ; save start of number
          call      progress_delimiter   ; move to the next operhand
          
          ; rax holds the distance we moved
          ; TODO parse 3 arbitrary sized ints

          leave
          ret


main:
          mov       rdi, welcome_msg 
          call      puts
          call      load_program
          ; initialize program counter to the start of the program in memory
          mov       r8,  [program]       ; dereference program
          mov       [pc], r8             ; initialize pc
          call      scan_opcode
          call      progress_delimiter
          mov       rdi, [pc]
          call      puts

          ret