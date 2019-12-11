
%define   O_RDONLY  00000000


          global    main
          extern    puts

          section   .text
main:
          mov       rdi, message
          call      puts

          mov       rdi, filepath   ; *filename
          xor       rsi, rsi        ; flags
          mov       rdx, O_RDONLY   ; mode
          syscall

          mov       rcx, rax
          

          ;mov rax, 9 ; sys_mmap
          ;xor rdi, rdi ; address
          ;xor rsi, rsi ; length

          ret
message:
          db        "Hola, mundo", 0
filepath:
          db        "input.txt", 0