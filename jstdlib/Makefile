TGT = target
BIN = $(TGT)/bin
LIB = $(TGT)/lib
OUT = $(TGT)/out
JNC = ../bin/jnc
OBJECTS = \
	$(LIB)/allocator.o \
	$(LIB)/io.o \
	$(LIB)/table.o \
	$(LIB)/string.o \
	$(LIB)/string.jn.o \
	$(LIB)/sys.o \

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

# if there's an error making a target, delete the target as it's in an unknown state
.DELETE_ON_ERROR:
# don't delete intermediate files created by pattern rules
.SECONDARY:
# never clean up partially-compiled assembly files (with errors)
.PRECIOUS: $(LIB)/*.s
