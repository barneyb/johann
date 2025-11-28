TGT = target
BIN = $(TGT)/bin
LIB = $(TGT)/lib
OUT = $(TGT)/out
JNC = ../bin/jnc
JSTDLIB = ../jstdlib/$(LIB)/jstdlib.o
OBJECTS = $(JSTDLIB) \
	$(LIB)/Block.o \
	$(LIB)/Env.o \
	$(LIB)/Symbol.o \
	$(LIB)/Token.o \
	$(LIB)/ast.o \
	$(LIB)/emitter.o \
	$(LIB)/lexer.o \
	$(LIB)/parser.o \
	$(LIB)/to_emitter.o \
	$(LIB)/to_header.o \
	$(LIB)/token_table.o \
	$(LIB)/util.o \
	$(LIB)/version.o \

define CATPILE
	@mkdir -p $(OUT)
	cat $^ > $*.jni
	$(JNC) < $*.jni > $@
endef

all: $(BIN)/jnc
	@echo -----------------------------------------------------
	@for opt in -v --version --help; do \
    	$(BIN)/jnc $$opt; \
		echo -----------------------------------------------------; \
	done

$(OUT)/version.jn $(LIB)/version.o: ./scripts/gen_version.sh
	@mkdir -p $(OUT) $(LIB)
	./scripts/gen_version.sh > $(OUT)/version.jn
	$(JNC) < $(OUT)/version.jn | gcc -o $(LIB)/version.o -x assembler -c -

$(OUT)/lexer.s: $(OUT)/token_table.jnh lexer.jn
	${CATPILE}

$(OUT)/parser.s: $(OUT)/token_table.jnh \
		$(OUT)/ast.jnh \
		parser.jn
	${CATPILE}

$(OUT)/to_emitter.s: $(OUT)/ast.jnh to_emitter.jn
	${CATPILE}

$(OUT)/emitter.s: $(OUT)/token_table.jnh \
		$(OUT)/ast.jnh \
		emitter.jn
	${CATPILE}

$(JSTDLIB)::
	$(MAKE) -C ../jstdlib

# Pattern targets

$(BIN)/%: $(LIB)/%.o $(OBJECTS)
	@mkdir -p $(BIN)
	gcc -o $@ -dead_strip $^
	@rm -f $(LIB)/version.o # blow away version info, so it'll rebuild next time

$(OUT)/%.s: %.jn
	@mkdir -p $(OUT)
	$(JNC) < $< > $@

$(OUT)/%.jnh: %.jn $(JNC)
	@mkdir -p $(OUT)
	$(JNC) --header < $< > $@
	$(JNC) < $@ > /dev/null

$(LIB)/%.o: $(OUT)/%.s
	@mkdir -p $(LIB)
	gcc -o $@ -c $<

# Utility targets

test: all
	$(MAKE) -C tests all
	$(MAKE) -C params test

touch_all:
	find . -name '*.jn' | xargs touch

clean:
	rm -rf $(TGT)
	$(MAKE) -C ../jstdlib clean
	$(MAKE) -C tests clean
	$(MAKE) -C params clean

# configuration targets

# don't delete intermediate files created by pattern rules
.SECONDARY:
# never clean up partially-compiled assembly files (with errors)
.PRECIOUS: $(OUT)/*.s
