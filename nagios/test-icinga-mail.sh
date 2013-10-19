#!/bin/bash
scriptfile=`readlink -f "$0"`
scriptdir=`dirname "$scriptfile"`

ADMINEMAIL=''
CONTACTEMAIL=''
NOTIFICATIONTYPE=''
HOSTNAME=`hostname -f`
HOSTALIAS=`hostname -f`
HOSTNOTES=''
HOSTSTATE='down'
HOSTSTATETYPE=''
HOSTATTEMPT=1
MAXHOSTATTEMPTS=5
HOSTDURATION='1h'
HOSTNOTIFICATIONNUMBER=1
HOSTCHECKCOMMAND='check_alive'
HOSTLATENCY='1s'
LASTHOSTCHECK=`date -R`
LASTHOSTSTATECHANGE=$LASTHOSTCHECK
LASTHOSTUP=''
LASTHOSTDOWN=''
LASTHOSTUNREACHABLE=''
HOSTOUTPUT=''
HOSTADDRESS='127.0.0.1'
HOSTNOTESURL="http://127.0.0.1/icinga/cgi-bin/extinfo.cgi?type=1&host=$(hostname -f)"
SERVICEDESC=''
SERVICESTATE=''
SERVICENOTIFICATIONNUMBER=1
SERVICEOUTPUT='foo'
LASTSERVICECHECK=`date -R`
LASTSERVICESTATECHANGE=''
LASTSERVICEOK=''
LASTSERVICEWARNING=''
LASTSERVICECRITICAL=''
LASTSERVICEUNKNOWN=''
SERVICESTATETYPE='down'
SERVICEATTEMPT=1
MAXSERVICEATTEMPTS=5
SERVICEDURATION='1h'
SERVICECHECKCOMMAND='check_service'
SERVICEDISPLAYNAME='service desc'
SERVICELATENCY='1s'
SERVICEPERCENTCHANGE=0
SERVICEACTIONURL='http://127.0.0.1/icinga/service/action'
SERVICENOTESURL="http://127.0.0.1/icinga/cgi-bin/extinfo.cgi?type=1&host=$(hostname -f)&service=foo"
SERVICENOTES=''
TIMET=0
PROCESSSTARTTIME=0
TOTALHOSTSUP=0
TOTALHOSTSDOWN=0
TOTALHOSTSUNREACHABLE=0
TOTALSERVICESOK=0
TOTALSERVICESWARNING=0
TOTALSERVICESCRITICAL=0
TOTALSERVICESUNKNOWN=0
TOTALHOSTPROBLEMSUNHANDLED=0
TOTALSERVICEPROBLEMSUNHANDLED=0
NOTIFICATIONAUTHOR=`id -u`
NOTIFICATIONCOMMENT=`id`

$scriptdir/icinga_mail.pl --debug 1 --smtphost 127.0.0.1 --icinga_url "http://localhost/icinga/" --pnp4nagios_url "http://localhost/pnp4nagios/" --originator "$ADMINEMAIL" --recipient "$CONTACTEMAIL" --notificationtype "$NOTIFICATIONTYPE" --adminemail "$ADMINEMAIL" --hostname "$HOSTNAME" --hostalias "$HOSTALIAS" --hostnotes "$HOSTNOTES" --hoststate "$HOSTSTATE" --hoststatetype "$HOSTSTATETYPE" --hostattempt "$HOSTATTEMPT" --maxhostattempt "$MAXHOSTATTEMPTS" --hostduration "$HOSTDURATION" --hostnotificationnumber "$HOSTNOTIFICATIONNUMBER" --hostcheckcommand "$HOSTCHECKCOMMAND" --hostlatency "$HOSTLATENCY" --lasthostcheck "$LASTHOSTCHECK" --lasthoststatechange "$LASTHOSTSTATECHANGE" --lasthostup "$LASTHOSTUP" --lasthostdown "$LASTHOSTDOWN" --lasthostunreachable "$LASTHOSTUNREACHABLE" --hostoutput "$HOSTOUTPUT" --hostaddress "$HOSTADDRESS" --hostnotesurl "$HOSTNOTESURL" --servicedesc "$SERVICEDESC" --servicestate "$SERVICESTATE" --servicenotificationnumber "$SERVICENOTIFICATIONNUMBER" --serviceoutput "$SERVICEOUTPUT" --lastservicecheck "$LASTSERVICECHECK" --lastservicestatechange "$LASTSERVICESTATECHANGE" --lastserviceok "$LASTSERVICEOK" --lastservicewarning "$LASTSERVICEWARNING" --lastservicecritical "$LASTSERVICECRITICAL" --lastserviceunknown "$LASTSERVICEUNKNOWN" --servicestatetype "$SERVICESTATETYPE" --serviceattempt "$SERVICEATTEMPT" --maxserviceattempts "$MAXSERVICEATTEMPTS" --serviceduration "$SERVICEDURATION" --servicecheckcommand "$SERVICECHECKCOMMAND" --servicedisplayname "$SERVICEDISPLAYNAME" --servicelatency "$SERVICELATENCY" --servicepercentchange "$SERVICEPERCENTCHANGE" --serviceactionurl "$SERVICEACTIONURL" --servicenotesurl "$SERVICENOTESURL" --servicenotes "$SERVICENOTES" --timet "$TIMET" --processstarttime "$PROCESSSTARTTIME" --totalhostsup "$TOTALHOSTSUP" --totalhostsdown "$TOTALHOSTSDOWN" --totalhostsunreachable "$TOTALHOSTSUNREACHABLE" --totalservicesok "$TOTALSERVICESOK" --totalserviceswarning "$TOTALSERVICESWARNING" --totalservicescritical "$TOTALSERVICESCRITICAL" --totalservicesunknown "$TOTALSERVICESUNKNOWN" --totalhostproblemsunhandled "$TOTALHOSTPROBLEMSUNHANDLED" --totalserviceproblemsunhandled "$TOTALSERVICEPROBLEMSUNHANDLED" --notificationauthor "$NOTIFICATIONAUTHOR" --notificationcomment "$NOTIFICATIONCOMMENT"
