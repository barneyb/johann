TGT = target
BIN = $(TGT)/bin
LIB = $(TGT)/lib
OUT = $(TGT)/out
JSTDLIB = ../jstdlib/$(LIB)/jstdlib.o
VERSION = $(OUT)/inc_version.s
OBJECTS = \
	$(JSTDLIB)
INCLUDES = \
	inc_token_table.s \
	$(VERSION)

all: $(BIN)/jnc
	$(BIN)/jnc --version
	$(BIN)/jnc -v
	echo "fn main(){}" | $(BIN)/jnc

$(VERSION):
	@mkdir -p $(OUT)
	echo "jnc_short_version: .asciz "'"jnc 0.'`date -u '+%Y%m%d'`-`git log --oneline -n 1 | cut -d ' ' -f 1`'\\n"' > $(VERSION)
	echo "jnc_long_version: .asciz "'"jnc 0.'`date -u '+%Y%m%d'`\\\\nbuild_time: `date -u -Iseconds`\\\\ncommit_hash: `git rev-parse HEAD`'\\n"' >> $(VERSION)

$(JSTDLIB)::
	$(MAKE) -C ../jstdlib

# Pattern targets

$(BIN)/%: $(LIB)/%.o $(OBJECTS)
	@mkdir -p $(BIN)
	gcc -o $@ -dead_strip $^

$(LIB)/%.o: %.s $(INCLUDES)
	@mkdir -p $(LIB)
	gcc -o $@ -c $<

# Utility targets

test:
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
