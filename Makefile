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

all: $(BIN)/jnc \
	$(BIN)/nql \
	$(LIB)/return_seven.s \
	$(LIB)/not_quite_lisp.s

jnc: $(BIN)/jnc
	$(BIN)/jnc < return_seven.jn
	$(BIN)/jnc < not_quite_lisp.jn

nql: $(BIN)/nql
	printf "" | $(BIN)/nql
	echo "(()))((((" | $(BIN)/nql
	echo "())())" | $(BIN)/nql
	$(BIN)/nql < not_quite_lisp.txt

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
