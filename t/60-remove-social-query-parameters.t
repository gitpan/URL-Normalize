#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 3;

BEGIN {
    use_ok( 'URL::Normalize' );
}

my %tests = (
    'http://www.huffingtonpost.com/2014/06/02/multilingual-benefits_n_5399980.html?ncid=tweetlnkushpmg00000067' => 'http://www.huffingtonpost.com/2014/06/02/multilingual-benefits_n_5399980.html',
    'http://www.example.com/?utm_campaign=&utm_medium=&utm_source=' => 'http://www.example.com/',
);

while ( my ($input, $output) = each %tests ) {
    my $normalize = URL::Normalize->new(
        url => $input,
    );

    $normalize->remove_social_query_parameters;

    is( $normalize->get_url, $output, 'Removed social query parts.' );
}

done_testing;
