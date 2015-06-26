LDAP_BIN_SCRIPTS := schema2ldif
LDAP_SBIN_SCRIPTS := slapd-clean-db \
		slapd-online-config \
		slapd-backup \
		slapd-debug

.PHONY: all

all:

clean:

install:
	install -m 0755 -o root -g root ${LDAP_BIN_SCRIPTS} $(DESTDIR)/usr/bin
	install -m 0755 -o root -g root ${LDAP_SBIN_SCRIPTS} $(DESTDIR)/usr/sbin
