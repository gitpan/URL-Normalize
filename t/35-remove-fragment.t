#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 13;

BEGIN {
    use_ok( 'URL::Normalize' );
}

{
    my %urls = (
        'http://www.example.com/#'                        => 'http://www.example.com/',
        'http://www.example.com/#foo'                     => 'http://www.example.com/',
        'http://www.example.com/#foo#bar'                 => 'http://www.example.com/',
        'http://www.example.com/#foo#bar#'                => 'http://www.example.com/',
        'http://www.example.com/bar.html#section1'        => 'http://www.example.com/bar.html',
        'http://www.example.com/#ThisIsOK/'               => 'http://www.example.com/#ThisIsOK/',
        'http://www.example.com/#ThisIsOK/index.html'     => 'http://www.example.com/#ThisIsOK/index.html',
        'http://www.example.com/#ThisIsOK/#foo'           => 'http://www.example.com/#ThisIsOK/',
        'http://www.example.com/#ThisIsOK/index.html#foo' => 'http://www.example.com/#ThisIsOK/index.html',
        'http://www.example.com/#/something'              => 'http://www.example.com/#/something',
        'http://www.example.com/#/something#foo'          => 'http://www.example.com/#/something',
        'http://www.example.com/#/something/#foo'         => 'http://www.example.com/#/something/',
    );

    foreach ( keys %urls ) {
        my $normalizer = URL::Normalize->new(
            url => $_,
        );

        $normalizer->remove_fragment;

        ok( $normalizer->get_url eq $urls{$_}, "$_ eq $urls{$_} - got " . $normalizer->get_url );
    }
}

done_testing();