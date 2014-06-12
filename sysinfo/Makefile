SYSINFO_BIN_SCRIPTS := pmem
SYSINFO_SBIN_SCRIPTS := biosinfo \
		motherboardinfo

.PHONY: all

all:

clean:

install:
	install -m 0755 -o root -g root ${SYSINFO_BIN_SCRIPTS} $(DESTDIR)/usr/bin
	install -m 0755 -o root -g root ${SYSINFO_SBIN_SCRIPTS} $(DESTDIR)/usr/sbin
