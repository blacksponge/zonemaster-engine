use Test::More;

BEGIN {
    use_ok( q{Zonemaster::Engine} );
    use_ok( q{Zonemaster::Engine::Test::Delegation} );
    use_ok( q{Zonemaster::Engine::Util} );
}

my $datafile = q{t/Test-delegation01-J.data};

if ( not $ENV{ZONEMASTER_RECORD} ) {
    die q{Stored data file missing} if not -r $datafile;
    Zonemaster::Engine::Nameserver->restore( $datafile );
    Zonemaster::Engine->profile->set( q{no_network}, 1 );
}

Zonemaster::Engine->add_fake_delegation_raw(
    'j.delegation01.exempelvis.se' => {
        'ns1.j.delegation01.exempelvis.se' => [ '46.21.97.97',    '2a02:750:12:77::97' ],
        'ns2.j.delegation01.exempelvis.se' => [ '194.18.226.122', '2001:2040:2b:1c13::53' ],
    }
);

my $zone = Zonemaster::Engine->zone( 'j.delegation01.exempelvis.se' );
my %res = map { $_->tag => $_ } Zonemaster::Engine::Test::Delegation->delegation01( $zone );

ok( $res{NO_IPV6_NS_CHILD},          q{should emit NO_IPV6_NS_CHILD} );
ok( !$res{NOT_ENOUGH_IPV6_NS_CHILD}, q{should not emit NOT_ENOUGH_IPV6_NS_CHILD} );
ok( !$res{ENOUGH_IPV6_NS_CHILD},     q{should not emit ENOUGH_IPV6_NS_CHILD} );

if ( $ENV{ZONEMASTER_RECORD} ) {
    Zonemaster::Engine::Nameserver->save( $datafile );
}

done_testing;
