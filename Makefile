TGT = target
BIN = $(TGT)/bin
LIB = $(TGT)/lib
OUT = $(TGT)/out

all:
	$(MAKE) -C jstdlib all
	$(MAKE) -C jnc all

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

mkdocs:
	docker run --rm -it -p 8000:8000 -v ${PWD}/documentation:/docs squidfunk/mkdocs-material

docs:
	./docs.sh

test:
	$(MAKE) -C jstdlib test
	$(MAKE) -C jnc test

clean:
	rm -rf $(TGT) *.s a.out
	$(MAKE) -C jstdlib clean
	$(MAKE) -C jnc clean

# configuration targets

# if there's an error making a target, delete the target as it's in an unknown state
.DELETE_ON_ERROR:
# don't delete intermediate files created by pattern rules
.SECONDARY:
# never clean up partially-compiled assembly files (with errors)
.PRECIOUS: $(OUT)/*.s
