APT_SBIN_SCRIPTS := apt-cleanup \
		apt-key-import \
		apt-purge-removed \
		apt-proxy \
		apt-repo

APT_BIN_SCRIPTS := dpkg-info

.PHONY: all

all:

clean:

install:
	install -m 0755 -o root -g root ${APT_BIN_SCRIPTS} $(DESTDIR)/usr/bin
	install -m 0755 -o root -g root ${APT_SBIN_SCRIPTS} $(DESTDIR)/usr/sbin
