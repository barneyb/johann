TGT = target
BIN = $(TGT)/bin
LIB = $(TGT)/lib
OUT = $(TGT)/out
JNC = ../bin/jnc
OBJECTS = \
	$(LIB)/ArrayList.jn.o \
	$(LIB)/HashMap.jn.o \
	$(LIB)/Queue.jn.o \
	$(LIB)/StringBuilder.jn.o \
	$(LIB)/TreeMap.jn.o \
	$(LIB)/algorithm.jn.o \
	$(LIB)/allocator.jn.o \
	$(LIB)/io.jn.o \
	$(LIB)/io.o \
	$(LIB)/math.jn.o \
	$(LIB)/math.o \
	$(LIB)/string.jn.o \
	$(LIB)/sys.jn.o \
	$(LIB)/sys.o \

HEADERS = \
	$(OUT)/ArrayList.jnh \
	$(OUT)/HashMap.jnh \
	$(OUT)/Queue.jnh \
	$(OUT)/StringBuilder.jnh \
	$(OUT)/TreeMap.jnh \
	$(OUT)/algorithm.jnh \
	$(OUT)/allocator.jnh \
	$(OUT)/io.jnh \
	$(OUT)/math.jnh \
	$(OUT)/string.jnh \
	$(OUT)/sys.jnh \

all: $(LIB)/jstdlib.o $(LIB)/jstdlib.jnh

$(LIB)/jstdlib.o: $(OBJECTS)
	@mkdir -p $(LIB)
	gcc -o $(LIB)/jstdlib.o -nostdlib -r $(OBJECTS)

$(LIB)/jstdlib.jnh: $(HEADERS)
	@mkdir -p $(LIB)
	cat $(HEADERS) \
		| tee $(LIB)/jstdlib.jnh \
		| $(JNC) --strict \
		> /dev/null

# Pattern targets

$(LIB)/%.o: %.s
	@mkdir -p $(LIB)
	gcc -o $@ -c $<

$(OUT)/%.jn.s $(OUT)/%.jnh: %.jn
	@mkdir -p $(OUT)
	$(JNC) < $< > $@
	$(JNC) --header < $< \
		| tee $(OUT)/$<h \
		| $(JNC) --strict \
		> /dev/null

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
