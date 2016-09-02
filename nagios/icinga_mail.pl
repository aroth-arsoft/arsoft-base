#!/usr/bin/perl
# icinga: -epn
#
#=BEGIN icinga_mail GPL
#
# This script produces more readable and more fancy emails from icinga
#
# Copyright(c) 2011 - Jens Schanz - <mail@jensschanz.de>
# https://blog.jensschanz.de
#
# This script may be licensed under the terms of of the
# GNU General Public License Version 2 (the ``GPL'').
#
# Software distributed under the License is distributed
# on an ``AS IS'' basis, WITHOUT WARRANTY OF ANY KIND, either
# express or implied. See the GPL for the specific language
# governing rights and limitations.
#
# You should have received a copy of the GPL along with this
# program. If not, go to http://www.gnu.org/licenses/gpl.html
# or write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
#=END icinga_mail GPL
#
#
#	BUILD:
#	2012-02-27		0.1.0		->	first working build (Jens Schanz)
#	2012-02-28		0.1.1		->	link to pnp4nagios added. png will be sent as base64 encoded string to show this
#									on external locations where no direct link to icinga/pnp4nagios is possible.
#	2012-03-01		0.2.0		->	nagiosbp over json integrated. if an service like "check_bp_" is detected, 
#									a query to nagiosbp will be sent to integrate the business process state dependent on nagiosbp_state
#									in the message body.
#	2012-03-06		0.2.1		->	host notifications added
#	2013-03-27		0.2.2		->	LASTSERVICEINKNOWN in LASTSERVICEUNKNOWN changed
#	2013-12-31		0.2.3		->	bugfix for notificationtype detection
#
#
use warnings;
use strict;
use Getopt::Long;

# load json extesion to decode nagiosbp status
use WWW::Mechanize;
use JSON -support_by_pp;
use Data::Dumper;
use HTML::Entities;

# define all used variables
# generic stuff
my $debug = "0";
my $show_environment = "0";
my ($mailServer, $icinga_url, $pnp4nagios_url, $nagiosbp_url, $nagiosbp_conf, $nagiosbp_state, $tempdir, $originator, $recipient, 
	$icinga_notificationtype, $icinga_adminemail
	);

# host informations			
my ($icinga_hostname, $icinga_hostalias, $icinga_hostnotes, $icinga_hoststate, $icinga_hoststatetype, 
	$icinga_hostattempt, $icinga_maxhostattempt, $icinga_hostduration, $icinga_hostnotificationnumber, 
	$icinga_hostcheckcommand, $icinga_hostlatency, $icinga_lasthostcheck, $icinga_lasthoststatechange,
	$icinga_lasthostup, $icinga_lasthostdown, $icinga_lasthostunreachable, $icinga_hostoutput, $icinga_hostaddress,
	$icinga_hostnotesurl
	);

# service informations
my ($icinga_servicedesc, $icinga_servicestate, $icinga_servicenotificationnumber, $icinga_serviceoutput,
	$icinga_lastservicecheck, $icinga_lastservicestatechange, $icinga_lastserviceok, $icinga_lastservicewarning,
	$icinga_lastservicecritical, $icinga_lastserviceunknown, $icinga_servicestatetype, $icinga_serviceattempt,
	$icinga_maxserviceattempts, $icinga_serviceduration, $icinga_servicecheckcommand, $icinga_servicedisplayname,
	$icinga_servicelatency, $icinga_servicepercentchange, $icinga_serviceactionurl, $icinga_servicenotesurl, $icinga_servicenotes
	);

# statistics
my ($icinga_timet, $icinga_processstarttime, $icinga_totalhostsup, $icinga_totalhostsdown, $icinga_totalhostsunreachable,
	$icinga_totalservicesok, $icinga_totalserviceswarning, $icinga_totalservicescritical, $icinga_totalservicesunknown,
	$icinga_totalhostproblemsunhandled, $icinga_totalserviceproblemsunhandled
	);
	
# notifications
my ($icinga_notificationauthor, $icinga_notificationcomment
	);

# catch all given variables via GetOptions ... most of the variables should be set by Icinga
grep {$_ eq '-h'} @ARGV and do { usage() };

