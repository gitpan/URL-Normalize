package URL::Normalize;
use 5.008008;
use Moose;

=head1 NAME

URL::Normalize - Normalize/optimize URLs.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use URI qw();
use URI::QueryParam qw();

has 'url'  => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    default  => '',
    reader   => 'get_url',
    writer   => '_set_url',
);

has 'base' => (
    isa      => 'Str',
    is       => 'ro',
    required => 0,
    default  => '',
    reader   => 'get_base',
);

has 'URI'  => (
    isa     => 'URI',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_URI',
    reader  => 'get_URI'
);

#
# Builders
#
sub _build_URI {
    my $self = shift;

    return URI->new( $self->get_url(), $self->get_base() );
}

=head1 SYNOPSIS

    use URL::Normalize;

    my $Normalizer = URL::Normalize->new(
        url => 'http://www.example.com/display?lang=en&article=fred',
    );

    # ...or

    my $Normalizer = URL::Normalize->new(
        url  => '/display?lang=en&article=fred',
        base => 'http://www.example.com',
    );

    # Get a normalized URL back

    $Normalizer->do_all(); # Perform all the normalizations available

    print $Normalizer->get_url();

=head1 CONSTRUCTORS

=head2 new( %opts )

Constructs a new URL::Normalizer object. Takes a hash as input argument;

    my $Normalizer = URL::Normalize->new(
        url  => '/foobar.html',            # required
        base => 'http://www.example.com/', # optional
    );

=cut

=head1 METHODS

=head2 make_canonical()

Just a shortcut for URI::URL->new()->canonical()->as_string(), and involves
the following steps (at least):

    * Converts the scheme and host to lower case.

    * Capitalizes letters in escape sequences.

    * Decodes percent-encoded octets of unreserved characters.

    * Removes the default port (port 80 for http).

Example:

    my $Normalizer = URL::Normalize->new(
        url => 'http://www.example.com/%7Eusername/',
    );

    $Normalize->make_canonical();

    print $Normalize->get_url(); # http://www.example.com/~username/

=cut

sub make_canonical {
    my $self = shift;

    #
    # Set new 'url' value
    #
    return $self->_set_url( $self->get_URI()->canonical()->as_string() );
}

=head2 remove_dot_segments()

The segments ".."" and "." will be removed from the URL according to the
algorithm described in RFC 3986.

Example:

    my $Normalizer = URL::Normalize->new(
        url => 'http://www.example.com/../a/b/../c/./d.html',
    );

    $Normalize->remove_dot_segments();

    print $Normalize->get_url(); # http://www.example.com/a/c/d.html

=cut

