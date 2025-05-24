TGT = target
BIN = $(TGT)/bin
LIB = $(TGT)/lib
OUT = $(TGT)/out
JNC = ../$(BIN)/jnc
JSTDLIB = ../../jstdlib/$(LIB)/jstdlib.o

all: \
	collatz \
	constants \
	control_flow \
	literals \
	not_quite_lisp \
	print_one \
	reverse \
	store_load \
	strings \
	sum \
	zero \

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

# Pattern targets

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
