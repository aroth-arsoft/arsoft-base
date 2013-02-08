.PHONY: all

CERTSDIR = /usr/share/ca-certificates
SUBDIRS = arsoft fastprotect
CERT_BIN_SCRIPTS := nss-import-cert

all:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir all; \
	done

clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done

install:
	install -m 0755 -o root -g root ${CERT_BIN_SCRIPTS} $(DESTDIR)/usr/bin
	mkdir -p $(DESTDIR)/$(CERTSDIR)
	for dir in $(SUBDIRS); do \
		mkdir $(DESTDIR)/$(CERTSDIR)/$$dir; \
		$(MAKE) -C $$dir install CERTSDIR=$(DESTDIR)/$(CERTSDIR)/$$dir; \
	done
