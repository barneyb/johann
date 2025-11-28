TGT = target
BIN = $(TGT)/bin
LIB = $(TGT)/lib
OUT = $(TGT)/out
JNC = ../$(BIN)/jnc
JSTDLIB = ../../jstdlib/$(LIB)/jstdlib.o

all: \
	$(LIB)/a_syntactic_menagerie.o \
	$(OUT)/a_syntactic_menagerie.strict.s \
	arrays \
	bit_ops \
	collatz \
	constants \
	control_flow \
	function_pointers \
	if_else \
	line_client \
	lisp \
	literals \
	logical_ops \
	not_quite_lisp \
	print_one \
	pseudo_methods \
	reverse \
	shift_ops \
	store_load \
	strings \
	sum \
	zero \

	@echo "Memory complaints:"
	@find $(OUT) -name '*.s' -o -name '*.jnh' | (! xargs grep -A3 '; MEM: ')

# non-standard targets

not_quite_lisp: $(BIN)/not_quite_lisp not_quite_lisp.expected.txt
	echo "()(())((()))())(()))))" | $(BIN)/not_quite_lisp > $(OUT)/not_quite_lisp.actual.txt
	diff -u not_quite_lisp.expected.txt $(OUT)/not_quite_lisp.actual.txt

sum: $(BIN)/sum sum.expected.txt
	echo "1 -23 456 100000 1 -5" | $(BIN)/sum > $(OUT)/sum.actual.txt
	diff -u sum.expected.txt $(OUT)/sum.actual.txt

collatz: $(BIN)/collatz collatz.expected.txt
	$(BIN)/collatz 5 12 19 27 > $(OUT)/collatz.actual.txt
	diff -u collatz.expected.txt $(OUT)/collatz.actual.txt

define CATPILE
	@mkdir -p $(OUT)
	cat $^ > $*.jni
	$(JNC) --strict < $*.jni > $@
endef

define HEADPILE
	@mkdir -p $(OUT)
	$(JNC) --header < $< > $@
	@# compile the header (a no-op) to ensure validity
	$(JNC) --strict < $@ > /dev/null
endef

$(OUT)/line.s: $(OUT)/allocator.jstd.jnh line.jn
	${CATPILE}

$(OUT)/line_client.s: $(OUT)/line.jnh $(OUT)/arraylist_utils.jnh $(OUT)/ArrayList.jstd.jnh $(OUT)/io.jstd.jnh line_client.jn
	${CATPILE}

$(OUT)/arraylist_utils.s: $(OUT)/ArrayList.jstd.jnh arraylist_utils.jn
	${CATPILE}

$(BIN)/line_client: $(LIB)/line_client.o $(LIB)/arraylist_utils.o $(LIB)/line.o $(JSTDLIB)
	@mkdir -p $(BIN)
	gcc $^ -o $@

# Pattern targets

$(OUT)/%.jstd.jnh: ../../jstdlib/%.jn $(JNC)
	${HEADPILE}

$(BIN)/%Test: $(LIB)/%Test.o ../$(LIB)/%.jn.o $(JSTDLIB)
	@mkdir -p $(BIN)
	gcc $^ -o $@

%: $(BIN)/% %.expected.txt
	$< > $(OUT)/$@.actual.txt
	diff -u $@.expected.txt $(OUT)/$@.actual.txt

$(BIN)/%: $(LIB)/%.o $(JSTDLIB)
	@mkdir -p $(BIN)
	gcc $^ -o $@

$(LIB)/%.o: $(OUT)/%.s
	@mkdir -p $(LIB)
	gcc -c $< -o $@

$(OUT)/%.s: %.jn $(JNC)
	@mkdir -p $(OUT)
	$(JNC) < $< > $@

$(OUT)/%.strict.s: %.jn $(JNC)
	@mkdir -p $(OUT)
	$(JNC) --strict < $< > $@

$(OUT)/%.jnh: %.jn $(JNC)
	${HEADPILE}

# Utility targets

$(JNC):
	$(MAKE) -C ..

$(JSTDLIB):
	$(MAKE) -C ../../jstdlib

clean:
	rm -rf $(TGT)

# configuration targets

# don't delete intermediate files created by pattern rules
.SECONDARY:
# never clean up partially-compiled assembly files (with errors)
.PRECIOUS: $(OUT)/*.s
