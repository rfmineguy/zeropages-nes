build:
	ca65 hellomario.s -o hellomario.o --debug-info
	ld65 hellomario.o -o hellomario.nes -m hellomario.map -t nes --dbgfile hellomario.dbg
