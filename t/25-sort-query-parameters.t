#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 9;

BEGIN {
    use_ok( 'URL::Normalize' );
}

{
    my %urls = (
        'http://www.example.com'                                => 'http://www.example.com',
        'http://www.example.com/'                               => 'http://www.example.com/',
        'http://www.example.com/?'                              => 'http://www.example.com/?',
        'http://www.example.com/?a=1&b=2&c=3'                   => 'http://www.example.com/?a=1&b=2&c=3',
        'http://www.example.com/?c=1&b=2&a=3&d=d=4'             => 'http://www.example.com/?a=3&b=2&c=1&d=d=4',
        'http://www.example.com/?b=2&c=3&a=0&A=1'               => 'http://www.example.com/?a=0&A=1&b=2&c=3',
        'http://www.example.com/index.html?c=3&b=2&a=0&A=1&a=4' => 'http://www.example.com/index.html?a=0&A=1&a=4&b=2&c=3',
        'http://www.example.com/?c=d&a=b'                       => 'http://www.example.com/?a=b&c=d',
    );

    foreach ( keys %urls ) {
        my $Normalizer = URL::Normalize->new(
            url => $_,
        );

        $Normalizer->sort_query_parameters;

        ok( $Normalizer->get_url eq $urls{$_}, "$_ eq $urls{$_} - got " . $Normalizer->get_url );
    }
}

done_testing;
