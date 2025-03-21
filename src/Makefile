
all: noise_test.gb

%.2bpp: %.png
	rgbgfx -o $@ $<

%.1bpp: %.png
	rgbgfx -d 1 -o $@ $<

noise_test.o: noise_test.asm font.2bpp noise_test_logo.2bpp
	rgbasm -Wunmapped-char=0 -o noise_test.o noise_test.asm

noise_test.gb: noise_test.o
	rgblink -n noise_test.sym -m noise_test.map -o $@ $<
	rgbfix -f gh -p 255 $@

	@if which md5sum &>/dev/null; then md5sum $@; else md5 $@; fi

clean:
	rm -f noise_test.o noise_test.gb noise_test.sym noise_test.map
	find . \( -iname '*.1bpp' -o -iname '*.2bpp' \) -exec rm {} +