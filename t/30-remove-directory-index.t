#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 19;

BEGIN {
    use_ok( 'URL::Normalize' );
}

{
    #
    # Remove well-known directory indexes.
    #
    my @indexes = (
        'default.asp',
        'default.aspx',
        'index.cgi',
        'index.htm',
        'index.html',
        'index.php',
        'index.php5',
        'index.pl',
        'index.shtml',
    );

    my %urls = ();

    foreach my $index ( @indexes ) {
        $urls{ 'http://www.example.com/' . $index                     } = 'http://www.example.com/';
        $urls{ 'http://www.example.com/' . $index . '?foo=/' . $index } = 'http://www.example.com/?foo=/' . $index;
    }

    foreach ( keys %urls ) {
        my $Normalizer = URL::Normalize->new(
            url => $_,
        );

        $Normalizer->remove_directory_index();

        ok( $Normalizer->get_url() eq $urls{$_}, "$_ eq $urls{$_} - got " . $Normalizer->get_url() );
    }
}

done_testing();