GetOptions (
	"debug=s"							=>	\$debug,
    "env=s"                             =>  \$show_environment,
	"smtphost=s" 						=> 	\$mailServer,
	"icinga_url=s"						=>	\$icinga_url,
	"pnp4nagios_url=s"					=>	\$pnp4nagios_url,
	"nagiosbp_url=s"					=>	\$nagiosbp_url,
	"nagiosbp_conf=s"					=>	\$nagiosbp_conf,
	"nagiosbp_state=s"					=>	\$nagiosbp_state,
	"tempdir=s"							=>	\$tempdir,
	"originator=s"						=>	\$originator,
	"recipient=s"						=>	\$recipient,
	"notificationtype=s"				=>	\$icinga_notificationtype,
	"adminemail=s"						=>	\$icinga_adminemail,
	# host information
	"hostname=s"						=>	\$icinga_hostname,
	"hostalias=s"						=>	\$icinga_hostalias,
	"hostnotes=s"						=>	\$icinga_hostnotes,
	"hoststate=s"						=>	\$icinga_hoststate,
	"hoststatetype=s"					=>	\$icinga_hoststatetype,
	"hostattempt=s"						=>	\$icinga_hostattempt,
	"maxhostattempt=s"					=>	\$icinga_maxhostattempt,
	"hostduration=s"					=>	\$icinga_hostduration,
	"hostnotificationnumber=s"			=>	\$icinga_hostnotificationnumber,
	"hostcheckcommand=s"				=>	\$icinga_hostcheckcommand,
	"hostlatency=s"						=>	\$icinga_hostlatency,
	"lasthostcheck=s"					=>	\$icinga_lasthostcheck,
	"lasthoststatechange=s"				=>	\$icinga_lasthoststatechange,
	"lasthostup=s"						=>	\$icinga_lasthostup,
	"lasthostdown=s"					=>	\$icinga_lasthostdown,
	"lasthostunreachable=s"				=>	\$icinga_lasthostunreachable,
	"hostoutput=s"						=>	\$icinga_hostoutput,
	"hostaddress=s"						=>	\$icinga_hostaddress,
	"hostnotesurl=s"					=>	\$icinga_hostnotesurl,
	# service information
	"servicedesc=s"						=>	\$icinga_servicedesc,
	"servicestate=s"					=>	\$icinga_servicestate,
	"servicenotificationnumber=s"		=>	\$icinga_servicenotificationnumber,
	"serviceoutput=s"					=>	\$icinga_serviceoutput,
	"lastservicecheck=s"				=>	\$icinga_lastservicecheck,
	"lastservicestatechange=s"			=>	\$icinga_lastservicestatechange,
	"lastserviceok=s"					=>	\$icinga_lastserviceok,
	"lastservicewarning=s"				=>	\$icinga_lastservicewarning,
	"lastservicecritical=s"				=>	\$icinga_lastservicecritical,
	"lastserviceunknown=s"				=>	\$icinga_lastserviceunknown,
	"servicestatetype=s"				=>	\$icinga_servicestatetype,
	"serviceattempt=s"					=>	\$icinga_serviceattempt,
	"maxserviceattempts=s"				=>	\$icinga_maxserviceattempts,
	"serviceduration=s"					=>	\$icinga_serviceduration,
	"servicecheckcommand=s"				=>	\$icinga_servicecheckcommand,
	"servicedisplayname=s"				=>	\$icinga_servicedisplayname,
	"servicelatency=s"					=>	\$icinga_servicelatency,
	"servicepercentchange=s"			=>	\$icinga_servicepercentchange,
	"serviceactionurl=s"				=>	\$icinga_serviceactionurl, 
	"servicenotesurl=s"					=>	\$icinga_servicenotesurl, 
	"servicenotes=s"					=>	\$icinga_servicenotes,
	# statistics
	"timet=s"							=>	\$icinga_timet,
	"processstarttime=s"				=>	\$icinga_processstarttime,
	"totalhostsup=s"					=>	\$icinga_totalhostsup,
	"totalhostsdown=s"					=>	\$icinga_totalhostsdown,
	"totalhostsunreachable"				=>	\$icinga_totalhostsunreachable,
	"totalservicesok=s"					=>	\$icinga_totalservicesok,
	"totalserviceswarning=s"			=>	\$icinga_totalserviceswarning,
	"totalservicescritical=s"			=>	\$icinga_totalservicescritical,
	"totalservicesunknown=s"			=>	\$icinga_totalservicesunknown,
	"totalhostproblemsunhandled=s"		=>	\$icinga_totalhostproblemsunhandled,
	"totalserviceproblemsunhandled=s"	=>	\$icinga_totalserviceproblemsunhandled,
	"notificationauthor=s"				=>	\$icinga_notificationauthor,
	"notificationcomment=s"				=>	\$icinga_notificationcomment
	);

# if mailserver undefined, use localhost
if (!$mailServer) {
	$mailServer = "127.0.0.1";
}

# set default tempdir
if (!$tempdir) {
	$tempdir = "/usr/local/icinga/var/spool/";
}

# define default nagiosbp_states
if (!$nagiosbp_state) {
	$nagiosbp_state = "OK,WARNING,CRITICAL,UNKNOWN";
}

# do some magic, like coloring, and converting here
# differ between host and service notification
my $self_notificationnumber = "DEBUG";
if ($icinga_hostnotificationnumber) {
	$self_notificationnumber = $icinga_hostnotificationnumber; 
} elsif ($icinga_servicenotificationnumber) {
	$self_notificationnumber = $icinga_servicenotificationnumber;
}

# choose color for notification type
my $icinga_servicestate_color = getColorForState($icinga_servicestate);
my $icinga_hoststate_color = getColorForState($icinga_hoststate);

