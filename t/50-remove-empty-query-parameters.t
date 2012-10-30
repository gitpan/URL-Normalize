#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;

BEGIN {
    use_ok( 'URL::Normalize' );
}

{
    my %urls = (
        'http://www.example.com/?a=1&b=&c=3' => 'http://www.example.com/?a=1&c=3',
    );

    foreach ( keys %urls ) {
        my $Normalizer = URL::Normalize->new(
            url => $_,
        );

        $Normalizer->remove_empty_query_parameters();

        ok( $Normalizer->get_url() eq $urls{$_}, "$_ eq $urls{$_} - got " . $Normalizer->get_url() );
    }
}

done_testing();