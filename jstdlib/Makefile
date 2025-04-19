TGT=target
BIN=$(TGT)/bin
LIB=$(TGT)/lib
OUT=$(TGT)/out
INCLUDE=../include
MODULES=\
	$(INCLUDE)/mem.s \
	$(INCLUDE)/print.s \
	$(INCLUDE)/reader.s \
	$(INCLUDE)/string.s \
	$(INCLUDE)/system.s \

all: $(LIB)/jstdlib.o

$(LIB)/jstdlib.o: jstdlib.s $(MODULES)
	@mkdir -p $(LIB) $(OUT)
	cat jstdlib.s > $(OUT)/jstdlib.s
	cat $(MODULES) >> $(OUT)/jstdlib.s
	gcc -c $(OUT)/jstdlib.s -o $(LIB)/jstdlib.o

# utility targets

test: all

clean:
	rm -rf $(TGT)

# configuration targets

# if there's an error making a target, delete the target as it's in an unknown state
.DELETE_ON_ERROR:
# don't delete intermediate files created by pattern rules
.SECONDARY:
# never clean up partially-compiled assembly files (with errors)
.PRECIOUS: $(LIB)/*.s
