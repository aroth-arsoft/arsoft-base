SUBDIRS = apt bind cert cron.daily cyrusimapd desktop \
	dhcp devel ldap nagios network pam \
	nfs openvpn pnp4nagios postfix puppet shell spamassassin \
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

	mkdir -p $(DESTDIR)/usr/bin
	mkdir -p $(DESTDIR)/usr/sbin
	mkdir -p $(DESTDIR)/bin
	mkdir -p $(DESTDIR)/sbin
	mkdir -p $(DESTDIR)/etc/default
	install -m 0644 -o root -g root etc_default_arsoft-scripts $(DESTDIR)/etc/default/arsoft-scripts

	for dir in $(SUBDIRS); do \
		${MAKE} -C $$dir install || exit 1; \
	done
