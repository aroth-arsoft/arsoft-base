SUBDIRS = apt bind cert cyrusimapd desktop \
	dhcp devel ldap mythtv nagios network \
	nfs openvpn postfix puppet shell spamassassin \
	ssh scm sysinfo tftp vim wine

.PHONY: all

all:

clean:
	for dir in $(SUBDIRS); do \
		${MAKE} -C $$dir clean || exit 1; \
	done

install:
	mkdir -p $(DESTDIR)/etc/cron.daily
	install -m 0755 -o root -g root cron.daily/arsoft-base-repos $(DESTDIR)/etc/cron.daily/arsoft-base-repos
	
	mkdir -p $(DESTDIR)/etc/apt/trusted.gpg.d
	install -m 0644 -o root -g root keyrings/ppa-aroth.gpg $(DESTDIR)/etc/apt/trusted.gpg.d/ppa-aroth.gpg
	install -m 0644 -o root -g root keyrings/puppetlabs.gpg $(DESTDIR)/etc/apt/trusted.gpg.d/puppetlabs.gpg

	mkdir -p $(DESTDIR)/usr/bin
	mkdir -p $(DESTDIR)/usr/sbin
	mkdir -p $(DESTDIR)/bin
	mkdir -p $(DESTDIR)/sbin
	mkdir -p $(DESTDIR)/etc/default
	install -m 0644 -o root -g root etc_default_arsoft-scripts $(DESTDIR)/etc/default/arsoft-scripts

	for dir in $(SUBDIRS); do \
		${MAKE} -C $$dir install || exit 1; \
	done
