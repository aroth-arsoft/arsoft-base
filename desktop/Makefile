DESKTOP_BIN_SCRIPTS := xpid
DESKTOP_SBIN_SCRIPTS := alsa-info

.PHONY: all

all:

install:
	install -m 0755 -o root -g root ${DESKTOP_BIN_SCRIPTS} $(DESTDIR)/usr/bin
	install -m 0755 -o root -g root ${DESKTOP_SBIN_SCRIPTS} $(DESTDIR)/usr/sbin