# convert unixtime to localtime
$icinga_lasthostcheck				= getLocaltimeFromUnixtime($icinga_lasthostcheck);
$icinga_lasthoststatechange			= getLocaltimeFromUnixtime($icinga_lasthoststatechange);
$icinga_lasthostup					= getLocaltimeFromUnixtime($icinga_lasthostup);
$icinga_lasthostdown				= getLocaltimeFromUnixtime($icinga_lasthostdown);
$icinga_lasthostunreachable			= getLocaltimeFromUnixtime($icinga_lasthostunreachable);
$icinga_lastservicecheck			= getLocaltimeFromUnixtime($icinga_lastservicecheck);
$icinga_lastservicestatechange		= getLocaltimeFromUnixtime($icinga_lastservicestatechange);
$icinga_lastserviceok				= getLocaltimeFromUnixtime($icinga_lastserviceok);
$icinga_lastservicewarning			= getLocaltimeFromUnixtime($icinga_lastservicewarning);
$icinga_lastservicecritical			= getLocaltimeFromUnixtime($icinga_lastservicecritical);
$icinga_lastserviceunknown			= getLocaltimeFromUnixtime($icinga_lastserviceunknown);
$icinga_timet						= getLocaltimeFromUnixtime($icinga_timet);
$icinga_processstarttime			= getLocaltimeFromUnixtime($icinga_processstarttime);

# check if host- or service notification an define subject for mail
my $subject;

# detect notification type by keyword (icinga servicestate)
my $notificationtype;
if (
		($icinga_servicestate eq "UNKNOWN") or 
		($icinga_servicestate eq "CRITICAL") or 
		($icinga_servicestate eq "WARNING") or (
		$icinga_servicestate eq "OK")
	) {
	# service notification
	$subject = "[Icinga] $icinga_notificationtype: $icinga_hostname $icinga_servicedisplayname is $icinga_servicestate";
	$notificationtype = "SERVICE";
} else {
	# host notification
	$subject = "[Icinga] $icinga_notificationtype: $icinga_hostname is $icinga_hoststate";
	$notificationtype = "HOST";
}

# build message body for mail
my $messageBody = getMessageBody();
if ($debug == 1) {
	print "$messageBody\n";
}
						
# send mail and finish
sendMail($messageBody);
exit 0;

###############################################################################
# define subs from here
###############################################################################
sub sendMail {
  my $messageBody = $_[0];
    open(MAIL, "|/usr/sbin/sendmail -t") or die "Can't send mail using sendmail.\n";

    # Email Header
    print MAIL "To: $recipient\n";
    print MAIL "From: $originator\n";
    print MAIL "Subject: $subject\n";
    print MAIL "MIME-Version: 1.0\n";
    print MAIL "Content-type: text/html; charset=\"UTF-8\"\n\n";
    # Email Body
    print MAIL $messageBody;

    close(MAIL);
}

sub getLocaltimeFromUnixtime {
	my $unixtime = $_[0];
	my $localtime;
	
	if ($unixtime == 0) {
		$localtime = "never";
	} else {
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($unixtime);
		$localtime = sprintf "%02d.%02d.%04d %02d:%02d:%02d", $mday, $mon+1, $year+1900, $hour,$min,$sec;
	}
	
	return $localtime;
}

sub getMessageBody {
	# add header to message body
	$messageBody = getheader4messagebody();

	# add host details to message body
	my $hostdetails4messagebody = gethostdetails4messagebody();
	$messageBody = $messageBody . $hostdetails4messagebody;

	# add service details to message body
	if ($notificationtype eq "SERVICE") {
		# add service entry only if service notification is set
		my $servicedetails4messagebody = getservicedetails4messagebody();
		$messageBody = $messageBody . $servicedetails4messagebody;
	}
	
	# add notifications details to message body if notification type is acknowledgement
	if ($icinga_notificationtype eq "ACKNOWLEDGEMENT") {
		my $notifications4messagebody = getnotifications4messagebody();
		$messageBody = $messageBody . $notifications4messagebody;
	}

	# add pnp4nagios graph to message body if url is set
	if ($pnp4nagios_url and $pnp4nagios_url ne "") {
		my $pnp4nagios4messagebody = getpnp4nagios4messagebody();
		$messageBody = $messageBody . $pnp4nagios4messagebody;
	}
	
	# add nagiosbp informations to message body
	if (($nagiosbp_url and $nagiosbp_url ne "") && ($icinga_servicedesc =~ m/^check_bp_/)) {
		# set nagiosbp_conf to default if nothing is set
		if (!$nagiosbp_conf) {
				$nagiosbp_conf = "nagios-bp";
		}
		my $nagiosbp4messagebody = getnagiosbp4messagebody($nagiosbp_url, $icinga_servicedesc, $nagiosbp_conf);
		$messageBody = $messageBody . $nagiosbp4messagebody;
	}

	# add icinga statstics to message body
	my $statistics4messagebody = getstatistics4messagebody();
	$messageBody = $messageBody . $statistics4messagebody;
    
    if ($show_environment) {
        my $environment4messagebody = getenvironment4messagebody();
        $messageBody = $messageBody . $environment4messagebody;
    }

	# close message body html
	my $footer4messagebody = getfooter4messagebody();
	$messageBody = $messageBody . $footer4messagebody;

return $messageBody;
}

