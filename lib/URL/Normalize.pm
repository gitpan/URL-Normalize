package URL::Normalize;
use strict;
use warnings;

=head1 NAME

URL::Normalize - Normalize/optimize URLs.

=head1 VERSION

Version 0.18

=cut

our $VERSION = '0.18';

our $DIRECTORY_INDEX_REGEXPS = [
    '/default\.aspx?',
    '/index\.cgi',
    '/index\.php\d?',
    '/index\.pl',
    '/index\.s?html?',
];

use URI qw();
use URI::QueryParam qw();

=head1 SYNOPSIS

    use URL::Normalize;

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/display?lang=en&article=fred',
    );

    # ...or

    my $normalizer = URL::Normalize->new(
        url  => '/display?lang=en&article=fred',
        base => 'http://www.example.com',
    );

    # Get a normalized URL back

    $normalizer->do_all; # Perform all the normalizations available

    print $normalizer->get_url;

=cut

sub new {
    my $class = shift;

    my $self = {
        url  => undef,
        base => undef,
    };
    bless( $self, $class );

    $self->_init( @_ );

    return $self;
}

sub _init {
    my $self = shift;
    my %opts = @_;

    if ( defined $opts{url} && length $opts{url} ) {
        $self->{url} = $opts{url};
    }
    else {
        Carp::croak( "The 'url' parameter is required!" );
    }

    if ( defined $opts{base} && length $opts{base} ) {
        $self->{base} = $opts{base};
    }

    my $URI = $self->get_URI;

    unless ( $URI->scheme ) {
        Carp::croak( "Illegal 'url' and/or 'base' values for '$URI'!" );
    }

    return 1;
}

sub DESTROY {
    my $self = shift;

    return 1;
}

=head1 DESCRIPTION

This is NOT a perfect solution. If you normalize a URL using all the methods in
this module, there is a high probability that the URL will "stop working". This
is merely a helper module for those of you who wants to either normalize a URL
using only a few of the safer methods, and/or for those of you who wants to
generate a unique "ID" from any given URL.

When writing a web crawler, for example, it's always very costly to check if a
URL has been fetched/seen when you have millions or billions of URLs in a sort
of database. This module can help you create a unique "ID", which you then can
use as a key in a key/value-store; the key is the normalized URL, whereas all
the URLs that converts to the normalized URL are part of the value (normally an
array or hash);

    'http://www.example.com/' = {
        'http://www.example.com:80/'        => 1,
        'http://www.example.com/index.html' => 1,
        'http://www.example.com/?'          => 1,
    }

Above, all the URLs inside the hash normalizes to the key if you run these
methods:

=over 4

=item * C<make_canonical>

=item * C<remove_directory_index>

=item * C<remove_empty_query>

=back

=head1 CONSTRUCTORS

=head2 new( %opts )

Constructs a new URL::Normalize object. Takes a hash as input argument;

    my $normalizer = URL::Normalize->new(
        url  => '/foobar.html',            # required
        base => 'http://www.example.com/', # optional
    );

=cut

=head1 METHODS

=head2 get_URI

Returns the C<URI> object representing the current state of the URL.

=cut

sub get_URI {
    my $self = shift;

    return URI->new( $self->get_url, $self->get_base );
}

=head2 get_url

Returns the current URL.

=cut

sub _get {
    my $self = shift;
    my $key  = shift;

    return ( defined($self->{$key}) && length($self->{$key}) ) ? $self->{$key} : '';
}

sub get_url {
    my $self = shift;

    return $self->_get( 'url' );
}

sub _set_url {
    my $self = shift;
    my $url  = shift;

    $self->{url} = $url;
}

=head2 get_base

Returns the current base.

=cut

sub get_base {
    my $self = shift;

    return $self->_get( 'base' );
}

=head2 make_canonical

Just a shortcut for URI::URL->new->canonical->as_string, and involves the
following steps (at least):

=over 4

=item * Converts the scheme and host to lower case.

=item * Capitalizes letters in escape sequences.

=item * Decodes percent-encoded octets of unreserved characters.

=item * Removes the default port (port 80 for http).

=back

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/%7Eusername/',
    );

    $Normalize->make_canonical;

    print $Normalize->get_url; # http://www.example.com/~username/

=cut

sub make_canonical {
    my $self = shift;

    #
    # Set new 'url' value
    #
    return $self->_set_url( $self->get_URI->canonical->as_string );
}

=head2 remove_dot_segments

The segments ".." and "." will be removed and "folded" (or flattened, if you
prefer) from the URL.

This method does NOT follor the algorithm described in RFC 3986, but rather
flattens each path segment. It works just as well, it seems, but keep in mind
that it also doesn't account for symbolic links on the server side.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/../a/b/../c/./d.html',
    );

    $normalizer->remove_dot_segments;

    print $normalizer->get_url; # http://www.example.com/a/c/d.html

