TGT = target
BIN = $(TGT)/bin
LIB = $(TGT)/lib
OUT = $(TGT)/out
JSTDLIB = ../$(LIB)/jstdlib.o

all: \
	ArrayList_test \
	Queue_tests \
	StringBuilderTest \
	TreeMap_test \
	allocations \
	getchar \
	hello_world \
	isdigit \
	isspace \
	printf \
	putchar \
	quicksort_test \
	read_line_test \
	strcmp_test \
	string_search \
	substr \
	symbols \

	# verify there aren't any memory complaints
	find $(OUT) -name '*.s' | (! xargs grep -A3 '; MEM: ' )

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

getchar: $(BIN)/getchar getchar.expected.txt
	@mkdir -p $(OUT)
	echo "qwerty\nasdf" | $(BIN)/getchar > $(OUT)/getchar.actual.txt
	diff -u getchar.expected.txt $(OUT)/getchar.actual.txt

read_line_test: $(BIN)/read_line_test read_line_test.expected.txt
	@mkdir -p $(OUT)
	echo "qwerty\nasdf\n\nzxcv\n\n" | $(BIN)/read_line_test > $(OUT)/read_line_test.actual.txt
	diff -u read_line_test.expected.txt $(OUT)/read_line_test.actual.txt

# Pattern targets

% : %.s # cancel this (default) rule

%: $(BIN)/% %.expected.txt
	@mkdir -p $(OUT)
	$< > $(OUT)/$@.actual.txt
	diff -u --text $@.expected.txt $(OUT)/$@.actual.txt

$(BIN)/%: $(LIB)/%.o $(JSTDLIB)
	@mkdir -p $(BIN)
	gcc $^ -o $@

$(LIB)/%.o: $(OUT)/%.s
	@mkdir -p $(LIB)
	gcc -c $< -o $@

$(LIB)/%.o: %.s
	@mkdir -p $(LIB)
	gcc -c $< -o $@

$(OUT)/%.s: %.jn
	@mkdir -p $(OUT)
	../../bin/jnc < $< > $@

# Utility targets

$(JSTDLIB):
	$(MAKE) -C ..

clean:
	rm -rf $(TGT)

# configuration targets

# don't delete intermediate files created by pattern rules
.SECONDARY:
# never clean up partially-compiled assembly files (with errors)
.PRECIOUS: $(OUT)/*.s
