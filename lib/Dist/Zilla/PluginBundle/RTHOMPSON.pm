use strict;
use warnings;
use feature 'switch';
use utf8;

package Dist::Zilla::PluginBundle::RTHOMPSON;
# ABSTRACT: RTHOMPSON's Dist::Zilla Configuration

use Moose;
use MooseX::Has::Sugar;
use Carp;
with 'Dist::Zilla::Role::PluginBundle::Easy';

sub mvp_multivalue_args { qw( -remove copy_file move_file allow_dirty ) }

# Returns true for strings of 'true', 'yes', or positive numbers,
# false otherwise.
sub _parse_bool {
    $_ ||= '';
    return 1 if $_[0] =~ m{^(true|yes|1)$}xsmi;
    return if $_[0] =~ m{^(false|no|0)$}xsmi;
    die "Invalid boolean value $_[0]. Valid values are true/yes/1 or false/no/0";
}

sub configure {
    my $self = shift;

    my $defaults = {
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
        copy_file => [],
        move_file => [],
        # version control system = git
        vcs => 'git',
        allow_dirty => [ 'dist.ini', 'README.pod', 'Changes' ],
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
        [ 'CopyFilesFromBuild' => {
            copy => ($args{copy_file} || [ '' ]),
            move => ($args{move_file} || [ '' ])
        } ]
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
        when (lc eq 'none') {
            # No release plugin
        }
        when ($_) {
            $self->add_plugins("$_")
        }
        default {
            # Empty string is the same as 'none'
        }
    }

    # Choose whether and where to archive releases
    if (_parse_bool($args{archive})) {
        $self->add_plugins(
            ['ArchiveRelease' => {
                directory => $args{archive_directory},
            } ]
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
        ['ReadmeAnyFromPod', 'text.build', {
            filename => 'README',
            type => 'text',
        }],
        # This one gets copied out of the build dir by default, and
        # does not become part of the dist.
        ['ReadmeAnyFromPod', 'pod.root', {
            filename => 'README.pod',
            type => 'pod',
            location => 'root',
        }],

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

    # Choose version control. This must be after 'NextRelease' so that
    # the Changes file is updated before committing.
    given (lc $args{vcs}) {
        when ('none') {
            # No-op
        }
        when ('git') {
            $self->add_plugins(
                ['Git::Check' => {
                    allow_dirty => [ 'dist.ini', 'README.pod', 'Changes' ],
                } ],
                [ 'Git::Commit' => {
                    allow_dirty => [ 'dist.ini', 'README.pod', 'Changes' ],
                } ],
                'Git::Tag',
                # This can't hurt. It's a no-op if github is not involved.
                'GithubMeta',
            );
        }
        default {
            croak "Unknown vcs: $_\nTry setting vcs = 'none' and setting it up yourself.";
        }
    }
}

1; # Magic true value required at end of module
__END__

=head1 SYNOPSIS

In dist.ini:

    [@RTHOMPSON]

=head1 DESCRIPTION

This plugin bundle, in its default configuration, is equivalent to:

    [AutoVersion]
    major = 0
    [GatherDir]
    [PruneCruft]
    [ManifestSkip]
    [MetaYAML]
    [License]
    [ExecDir]
    [ShareDir]
    [MakeMaker]
    [Manifest]
    [PkgVersion]
    [PodWeaver]
    [InstallGuide]
    [ReadmeAnyFromPod / text.build ]
    filename = README
    type = text
    [ReadmeAnyFromPod / pod.root ]
    filename = README.pod
    type = pod
    location = root
    [CriticTests]
    [PodTests]
    [HasVersionTests]
    [PortabilityTests]
    [UnusedVarsTests]
    [CompileTests]
    skip = Test$
    [KwaliteeTests]
    [ExtraTests]
    [ReportVersions]
    [MinimumPerl]
    [AutoPrereqs]
    [CheckChangesHasContent]
    [NextRelease]
    [TestRelease]
    [ConfirmRelease]
    [UploadToCPAN]
    [ArchiveRelease]
    directory = releases
    [Git::Check]
    allow_dirty = dist.ini
    allow_dirty = README.pod
    allow_dirty = Changes
    [Git::Commit]
    allow_dirty = dist.ini
    allow_dirty = README.pod
    allow_dirty = Changes
    [Git::Tag]
    [GithubMeta]

There are several options that can change the default configuation,
though.

=option -remove

This option can be used to remove specific plugins from the bundle. It
can be used multiple times.

Obviously, the default is not to remove any plugins.

Example:

    ; Remove these two plugins from the bundle
    -remove = CriticTests
    -remove = GithubMeta

=option version, version_major

This option is used to specify the version of the module. The default
is 'auto', which uses the AutoVersion plugin to choose a version
number. You can also set the version number manually, or choose
'disable' to prevent this bundle from supplying a version.

Examples:

    ; Use AutoVersion (default)
    version = auto
    version_major = 0
    ; Use manual versioning
    version = 1.14.04
    ; Provide no version, so that another plugin can handle it.
    version = disable

=option copy_file, move_file

If you want to copy or move files out of the build dir and into the
distribution dir, use these two options to specify those files. Both
of these options can be specified multiple times.

The most common reason to use this would be to put automatically
generated files under version control. For example, Github likes to
see a README file in your distribution, but if your README file is
auto-generated during the build, you need to copy each newly-generated
README file out of its build directory in order for Github to see it.

If you want to include an auto-generated file in your distribution but
you I<don't> want to include it in the build, use C<move_file> instead
of C<copy_file>.

The default is to move F<README.pod> out of the build dir. If you use
C<move_file> in your configuration, this default will be disabled, so
if you want it, make sure to include it along with your other
C<move_file>s.

Example:

    copy_file = README
    move_file = README.pod
    copy_file = README.txt

=option synopsis_is_perl_code

If this is set to true (the default), then the SynopsisTests plugin
will be enabled. This plugin checks the perl syntax of the SYNOPSIS
sections of your modules. Obviously, if your SYNOPSIS section is not
perl code (case in point: this module), you should set this to false.

Example:

    synopsis_is_perl_code = false

=option release

This option chooses the type of release to do. The default is 'real,'
which means "really upload the release to CPAN" (i.e. load the
C<UploadToCPAN> plugin). You can set it to 'fake,' in which case the
C<FakeRelease> plugin will be loaded, which simulates the release
process without actually doing anything. You can also set it to 'none'
if you do not want this module to load any release plugin, in which
case your F<dist.ini> file should load a release plugin directly. Any
other value for this option will be interpreted as a release plugin
name to be loaded.

Examples:

    ; Release to CPAN for real (default)
    release = real
    ; For testing, you can do fake releases
    release = fake
    ; Or you can choose no release plugin
    release = none
    ; Or you can specify a specific release plugin.
    release = OtherReleasePlugin

=option archive, archive_directory

If set to true, the C<archive> option copies each released version of
the module to an archive directory, using the C<ArchiveRelease>
plugin. This is the default. The name of the archive directory is
specified using C<archive_directory>, which is F<releases> by default.

Examples:

    ; archive each release to the "releases" directory
    archive = true
    archive_directory = releases
    ; Or don't archive
    archive = false

=option vcs

This option specifies which version control system is being used for
the distribution. Integration for that version control system is
enabled. The default is 'git', and currently the only other option is
'none', which does not load any version control plugins.

=option allow_dirty

This corresponds to the option of the same name in the Git::Check and
Git::Commit plugins. Briefly, files listed in C<allow_dirty> are
allowed to have changes that are not yet committed to git, and during
the release process, they will be checked in (committed).

The default is F<dist.ini>, F<Changes>, and F<README.pod>. If you
override the default, you must include these files manually if you
want them.

This option only has an effect if C<vcs> is 'git'.

=for Pod::Coverage  configure mvp_multivalue_args

=head1 BUGS AND LIMITATIONS

This module should be more configurable. Suggestions welcome.

Please report any bugs or feature requests to
C<rct+perlbug@thompsonclan.org>.
