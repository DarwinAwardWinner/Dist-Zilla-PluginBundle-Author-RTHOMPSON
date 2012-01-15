use strict;
use warnings;
use feature 'switch';
use utf8;

package Dist::Zilla::PluginBundle::RTHOMPSON;
# ABSTRACT: (DEPRECATED) RTHOMPSON's Dist::Zilla Configuration

use Moose;
extends "Dist::Zilla::PluginBundle::Author::RTHOMPSON";
use namespace::autoclean;

before register_component => sub {
  warn '!!! [@RTHOMPSON] is deprecated and may be removed in the future; replace it with [@Author::RTHOMPSON]\n';
};

1; # Magic true value required at end of module
__END__

=head1 SYNOPSIS

DEPRECATED, use Dist::Zilla::PluginBundle::Author::RTHOMPSON instead.
