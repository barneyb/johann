LIB=target/lib
BIN=target/bin
OBJECTS=$(LIB)/jnc.o $(LIB)/system.o

all: $(BIN)/jnc
	echo "(()))((((" | $(BIN)/jnc
	echo "((())))))" | $(BIN)/jnc
	@echo "\nWATCH OUT!\n    Little-endian decimal results (read right-to-left).\n"
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
