TGT = target
BIN = $(TGT)/bin
LIB = $(TGT)/lib
OUT = $(TGT)/out
JNC = ../$(BIN)/jnc
JSTDLIB = ../../jstdlib/$(LIB)/jstdlib.o

all: not_quite_lisp \
	constants \
	sum \
	print_one \
	store_load \

constants: $(BIN)/constants constants.expected.txt
	$(BIN)/constants > $(OUT)/constants.actual.txt
	diff -u constants.expected.txt $(OUT)/constants.actual.txt

not_quite_lisp: $(BIN)/not_quite_lisp not_quite_lisp.expected.txt
	echo "()(())((()))())(()))))" | $(BIN)/not_quite_lisp > $(OUT)/not_quite_lisp.actual.txt
	diff -u not_quite_lisp.expected.txt $(OUT)/not_quite_lisp.actual.txt

sum: $(BIN)/sum sum.expected.txt
	echo "1 23 456 100000 1 5" | $(BIN)/sum > $(OUT)/sum.actual.txt
	diff -u sum.expected.txt $(OUT)/sum.actual.txt

print_one: $(BIN)/print_one print_one.expected.txt
	$(BIN)/print_one > $(OUT)/print_one.actual.txt
	diff -u print_one.expected.txt $(OUT)/print_one.actual.txt

store_load: $(BIN)/store_load store_load.expected.txt
	$(BIN)/store_load > $(OUT)/store_load.actual.txt
	diff -u store_load.expected.txt $(OUT)/store_load.actual.txt

# Pattern targets

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

# if there's an error making a target, delete the target as it's in an unknown state
.DELETE_ON_ERROR:
# don't delete intermediate files created by pattern rules
.SECONDARY:
# never clean up partially-compiled assembly files (with errors)
.PRECIOUS: $(OUT)/*.s
