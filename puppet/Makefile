PUPPET_BIN_SCRIPTS := puppet-template-check \
		puppet-function-check \
		puppet-clean-ssl

.PHONY: all

all:

clean:

install:
	install -m 0755 -o root -g root ${PUPPET_BIN_SCRIPTS} $(DESTDIR)/usr/bin
