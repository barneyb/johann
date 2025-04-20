TGT = target
BIN = $(TGT)/bin
LIB = $(TGT)/lib
OUT = $(TGT)/out

all: $(BIN)/jnc $(LIB)/jstdlib.o

$(BIN)/jnc:
	$(MAKE) -C jnc all
	@mkdir -p $(BIN)

$(LIB)/jstdlib.o:
	$(MAKE) -C jstdlib all
	@mkdir -p $(LIB)

not_quite_lisp: not_quite_lisp.jn bin/jnc lib/jstdlib.o
	@mkdir -p $(OUT) $(LIB) $(BIN)
	bin/jnc < not_quite_lisp.jn > $(OUT)/not_quite_lisp.s
	gcc -o $(LIB)/not_quite_lisp.o -c $(OUT)/not_quite_lisp.s
	gcc -o $(BIN)/not_quite_lisp $(LIB)/not_quite_lisp.o lib/jstdlib.o
	printf "" | $(BIN)/not_quite_lisp
	echo "(()))((((" | $(BIN)/not_quite_lisp
	echo "())())" | $(BIN)/not_quite_lisp
	$(BIN)/not_quite_lisp < not_quite_lisp.txt

# utility targets

test:
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
