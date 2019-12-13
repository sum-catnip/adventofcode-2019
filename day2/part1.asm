; build with
; nasm -felf64 part1.asm
; gcc -static part1.o


%define   O_RDONLY  0

%define   PROT_READ 1
%define   PROT_WRITE 2

%define   MAP_PRIVATE 2
%define   MAP_ANONYMOUS 20

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

struc PROG
    .start          resq 1
    .end            resq 1
    .size           resq 1
    .index          resq 1
endstruc


          section   .bss
          fstat     resb FSTAT_size
          compiled  resb PROG_size
          raw       resb PROG_size
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


initialize:
          enter     0,   0          ; prologue with 0 space for locals

          ; first we load the raw program into memory
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
          mov       rdx, PROT_READ  ; protection
          mov       r10, MAP_PRIVATE ; flags
          xor       r9,  r9         ; offset
          mov       rax, 0x9        ; sys_mmap
          syscall

          ; next we initialize the raw program structure
          mov       [raw + PROG.start], rax ; store address the mapped file 
          mov       [raw + PROG.index], rax
          mov       [raw + PROG.size], rsi ; save size for convenient access
          add       rsi, rax        ; calculate end of program
          mov       [raw + PROG.end], rsi

          ; program is in memory, descriptor not needed anymore
          mov       rdi, r8         ; file descriptor
          mov       rax, 0x3        ; sys_close
          syscall

          ; allocate memory for the compiled program
          ; some implementations require fd to be 0 for MAP_ANON
          mov       r8, -1
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
          mov       [compiled + PROG.index], rax

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
          cmp       r8b, ';'        ; did we reach the delimiter yet?
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

          leave
          ret


; ; parses the opcode at the current [pc]
; ; calls the appropriate function to handle the opcode
; scan_opcode:
;           enter     0, 0
;           mov       r12, [pc]       ; dereference pc into r12
;           cmp       byte [r12], '1' ; check if current opcode is opcode '1'
;           jnz       .check_op2
;           mov       rdi, instruction_format
;           mov       rsi, 1
;           xor       rax, rax
;           call printf
; .check_op2:
;           cmp       byte [r12], '2'
;           jnz       .check_op99
;           mov       rdi, instruction_format
;           mov       rsi, 2
;           xor       rax, rax
;           call printf
; .check_op99:
;           cmp       word [r12], '99'
;           jnz       .end
;           mov       rdi, instruction_format
;           mov       rsi, 99
;           xor       rax, rax
;           call printf
; .end:
;           leave
;           ret


; ; calculate the remaining program bytes (bytes not yet executed)
; calc_remaining:
;           enter     0, 0

;           lea       rax, [raw + PROG.end] ; find end of prog in memory
;           sub       rax, [raw + PROG.index] ; diff pc - end of prog
;           dec       rax                  ; not counting the byte were at

;           leave
;           ret


; ; progresses the program counter until after the next delimiter
; ; returns how far we moved
; progress_delimiter:
;           enter     0, 0

;           call      calc_remaining
;           mov       rcx, rax             ; remaining bytes into rcx
;           mov       rax, ','             ; find next occurence of ';'
;           mov       rdi, [raw + PROG.index] ; starting from pc
;           mov       r8, rdi              ; save current pc
;           repne     scasb                ; inc rdi until [rdi] = ','
;           mov       [raw + PROG.index], rdi
;           sub       r8, rdi
;           mov       rax, r8              ; return how far we moved

;           leave
;           ret


; ; parses a string number to an x64 integer
; ; rdi should hold the size of the string
; ; rsi should hold the start of the string
; parse_number:
;           enter     0, 0
;           xor       rax, rax             ; result will be in eax
;           mov       rcx, rdi             ; loop count needs to be in rcx

; .loop_start:
;           mov       r9, rdi              ; safe string size
;           sub       r9, rcx              ; how often did we loop yet?
;           mov       r8, '0'              ; start of ascii number range
;           sub       r8, [rsi + r9]       ; r8 now holds the int
;           imul      eax, 10              ; make sum space for the new number
;           add       eax, r8

;           loop      .loop_start          ; loops rcx times

;           leave
;           ret


; ; processes the opcode 1
; process_op1:
;           enter     0, 0

;           mov       r12, [pc]            ; save start of number
;           call      progress_delimiter   ; move to the next operhand
          
;           ; rax holds the distance we moved
;           ; TODO parse 3 arbitrary sized ints

;           leave
        ;   ret


main:
          mov       rdi, welcome_msg 
          call      puts
          call      initialize
          call      compile_program
        ;   call      scan_opcode
        ;   call      progress_delimiter
        ;   mov       rdi, [pc]
        ;   call      puts

          ret