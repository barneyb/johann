TGT=target
LIB=$(TGT)/lib
BIN=$(TGT)/bin
OBJECTS=\
	$(LIB)/emitter.o \
	$(LIB)/mem.o \
	$(LIB)/lexer.o \
	$(LIB)/parser.o \
	$(LIB)/print.o \
	$(LIB)/reader.o \
	$(LIB)/string.o \
	$(LIB)/system.o \
	$(LIB)/token.o

all: $(BIN)/jnc \
	$(BIN)/nql \
	$(LIB)/not_quite_lisp.s
	head $(LIB)/*.s

jnc: $(BIN)/jnc
	$(BIN)/jnc < not_quite_lisp.jn

not_quite_lisp: $(LIB)/not_quite_lisp.s $(LIB)/jstdlib.o
	gcc -c $(LIB)/not_quite_lisp.s -o $(LIB)/not_quite_lisp.o
	gcc	$(LIB)/not_quite_lisp.o $(LIB)/jstdlib.o -o $(BIN)/not_quite_lisp

nql: $(BIN)/nql
	printf "" | $(BIN)/nql
	echo "(()))((((" | $(BIN)/nql
	echo "())())" | $(BIN)/nql
	$(BIN)/nql < not_quite_lisp.txt

$(BIN)/nql: nql.s $(LIB)/jstdlib.o
	@mkdir -p $(BIN)
	gcc nql.s $(LIB)/jstdlib.o -o $(BIN)/nql

$(LIB)/jstdlib.o: jstdlib.s mem.s print.s reader.s string.s system.s
	@mkdir -p $(LIB)
	cat jstdlib.s > $(LIB)/jstdlib.s
	cat mem.s >> $(LIB)/jstdlib.s
	cat print.s >> $(LIB)/jstdlib.s
	cat reader.s >> $(LIB)/jstdlib.s
	cat string.s >> $(LIB)/jstdlib.s
	cat system.s >> $(LIB)/jstdlib.s
	gcc -c $(LIB)/jstdlib.s -o $(LIB)/jstdlib.o

# pattern rules

$(BIN)/%: $(LIB)/%.o $(OBJECTS)
	@mkdir -p $(BIN)
	gcc $< $(OBJECTS) -o $@

# including the token table here is a little draconian, but whatever
$(LIB)/%.o: %.s inc_token_table.s
	@mkdir -p $(LIB)
	gcc -c $< -o $@

$(LIB)/%.s: %.jn $(BIN)/jnc
	@mkdir -p $(LIB)
	$(BIN)/jnc < $< > $@

# utility targets

clean:
	rm -rf target

# configuration targets

# if there's an error making a target, delete the target as it's in an unknown state
.DELETE_ON_ERROR:
# don't delete intermediate files created by pattern rules
.SECONDARY:
# never clean up partially-compiled assembly files (with errors)
.PRECIOUS: $(LIB)/*.s
