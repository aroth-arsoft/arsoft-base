TFTP_SBIN_SCRIPTS := tftp-update-installers

.PHONY: all

all:

install:
	install -m 0755 -o root -g root ${TFTP_SBIN_SCRIPTS} $(DESTDIR)/usr/sbin
	#install -m 0755 -o root -g root system-info-check $(DESTDIR)/etc/cron.daily
