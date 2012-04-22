.PHONY: all

all:

install:
	mkdir -p $(DESTDIR)/etc/cron.daily
	install -m 0755 -o root -g root cron.daily/arsoft-base-repos $(DESTDIR)/etc/cron.daily/arsoft-base-repos
	
	mkdir -p $(DESTDIR)/usr/share/keyrings
	install -m 0644 -o root -g root keyrings/ppa-aroth.gpg $(DESTDIR)/usr/share/keyrings/ppa-aroth.gpg

	mkdir -p $(DESTDIR)/usr/share/arsoft-base/vim
	install -m 0644 -o root -g root vim/vimrc $(DESTDIR)/usr/share/arsoft-base/vim/vimrc
	
	mkdir -p $(DESTDIR)/usr/share/arsoft-base/bash
	install -m 0644 -o root -g root bash/bash.bashrc $(DESTDIR)/usr/share/arsoft-base/bash/bash.bashrc
	