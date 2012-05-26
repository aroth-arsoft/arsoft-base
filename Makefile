SUBDIRS = apt bash bind cyrusimapd desktop \
	dhcp devel kernel ldap mythtv network \
	openvpn postfix puppet svn sysinfo \
	vim

.PHONY: all

all:

install:
	mkdir -p $(DESTDIR)/etc/cron.daily
	install -m 0755 -o root -g root cron.daily/arsoft-base-repos $(DESTDIR)/etc/cron.daily/arsoft-base-repos
	
	mkdir -p $(DESTDIR)/etc/apt/trusted.gpg.d
	install -m 0644 -o root -g root keyrings/ppa-aroth.gpg $(DESTDIR)/etc/apt/trusted.gpg.d/ppa-aroth.gpg
	install -m 0644 -o root -g root keyrings/puppetlabs.gpg $(DESTDIR)/etc/apt/trusted.gpg.d/puppetlabs.gpg

	mkdir -p $(DESTDIR)/usr/bin
	mkdir -p $(DESTDIR)/usr/sbin
	mkdir -p $(DESTDIR)/etc/default
	install -m 0644 -o root -g root etc_default_arsoft-scripts $(DESTDIR)/etc/default/arsoft-scripts
	
	for dir in $(SUBDIRS); do \
		(cd $$dir; ${MAKE} install); \
	done
