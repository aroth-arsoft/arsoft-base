LDAP_SBIN_SCRIPTS := autofs-ldap-auth \
		schema2ldif \
		slapd-clean-db \
		slapd-online-config \
		slapd-backup

.PHONY: all

all:

install:
	install -m 0755 -o root -g root ${LDAP_SBIN_SCRIPTS} $(DESTDIR)/usr/sbin
