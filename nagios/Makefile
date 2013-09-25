.PHONY: all

all:

clean:

install:
	mkdir -p $(DESTDIR)/usr/lib/nagios/plugins
	install -m 0755 -o root -g root check_apt_upgrade $(DESTDIR)/usr/lib/nagios/plugins/check_apt_upgrade
	install -m 0755 -o root -g root check_jenkins_job_time.pl $(DESTDIR)/usr/lib/nagios/plugins/check_jenkins_job_time.pl
	install -m 0755 -o root -g root check_jenkins.pl $(DESTDIR)/usr/lib/nagios/plugins/check_jenkins.pl
	install -m 0755 -o root -g root check_jenkins_slaves.pl $(DESTDIR)/usr/lib/nagios/plugins/check_jenkins_slaves.pl
	install -m 0755 -o root -g root check_jenkins_version.pl $(DESTDIR)/usr/lib/nagios/plugins/check_jenkins_version.pl
	install -m 0755 -o root -g root capture_plugin.pl $(DESTDIR)/usr/lib/nagios/plugins/capture_plugin.pl
	install -m 0755 -o root -g root icinga_mail.pl $(DESTDIR)/usr/lib/nagios/icinga_mail.pl
	install -m 0755 -o root -g root nma.pl $(DESTDIR)/usr/lib/nagios/nma.pl
	install -m 0755 -o root -g root check_puppetdb_dups $(DESTDIR)/usr/lib/nagios/plugins/check_puppetdb_dups
	install -m 0755 -o root -g root check_puppetdb_memory $(DESTDIR)/usr/lib/nagios/plugins/check_puppetdb_memory
	install -m 0755 -o root -g root check_puppetdb_populations $(DESTDIR)/usr/lib/nagios/plugins/check_puppetdb_populations
	install -m 0755 -o root -g root check_puppetdb_processed $(DESTDIR)/usr/lib/nagios/plugins/check_puppetdb_processed
	install -m 0755 -o root -g root check_puppetdb_queue $(DESTDIR)/usr/lib/nagios/plugins/check_puppetdb_queue
	install -m 0755 -o root -g root check_nagiostats $(DESTDIR)/usr/lib/nagios/plugins/check_nagiostats
	install -m 0755 -o root -g root check_smb $(DESTDIR)/usr/lib/nagios/plugins/check_smb
	install -m 0755 -o root -g root check_spamassassin_bayes $(DESTDIR)/usr/lib/nagios/plugins/check_spamassassin_bayes
	install -m 0755 -o root -g root check_spamd.pl $(DESTDIR)/usr/lib/nagios/plugins/check_spamd.pl
	install -m 0755 -o root -g root check_ps $(DESTDIR)/usr/lib/nagios/plugins/check_ps
	install -m 0755 -o root -g root check_ntp_configured_peer $(DESTDIR)/usr/lib/nagios/plugins/check_ntp_configured_peer
	install -m 0755 -o root -g root check_openvz_ubc.pl $(DESTDIR)/usr/lib/nagios/plugins/check_openvz_ubc.pl
	mkdir -p $(DESTDIR)/etc/nagios-plugins/config
	install -m 0644 -o root -g root apt_upgrade.cfg $(DESTDIR)/etc/nagios-plugins/config/apt_upgrade.cfg
	install -m 0644 -o root -g root dhcp-remote.cfg $(DESTDIR)/etc/nagios-plugins/config/dhcp-remote.cfg
	install -m 0644 -o root -g root jenkins.cfg $(DESTDIR)/etc/nagios-plugins/config/jenkins.cfg
	install -m 0644 -o root -g root puppet.cfg $(DESTDIR)/etc/nagios-plugins/config/puppet.cfg
	install -m 0644 -o root -g root nagiostats.cfg $(DESTDIR)/etc/nagios-plugins/config/nagiostats.cfg
	install -m 0644 -o root -g root smb.cfg $(DESTDIR)/etc/nagios-plugins/config/smb.cfg
	install -m 0644 -o root -g root nma_notify.cfg $(DESTDIR)/etc/nagios-plugins/config/nma_notify.cfg
	install -m 0644 -o root -g root spamassassin.cfg $(DESTDIR)/etc/nagios-plugins/config/spamassassin.cfg
	install -m 0644 -o root -g root ps.cfg $(DESTDIR)/etc/nagios-plugins/config/ps.cfg
	install -m 0644 -o root -g root ntpex.cfg $(DESTDIR)/etc/nagios-plugins/config/ntpex.cfg
	install -m 0644 -o root -g root openvz.cfg $(DESTDIR)/etc/nagios-plugins/config/openvz.cfg
	mkdir -p $(DESTDIR)/usr/share/man/man1
	# keep the utils.sh in the directory (from nagios-plugins), but do not install it:
	#install -m 0755 -o root -g root utils.sh $(DESTDIR)/usr/lib/nagios/plugins/utils.sh