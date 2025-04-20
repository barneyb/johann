TGT = target
BIN = $(TGT)/bin
LIB = $(TGT)/lib
OUT = $(TGT)/out
INCLUDE = ../include
OBJECTS = \
	$(LIB)/mem.o \
	$(LIB)/print.o \
	$(LIB)/reader.o \
	$(LIB)/string.o \
	$(LIB)/system.o \

all: $(LIB)/jstdlib.o

$(LIB)/jstdlib.o: $(LIB)/_jstdlib.o $(OBJECTS)
	@mkdir -p $(LIB)
	gcc -o $(LIB)/jstdlib.o $(LD_OPTS) -nostdlib -r $(LIB)/_jstdlib.o $(OBJECTS)

# Pattern targets

$(LIB)/_%.o: %.s
	@mkdir -p $(LIB)
	gcc -o $@ -c $<

$(LIB)/%.o: $(INCLUDE)/%.s
	@mkdir -p $(LIB)
	gcc -o $@ -c $<

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
