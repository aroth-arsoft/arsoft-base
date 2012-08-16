.PHONY: all

all:

install:
	mkdir -p $(DESTDIR)/usr/lib/nagios/plugins
	install -m 0755 -o root -g root check_fritzbox $(DESTDIR)/usr/lib/nagios/plugins/check_fritzbox
	install -m 0755 -o root -g root check_lm_sensors $(DESTDIR)/usr/lib/nagios/plugins/check_lm_sensors
	mkdir -p $(DESTDIR)/etc/nagios-plugins/config
	install -m 0644 -o root -g root fritzbox.cfg $(DESTDIR)/etc/nagios-plugins/config/fritzbox.cfg
	install -m 0644 -o root -g root lm_sensors.cfg $(DESTDIR)/etc/nagios-plugins/config/lm_sensors.cfg
