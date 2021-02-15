# SPDX-License-Identifier: GPL-2.0

SUBDIRS = ksrc src

all:
	@for s in $(SUBDIRS); do \
		make -C $$s all; \
	done

clean:
	@for s in $(SUBDIRS); do \
		make -C $$s clean; \
	done