sub getheader4messagebody {
	my $is_service = ($notificationtype eq "SERVICE") ? 1 : 0;
    my $statebox_color = ($is_service) ? $icinga_servicestate_color : $icinga_hoststate_color;
	# build header for message body
	my $messageBody = "<!DOCTYPE html><html><head>";
    $messageBody = $messageBody. "<style>body {
    font-family: sans-serif;
    font-size: 10pt;
}
table {
    width:100%;
    border: 1px solid #CFCFCF;
    border-spacing: 0;
    border-collapse: collapse;
    vertical-align:top;
    text-align:left;
    padding: 0 0 10px 0;
}
table.outer {
    border: 0px;
}
td {
    padding-left: 4px;
    vertical-align:top;
}
td.outer {
    padding-bottom: 4px;
}
td.statebox {
    width: 16px;
    height: 16px;
    padding: 0px;
    vertical-align:middle;
}
td.key {
    padding: 1px 2px 1px 2px; 
    width: 120px; 
    font-weight: bold;
}
td.half {
    width:50%;
}
thead {
    font-weight: bold; 
    color: #003399; 
    background-color: #CFCFCF;
}
div.statebox {
    height: 16px;
    width: 16px;
    padding: 0px;
    background-color: ${statebox_color};
}
h1 {
    font-weight: bold; 
    color: #666666;
    font-size: 18pt;
    margin: 0px 0px 0px 0px;
}
h2 {
    font-family: sans-serif;
    font-size: 10pt; 
    font-weight: bold; 
    color: #666666; 
    border-bottom: 1px solid #CCCCCC; 
    clear: both; 
    margin-top: 15px;
}</style>";

	# $messageBody = $messageBody. "<link rel=\"stylesheet\" type=\"text/css\" href=\"mystyle.css\">";
	my $title = "";

    if ($is_service) {
		$title = "Service $icinga_notificationtype " .
			encode_entities($icinga_hostname) . " " . encode_entities($icinga_servicedesc) . " is " .
			encode_entities($icinga_servicestate) . " ($self_notificationnumber)";
    } else {
		$title = "Host $icinga_notificationtype " .
			encode_entities($icinga_hostname) . " is $icinga_hoststate ($self_notificationnumber)";
    }
	my $state = ($is_service) ? $icinga_servicestate : $icinga_hoststate;
    
	$messageBody = $messageBody. "<title>[Icinga] $title</title>";
    $messageBody = $messageBody. "<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">";
    $messageBody = $messageBody. "</head><body>";
    $messageBody = $messageBody. "<table class=\"outer\"><tr><td colspan=\"2\">";
    $messageBody = $messageBody. "<table class=\"outer\"><tr><td class=\"statebox\"><div class=\"statebox\">&nbsp;</div></td><td><h1>$title</h1></td></tr></table>\r\n";
	$messageBody = $messageBody. "</td></tr>";

	my $output = ($is_service) ? $icinga_serviceoutput : $icinga_hostoutput;
	$messageBody = $messageBody . "<tr><td class=\"key\">Output</td><td>$state: " . encode_entities($output) . "</td></tr>";
	
	if($icinga_url) {
        $messageBody = $messageBody . "<tr><td class=\"key\">URL</td><td><a href=\"$icinga_url\">$icinga_url</a></td></tr>";
    }
	$messageBody = $messageBody . "</td></tr></table>";
	
	return $messageBody;
}

sub getfooter4messagebody {
	return "</body></html>";
}

