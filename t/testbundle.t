#!perl
use Test::Most;

use strict;
use warnings;

use autodie;
use Test::DZil;

use Moose::Autobox;

use Dist::Zilla::PluginBundle::RTHOMPSON;

my %tzil = (
    normal => Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => dist_ini({
                    name     => 'DZT-Sample',
                    abstract => 'Sample DZ Dist',
                    # Need no version
                    # version  => '0.001',
                    author   => 'E. Xavier Ample <example@example.org>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                }, [
                    '@RTHOMPSON', {
                        release => 'fake',
                    }
                ])
            },
        }
    ),
    staticversion => Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => dist_ini({
                    name     => 'DZT-Sample',
                    abstract => 'Sample DZ Dist',
                    # Need no version
                    # version  => '0.001',
                    author   => 'E. Xavier Ample <example@example.org>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                }, [
                    '@RTHOMPSON', {
                        release => 'fake',
                        version => '1.5',
                    }
                ])
            },
        }
    ),
    disableversion => Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => dist_ini({
                    name     => 'DZT-Sample',
                    abstract => 'Sample DZ Dist',
                    # Need no version
                    version  => '0.001',
                    author   => 'E. Xavier Ample <example@example.org>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                }, [
                    '@RTHOMPSON', {
                        release => 'fake',
                        version => 'none',
                    }
                ])
            },
        }
    ),
    emptyversion => Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => dist_ini({
                    name     => 'DZT-Sample',
                    abstract => 'Sample DZ Dist',
                    # Need no version
                    version  => '0.001',
                    author   => 'E. Xavier Ample <example@example.org>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                }, [
                    '@RTHOMPSON', {
                        release => 'fake',
                        version => '',
                    }
                ])
            },
        }
    ),
);

for my $name (keys %tzil) {
    my $tzil = $tzil{$name};
    lives_ok { $tzil->build; } "$name dist builds successfully";
    my $readme_content = $tzil->slurp_file('build/README');
    like($readme_content, qr/\S/, "$name dist has a non-empty README file");
}

done_testing(2 * scalar keys %tzil);
