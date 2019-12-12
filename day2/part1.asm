
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


          section   .rodata
message:
          db        "yeet", 0
filepath:
          db        "input.txt", 0
filesize_format:
          db        "filesize: %llx", 0


          section   .text
main:
          mov       rdi, message
          call      puts

          mov       rdi, filepath   ; *filename
          xor       rsi, rsi        ; flags
          mov       rdx, O_RDONLY   ; mode
          mov       rax, 0x2        ; sys_open
          syscall

          mov       rdi, rax        ; file descriptor
          mov       rsi, fstat      ; *statbuf
          mov       rax, 0x5        ; sys_fstat
          syscall

; print filesize for debugging
        ;   mov       rdi, filesize_format
        ;   mov       rsi, [fstat + FSTAT.st_size]
        ;   xor       rax, rax        ; used xmm registers
        ;   call      printf

          xor       rdi, rdi        ; addr (null for auto assign)
          mov       rsi, rax        ; size
          mov       rdx, PROT_READ | PROT_WRITE ; protection
          mov       r10, MAP_PRIVATE ; flags
          mov       r8,  rdi        ; file descriptor
          xor       r9,  r9         ; offset
          mov       rax, 0x9
          syscall

          mov       [program], rax  ; store address the mapped file

          mov       rdi, filesize_format
          mov       rsi, [program]
          xor       rax, rax        ; used xmm registers
          call      printf 

        ;   mov       rdi, r8         ; file descriptor
        ;   mov       rax, 0x3        ; sys_close
        ;   syscall

        ;   mov       rdi, 1          ; stdout handle
        ;   mov       rsi, [program]    ; *output string
        ;   mov       rdx, 8          ; output bytes
        ;   mov       rax, 0x1        ; sys_write
        ;   syscall

          ;mov rax, 9 ; sys_mmap
          ;xor rdi, rdi ; address
          ;xor rsi, rsi ; length

          ret