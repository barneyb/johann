JNC = ../target/bin/jnc
JSTDLIB = ../../lib/jstdlib.o

all: ccmain cjmain jjmain jcmain

test: all
	./ccmain > actual.txt
	./cjmain >> actual.txt
	./jjmain >> actual.txt
	./jcmain >> actual.txt
	diff expected.txt actual.txt

clean:
	rm -f *main *.jnh *.s *.o

ccmain: cmain.s clib.o
	gcc -o ccmain cmain.s clib.o $(JSTDLIB)

cjmain: cmain.s jlib.o $(JSTDLIB)
	gcc -o cjmain cmain.s jlib.o $(JSTDLIB)

cmain.s: cmain.c
	gcc -S cmain.c

clib.o: clib.s
	gcc -c clib.c

clib.s: clib.c
	gcc -S clib.c

jjmain: jmain.s jlib.o $(JSTDLIB)
	gcc -o jjmain jmain.s jlib.o $(JSTDLIB)

jcmain: jmain.s clib.o $(JSTDLIB)
	gcc -o jcmain jmain.s clib.o $(JSTDLIB)

jmain.s: jmain.jn $(JNC)
	$(JNC) < jmain.jn > jmain.s

jlib.o: jlib.s
	gcc -c jlib.s

jlib.s jlib.jnh: jlib.jn $(JNC)
	$(JNC) < jlib.jn > jlib.s
	$(JNC) --header < jlib.jn > jlib.jnh