sub gethostdetails4messagebody {
	# build message body for host details
	my $messageBody = "<h2>Host details</h2>
	<table class=\"outer\">
		<tr><td colspan=\"2\">
			<table>
				<thead><tr><td colspan=\"2\">Host Informations</td></tr></thead>
				<tbody>
					<tr>
						<td class=\"key\">Hostname</td>
						<td>$icinga_hostname</td>
					</tr>
					<tr>
						<td class=\"key\">Alias</td>
						<td>$icinga_hostalias</td>
					</tr>
					<tr>
						<td class=\"key\">Notes</td>
						<td>" . encode_entities($icinga_hostnotes) . "</td>
					</tr>
					<tr>
						<td class=\"key\">Address</td>
						<td>$icinga_hostaddress</td>
					</tr>
					<tr>
						<td class=\"key\">URL</td>
						<td><a href=\"$icinga_hostnotesurl\">$icinga_hostnotesurl</a></td>
					</tr>
				</tbody>
			</table>
        </td></td>
		<tr><td colspan=\"2\"><table>
            <thead><tr><td>Host output</td></tr></thead>
				<tbody>
					<tr><td>" . encode_entities($icinga_hostoutput) . "</td></tr>
				</tbody>
        </table></td></tr>
		<tr><td class=\"half\">
			<table>
				<thead><tr><td colspan=\"2\">Host state</td></tr></thead>
				<tbody>
					<tr>
						<td class=\"key\">State</td>
						<td>$icinga_hoststate</td>
					</tr>
					<tr>
						<td class=\"key\">State type</td>
						<td>$icinga_hoststatetype</td>
					</tr>
					<tr>
						<td class=\"key\">Attempt</td>
						<td>$icinga_hostattempt of $icinga_maxhostattempt</td>
					</tr>
					<tr>
						<td class=\"key\">Duration</td>
						<td>$icinga_hostduration</td>
					</tr>
				</tbody>
			</table>
			</td>
            <td class=\"half\">
            <table>
			<thead><tr><td colspan=\"2\">Host state data</td></tr></thead>
			<tbody>
				<tr>
					<td class=\"key\">Command</td>
					<td>" . encode_entities($icinga_hostcheckcommand) . "</td>
				</tr>
				<tr>
					<td class=\"key\">Latency</td>
					<td>$icinga_hostlatency</td>
				</tr>
			</tbody>
            </table>
            </td>
		</tr>
		<tr>
			<td colspan=\"2\">
			<table>
                <thead><tr><td colspan=\"2\">Host times</td></tr></thead>
                <tbody>
					<tr>
						<td class=\"key\">Last Check</td>
						<td>$icinga_lasthostcheck</td>
					</tr>
					<tr>
						<td class=\"key\">Last State-Change</td>
						<td>$icinga_lasthoststatechange</td>
					</tr>
					<tr>
						<td class=\"key\">Last Up</td>
						<td>$icinga_lasthostup</td>
					</tr>
					<tr>
						<td class=\"key\">Last Down</td>
						<td>$icinga_lasthostdown</td>
					</tr>
					<tr>
						<td class=\"key\">Last Unrechable</td>
						<td>$icinga_lasthostunreachable</td>
					</tr>
				</tbody>
			</table>
			</td>
		</tr>
	</table>
	";
	
	return $messageBody;
}

sub getservicedetails4messagebody {
	# build message body for service details
	my $messageBody = "
	<h2>Service Details</h2>
	<table class=\"outer\">
		<tr><td colspan=\"2\"><table>
            <thead><tr><td colspan=\"2\">Service details</td></tr></thead>
            <tbody>
                <tr>
                    <td class=\"key\">Service</td>
                    <td>" . encode_entities($icinga_servicedesc) . "</td>
                </tr>
                <tr>
                    <td class=\"key\">Alias</td>
                    <td>" . encode_entities($icinga_servicedisplayname) . "</td>
                </tr>
                <tr>
                    <td class=\"key\">Notes</td>
                    <td>" . encode_entities($icinga_servicenotes) . "</td>
                </tr>
                <tr>
                    <td class=\"key\">URL</td>
                    <td><a href=\"$icinga_servicenotesurl\">" . encode_entities($icinga_servicenotesurl) . "</a></td>
                </tr>
                <tr>
                    <td class=\"key\">Command</td>
                    <td>" . encode_entities($icinga_servicecheckcommand) . "</td>
                </tr>
                <tr>
                    <td class=\"key\">Latency</td>
                    <td>$icinga_servicelatency</td>
                </tr>
                <tr>
                    <td class=\"key\">Percentage</td>
                    <td>$icinga_servicepercentchange</td>
                </tr>
            </tbody>
        </table></td></tr>
		<tr><td colspan=\"2\">
			<table>
				<thead><tr><td>Service output</td></tr></thead>
				<tbody>
					<tr><td class=\"value\">" . encode_entities($icinga_serviceoutput) . "</td></tr>
				</tbody>
			</table>
        </td></tr>
		<tr>
			<td class=\"half\"><table>
				<thead><tr><td colspan=\"2\">Service state</td></tr></thead>
				<tbody>
					<tr>
						<td class=\"key\">State</td>
						<td>$icinga_servicestate</td>
					</tr>
					<tr>
						<td class=\"key\">State type</td>
						<td>$icinga_servicestatetype</td>
					</tr>
					<tr>
						<td class=\"key\">Attempt</td>
						<td>$icinga_serviceattempt of $icinga_maxserviceattempts</td>
					</tr>
					<tr>
						<td class=\"key\">Duration</td>
						<td>$icinga_serviceduration</td>
					</tr>
				</tbody>
			</table></td>
			<td class=\"half\"><table>
				<thead><tr><td colspan=\"2\">Service times</td></tr></thead>
				<tbody>
					<tr>
						<td class=\"key\">Last Check</td>
						<td>$icinga_lastservicecheck</td>
					</tr>
					<tr>
						<td class=\"key\">Last State-Change</td>
						<td>$icinga_lastservicestatechange</td>
					</tr>
					<tr>
						<td class=\"key\">Last OK</td>
						<td>$icinga_lastserviceok</td>
					</tr>
					<tr>
						<td class=\"key\">Last Critical</td>
						<td>$icinga_lastservicecritical</td>
					</tr>
					<tr>
						<td class=\"key\">Last Warning</td>
						<td>$icinga_lastservicewarning</td>
					</tr>
					<tr>
						<td class=\"key\">Last Unknown</td>
						<td>$icinga_lastserviceunknown</td>
					</tr>
				</tbody>
			</table></td>
		</tr>
	</table>
	";
	
	return $messageBody;
}

