PBUILDER_BIN_SCRIPTS := pbuildmgr

.PHONY: all

all:

clean:

install:
	mkdir -p $(DESTDIR)/etc/arsoft/pbuilder/hook.d
	mkdir -p $(DESTDIR)/etc/arsoft/pbuilder/conf.d
	install -m 0755 -o root -g root hook/* $(DESTDIR)/etc/arsoft/pbuilder/hook.d
	chmod 644 $(DESTDIR)/etc/arsoft/pbuilder/hook.d/README
	# remove icecc and no compression
	rm $(DESTDIR)/etc/arsoft/pbuilder/hook.d/D20icecc
	rm $(DESTDIR)/etc/arsoft/pbuilder/hook.d/D99nocompression
	install -m 0755 -o root -g root ${PBUILDER_BIN_SCRIPTS} $(DESTDIR)/usr/bin
