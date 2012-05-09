.PHONY: all

all:

install:
	mkdir -p $(DESTDIR)/etc/cron.daily
	install -m 0755 -o root -g root cron.daily/arsoft-base-repos $(DESTDIR)/etc/cron.daily/arsoft-base-repos
	
	mkdir -p $(DESTDIR)/etc/apt/trusted.gpg.d
	install -m 0644 -o root -g root keyrings/ppa-aroth.gpg $(DESTDIR)/etc/apt/trusted.gpg.d/ppa-aroth.gpg
	install -m 0644 -o root -g root keyrings/puppetlabs.gpg $(DESTDIR)/etc/apt/trusted.gpg.d/puppetlabs.gpg

	mkdir -p $(DESTDIR)/usr/share/arsoft-base/vim
	install -m 0644 -o root -g root vim/vimrc $(DESTDIR)/usr/share/arsoft-base/vim/vimrc
	
	mkdir -p $(DESTDIR)/usr/share/arsoft-base/bash
	install -m 0644 -o root -g root bash/bash.bashrc $(DESTDIR)/usr/share/arsoft-base/bash/bash.bashrc
	
	mkdir -p $(DESTDIR)/usr/sbin
	install -m 0755 -o root -g root openvpn/openvpn-status $(DESTDIR)/usr/sbin
	install -m 0755 -o root -g root openvpn/openvpn-zip-config $(DESTDIR)/usr/sbin
