#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 12;

BEGIN {
    use_ok( 'URL::Normalize' );
}

{
    #
    # Removing dot-segments. The segments ".."" and "." can be removed from
    # a URL according to the algorithm described in RFC 3986 (or a similar
    # algorithm).
    #
    my %urls = (
        'http://www.example.com/'                                                            => 'http://www.example.com/',
        'http://www.example.com/../a/b/../c/./d.html'                                        => 'http://www.example.com/a/c/d.html',
        'http://www.example.com/../a/b/../c/./d.html?foo=../bar'                             => 'http://www.example.com/a/c/d.html?foo=../bar',
        'http://www.example.com/foo/../bar'                                                  => 'http://www.example.com/bar',
        'http://www.example.com/foo/../bar/'                                                 => 'http://www.example.com/bar/',
        'http://www.example.com/../foo'                                                      => 'http://www.example.com/foo',
        'http://www.example.com/../foo/..'                                                   => 'http://www.example.com/',
        'http://www.example.com/../../'                                                      => 'http://www.example.com/',
        'http://www.example.com/../../foo'                                                   => 'http://www.example.com/foo',
        'http://go.dagbladet.no/ego.cgi/dbf_tagcloud/http://www.dagbladet.no/tag/adam+lanza' => 'http://go.dagbladet.no/ego.cgi/dbf_tagcloud/http://www.dagbladet.no/tag/adam+lanza',
        'http://www.example.org/a/b/../../index.html'                                        => 'http://www.example.org/index.html',
    );

    foreach ( keys %urls ) {
        my $normalizer = URL::Normalize->new(
            url => $_,
        );

        $normalizer->remove_dot_segments;

        ok( $normalizer->get_url eq $urls{$_}, "$_ eq $urls{$_} - got " . $normalizer->get_url );
    }
}

done_testing;
