PUPPET_BIN_SCRIPTS := puppet-template-check \
		puppet-function-check \
		puppet-clean-ssl
PUPPET_SBIN_SCRIPTS := puppet-node

.PHONY: all

all:

install:
	install -m 0755 -o root -g root ${PUPPET_SBIN_SCRIPTS} $(DESTDIR)/usr/sbin
	install -m 0755 -o root -g root ${PUPPET_BIN_SCRIPTS} $(DESTDIR)/usr/bin