=cut

sub remove_dot_segments {
    my $self = shift;

    my $URI = URI->new( $self->get_url, $self->get_base );

    my @old_segments = split( '/', $URI->path_segments );
    my @new_segments = ();

    foreach my $segment ( @old_segments ) {
        if ( $segment eq '.' ) {
            next;
        }

        if ( $segment eq '..' ) {
            pop( @new_segments );
            next;
        }

        push( @new_segments, $segment );
    }

    if ( @new_segments ) {
        $URI->path_segments( @new_segments );
    }
    else {
        $URI->path_segments( '' );
    }

    if ( $self->get_url =~ m,/$, ) {
        $self->_set_url( $URI->as_string . '/' );
    }
    else {
        $self->_set_url( $URI->as_string );
    }

    $self->make_canonical;
}

=head2 remove_directory_index

Removes well-known directory indexes, eg. "index.html", "default.asp" etc.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/index.cgi?foo=/',
    );

    $normalizer->remove_directory_index;

    print $normalizer->get_url; # http://www.example.com/?foo=/

You are free to modify the global C<$DIRECTORY_INDEX_REGEXPS> arrayref to
your own fitting:

    $URL::Normalize::DIRECTORY_INDEX_REGEXPS = [ ... ];

=cut

sub remove_directory_index {
    my $self = shift;

    my $URI  = $self->get_URI;
    my $path = $URI->path;

    foreach my $regexp ( @{$DIRECTORY_INDEX_REGEXPS} ) {
        $path =~ s,$regexp,/,;
    }

    $URI->path( $path );

    #
    # Set new 'url' value
    #
    return $self->_set_url( $URI->as_string );

}

=head2 sort_query_parameters

Sorts the query parameters alphabetically.

Uppercased parameters will be lower cased during sorting only, and if there are
multiple values for a parameter, the key/value-pairs will be sorted as well.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/?b=2&c=3&a=0&A=1',
    );

    $normalizer->sort_query_parameters;

    print $normalizer->get_url; # http://www.example.com/?a=0&A=1&b=2&c=3

=cut

sub sort_query_parameters {
    my $self = shift;

    my $URI = $self->get_URI;

    if ( $self->get_URI->as_string =~ m,\?, ) {
        my $query_hash     = $URI->query_form_hash || {};
        my $query_string   = '';
        my %new_query_hash = ();

        foreach my $key ( sort { lc($a) cmp lc($b) } keys %{$query_hash} ) {
            my $values = $query_hash->{ $key };
            unless ( ref $values ) {
                $values = [ $values ];
            }

            foreach my $value ( @{$values} ) {
                push( @{ $new_query_hash{lc($key)}->{$value} }, $key );
            }
        }

        foreach my $sort_key ( sort keys %new_query_hash ) {
            foreach my $value ( sort keys %{$new_query_hash{$sort_key}} ) {
                foreach my $key ( @{$new_query_hash{$sort_key}->{$value}} ) {
                    $query_string .= $key . '=' . $value . '&';
                }
            }
        }

        $query_string =~ s,&$,,;

        $URI->query( $query_string );
    }

    #
    # Set new 'url' value
    #
    return $self->_set_url( $URI->as_string );
}

=head2 remove_duplicate_query_parameters

Removes duplicate query parameters, ie. where the key/value combination is
identical with another key/value combination.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/?a=1&a=2&b=4&a=1&c=4',
    );

    $normalizer->remove_duplicate_query_parameters;

    print $normalizer->get_url; # http://www.example.com/?a=1&a=2&b=3&c=4

=cut

sub remove_duplicate_query_parameters {
    my $self = shift;

    my $URI = $self->get_URI;

    my %seen      = ();
    my @new_query = ();

    foreach my $key ( $URI->query_param ) {
        my @values = $URI->query_param( $key );
        foreach my $value ( @values ) {
            unless ( $seen{$key}->{$value} ) {
                push( @new_query, { key => $key, value => $value } );
                $seen{$key}->{$value}++;
            }
        }
    }

    my $query_string = '';
    foreach ( @new_query ) {
        $query_string .= $_->{key} . '=' . $_->{value} . '&';
    }

    $query_string =~ s,&$,,;

    $URI->query( $query_string );

    #
    # Set new 'url' value
    #
    return $self->_set_url( $URI->as_string );
}

=head2 remove_empty_query_parameters

Removes empty query parameters, ie. where there are keys with no value.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/?a=1&b=&c=3',
    );

    $Normalize->remove_empty_query_parameters;

    print $normalizer->get_url; # http://www.example.com/?a=1&c=3

