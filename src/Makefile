# SPDX-License-Identifier: GPL-2.0

include ../config.mk

ifneq (,$(BUILDDIR))
OBJDIR = $(BUILDDIR)/src/obj/
else
OBJDIR = obj/
endif

ifneq (,$(BUILDDIR))
BINDIR = $(BUILDDIR)/src/bin/
else
BINDIR = bin/
endif

MODS += $(BINDIR)xdp_l2fwd

VPATH := .

CFLAGS += -O2 -g -Wall

INCLUDES  = -I../include

COMMON += $(OBJDIR)libbpf_helpers.o
COMMON += $(OBJDIR)str_utils.o

.PRECIOUS: $(OBJDIR)%.o

all: build $(MODS)

build:
	@mkdir -p $(OBJDIR) $(BINDIR)

$(BINDIR)%: $(OBJDIR)%.o $(COMMON)
	$(QUIET_LINK)$(CC) $(INCLUDES) $(DEFS) $(CFLAGS) $^ -o $@ $(LDLIBS)

$(BINDIR)xdp_%: $(OBJDIR)xdp_%_user.o $(COMMON)
	$(QUIET_LINK)$(CC) $(INCLUDES) $(DEFS) $(CFLAGS) $^ -o $@ $(LDLIBS)

$(OBJDIR)%.o: %.c
	$(QUIET_CC)$(CC) $(INCLUDES) $(DEFS) $(CFLAGS) -c $^ -o $@

clean:
	@rm -rf $(OBJDIR) $(BINDIR)
