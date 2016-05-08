SUBDIRS = apt bind cert cron.daily cyrusimapd desktop \
	dhcp devel ldap nagios network nfs openvpn pam \
	pbuilder pnp4nagios postfix puppet shell spamassassin \
	ssh scm sysinfo tftp wine

.PHONY: all

all:

clean:
	for dir in $(SUBDIRS); do \
		${MAKE} -C $$dir clean || exit 1; \
	done

install:
	mkdir -p $(DESTDIR)/etc/apt/trusted.gpg.d
	install -m 0644 -o root -g root keyrings/*.gpg $(DESTDIR)/etc/apt/trusted.gpg.d
	mkdir -p $(DESTDIR)/usr/share/keyrings
	install -m 0644 -o root -g root keyrings/*.gpg $(DESTDIR)/usr/share/keyrings

	mkdir -p $(DESTDIR)/usr/bin
	mkdir -p $(DESTDIR)/usr/sbin
	mkdir -p $(DESTDIR)/bin
	mkdir -p $(DESTDIR)/sbin

	for dir in $(SUBDIRS); do \
		${MAKE} -C $$dir install || exit 1; \
	done
