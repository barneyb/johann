TGT=target
BIN=$(TGT)/bin
LIB=$(TGT)/lib
OUT=$(TGT)/out

all: $(BIN)/jnc $(LIB)/jstdlib.o

$(BIN)/jnc:
	$(MAKE) -C jnc

$(LIB)/jstdlib.o:
	$(MAKE) -C jstdlib

not_quite_lisp: $(OUT)/not_quite_lisp.s $(LIB)/jstdlib.o
	gcc -c $(OUT)/not_quite_lisp.s -o $(LIB)/not_quite_lisp.o
	gcc	$(LIB)/not_quite_lisp.o $(LIB)/jstdlib.o -o $(BIN)/not_quite_lisp
	printf "" | $(BIN)/not_quite_lisp
	echo "(()))((((" | $(BIN)/not_quite_lisp
	echo "())())" | $(BIN)/not_quite_lisp
	$(BIN)/not_quite_lisp < not_quite_lisp.txt

# pattern rules

$(OUT)/%.s: %.jn $(BIN)/jnc
	@mkdir -p $(OUT)
	$(BIN)/jnc < $< > $@

# utility targets

clean:
	$(MAKE) -C jnc clean
	$(MAKE) -C jstdlib clean

# configuration targets

# if there's an error making a target, delete the target as it's in an unknown state
.DELETE_ON_ERROR:
# don't delete intermediate files created by pattern rules
.SECONDARY:
# never clean up partially-compiled assembly files (with errors)
.PRECIOUS: $(OUT)/*.s
