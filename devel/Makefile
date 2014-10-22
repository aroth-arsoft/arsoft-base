DEVEL_BIN_SCRIPTS := ppa_publish ppa_copy git-branch-diff

.PHONY: all

all:

clean:

install:
	install -m 0755 -o root -g root ${DEVEL_BIN_SCRIPTS} $(DESTDIR)/usr/bin
	mkdir -p $(DESTDIR)/usr/share/arsoft-base/devel
	install -m 0755 -o root -g root gdb-add-index $(DESTDIR)/usr/share/arsoft-base/devel