sub getpnp4nagios4messagebody {
	# get pnp4nagios images as base64
	my $base64image = `wget --no-proxy --no-check-certificate -O - --timeout=3 '$pnp4nagios_url/image?host=$icinga_hostname&srv=$icinga_servicedesc&view=1&source=0' 2> /dev/null | base64`;

	# build message body for pnp4nagios if a pnp4nagios graph was found
	my $messageBody = "";
	if ($base64image) {
		$messageBody = "<h2>PNP4Nagios</h2>
		<table class=\"outer\">
			<tr>
				<td>
				<table>
					<thead><tr><td>PNP4Nagios</td></tr></thead>
					<tbody>
						<tr>
							<td>
							<a href=\"$pnp4nagios_url/graph?host=$icinga_hostname&srv=$icinga_servicedesc\"target=\"_blank\"><img src=\"data:image/png;base64, $base64image \" alt=\"pnp4nagios: $icinga_hostname $icinga_servicedesc\" /></a>
							</td>
						</tr>
					</tbody>
				</table>
				</td>
			</tr>
		</table>";
	}
	
	return $messageBody;
}

sub getnagiosbp4messagebody {
	my $nagiosbp_url = $_[0];
	my $icinga_servicedesc = $_[1];
	my $nagiosbp_conf = $_[2];
	
	# transform icinga_servicedesc in nagiosbp_servicedesc (remove check_bp_ from icinga_servicedesc to match nagiosbp servicedesc in conf)
	$icinga_servicedesc =~ s/check_bp_//;
	
	# build root nagiosbp_url json url
	my $nagiosbp_json_url = $nagiosbp_url . "?outformat=json" . "&tree=$icinga_servicedesc" . "&conf=$nagiosbp_conf";
	
	# build message body for icinga business processes
	my $messageBody = "<h2>Business Process Information</h2><table>";
	
	# get messagebody from json structure
	$messageBody = $messageBody . getnagiosbpjson($nagiosbp_json_url, $nagiosbp_url);
	
	return $messageBody;
}

sub getstatistics4messagebody {
	# build message body for icinga statistics
	my $messageBody = "<h2>Information</h2>
	<table class=\"outer\">
		<tr>
		<td class=\"half\"><table>
            <thead><tr><td colspan=\"2\">Host statistics</td></tr></thead>
			<tbody>
				<tr>
					<td class=\"key\">Up</td>
					<td>$icinga_totalhostsup</td>
				</tr>
				<tr>
					<td class=\"key\">Down</td>
					<td>$icinga_totalhostsdown</td>
				</tr>
				<tr>
					<td class=\"key\">Unreachable</td>
					<td>$icinga_totalhostsunreachable</td>
				</tr>
				<tr>
					<td class=\"key\">Unhandled</td>
					<td>$icinga_totalhostproblemsunhandled</td>
				</tr>
			</tbody>
            </table>
            <table>
            <thead><tr><td colspan=\"2\">Service statistics</td></tr></thead>
			<tbody>
				<tr>
					<td class=\"key\">OK</td>
					<td>$icinga_totalservicesok</td>
				</tr>
				<tr>
					<td class=\"key\">Warning</td>
					<td>$icinga_totalserviceswarning</td>
				</tr>
				<tr>
					<td class=\"key\">Critical</td>
					<td>$icinga_totalservicescritical</td>
				</tr>
				<tr>
					<td class=\"key\">Unknown</td>
					<td>$icinga_totalservicesunknown</td>
				</tr>
				<tr>
					<td class=\"key\">Unhandled</td>
					<td>$icinga_totalserviceproblemsunhandled</td>
				</tr>
			</tbody>
            </table>
        </td>
		<td class=\"half\"><table>
            <thead><tr><td colspan=\"2\">Icinga statistics</td></tr></thead>
			<tbody>
				<tr><td class=\"key\">Report Time</td><td>$icinga_timet</td></tr>
				<tr><td class=\"key\">Admin Contact</td><td>$icinga_adminemail</td>
				</tr><tr><td class=\"key\">Last Start</td><td>$icinga_processstarttime</td>
				</tr>
			</tbody>
            </table>
        </td>
		</tr>
	</table>
	";
	return $messageBody;
}

