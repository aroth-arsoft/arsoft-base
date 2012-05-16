NETWORK_SBIN_SCRIPTS := managehosts

.PHONY: all

all:

install:
#	mkdir -p $(DESTDIR)/etc/network/if-down.d
#	install -m 0755 -o root -g root network/lo-down-script $(DESTDIR)/etc/network/if-down.d/00-lo-down
#	mkdir -p $(DESTDIR)/etc/network/if-up.d
#	install -m 0755 -o root -g root network/lo-up-script $(DESTDIR)/etc/network/if-up.d/zz-lo-up
	install -m 0755 -o root -g root ${NETWORK_SBIN_SCRIPTS} $(DESTDIR)/usr/sbin
