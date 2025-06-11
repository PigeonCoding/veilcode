none:
	echo "make debug_linux|release_linux"

debug_linux: stb_c_lexer_linux64.o out
	odin build . -debug -out:out/veilcode -thread-count:4
release_linux: stb_c_lexer_linux64.o out
	odin build . -o:speed -out:out/veilcode -thread-count:4
stb_c_lexer_linux64.o: ./thirdparty/stb_c_lexer/stb_c_lexer.h
	cc -x c -c -g ./thirdparty/stb_c_lexer/stb_c_lexer.h -o thirdparty/stb_c_lexer/stb_c_lexer_linux64.o -DSTB_C_LEXER_IMPLEMENTATION

debug_win64: stb_c_lexer_win64.o out
	echo "WIP"
# odin build . -debug -out:out/veilcode.exe -thread-count:4
release_win64: stb_c_lexer_win64.o out
	echo "WIP"
# odin build . -o:speed -out:out/veilcode.exe -thread-count:4
# TODO: will have to rewrite stb_c_lexer in odin cause cannot compile
out:
	mkdir -p out

