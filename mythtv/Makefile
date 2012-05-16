MYTHTV_BIN_SCRIPTS := mythtv-restart \
		mythtv-startx-tty \
		mythtv-webradio
MYTHTV_SHARE_SCRIPTS := mythadder.py 

.PHONY: all

all:

install:
	mkdir -p $(DESTDIR)/usr/share/mythtv
	install -m 0755 -o root -g root ${MYTHTV_SHARE_SCRIPTS} $(DESTDIR)/usr/share/mythtv
	install -m 0755 -o root -g root ${MYTHTV_BIN_SCRIPTS} $(DESTDIR)/usr/bin
