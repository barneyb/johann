TGT = target
BIN = $(TGT)/bin
LIB = $(TGT)/lib
OUT = $(TGT)/out
JNC = ../bin/jnc
JSTDLIB = ../jstdlib/$(LIB)/jstdlib.o
VERSION = inc_version.jn
OBJECTS = $(JSTDLIB) \
	$(LIB)/emitter.o \
	$(LIB)/jnc.jn.o \
	$(LIB)/lexer.o \
	$(LIB)/parser.o \
	$(LIB)/symbol.o \
	$(LIB)/token.o \
	$(LIB)/inc_version.jn.o \

INCLUDES = \
	inc_token_table.s \

all: $(BIN)/jnc
	@echo --------------------------------------------------
	$(BIN)/jnc --version
	@echo --------------------------------------------------
	$(BIN)/jnc -v
	@echo --------------------------------------------------

$(LIB)/inc_version.jn.o:
	echo "char* JNC_SHORT_VERSION = "'"jnc 0.'`date -u '+%Y%m%d'`-`git log --oneline -n 1 | cut -d ' ' -f 1`'"'";\
 	char* JNC_LONG_VERSION = "'"jnc 0.'`date -u '+%Y%m%d'`\\\\nbuild_time: `date -u -Iseconds`\\\\ncommit_hash: `git rev-parse HEAD`'";' \
	| $(JNC) | gcc -o $(LIB)/inc_version.jn.o -x assembler -c -

$(JSTDLIB)::
	$(MAKE) -C ../jstdlib

# Pattern targets

$(BIN)/%: $(LIB)/%.o $(OBJECTS)
	@mkdir -p $(BIN)
	gcc -o $@ -dead_strip $^
	@rm -f $(LIB)/inc_version.jn.o # blow away version info, so it'll rebuild next time

$(LIB)/%.o: %.s $(INCLUDES)
	@mkdir -p $(LIB)
	gcc -o $@ -c $<

$(OUT)/%.jn.s: %.jn
	@mkdir -p $(OUT)
	$(JNC) < $< > $@

$(LIB)/%.jn.o: $(OUT)/%.jn.s
	@mkdir -p $(LIB)
	gcc -o $@ -c $<

# Utility targets

test: all
	$(MAKE) -C tests all

clean:
	rm -rf $(TGT)
	$(MAKE) -C ../jstdlib clean
	$(MAKE) -C tests clean

# configuration targets

# if there's an error making a target, delete the target as it's in an unknown state
.DELETE_ON_ERROR:
# don't delete intermediate files created by pattern rules
.SECONDARY:
# never clean up partially-compiled assembly files (with errors)
.PRECIOUS: $(OUT)/*.s
