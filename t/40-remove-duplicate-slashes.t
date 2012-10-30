#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 4;

BEGIN {
    use_ok( 'URL::Normalize' );
}

{
    my %urls = (
        'http://www.example.com//'             => 'http://www.example.com/',
        'http://www.example.com///'            => 'http://www.example.com/',
        'http://www.example.com/foo//bar.html' => 'http://www.example.com/foo/bar.html',
    );

    foreach ( keys %urls ) {
        my $Normalizer = URL::Normalize->new(
            url => $_,
        );

        $Normalizer->remove_duplicate_slashes();

        ok( $Normalizer->get_url() eq $urls{$_}, "$_ eq $urls{$_} - got " . $Normalizer->get_url() );
    }
}

done_testing();