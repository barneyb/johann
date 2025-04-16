TGT=../target
BIN=$(TGT)/bin
LIB=$(TGT)/lib
OUT=$(TGT)/out
INCLUDE=../lib
OBJECTS=\
	$(LIB)/emitter.o \
	$(LIB)/lexer.o \
	$(LIB)/mem.o \
	$(LIB)/parser.o \
	$(LIB)/print.o \
	$(LIB)/reader.o \
	$(LIB)/string.o \
	$(LIB)/system.o \
	$(LIB)/token.o \

all: $(BIN)/jnc

# pattern rules

$(BIN)/%: $(LIB)/%.o $(OBJECTS)
	@mkdir -p $(BIN)
	gcc $< $(OBJECTS) -o $@

# including the token table here is a little draconian, but whatever
$(LIB)/%.o: %.s inc_token_table.s
	@mkdir -p $(LIB)
	gcc -c $< -o $@

$(LIB)/%.o: $(INCLUDE)/%.s
	@mkdir -p $(LIB)
	gcc -c $< -o $@

# utility targets

clean:
	rm -rf $(TGT)

# configuration targets

# if there's an error making a target, delete the target as it's in an unknown state
.DELETE_ON_ERROR:
# don't delete intermediate files created by pattern rules
.SECONDARY:
# never clean up partially-compiled assembly files (with errors)
.PRECIOUS: $(LIB)/*.s
