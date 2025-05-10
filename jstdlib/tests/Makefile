TGT = target
BIN = $(TGT)/bin
LIB = $(TGT)/lib
OUT = $(TGT)/out
JNC = ../../jnc/$(BIN)/jnc
JSTDLIB = ../$(LIB)/jstdlib.o

all: hello_world \
	isspace \
	isdigit \
	printf \
	putchar \
	symbols \
	getchar \

hello_world: $(BIN)/hello_world hello_world.expected.txt
	@mkdir -p $(OUT)
	echo | $(BIN)/hello_world > $(OUT)/hello_world.actual.txt
	echo Johann | $(BIN)/hello_world >> $(OUT)/hello_world.actual.txt
	$(BIN)/hello_world Barney et al >> $(OUT)/hello_world.actual.txt
	echo 'Barney the Hobgoblin' \
		| $(BIN)/hello_world >> $(OUT)/hello_world.actual.txt
	$(BIN)/hello_world 'Barney the Hobgoblin' >> $(OUT)/hello_world.actual.txt
	echo "three\nshort\nlines" | $(BIN)/hello_world >> $(OUT)/hello_world.actual.txt
	diff -u hello_world.expected.txt $(OUT)/hello_world.actual.txt

isspace: $(BIN)/isspace isspace.expected.txt
	@mkdir -p $(OUT)
	$(BIN)/isspace > $(OUT)/isspace.actual.txt
	diff -u isspace.expected.txt $(OUT)/isspace.actual.txt

isdigit: $(BIN)/isdigit isdigit.expected.txt
	@mkdir -p $(OUT)
	$(BIN)/isdigit > $(OUT)/isdigit.actual.txt
	diff -u isdigit.expected.txt $(OUT)/isdigit.actual.txt

printf: $(BIN)/printf printf.expected.txt
	@mkdir -p $(OUT)
	$(BIN)/printf > $(OUT)/printf.actual.txt
	diff -u printf.expected.txt $(OUT)/printf.actual.txt

putchar: $(BIN)/putchar putchar.expected.txt
	@mkdir -p $(OUT)
	$(BIN)/putchar > $(OUT)/putchar.actual.txt
	diff -u putchar.expected.txt $(OUT)/putchar.actual.txt

symbols: $(BIN)/symbols symbols.expected.txt
	@mkdir -p $(OUT)
	$(BIN)/symbols > $(OUT)/symbols.actual.txt
	diff -u symbols.expected.txt $(OUT)/symbols.actual.txt

getchar: $(BIN)/getchar getchar.expected.txt
	@mkdir -p $(OUT)
	echo "qwerty\nasdf" | $(BIN)/getchar > $(OUT)/getchar.actual.txt
	diff -u getchar.expected.txt $(OUT)/getchar.actual.txt

# Pattern targets

$(BIN)/%: $(LIB)/%.o $(JSTDLIB)
	@mkdir -p $(BIN)
	gcc $^ -o $@

$(LIB)/%.o: $(OUT)/%.s
	@mkdir -p $(LIB)
	gcc -c $< -o $@

$(LIB)/%.o: %.s
	@mkdir -p $(LIB)
	gcc -c $< -o $@

$(OUT)/%.s: %.jn $(JNC)
	@mkdir -p $(OUT)
	$(JNC) < $< > $@

# Utility targets

$(JSTDLIB)::
	$(MAKE) -C ..

clean:
	rm -rf $(TGT)

# configuration targets

# don't delete intermediate files created by pattern rules
.SECONDARY:
# never clean up partially-compiled assembly files (with errors)
.PRECIOUS: $(OUT)/*.s
