use Test::More;
use File::Slurp;
use File::Basename;
use strict;
use warnings;
    
BEGIN {
    use_ok( q{Zonemaster::Engine} );
    use_ok( q{Zonemaster::Engine::Nameserver} );
    use_ok( q{Zonemaster::Engine::Test::Zone} );
    use_ok( q{Zonemaster::Engine::Util}, qw( parse_hints ) );
}

my $checking_module = q{Zone};
my $testcase = 'zone09';

sub zone_gives {
    my ( $test, $zone, $gives_ref ) = @_;
    Zonemaster::Engine->logger->clear_history();
    my @res = grep { $_->tag !~ /^TEST_CASE_(END|START)$/ } Zonemaster::Engine->test_method( $checking_module, $test, $zone );
    foreach my $gives ( @{$gives_ref} ) {
        ok( ( grep { $_->tag eq $gives } @res ), $zone->name->string . " gives $gives" );
    }
    return scalar( @res );
}

sub zone_gives_not {
    my ( $test, $zone, $gives_ref ) = @_;

    Zonemaster::Engine->logger->clear_history();
    my @res = grep { $_->tag !~ /^TEST_CASE_(END|START)$/ } Zonemaster::Engine->test_method( $checking_module, $test, $zone );
    foreach my $gives ( @{$gives_ref} ) {
        ok( !( grep { $_->tag eq $gives } @res ), $zone->name->string . " does not give $gives" );
    }
    return scalar( @res );
}

my $datafile = 't/' . basename ($0, '.t') . '.data';
if ( not $ENV{ZONEMASTER_RECORD} ) {
    die q{Stored data file missing} if not -r $datafile;
    Zonemaster::Engine::Nameserver->restore( $datafile );
    Zonemaster::Engine::Profile->effective->set( q{no_network}, 1 );
}

# Test case specific hints file (test-zone-data/Zone-TP/zone09/hintfile-root-email-domain)
my $hints;
{
    $hints = <<EOF,
.       3600000    NS    ns1
ns1.    3600000    A     127.19.9.43
ns1.    3600000    AAAA  fda1:b2:c3::127:19:9:43
;
.       3600000    NS    ns2
ns2.    3600000    A     127.19.9.44
ns2.    3600000    AAAA  fda1:b2:c3::127:19:9:44

EOF

};
my $hints_data = parse_hints( $hints);
Zonemaster::Engine::Recursor->remove_fake_addresses( '.' );
Zonemaster::Engine::Recursor->add_fake_addresses( '.', $hints_data );

###########
# zone09
###########

my ($json, $profile_test);
$json         = qq({ "test_cases": [ "$testcase" ] });
$profile_test = Zonemaster::Engine::Profile->from_json( $json );
Zonemaster::Engine::Profile->effective->merge( $profile_test );

my $blockline = 0;
my ($zonename, @gives, @gives_not);
while (my $line = <DATA>) {
    chomp($line);
    next if $line =~ /^#/;
    next if ($blockline == 0 and $line eq '');
    if ($blockline == 3 and $line eq '') {
	$blockline = 0;
	next;
    };
    if ($blockline == 0) {
	$zonename = $line;
	$blockline = 1;
	next;
    };
    if ($blockline == 1) {
	if ($line eq '(none)') {
	    @gives = ();
	} else {
	    $line =~ s/ *, */ /g;
	    @gives = split (/ +/, $line);
	}
	$blockline = 2;
	next;
    };
    if ($blockline == 2) {
	if ($line eq '(none)') {
	    @gives_not = ();
	} else {
	    $line =~ s/ *, */ /g;
	    @gives_not = split (/ +/, $line);
	}

	my $zone = Zonemaster::Engine->zone( $zonename );
	zone_gives( $testcase, $zone, \@gives ) if scalar @gives;
	zone_gives_not( $testcase, $zone, \@gives_not ) if scalar @gives_not;
	$blockline = 3;
	$zonename = '';
	@gives = '';
	@gives_not = '';
	next;
    };
    die "Error in data section";
};


if ( $ENV{ZONEMASTER_RECORD} ) {
    Zonemaster::Engine::Nameserver->save( $datafile );
}

Zonemaster::Engine::Profile->effective->set( q{no_network}, 0 );
Zonemaster::Engine::Profile->effective->set( q{net.ipv4}, 0 );
Zonemaster::Engine::Profile->effective->set( q{net.ipv6}, 0 );

TODO: {
    local $TODO = "Nothing";
}

done_testing;


# In that __DATA__ section each test is a block consisting of three lines:
# 1 Zone name
# 2 Tags tag "gives"
# 3 Tags that "gives not"
#
# If tag line is "(none)" than it should be ignored.
#
# Empty lines between blocks. Lines with "#" in column one are ignored (comments);


__DATA__
# Scenario ROOT-EMAIL-DOMAIN
.
Z09_ROOT_EMAIL_DOMAIN
Z09_INCONSISTENT_MX_DATA, Z09_MX_DATA, Z09_MISSING_MAIL_TARGET, Z09_TLD_EMAIL_DOMAIN, Z09_NULL_MX_WITH_OTHER_MX, Z09_NULL_MX_NON_ZERO_PREF

# Always an emapty line after the last block
