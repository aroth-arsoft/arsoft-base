.PHONY: all

all:

install:
	mkdir -p $(DESTDIR)/usr/lib/nagios/plugins
	install -m 0755 -o root -g root check_lm_sensors $(DESTDIR)/usr/lib/nagios/plugins/check_lm_sensors
	install -m 0755 -o root -g root check_ssl_cert $(DESTDIR)/usr/lib/nagios/plugins/check_ssl_cert
	install -m 0755 -o root -g root check_apt_upgrade $(DESTDIR)/usr/lib/nagios/plugins/check_apt_upgrade
	mkdir -p $(DESTDIR)/etc/nagios-plugins/config
	install -m 0644 -o root -g root lm_sensors.cfg $(DESTDIR)/etc/nagios-plugins/config/lm_sensors.cfg
	install -m 0644 -o root -g root ssl_cert.cfg $(DESTDIR)/etc/nagios-plugins/config/ssl_cert.cfg
	install -m 0644 -o root -g root apt_upgrade.cfg $(DESTDIR)/etc/nagios-plugins/config/apt_upgrade.cfg
	mkdir -p $(DESTDIR)/usr/share/man/man1
	#install -m 0644 -o root -g root check_ssl_cert.1 $(DESTDIR)/usr/share/man/man1