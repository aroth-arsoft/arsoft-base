#!/usr/bin/perl -w

use warnings;
use strict;
use Data::Dumper;


#use Dumpvalue;
# Nagios return values
use constant {
    OK       => 0,
    WARNING  => 1,
    CRITICAL => 2,
    UNKNOWN  => 3,
};

use Getopt::Long
  qw(GetOptions HelpMessage VersionMessage :config no_ignore_case bundling);

our $VERSION = '1.1';
my %args;
my $user_beancounters_file = "/proc/user_beancounters";
my %containers;
my $uid = -1;
my $all_uids = 0;
my $use_sudo = 1;
my @resources_critical = ();
my @resources_warning = ();
my @resources_ok = ();
my @perf_data = ();

sub parse
{
    my $file = shift;
    my $filename_to_open;

    if ( $use_sudo != 0 ) {
        $filename_to_open = "/usr/bin/sudo /bin/cat " . $file . "|";
    } else {
        $filename_to_open = "<" . $file;
    }

    if (!open (FILE, $filename_to_open))
    {
        print "Could not open " . $file . "\n";
        exit CRITICAL;
    }

    my %container = ();
    my $aktzone = -1;

    while (my $line = <FILE>)
    {
        next if ($line =~ m/^version/i);
        my @vals = split(/\s+/, $line);
        my $descr = scalar (@vals) > 7 ? $vals[2] : $vals[1];
        my $held = scalar (@vals) > 7 ? $vals[3] : $vals[2];
        my $maxheld = scalar (@vals) > 7 ? $vals[4] : $vals[3];
        my $barrier = scalar (@vals) > 7 ? $vals[5] : $vals[4];
        my $limit = scalar (@vals) > 7 ? $vals[6] : $vals[5];
        my $failcnt = scalar (@vals) > 7 ? $vals[7] : $vals[6];
        next if ($failcnt =~ m/fail/i);
        
        if (scalar (@vals) == 8) {
            $aktzone = substr ($vals[1], 0, -1);
            if (!exists($container{$aktzone})) {
                $container{$aktzone} = ();
            }
        }
        
        #print "$descr   $held, $maxheld, $barrier, $limit, $failcnt, \n";
        my @row_values = ( $held, $maxheld, $barrier, $limit, $failcnt );
        $container{$aktzone}{$descr} = [ @row_values ];
        
        my @val = @{$container{$aktzone}{$descr}};
        #print "$descr ->  ", join(", ", @val), "\n";
    }

    close(FILE); 
    return %container;
}

sub check_container
{
    my $container_uid = shift;
    my $container_ref = shift;
    my %container_values = %{$container_ref};
    
    my $resource_name_prefix = ($container_uid != 0) ? "${container_uid}_" : "";
    
    my $key;
    my @values;
    #print "check_container: ";
    #print Dumper(\%container_values);
    #print "\n";
    
    foreach my $key ( sort keys %container_values )
    {
        if ( $key ne 'dummy' ) 
        {
            my $held;
            my $maxheld;
            my $barrier;
            my $limit;
            my $failcnt;
            my $resource_name = "${resource_name_prefix}${key}";
            ( $held, $maxheld, $barrier, $limit, $failcnt ) = @{$container_values{$key}};
            my $resource_text;
            if ( $held >= $limit )
            {
                push(@resources_critical, "$key $held >= $limit")
            }
            elsif ( $held >= $barrier )
            {
                push(@resources_warning, "$key $held >= $barrier")
            }
            else
            {
                push(@resources_ok, "$key=$held")
            }
            my $value_perf_data = "'$resource_name'=$held;$barrier;$limit;;$maxheld";
            push(@perf_data, $value_perf_data);
        }
    }
}

# Main
GetOptions(
    \%args,
    'version|v' => sub { VersionMessage({'-exitval' => UNKNOWN}) },
    'help|h'    => sub { HelpMessage({'-exitval'    => UNKNOWN}) },
    'ubc:s'    => \$user_beancounters_file,
    'uid:i'    => \$uid,
    'all!'     => \$all_uids,
    'sudo!'    => \$use_sudo,
  )
  or pod2usage({'-exitval' => UNKNOWN});

#print $user_beancounters_file;

%containers = parse($user_beancounters_file);

#print Dumper(\%containers);

if ($uid < 0) {
    
    if ( $all_uids != 0 )
    {
        foreach my $key ( keys %containers )
        {
            my %container_values = %{$containers{$key}};
            check_container($key, \%container_values);
        }
    }
    else
    {
        my @container_keys = keys %containers;
        $uid = $container_keys[0];
        check_container(0, \%{$containers{$uid}});
    }
}
else 
{
    check_container(0, \%{$containers{$uid}});
}

my $exitcode = UNKNOWN;
my $exitmessage = 'UNKNOWN';
my $exitperfdata;
if (scalar(@resources_critical) > 0)
{
    $exitmessage = 'CRITICAL: ' . join(", ", @resources_critical);
    $exitcode = CRITICAL;
}
elsif (scalar(@resources_warning) > 0)
{
    $exitmessage = 'WARNING: ' . join(", ", @resources_warning);
    $exitcode = WARNING;
}
else
{
    $exitmessage = 'OK';
    $exitcode = OK;
}
$exitperfdata = join(" ", @perf_data);
print ($exitmessage . "| " . $exitperfdata . "\n");

# foreach my $key ( keys %$containers )
# {
#     print $key . "=" . $value_hash->{$key}  . "\n";
#     print $key . "=" . $value_hash->{$key}  . "\n";
# }

exit $exitcode;
