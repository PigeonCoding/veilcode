naned: naned.c
	gcc naned.c -o out/naned
prt_gcc: prt.asm
	fasm ./prt.asm
	mv prt.o ./out/prt_gcc.o
	gcc ./out/prt_gcc.o -o out/prt_gcc -no-pie 
prt_fasm: prt.asm
	cat ./prt.asm > tmp.asm
	echo " " >> tmp.asm
	echo "public _start" >> tmp.asm
	echo "_start:" >> tmp.asm
	echo "  call main" >> tmp.asm
	echo "  mov rax, 60" >> tmp.asm
	echo "  mov rdi, 0" >> tmp.asm
	echo "  syscall" >> tmp.asm
	fasm ./tmp.asm
	mv tmp.o ./out/prt_fasm.o
	ld ./out/prt_fasm.o -o out/prt_fasm
	rm ./tmp.asm
