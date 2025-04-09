TGT=target
LIB=$(TGT)/lib
BIN=$(TGT)/bin
OBJECTS=\
	$(LIB)/mem.o \
	$(LIB)/lexer.o \
	$(LIB)/print.o \
	$(LIB)/reader.o \
	$(LIB)/string.o \
	$(LIB)/system.o \
	$(LIB)/token.o

all: $(BIN)/jnc jnc $(BIN)/not_quite_lisp nql

jnc: $(BIN)/jnc
	$(BIN)/jnc < return_seven.jn

nql: $(BIN)/not_quite_lisp
	printf "" | $(BIN)/not_quite_lisp
	echo "(()))((((" | $(BIN)/not_quite_lisp
	echo "())())" | $(BIN)/not_quite_lisp
	$(BIN)/not_quite_lisp < not_quite_lisp.txt

# pattern rules

$(BIN)/%: $(LIB)/%.o $(OBJECTS)
	@mkdir -p $(BIN)
	gcc $< $(OBJECTS) -o $@

# including the table here is a little draconian, but whatever
$(LIB)/%.o: %.s inc_token_table.s
	@mkdir -p $(LIB)
	gcc -c $< -o $@

# utility targets

clean:
	rm -rf target

# configuration targets

# if there's an error making a target, delete the target as it's in an unknown state
.DELETE_ON_ERROR:
# don't delete intermediate files created by pattern rules
.SECONDARY:
