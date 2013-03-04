.PHONY: all

all:

clean:

install:
	mkdir -p $(DESTDIR)/usr/lib/nagios/plugins
	install -m 0755 -o root -g root check_lm_sensors $(DESTDIR)/usr/lib/nagios/plugins/check_lm_sensors
	install -m 0755 -o root -g root check_apt_upgrade $(DESTDIR)/usr/lib/nagios/plugins/check_apt_upgrade
	install -m 0755 -o root -g root check_jenkins_job_time.pl $(DESTDIR)/usr/lib/nagios/plugins/check_jenkins_job_time
	install -m 0755 -o root -g root check_jenkins.pl $(DESTDIR)/usr/lib/nagios/plugins/check_jenkins
	install -m 0755 -o root -g root check_jenkins_slaves.pl $(DESTDIR)/usr/lib/nagios/plugins/check_jenkins_slaves
	install -m 0755 -o root -g root check_jenkins_version.pl $(DESTDIR)/usr/lib/nagios/plugins/check_jenkins_version
	install -m 0755 -o root -g root capture_plugin.pl $(DESTDIR)/usr/lib/nagios/plugins/capture_plugin
	mkdir -p $(DESTDIR)/etc/nagios-plugins/config
	install -m 0644 -o root -g root lm_sensors.cfg $(DESTDIR)/etc/nagios-plugins/config/lm_sensors.cfg
	install -m 0644 -o root -g root apt_upgrade.cfg $(DESTDIR)/etc/nagios-plugins/config/apt_upgrade.cfg
	install -m 0644 -o root -g root dhcp-remote.cfg $(DESTDIR)/etc/nagios-plugins/config/dhcp-remote.cfg
	install -m 0644 -o root -g root jenkins.cfg $(DESTDIR)/etc/nagios-plugins/config/jenkins.cfg
	mkdir -p $(DESTDIR)/usr/share/man/man1
	#install -m 0644 -o root -g root check_ssl_cert.1 $(DESTDIR)/usr/share/man/man1