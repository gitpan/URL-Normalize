#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 6;

BEGIN {
    use_ok( 'URL::Normalize' );
}

{
    my %urls = (
        'http://example.com/'       => 'http://example.com/',
        'http://www.example.com/'   => 'http://example.com/',
        'http://www1.example.com/'  => 'http://example.com/',
        'http://www23.example.com/' => 'http://example.com/',
        'http://www.com/'           => 'http://www.com/',
    );

    foreach ( keys %urls ) {
        my $Normalizer = URL::Normalize->new(
            url => $_,
        );

        $Normalizer->remove_hostname_prefix();

        ok( $Normalizer->get_url() eq $urls{$_}, "$_ eq $urls{$_} - got " . $Normalizer->get_url() );
    }
}

done_testing();