sub getnotifications4messagebody {
	# get acknowledges for message body
	my $messageBody = "<h2>Notifications</h2>
		<table>
		<tr>
		<td>
		<table>
			<thead><tr><td colspan=\"2\">Notifications</td></tr></thead>
			<tbody>
				<tr>
					<td
						style=\"padding: 1px 2px 1px 2px; width: 120px; font-weight: bold;\">Author</td>
					<td>$icinga_notificationauthor</td>
				</tr>
				<tr>
					<td
						style=\"padding: 1px 2px 1px 2px; width: 120px; font-weight: bold;\">Comment</td>
					<td>$icinga_notificationcomment</td>
				</tr>
			</tbody>
		</table>
		</td>
		<td>&nbsp;</td>
		</tr>
	</table>
	";
	
	return $messageBody;
}

sub getenvironment4messagebody {
    # get acknowledges for message body
    my $messageBody = "<h2>Environment</h2><table><thead class=\"env\"><tr><td>Name</td><td>Value</td></tr></thead><tbody>";

    my $key;
    foreach $key (sort keys(%ENV)) {
        $messageBody = $messageBody . "<tr><td>$key</td><td>" . encode_entities($ENV{$key}) . "</td></tr>";
    }

    $messageBody = $messageBody . "</tbody></table>";

    return $messageBody;
}


sub getnagiosbpjson {
	my $nagiosbp_json_url = $_[0];
	my $nagiosbp_url = $_[1];
	my $browser = WWW::Mechanize->new();
	my $messageBody;
	
	if ($debug == 1) {
		print "$nagiosbp_json_url\n";
		print "$nagiosbp_url\n";
	}

	# get json stream
	# TODO -> secure block with an eval. otherwise no mail is generated if url of nagiosbp not valid or icinga is unreachable during restart
	# TODO -> eval {
	$browser->get($nagiosbp_json_url);
	my $content = $browser->content();
	my $json    = new JSON;

	# these are some nice json options to relax restrictions a bit:
	my $json_text = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($content);
	if ( $debug == 1 ) {
		print Dumper($json_text);
	}

	# iterate over each element in the JSON structure
	foreach my $element ( @{ $json_text->{business_process}->{components} } ) {
		# get service state
		my $servicestate_color = getColorForState( $element->{hardstate} );
		
		# if element host exists create html code
		if ($element->{host}) {
			# check if business process hardstate matches on of nagiosbp_state. careful ... subprocess also uses hardstate.
			if ($nagiosbp_state =~ /($element->{hardstate})/) {
				$messageBody = $messageBody . "	
					<tr>
						<td>
						<table>
                            <thead><tr><td colspan=\"2\">$element->{host}->$element->{service}</td></tr></thead>
							<tbody>
								<tr>
									<td class=\"key\">Host</td>
									<td>$element->{host}</td>
								</tr>
								<tr>
									<td class=\"key\">Service</td>
									<td>$element->{service}</td>
								</tr>
								<tr style=\"color: $servicestate_color;\">
									<td class=\"key\">State</td>
									<td>$element->{hardstate}</td>
								</tr>
								<tr>
									<td class=\"key\">Output</td>
									<td>" . encode_entities($element->{plugin_output}) . "</td>
								</tr>
							</tbody>
						</table>
						</td>
					</tr>
				";
			}
		} elsif ($element->{subprocess}) {
			# get underlying business process ... rebuild nagiosbp-json-url with new subprocess
			my $nagiosbp_json_url = $nagiosbp_url . "?outformat=json" . "&tree=$element->{subprocess}" . "&conf=$nagiosbp_conf";
			$messageBody = $messageBody . getnagiosbpjson($nagiosbp_json_url, $nagiosbp_url);
		}
	}
	$messageBody = $messageBody . "	
	</table>
	";

	# TODO -> Close eval here ... Needs more testing, what happens if url is unreachable
	# TODO -> }
	return $messageBody;
}

sub getColorForState {
	
	my $servicestate = $_[0];
	my $servicestate_color;
	
	if ($servicestate eq "OK" or $servicestate eq "UP") {
		$servicestate_color = "#00CC33";
	} elsif ($servicestate eq "WARNING" or $servicestate eq "UNREACHABLE") {
		$servicestate_color = "#FFA500";	
	} elsif ($servicestate eq "CRITICAL" or $servicestate eq "DOWN") {
		$servicestate_color = "#FF3300";	
	} elsif ($servicestate eq "UNKNOWN") {
		$servicestate_color = "#E066FF";
	} else {
		$servicestate_color = "#FFFFFF"
	}
	
	return $servicestate_color;	
}

