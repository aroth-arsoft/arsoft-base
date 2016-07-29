macro(install_nagios_plugin)

    install(
        FILES
            ${ARGN}
        DESTINATION
            usr/lib/nagios/plugins
        PERMISSIONS
            ${PERM_0755}
           )
endmacro(install_nagios_plugin)

macro(install_nagios_config)

    install(
        FILES
            ${ARGN}
        DESTINATION
            etc/nagios-plugins/config
           )
endmacro(install_nagios_config)

install(
    FILES
        capture_plugin.pl
        icinga_mail.pl
        nma.pl
    DESTINATION
        usr/lib/nagios
    PERMISSIONS
        ${PERM_0755}
        )

install_nagios_plugin(
    check_apt_upgrade
    check_jenkins_job_time.pl
    check_jenkins.pl
    check_jenkins_slaves.pl
    check_jenkins_version.pl
    check_puppetdb_dups
    check_puppetdb_memory
    check_puppetdb_populations
    check_puppetdb_processed
    check_puppetdb_queue
    check_nagiostats
    check_smb
    check_spamassassin_bayes
    check_spamd.pl
    check_ps
    check_ntp_configured_peer
    check_openvz_ubc.pl
    check_system_user_disk
)

install_nagios_config(
    apt_upgrade.cfg
    dhcp-remote.cfg
    jenkins.cfg
    puppet.cfg
    nagiostats.cfg
    smb.cfg
    nma_notify.cfg
    spamassassin.cfg
    ps.cfg
    ntpex.cfg
    openvz.cfg
    system_user_disk.cfg
)
