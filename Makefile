COPY_TARGET = /Volumes/MSXDOS2

all:
	mkdir -p bin
	cp res/driver.com bin/
	java -jar tools/glass.jar src/COM.asm bin/term4msx.com bin/term4msx.sym

dist: all
	rm -f bin/term4msx.zip
	zip -j bin/term4msx.zip bin/term4msx.com res/driver.com term4msx.txt

copy: all
	cp bin/term4msx.com $(COPY_TARGET)/term4msx/
	diskutil umount $(COPY_TARGET)

run: all
	openmsx -machine Panasonic_FS-A1GT -ext rs232 -diska bin/ -script openmsx.tcl