sub usage {
  
  print STDERR <<_EOF_;
$0: $0 [options]
	-h	print this help screen and quit
		
	# insert the following notification command in commands.cfg or in notifications.cfg 
 	define command {
 		command_name	notify-by-html-email
 		command_line	/usr/local/icinga/bin/icinga_mail.pl --debug 0 --smtphost 127.0.0.1 --icinga_url http://icinga.localdomain/icinga/ 
 		[--pnp4nagios_url http://icinga.localdomain/pnp4nagios/] [--nagiosbp_url http://icinga.localdomain/nagiosbp/cgi-bin/nagios-bp.cgi] 
 		[--nagiosbp_conf MYCONF] [--nagiosbp_state OK,WARNING,CRITICAL,UNKNOWN] --originator "\$ADMINEMAIL\$" --recipient "\$CONTACTEMAIL\$" 
 		--notificationtype "\$NOTIFICATIONTYPE\$" --adminemail "\$ADMINEMAIL\$" --hostname "\$HOSTNAME\$" --hostalias "\$HOSTALIAS\$" 
 		--hostnotes "\$HOSTNOTES\$" --hoststate "\$HOSTSTATE\$" --hoststatetype "\$HOSTSTATETYPE\$" --hostattempt "\$HOSTATTEMPT\$" 
 		--maxhostattempt "\$MAXHOSTATTEMPTS\$" --hostduration "\$HOSTDURATION\$" --hostnotificationnumber "\$HOSTNOTIFICATIONNUMBER\$" 
 		--hostcheckcommand "\$HOSTCHECKCOMMAND\$" --hostlatency "\$HOSTLATENCY\$" --lasthostcheck "\$LASTHOSTCHECK\$" 
 		--lasthoststatechange "\$LASTHOSTSTATECHANGE\$" --lasthostup "\$LASTHOSTUP\$" --lasthostdown "\$LASTHOSTDOWN\$" 
 		--lasthostunreachable "\$LASTHOSTUNREACHABLE\$" --hostoutput "\$HOSTOUTPUT\$" --hostaddress "\$HOSTADDRESS\$" 
 		--hostnotesurl "\$HOSTNOTESURL\$" --servicedesc "\$SERVICEDESC\$" --servicestate "\$SERVICESTATE\$" 
 		--servicenotificationnumber "\$SERVICENOTIFICATIONNUMBER\$" --serviceoutput "\$SERVICEOUTPUT\$" 
 		--lastservicecheck "\$LASTSERVICECHECK\$" --lastservicestatechange "\$LASTSERVICESTATECHANGE\$" 
 		--lastserviceok "\$LASTSERVICEOK\$" --lastservicewarning "\$LASTSERVICEWARNING\$" --lastservicecritical "\$LASTSERVICECRITICAL\$" 
 		--lastserviceunknown "\$LASTSERVICEUNKNOWN\$" --servicestatetype "\$SERVICESTATETYPE\$" --serviceattempt "\$SERVICEATTEMPT\$" 
 		--maxserviceattempts "\$MAXSERVICEATTEMPTS\$" --serviceduration "\$SERVICEDURATION\$" --servicecheckcommand "\$SERVICECHECKCOMMAND\$" 
 		--servicedisplayname "\$SERVICEDISPLAYNAME\$" --servicelatency "\$SERVICELATENCY\$" --servicepercentchange "\$SERVICEPERCENTCHANGE\$" 
 		--serviceactionurl "\$SERVICEACTIONURL\$" --servicenotesurl "\$SERVICENOTESURL\$" --servicenotes "\$SERVICENOTES\$"
 		--timet "\$TIMET\$" --processstarttime "\$PROCESSSTARTTIME\$" --totalhostsup "\$TOTALHOSTSUP\$" --totalhostsdown "\$TOTALHOSTSDOWN\$" 
 		--totalhostsunreachable "\$TOTALHOSTSUNREACHABLE\$" --totalservicesok "\$TOTALSERVICESOK\$" --totalserviceswarning "\$TOTALSERVICESWARNING\$" 
 		--totalservicescritical "\$TOTALSERVICESCRITICAL\$" --totalservicesunknown "\$TOTALSERVICESUNKNOWN\$" 
 		--totalhostproblemsunhandled "\$TOTALHOSTPROBLEMSUNHANDLED\$" --totalserviceproblemsunhandled "\$TOTALSERVICEPROBLEMSUNHANDLED\$" 
 		--notificationauthor "\$NOTIFICATIONAUTHOR\$" --notificationcomment "\$NOTIFICATIONCOMMENT\$"
	}
	
	You'll need the Perl Mail::Sender package. On Debian please use 
	"sudo apt-get install libmail-sender-perl libjson-perl libjson-xs-perl libwww-mechanize-perl libdata-dumper-simple-perl" ... 

	Otherwise try
	"cpan Mail::Sender WWW::Mechanize JSON Data::Dumper install".
	
	# HINT:
	--nagiosbp_url could handle more than one config file. you can define that with --nagiosbp_conf. if nbothing is set nagios-bp.conf is used
	
	For more information have a look in the wiki on http://code.google.com/p/icinga-html-mail-template/
	
_EOF_
  exit 1;
}
