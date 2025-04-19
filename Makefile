TGT=target
BIN=$(TGT)/bin
LIB=$(TGT)/lib
OUT=$(TGT)/out

all: $(BIN)/jnc $(LIB)/jstdlib.o

$(BIN)/jnc:
	$(MAKE) -C jnc all
	@mkdir -p $(BIN)
	cp jnc/$(BIN)/jnc $(BIN)/jnc

$(LIB)/jstdlib.o:
	$(MAKE) -C jstdlib all
	@mkdir -p $(LIB)
	cp jstdlib/$(LIB)/jstdlib.o $(LIB)/jstdlib.o

not_quite_lisp: not_quite_lisp.jn $(BIN)/jnc $(LIB)/jstdlib.o
	@mkdir -p $(OUT)
	$(BIN)/jnc < not_quite_lisp.jn > $(OUT)/not_quite_lisp.s
	gcc -c $(OUT)/not_quite_lisp.s -o $(LIB)/not_quite_lisp.o
	gcc	$(LIB)/not_quite_lisp.o $(LIB)/jstdlib.o -o $(BIN)/not_quite_lisp
	printf "" | $(BIN)/not_quite_lisp
	echo "(()))((((" | $(BIN)/not_quite_lisp
	echo "())())" | $(BIN)/not_quite_lisp
	$(BIN)/not_quite_lisp < not_quite_lisp.txt

# utility targets

test: all
	$(MAKE) -C jnc test
	$(MAKE) -C jstdlib test

clean:
	rm -rf $(TGT)
	$(MAKE) -C jnc clean
	$(MAKE) -C jstdlib clean

# configuration targets

# if there's an error making a target, delete the target as it's in an unknown state
.DELETE_ON_ERROR:
# don't delete intermediate files created by pattern rules
.SECONDARY:
# never clean up partially-compiled assembly files (with errors)
.PRECIOUS: $(OUT)/*.s
