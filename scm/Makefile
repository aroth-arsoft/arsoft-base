SVN_BIN_SCRIPTS := mimediff \
		oodiff \
		zipdiff \
		imagediff \
		git-notifier

.PHONY: all

all:

install:
	install -m 0755 -o root -g root ${SVN_BIN_SCRIPTS} $(DESTDIR)/usr/bin
