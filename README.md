# NAME

URL::Normalize - Normalize/optimize URLs.

# VERSION

Version 0.18

# SYNOPSIS

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

# DESCRIPTION

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

- `make_canonical`
- `remove_directory_index`
- `remove_empty_query`

# CONSTRUCTORS

## new( %opts )

Constructs a new URL::Normalize object. Takes a hash as input argument;

    my $normalizer = URL::Normalize->new(
        url  => '/foobar.html',            # required
        base => 'http://www.example.com/', # optional
    );

# METHODS

## get\_URI

Returns the `URI` object representing the current state of the URL.

## get\_url

Returns the current URL.

## get\_base

Returns the current base.

## make\_canonical

Just a shortcut for URI::URL->new->canonical->as\_string, and involves the
following steps (at least):

- Converts the scheme and host to lower case.
- Capitalizes letters in escape sequences.
- Decodes percent-encoded octets of unreserved characters.
- Removes the default port (port 80 for http).

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/%7Eusername/',
    );

    $Normalize->make_canonical;

    print $Normalize->get_url; # http://www.example.com/~username/

## remove\_dot\_segments

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

## remove\_directory\_index

Removes well-known directory indexes, eg. "index.html", "default.asp" etc.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/index.cgi?foo=/',
    );

    $normalizer->remove_directory_index;

    print $normalizer->get_url; # http://www.example.com/?foo=/

You are free to modify the global `$DIRECTORY_INDEX_REGEXPS` arrayref to
your own fitting:

    $URL::Normalize::DIRECTORY_INDEX_REGEXPS = [ ... ];

## sort\_query\_parameters

Sorts the query parameters alphabetically.

Uppercased parameters will be lower cased during sorting only, and if there are
multiple values for a parameter, the key/value-pairs will be sorted as well.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/?b=2&c=3&a=0&A=1',
    );

    $normalizer->sort_query_parameters;

    print $normalizer->get_url; # http://www.example.com/?a=0&A=1&b=2&c=3

## remove\_duplicate\_query\_parameters

Removes duplicate query parameters, ie. where the key/value combination is
identical with another key/value combination.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/?a=1&a=2&b=4&a=1&c=4',
    );

    $normalizer->remove_duplicate_query_parameters;

    print $normalizer->get_url; # http://www.example.com/?a=1&a=2&b=3&c=4

## remove\_empty\_query\_parameters

Removes empty query parameters, ie. where there are keys with no value.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/?a=1&b=&c=3',
    );

    $Normalize->remove_empty_query_parameters;

    print $normalizer->get_url; # http://www.example.com/?a=1&c=3

## remove\_empty\_query

Removes empty query from the URL.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/foo?',
    );

    $normalizer->remove_empty_query;

    print $Normalize->get_url; # http://www.example.com/foo

## remove\_fragment

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

## remove\_fragments

Removes EVERYTHING after a '#'. You should use this sparsely, because a lot
of web applications these days returns different output in response to what
the fragment is, for example:

    http://www.example.com/users#list
    http://www.example.com/users#edit

...etc.

## remove\_duplicate\_slashes

Remove duplicate slashes from the URL.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/foo//bar.html',
    );

    $normalizer->remove_duplicate_slashes;

    print $normalizer->get_url; # http://www.example.com/foo/bar.html

## remove\_hostname\_prefix

Removes 'www' followed by a potential number before the actual hostname.

Example:

    my $normalizer = URL::Normalize->new(
        url => 'http://www.example.com/',
    );

    $normalizer->remove_hostname_prefix;

    print $normalizer->get_url; # http://example.com/

## do\_all

Performs all of the normalization methods mentioned above.

# SEE ALSO

- [URI](https://metacpan.org/pod/URI)
- [URI::URL](https://metacpan.org/pod/URI::URL)
- [URI::QueryParam](https://metacpan.org/pod/URI::QueryParam)
- [RFC 3986: Uniform Resource Indentifier](http://tools.ietf.org/html/rfc3986)
- [Wikipedia: URL normalization](http://en.wikipedia.org/wiki/URL_normalization)

# AUTHOR

Tore Aursand, `<toreau at gmail.com>`

# BUGS

Please report any bugs or feature requests to the web interface at [https://rt.cpan.org/Dist/Display.html?Name=URL-Normalize](https://rt.cpan.org/Dist/Display.html?Name=URL-Normalize)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URL::Normalize

You can also look for information at:

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/URL-Normalize](http://annocpan.org/dist/URL-Normalize)

- CPAN Ratings

    [http://cpanratings.perl.org/d/URL-Normalize](http://cpanratings.perl.org/d/URL-Normalize)

- Search CPAN

    [http://search.cpan.org/dist/URL-Normalize/](http://search.cpan.org/dist/URL-Normalize/)

# LICENSE AND COPYRIGHT

Copyright 2012-2014 Tore Aursand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

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
