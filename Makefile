debug: stb_c_lexer.o out
	odin build . -debug -out:out/veilcode -thread-count:4
release: stb_c_lexer.o out
	odin build . -o:speed -out:out/veilcode -thread-count:4
stb_c_lexer.o: ./thirdparty/stb_c_lexer/stb_c_lexer.h
	cc -x c -c -g ./thirdparty/stb_c_lexer/stb_c_lexer.h -o thirdparty/stb_c_lexer/stb_c_lexer_linux.o -DSTB_C_LEXER_IMPLEMENTATION
# TODO: will compile stb_c_lexer for other platforms later
out:
	mkdir -p out

