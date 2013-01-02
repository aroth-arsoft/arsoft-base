.PHONY: all

CERTSDIR = /usr/share/ca-certificates
SUBDIRS = arsoft fastprotect

all:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir all; \
	done

clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done

install:
	mkdir -p $(DESTDIR)/$(CERTSDIR)
	for dir in $(SUBDIRS); do \
		mkdir $(DESTDIR)/$(CERTSDIR)/$$dir; \
		$(MAKE) -C $$dir install CERTSDIR=$(DESTDIR)/$(CERTSDIR)/$$dir; \
	done
