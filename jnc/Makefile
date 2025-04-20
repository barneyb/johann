TGT = target
BIN = $(TGT)/bin
LIB = $(TGT)/lib
OUT = $(TGT)/out
INCLUDE = ../include
VERSION = $(OUT)/inc_version.s
OBJECTS = \
	$(LIB)/emitter.o \
	$(LIB)/lexer.o \
	$(LIB)/mem.o \
	$(LIB)/parser.o \
	$(LIB)/print.o \
	$(LIB)/reader.o \
	$(LIB)/string.o \
	$(LIB)/system.o \
	$(LIB)/token.o
INCLUDES = \
	inc_token_table.s \
	$(VERSION)

all: $(BIN)/jnc

$(VERSION):
	@mkdir -p $(OUT)
	rm -f $(VERSION)
	echo "jnc_short_version: .asciz "'"jnc 0.'`date -u '+%Y%m%d'`-`git log --oneline -n 1 | cut -d ' ' -f 1`'"' >> $(VERSION)
	echo "jnc_long_version: .asciz "'"jnc 0.'`date -u '+%Y%m%d'`\\\\nbuild_time: `date -u -Iseconds`\\\\ncommit_hash: `git rev-parse HEAD`'"' >> $(VERSION)

# Pattern targets

$(BIN)/%: $(LIB)/%.o $(OBJECTS)
	@mkdir -p $(BIN)
	gcc -o $@ -nostdlib -dead_strip $< $(OBJECTS)

$(LIB)/%.o: %.s $(INCLUDES)
	@mkdir -p $(LIB)
	gcc -o $@ -c $<

$(LIB)/%.o: $(INCLUDE)/%.s
	@mkdir -p $(LIB)
	gcc -o $@ -c $<

# Utility targets

test::
	$(MAKE) -C test all

clean:
	rm -rf $(TGT)
	$(MAKE) -C test clean

# configuration targets

# if there's an error making a target, delete the target as it's in an unknown state
.DELETE_ON_ERROR:
# don't delete intermediate files created by pattern rules
.SECONDARY:
# never clean up partially-compiled assembly files (with errors)
.PRECIOUS: $(LIB)/*.s
