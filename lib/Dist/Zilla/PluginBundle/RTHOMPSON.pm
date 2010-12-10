use strict;
use warnings;
use v5.10;
use utf8;

package Dist::Zilla::PluginBundle::RTHOMPSON;
# ABSTRACT: RTHOMPSON's Dist::Zilla Configuration

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

my $sample_dist_ini = <<'EOF';
fdfsd
[@RTHOMPSON]
; Support remove like @Filter
-remove = SynopsisTests
-remove = JRandomPlugin

; Use AutoVersion
version = auto
version_major = 0
; OR Use manual versioning
; TODO: Write Dist::Zilla::Plugin::StaticVersion
version = 1.14.04
; OR Provide no version

; Whether to do real releases
release = real (default)
; OR fake
release = fake
; OR other
release = SpecificPluginName

; Whether to archive
archive = yes|true|1 (default)
; OR not
archive = no|false|0|-1

; Whether the synopsis is perl code that should be tested for successful compilation
synopsis_is_perl_code = true

; Files to copy from build dir
copy_file = README
copy_file = README.mkdn

EOF

sub mvp_multivalue_args { qw( -remove copy_file ) }

my @options = qw( -remove version version_major synopsis_is_perl_code copy_file
                  release archive  );

# Returns true for strings of 'true', 'yes', or positive numbers,
# false otherwise.
sub _parse_bool {
    return 1 if $_[0] =~ m{true|yes|1}i;
    return if $_[0] =~ m{false|no|0}i;
    die "Invalid boolean value $_[0]. Valid values are true/false yes/no 1/0";
}

sub configure {
    my $self = shift;
    state $defaults = {
        # AutoVersion by default
        version => 'auto',
        # Assume that the module is experimental unless told
        # otherwise.
        version_major => 0,
        # Assume that synopsis is perl code and should compile
        # cleanly.
        synopsis_is_perl_code => 1,
        # Realease to CPAN for real
        release => 'real',
        # Archive releases
        archive => 1,
        archive_directory => 'releases',
        # Copy README.pod from build dir to dist dir, for Github and
        # suchlike.
        copy_file => [ 'README.pod' ],
    };
    my %args = (%$defaults, %{$self->payload});

    # Use the @Filter bundle to handle '-remove'.
    if ($args{-remove}) {
        $self->add_bundle('@Filter' => { %args, -bundle => '@RTHOMPSON' });
        return;
    }

    # Add appropriate version plugin
    if (lc($args{version}) eq 'auto') {
        $self->add_plugins(
            [ 'AutoVersion' => { major => $args{version_major} } ]
        );
    }
    elsif (lc($args{version}) eq 'disable') {
        # No-op
        $self->add_plugins(
            [ 'StaticVersion' => { version => '' } ]
        );
    }
    else {
        # If version is empty, this is a no-op.
        $self->add_plugins(
            [ 'StaticVersion' => { version => $args{version} } ]
        );
    }

    # Copy files from build dir
    $self->add_plugins(
        [ 'CopyFilesFromBuild' => { file => $args{copy_file} } ]
    );

    # Decide whether to test SYNOPSIS for syntax.
    if (_parse_bool($args{synopsis_is_perl_code})) {
        $self->add_plugins('SynopsisTests');
    }

    # Choose release plugin
    given ($args{release}) {
        when (lc eq 'real') {
            $self->add_plugins('UploadToCPAN')
        }
        when (lc eq 'fake') {
            $self->add_plugins('FakeRelease')
        }
        when ($_) {
            $self->add_plugins($_)
        }
        default {
            # Empty string means no release plugin
        }
    }

    # Choose whether and where to archive releases
    if (_parse_bool($args{archive})) {
        $self->add_plugins(
            ['ArchiveRelease' => {
                directory => $args{archive_directory},
            }]
        );
    }

    # All the invariant plugins
    $self->add_plugins(
        # @Basic
        'GatherDir',
        'PruneCruft',
        'ManifestSkip',
        'MetaYAML',
        'License',
        'ExecDir',
        'ShareDir',
        'MakeMaker',
        'Manifest',

        # Mods
        'PkgVersion',
        # TODO: Only add PodWeaver if weaver.ini exists
        'PodWeaver',

        # Generated Docs
        'InstallGuide',
        ['ReadmeAnyFromPod', 'text', {
            filename => 'README',
            type => 'text',
        }],
        ['ReadmeAnyFromPod', 'pod', {
            filename => 'README.pod',
            type => 'pod',
        }],

        # This can't hurt. It's a no-op if github is not involved.
        'GithubMeta',

        # Tests
        'CriticTests',
        'PodTests',
        'HasVersionTests',
        'PortabilityTests',
        'UnusedVarsTests',
        ['CompileTests' => {
            # The test files don't seem to compile in the context of
            # this test. But it's ok, because if they really have
            # problems, they'll fail to compile when they run.
            skip => 'Test$',
        }],
        'KwaliteeTests',
        'ExtraTests',

        # Prerequisite checks
        'ReportVersions',
        'MinimumPerl',
        'AutoPrereqs',

        # Release checks
        'CheckChangesHasContent',

        # Release
        'NextRelease',
        'TestRelease',
        'ConfirmRelease',

    );
}
1; # Magic true value required at end of module
__END__

=head1 SYNOPSIS

In dist.ini:

    [@RTHOMPSON]
    TODO ADD STUFF

=head1 DESCRIPTION

TODO ADD STUFF

=for Pod::Coverage  configure mvp_multivalue_args

=head1 BUGS AND LIMITATIONS

This module should be more configurable. Suggestions welcome.

Please report any bugs or feature requests to
C<rct+perlbug@thompsonclan.org>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