=cut

sub remove_empty_query_parameters {
    my $self = shift;

    my $URI = $self->get_URI;

    my $query_string = '';

    foreach my $key ( $URI->query_param ) {
        my @values = $URI->query_param( $key );
        foreach my $value ( @values ) {
            if ( defined $value && length $value ) {
                $query_string .= $key . '=' . $value . '&';
            }
        }
    }

    $query_string =~ s,&$,,;

    $URI->query( $query_string );

    #
    # Set new 'url' value
    #
    return $self->_set_url( $URI->as_string );
}

=head2 remove_empty_query

Removes empty query from the URL.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/foo?',
    );

    $normalizer->remove_empty_query;

    print $Normalize->get_url; # http://www.example.com/foo

=cut

sub remove_empty_query {
    my $self = shift;

    my $url = $self->get_url;

    $url =~ s,\?$,,;

    #
    # Set new 'url' value
    #
    $self->_set_url( $url );
}

=head2 remove_fragment

Removes the fragment from the URL, but only if they are at the end of the URL.

For example "http://www.example.com/#foo" will be translated to
"http://www.example.com/", but "http://www.example.com/#foo/bar" will stay the
same.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/bar.html#section1',
    );

    $normalizer->remove_fragment;

    print $normalizer->get_url; # http://www.example.com/bar.html

You should probably use this with caution, as most web frameworks today allows
fragments for logic, for example:

    http://www.example.com/players#all
    http://www.example.com/players#banned
    http://www.example.com/players#top

...can all result in very different results, despite their "unfragmented" URL
being the same.

=cut

sub remove_fragment {
    my $self = shift;

    my $url = $self->get_url;

    $url =~ s{#(?:/|[^?/]*)$}{};

    $self->_set_url( $url );
}

=head2 remove_fragments

Removes EVERYTHING after a '#'. You should use this sparsely, because a lot
of web applications these days returns different output in response to what
the fragment is, for example:

    http://www.example.com/users#list
    http://www.example.com/users#edit

...etc.

=cut

sub remove_fragments {
    my $self = shift;

    my $url = $self->get_url;

    $url =~ s/#.*//;

    $self->_set_url( $url );
}

=head2 remove_duplicate_slashes

Remove duplicate slashes from the URL.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/foo//bar.html',
    );

    $normalizer->remove_duplicate_slashes;

    print $normalizer->get_url; # http://www.example.com/foo/bar.html

=cut

sub remove_duplicate_slashes {
    my $self = shift;

    my $URI  = $self->get_URI;
    my $path = $URI->path;

    $path =~ s,/+,/,g;

    $URI->path( $path );

    #
    # Set new 'url' value
    #
    $self->_set_url( $URI->as_string );
}

=head2 remove_hostname_prefix

Removes 'www' followed by a potential number before the actual hostname.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/',
    );

    $normalizer->remove_hostname_prefix;

    print $normalizer->get_url; # http://example.com/

=cut

sub remove_hostname_prefix {
    my $self = shift;

    my $URI  = $self->get_URI;
    my $host = $URI->host;

    #
    # Count the number of parts in the hostname. If it's more than two parts
    # in the URL, it's safe (...) to remove the "www\d*?\." prefix.
    #
    my @parts = split( /\./, $host );

    if ( scalar(@parts) > 2 ) {
        $host =~ s,^www\d*?\.,,;
        $URI->host( $host );
    }

    #
    # Set new 'url' value
    #
    $self->_set_url( $URI->as_string );
}

=head2 do_all

Performs all of the normalization methods mentioned above.

=cut

sub do_all {
    my $self = shift;

    $self->make_canonical;
    $self->remove_dot_segments;
    $self->remove_directory_index;
    $self->sort_query_parameters;
    $self->remove_fragment;
    $self->remove_duplicate_slashes;
    $self->remove_duplicate_query_parameters;
    $self->remove_empty_query_parameters;
    $self->remove_hostname_prefix;
    $self->remove_empty_query;

    return 1;
}

=head1 SEE ALSO

=over 4

=item * L<URI>

=item * L<URI::URL>

=item * L<URI::QueryParam>

=item * L<RFC 3986: Uniform Resource Indentifier|http://tools.ietf.org/html/rfc3986>

=item * L<Wikipedia: URL normalization|http://en.wikipedia.org/wiki/URL_normalization>

=back

=head1 AUTHOR

Tore Aursand, C<< <toreau at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to the web interface at L<https://rt.cpan.org/Dist/Display.html?Name=URL-Normalize>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URL::Normalize

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URL-Normalize>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URL-Normalize>

=item * Search CPAN

L<http://search.cpan.org/dist/URL-Normalize/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2014 Tore Aursand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of URL::Normalize
