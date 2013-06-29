SHELL_BIN_SCRIPTS := cp_p

.PHONY: all

all:

clean:

install:
	mkdir -p $(DESTDIR)/usr/share/arsoft-base/bash
	install -m 0644 -o root -g root bash.bashrc $(DESTDIR)/usr/share/arsoft-base/bash/bash.bashrc
	ln -s /usr/share/arsoft-base/bash/bash.bashrc $(DESTDIR)/etc/bash.bashrc
	install -m 0644 -o root -g root profile $(DESTDIR)/usr/share/arsoft-base/profile
	ln -s /usr/share/arsoft-base/profile $(DESTDIR)/etc/profile
	install -m 0755 -o root -g root ${SHELL_BIN_SCRIPTS} $(DESTDIR)/usr/bin
	install -d -m 0755 -o root -g root $(DESTDIR)/etc/arsoft-base/system-startup.d
	install -d -m 0755 -o root -g root $(DESTDIR)/etc/arsoft-base/system-shutdown.d
