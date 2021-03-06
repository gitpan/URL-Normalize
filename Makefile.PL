
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.027.
use strict;
use warnings;



use ExtUtils::MakeMaker;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Normalize/optimize URLs.",
  "AUTHOR" => "Tore Aursand <toreau\@gmail.com>",
  "BUILD_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.64"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "URL-Normalize",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "URL::Normalize",
  "PREREQ_PM" => {
    "URI" => "1.65"
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.98"
  },
  "VERSION" => "0.20",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "ExtUtils::MakeMaker" => "6.64",
  "Test::More" => "0.98",
  "URI" => "1.65"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



