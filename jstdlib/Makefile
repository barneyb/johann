TGT = target
BIN = $(TGT)/bin
LIB = $(TGT)/lib
OUT = $(TGT)/out
JNC = ../bin/jnc
OBJECTS = \
	$(LIB)/ArrayList.jn.o \
	$(LIB)/Queue.jn.o \
	$(LIB)/StringBuilder.jn.o \
	$(LIB)/TreeMap.jn.o \
	$(LIB)/algorithm.jn.o \
	$(LIB)/allocator.jn.o \
	$(LIB)/io.jn.o \
	$(LIB)/io.o \
	$(LIB)/math.jn.o \
	$(LIB)/string.jn.o \
	$(LIB)/sys.jn.o \
	$(LIB)/sys.o \
	$(LIB)/table.o \

all: $(LIB)/jstdlib.o

$(LIB)/jstdlib.o: $(OBJECTS)
	@mkdir -p $(LIB)
	gcc -o $(LIB)/jstdlib.o -nostdlib -r $(OBJECTS)

# Pattern targets

$(LIB)/%.o: %.s
	@mkdir -p $(LIB)
	gcc -o $@ -c $<

$(OUT)/%.jn.s: %.jn
	@mkdir -p $(OUT)
	$(JNC) < $< > $@

$(LIB)/%.jn.o: $(OUT)/%.jn.s
	@mkdir -p $(LIB)
	gcc -o $@ -c $<

# utility targets

test: all
	$(MAKE) -C tests all

clean:
	rm -rf $(TGT)
	$(MAKE) -C tests clean

# configuration targets

# don't delete intermediate files created by pattern rules
.SECONDARY:
# never clean up partially-compiled assembly files (with errors)
.PRECIOUS: $(LIB)/*.s
