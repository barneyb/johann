LIB=target/lib
BIN=target/bin
OBJECTS=$(LIB)/jnc.o \
	$(LIB)/mem.o \
	$(LIB)/print.o \
	$(LIB)/reader.o \
	$(LIB)/string.o \
	$(LIB)/system.o

all: $(BIN)/jnc
	printf "" | $(BIN)/jnc
	echo "(()))((((" | $(BIN)/jnc
	echo "())())" | $(BIN)/jnc
	$(BIN)/jnc < not_quite_lisp.txt

$(BIN)/jnc: $(OBJECTS)
	@mkdir -p $(BIN)
	gcc $(OBJECTS) -o $(BIN)/jnc

# pattern rules

$(LIB)/%.o: %.s
	@mkdir -p $(LIB)
	gcc -c $< -o $@

# utility targets

clean:
	rm -rf target

# configuration targets

.DELETE_ON_ERROR:
