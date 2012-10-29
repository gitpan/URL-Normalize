# NAME

URL::Normalize - Normalize/optimize URLs.

# VERSION

Version 0.04

# SYNOPSIS

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

# CONSTRUCTORS

## new( %opts )

Constructs a new URL::Normalizer object. Takes a hash as input argument;

    my $Normalizer = URL::Normalize->new(
        url  => '/foobar.html',            # required
        base => 'http://www.example.com/', # optional
    );

# METHODS

## make\_canonical()

Just a shortcut for URI::URL->new()->canonical()->as\_string(), and involves
the following steps (at least):

- Converts the scheme and host to lower case.
- Capitalizes letters in escape sequences.
- Decodes percent-encoded octets of unreserved characters.
- Removes the default port (port 80 for http).

Example:

    my $Normalizer = URL::Normalize->new(
        url => 'http://www.example.com/%7Eusername/',
    );

    $Normalize->make_canonical();

    print $Normalize->get_url(); # http://www.example.com/~username/

## remove\_dot\_segments()

The segments ".."" and "." will be removed from the URL according to the
algorithm described in RFC 3986.

Example:

    my $Normalizer = URL::Normalize->new(
        url => 'http://www.example.com/../a/b/../c/./d.html',
    );

    $Normalize->remove_dot_segments();

    print $Normalize->get_url(); # http://www.example.com/a/c/d.html

## remove\_directory\_index()

Removes well-known directory indexes, eg. "index.html", "default.asp" etc.

## sort\_query\_parameters()

Sorts the query parameters alphabetically.

Uppercased parameters will be lower cased during sorting only, and if there are
multiple values for a parameter, the key/value-pairs will be sorted as well.

Example:

    my $Normalizer = URL::Normalize->new(
        url => 'http://www.example.com/?b=2&c=3&a=0&A=1',
    );

    $Normalizer->sort_query_parameters();

    print $Normalizer->get_url(); # http://www.example.com/?a=0&A=1&b=2&c=3

## remove\_empty\_query()

Removes empty query from the URL.

Example:

    my $Normalizer = URL::Normalize->new(
        url => 'http://www.example.com/foo?',
    );

    $Normalizer->remove_empty_query();

    print $Normalize->get_url(); # http://www.example.com/foo

## remove\_fragment()

Removes fragments from the URL. This is dangerous, as lot of AJAX-ified
applications uses this part.

Example:

    my $Normalizer = URL::Normalize->new(
        url => 'http://www.example.com/bar.html#section1',
    );

    $Normalizer->remove_fragment();

    print $Normalizer->get_url(); # http://www.example.com/bar.html

## remove\_duplicate\_slashes()

Remove duplicate slashes from the URL.

Example:

    my $Normalizer = URL::Normalize->new(
        url => 'http://www.example.com/foo//bar.html',
    );

    $Normalizer->remove_duplicate_slashes();

    print $Normalizer->get_url(); # http://www.example.com/foo/bar.html

## do\_all()

Performs all of the normalization methods.

# SEE ALSO

- [URI](http://search.cpan.org/perldoc?URI)
- [URI::URL](http://search.cpan.org/perldoc?URI::URL)
- [URI::QueryParam](http://search.cpan.org/perldoc?URI::QueryParam)
- RFC 3986: Uniform Resource Indentifier

    [http://tools.ietf.org/html/rfc3986](http://tools.ietf.org/html/rfc3986)

- Wikipedia: URL normalization

    [http://en.wikipedia.org/wiki/URL\_normalization](http://en.wikipedia.org/wiki/URL\_normalization)

# AUTHOR

Tore Aursand, `<toreau at gmail.com>`

# BUGS

Please report any bugs or feature requests to the web interface at [https://github.com/toreau/url-normalize/issues/new](https://github.com/toreau/url-normalize/issues/new).

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URL::Normalize

You can also look for information at:

- github (report bugs here)

    [https://github.com/toreau/url-normalize/issues](https://github.com/toreau/url-normalize/issues)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/URL-Normalize](http://annocpan.org/dist/URL-Normalize)

- CPAN Ratings

    [http://cpanratings.perl.org/d/URL-Normalize](http://cpanratings.perl.org/d/URL-Normalize)

- Search CPAN

    [http://search.cpan.org/dist/URL-Normalize/](http://search.cpan.org/dist/URL-Normalize/)

# LICENSE AND COPYRIGHT

Copyright 2012 Tore Aursand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic\_license\_2\_0)

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
