use strict;
use warnings;

use Module::Build;

my $Builder = Module::Build->new(
    module_name         => 'URL::Normalize',
    license             => 'perl',
    dist_author         => 'Tore Aursand <toreau@gmail.com>',
    dist_version_from   => 'lib/URL/Normalize.pm',
    build_requires => {
        'Test::More'      => 0,
        'URI'             => 0,
        'URI::QueryParam' => 0,
    },
    create_makefile_pl  => 'traditional',
);

$Builder->create_build_script();