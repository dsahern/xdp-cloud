# SPDX-License-Identifier: GPL-2.0

PROGS += tap_fwd

VPATH := .

CFLAGS += -O2 -g -Wall

all: $(PROGS)

$(BINDIR)%: $(OBJDIR)%.o
	$(QUIET_LINK)$(CC) $(CFLAGS) $^ -o $@

clean:
	@rm -rf $(PROGS)
