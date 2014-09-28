SSH_BIN_SCRIPTS := ssh-nogss ssh-nopubkey ssh-setup-keys sshsudo

.PHONY: all

all:

clean:

install:
	install -m 0755 -o root -g root ${SSH_BIN_SCRIPTS} $(DESTDIR)/usr/bin