sub remove_dot_segments {
    my $self = shift;

    my $URI = URI->new( $self->get_url(), $self->get_base() );

    my $old_path = $URI->path();
    my $new_path = '';

    while ( length $old_path ) {
        #
        # If the input buffer begins with a prefix of "../" or "./", then
        # remove that prefix from the input buffer;
        #
        if ( $old_path =~ m,^\.\.?/, ) {
            $old_path =~ s,^\.\.?/,,;
        }
        #
        # Otherwise, if the input buffer begins with a prefix of "/./" or "/.",
        # where "." is a complete path segment, then replace that prefix with
        # "/" in the input buffer;
        #
        elsif ( $old_path =~ m,^/\./, ) {
            $old_path =~ s,^/\./,/,;
        }
        #
        # Otherwise, if the input buffer begins with a prefix of "/../" or
        # "/..", where ".." is a complete path segment, then replace that
        # prefix with "/" in the input buffer and remove the last segment
        # and its preceding "/" (if any) from the output buffer;
        #
        elsif ( $old_path =~ m,^/\.$, ) {
            $old_path =~ s,^/\.$,/,;
        }
        #
        # (continued from above)
        #
        elsif ( $old_path =~ m,^(/\.\./?), ) {
            $old_path =~ s,^$1,/,;
            $new_path =~ s,[^/]+$,,;
        }
        #
        # Otherwise, if the input buffer consists only of "." or "..", then
        # remove that from the input buffer;
        #
        elsif ( $old_path eq '.' || $old_path eq '..' ) {
            $old_path = '';
        }
        #
        # Otherwise, move the first path segment in the input buffer to the
        # end of the output buffer, including the initial "/" character (if
        # any) and any subsequent characters up to, but not including, the
        # next "/" character or the end of the input buffer.
        #
        else {
            if ( $old_path =~ m,(/*[^/]*), ) {
                my $first_path_segment = $1;

                $new_path .= $first_path_segment;
                $old_path =~ s,^$first_path_segment,,;
            }
        }

        $new_path =~ s,/+,/,g;
    }

    $URI->path( $new_path );

    #
    # Set new 'url' value
    #
    return $self->_set_url( $URI->as_string() );
}

=head2 remove_directory_index()

Removes well-known directory indexes, eg. "index.html", "default.asp" etc.

=cut

sub remove_directory_index {
    my $self = shift;

    my $URI  = $self->get_URI();
    my $path = $URI->path();

    my @indexes = (
        '/default\.aspx?',
        '/index\.cgi',
        '/index\.php\d?',
        '/index\.pl',
        '/index\.s?html?',
    );

    foreach my $index ( @indexes ) {
        $path =~ s,$index,/,;
    }

    $URI->path( $path );

    #
    # Set new 'url' value
    #
    return $self->_set_url( $URI->as_string() );

}

=head2 sort_query_parameters()

Sorts the query parameters alphabetically.

Uppercased parameters will be lower cased during sorting only, and if there are
multiple values for a parameters, the key/value-pairs will be sorted as well.

Example:

    my $Normalizer = URL::Normalize->new(
        url => 'http://www.example.com/?b=2&c=3&a=0&A=1',
    );

    $Normalizer->sort_query_parameters();

    print $Normalizer->get_url(); # http://www.example.com/?a=0&A=1&b=2&c=3

=cut

sub sort_query_parameters {
    my $self = shift;

    my $URI = $self->get_URI();

    my $query_hash     = $URI->query_form_hash();
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
            foreach my $key ( sort @{$new_query_hash{$sort_key}->{$value}} ) {
                $query_string .= $key . '=' . $value . '&';
            }
        }
    }

    $query_string =~ s,&$,,;

    $URI->query( $query_string );

    #
    # Set new 'url' value
    #
    return $self->_set_url( $URI->as_string() );
}

=head2 remove_empty_query()

Removes empty query from the URL.

Example:

    my $Normalizer = URL::Normalize->new(
        url => 'http://www.example.com/foo?',
    );

    $Normalizer->remove_empty_query();

    print $Normalize->get_url(); # http://www.example.com/foo

=cut

sub remove_empty_query {
    my $self = shift;

    my $url = $self->get_url();

    $url =~ s,\?$,,;

    #
    # Set new 'url' value
    #
    $self->_set_url( $url );
}

=head2 remove_fragment()

Removes fragments from the URL. This is dangerous, as lot of AJAX-ified
applications uses this part.

Example:

    my $Normalizer = URL::Normalize->new(
        url => 'http://www.example.com/bar.html#section1',
    );

    $Normalizer->remove_fragment();

    print $Normalizer->get_url(); # http://www.example.com/bar.html

=cut

sub remove_fragment {
    my $self = shift;

    my $url = $self->get_url();

    $url =~ s,#.*,,;

    #
    # Set new 'url' value
    #
    $self->_set_url( $url );
}

=head2 remove_duplicate_slashes()

Remove duplicate slashes from the URL.

Example:

    my $Normalizer = URL::Normalize->new(
        url => 'http://www.example.com/foo//bar.html',
    );

    $Normalizer->remove_duplicate_slashes();

    print $Normalizer->get_url(); # http://www.example.com/foo/bar.html

=cut

sub remove_duplicate_slashes {
    my $self = shift;

    my $URI  = $self->get_URI();
    my $path = $URI->path();

    $path =~ s,/+,/,g;

    $URI->path( $path );

    #
    # Set new 'url' value
    #
    $self->_set_url( $URI->as_string() );
}

=head2 do_all()

Performs all of the normalization methods.

=cut

sub do_all {
    my $self = shift;

    $self->make_canonical();
    $self->remove_dot_segments();
    $self->remove_directory_index();
    $self->sort_query_parameters();
    $self->remove_empty_query();
    $self->remove_fragment();
    $self->remove_duplicate_slashes();

    return 1;
}

=head1 SEE ALSO

L<URI>

L<URI::URL>

L<URI::QueryParam>

L<RFC 3986: Uniform Resource Indentifier|http://tools.ietf.org/html/rfc3986>

L<Wikipedia: URL normalization|http://en.wikipedia.org/wiki/URL_normalization>

=head1 AUTHOR

Tore Aursand, C<< <toreau at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to the web interface at L<https://github.com/toreau/url-normalize/issues/new>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URL::Normalize

You can also look for information at:

=over 4

=item * github (report bugs here)

L<https://github.com/toreau/url-normalize/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URL-Normalize>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URL-Normalize>

=item * Search CPAN

L<http://search.cpan.org/dist/URL-Normalize/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Tore Aursand.

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