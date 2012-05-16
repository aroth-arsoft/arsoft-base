POSTFIX_BIN_SCRIPTS := postfix-delete \
		postfix-sendmail \
		postfix-flush-queue \
		postfix-queue-rm \
		postfix-mailstat \
		postfix-update-maps
		
POSTFIX_SBIN_SCRIPTS := postfix-ldap

.PHONY: all

all:

install:
	install -m 0755 -o root -g root ${POSTFIX_BIN_SCRIPTS} $(DESTDIR)/usr/bin
	install -m 0755 -o root -g root ${POSTFIX_SBIN_SCRIPTS} $(DESTDIR)/usr/sbin
