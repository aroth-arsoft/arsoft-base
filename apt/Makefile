APT_BIN_SCRIPTS := apt-cleanup \
		apt-key-import \
		apt-purge-removed \
		apt-proxy \
		apt-repo \
		dpkg-info

.PHONY: all

all:

clean:

install:
	install -m 0755 -o root -g root ${APT_BIN_SCRIPTS} $(DESTDIR)/usr/bin
