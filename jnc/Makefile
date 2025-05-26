TGT = target
BIN = $(TGT)/bin
LIB = $(TGT)/lib
OUT = $(TGT)/out
JNC = ../bin/jnc
JSTDLIB = ../jstdlib/$(LIB)/jstdlib.o
OBJECTS = $(JSTDLIB) \
	$(LIB)/Token.jn.o \
	$(LIB)/emitter.jn.o \
	$(LIB)/emitter.o \
	$(LIB)/inc_version.jn.o \
	$(LIB)/jnc.jn.o \
	$(LIB)/lexer.jn.o \
	$(LIB)/parser.jn.o \
	$(LIB)/symbol.o \
	$(LIB)/token_table.jn.o \

all: $(BIN)/jnc
	@echo --------------------------------------------------
	$(BIN)/jnc --version
	@echo --------------------------------------------------
	$(BIN)/jnc -v
	@echo --------------------------------------------------

$(LIB)/inc_version.jn.o:
	@mkdir -p $(LIB)
	echo "pub char* JNC_SHORT_VERSION = "'"jnc 0.'`date -u '+%Y%m%d'`-`git log --oneline -n 1 | cut -d ' ' -f 1`'"'";\
 	pub char* JNC_LONG_VERSION = "'"jnc 0.'`date -u '+%Y%m%d'`\\\\nbuild_time: `date -u -Iseconds`\\\\ncommit_hash: `git rev-parse HEAD`'";' \
	| $(JNC) | gcc -o $(LIB)/inc_version.jn.o -x assembler -c -

inc_token_table.s: token_table.jn
	@mkdir -p $(OUT)
	sed -e 's/^#/;/' -e 's/^pub int /    /' token_table.jn > inc_token_table.s

$(JSTDLIB)::
	$(MAKE) -C ../jstdlib

# Pattern targets

$(BIN)/%: $(LIB)/%.jn.o $(OBJECTS)
	@mkdir -p $(BIN)
	gcc -o $@ -dead_strip $^
	@rm -f $(LIB)/inc_version.jn.o # blow away version info, so it'll rebuild next time

$(LIB)/%.o: %.s inc_token_table.s
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

# don't delete intermediate files created by pattern rules
.SECONDARY:
# never clean up partially-compiled assembly files (with errors)
.PRECIOUS: $(OUT)/*.s
