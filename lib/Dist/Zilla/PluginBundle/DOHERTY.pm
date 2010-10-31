use strict;
use warnings;
use diagnostics;

package Dist::Zilla::PluginBundle::DOHERTY;
BEGIN {
  $Dist::Zilla::PluginBundle::DOHERTY::VERSION = '0.001';
}
# ABSTRACT: Dist::Zilla configuration the way DOHERTY does it
# ENCODING: utf-8


# Dependencies
use autodie 2.00;
use Moose 0.99;
use Moose::Autobox;
use namespace::autoclean 0.09;

use Dist::Zilla 4.102341; # dzil authordeps
use Dist::Zilla::Plugin::Git::Check                     qw();
use Dist::Zilla::Plugin::AutoPrereqs                    qw();
use Dist::Zilla::Plugin::MinimumPerl                    qw();
use Dist::Zilla::Plugin::Repository         0.13        qw(); # v2 Meta spec
use Dist::Zilla::Plugin::Bugtracker         1.102670    qw(); # to set bugtracker in dist.ini
use Dist::Zilla::Plugin::PodWeaver                      qw();
use Dist::Zilla::Plugin::InstallGuide                   qw();
use Dist::Zilla::Plugin::ReadmeFromPod                  qw();
use Dist::Zilla::Plugin::CopyReadmeFromBuild            qw();
use Dist::Zilla::Plugin::Git::NextVersion               qw();
use Dist::Zilla::Plugin::PkgVersion                     qw();
use Dist::Zilla::Plugin::NextRelease                    qw();
use Dist::Zilla::Plugin::CheckChangesHasContent         qw();
use Dist::Zilla::Plugin::Git::Commit                    qw();
use Dist::Zilla::Plugin::Git::Tag                       qw();
use Dist::Zilla::PluginBundle::TestingMania             qw();
use Dist::Zilla::Plugin::LocalInstall                   qw();

use Pod::Weaver::Section::BugsAndLimitations 1.102670   qw(); # To read from D::Z::P::Bugtracker

with 'Dist::Zilla::Role::PluginBundle::Easy';


has fake_release => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { $_[0]->payload->{fake_release} || 0 },
);


has bugtracker => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->payload->{bugtracker} || 'http://github.com/doherty/%s/issues' },
);


has add_tests => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => '',
);


has skip_tests => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => '',
);


has tag_format => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->payload->{tag_format} || 'release-%v' },
);


has version_regexp => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->payload->{version_regexp} || '^release-(.+)$' },
);


sub configure {
    my $self = shift;

    $self->add_plugins(
        # Version number
        [ 'Git::NextVersion' => { version_regexp => $self->version_regexp } ],
        'PkgVersion',

        # Gather & prune
        'GatherDir',
        'PruneCruft',
        'ManifestSkip',

        # Generate dist files & metadata
        'ReadmeFromPod',
        'CopyReadmeFromBuild',
        'License',
        'MinimumPerl',
        'AutoPrereqs',
        'MetaYAML',
        'Repository',
        [ 'Bugtracker' => { web => $self->bugtracker } ],

        # File munging
        [ 'PodWeaver' => { config_plugin => '@DOHERTY' } ],

        # Build system
        'ExecDir',
        'ShareDir',
        'MakeMaker',

        # Manifest stuff must come after generated files
        'Manifest',

        # Before release
        'Git::Check',
        [ 'CheckChangesHasContent' => { changelog => 'CHANGES' } ],
        'TestRelease',
        'ConfirmRelease',

        # Release
        ( $self->fake_release ? 'FakeRelease' : 'UploadToCPAN' ),

        # After release
        'LocalInstall',
        'Git::Commit',
        [ 'Git::Tag' => { tag_format => $self->tag_format } ],
        [ 'NextRelease' => { filename => 'CHANGES', format => '%-9v %{yyyy-MM-dd}d' } ],
    );

    $self->add_bundle(
        'TestingMania' => {
            add => $self->add_tests,
            skip => $self->skip_tests,
        }
    );
}


__PACKAGE__->meta->make_immutable;

1;



=pod

=encoding utf-8

=head1 NAME

Dist::Zilla::PluginBundle::DOHERTY - Dist::Zilla configuration the way DOHERTY does it

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    # in dist.ini
    [@DOHERTY]

=head1 DESCRIPTION

C<Dist::Zilla::PluginBundle::DOHERTY> provides shorthand for
a L<Dist::Zilla> configuration like:

    [Git::Check]
    [@Filter]
    -bundle = @Basic    ; Equivalent to using [@Basic]
    -remove = Readme    ; For use with [CopyReadmeFromBuild]
    -remove = ExtraTests

    [AutoPrereqs]
    [MinimumPerl]
    [Repository]
    [Bugtracker]
    :version = 1.102670 ; To set bugtracker
    web = http://github.com/doherty/%s/issues
    [PodWeaver]
    config_plugin = @DOHERTY
    [InstallGuide]
    [ReadmeFromPod]
    [CopyReadmeFromBuild]

    [Git::NextVersion]
    [PkgVersion]
    [NextRelease]
    filename = CHANGES
    format   = %-9v %{yyyy-MM-dd}d
    [CheckChangesHasContent]
    changelog = CHANGES

    [Git::Commit]
    [Git::Tag]

    [@TestingMania]
    [LocalInstall]

=head1 USAGE

Just put C<[@DOHERTY]> in your F<dist.ini>. You can supply the following
options:

=over 4

=item *

C<fake_release> specifies whether to use C<L<FakeRelease|Dist::Zilla::Plugin::FakeRelease>>
instead of C<L<UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN>>. Defaults to 0.

=item *

C<bugtracker> specifies a URL for your bug tracker. This is passed to C<L<Bugtracker|Dist::Zilla::Plugin::Bugtracker>>,
so the same interpolation rules apply. Defaults to C<http://github.com/doherty/%s/issues'>.

=item *

C<add_tests> is a comma-separated list of testing plugins to add
to C<L<TestingMania|Dist::Zilla::PluginBundle::TestingMania>>.

=item *

C<skip_tests> is a comma-separated list of testing plugins to skip in
C<L<TestingMania|Dist::Zilla::PluginBundle::TestingMania>>.

=item *

C<tag_format> specifies how a git release tag should be named. This is
passed to C<L<Git::Tag|Dist::Zilla::Plugin::Git::Tag>>.

=item *

C<version_regex> specifies a regexp to find the version number part of
a git release tag. This is passed to C<L<Git::NextVersion|Dist::Zilla::Plugin::Git::NextVersion>>.

=back

=head1 SEE ALSO

C<L<Dist::Zilla>>

=for Pod::Coverage configure

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Dist-Zilla-PluginBundle-DOHERTY/>.

The development version lives at L<http://github.com/doherty/Dist-Zilla-PluginBundle-DOHERTY>
and may be cloned from L<git://github.com/doherty/Dist-Zilla-PluginBundle-DOHERTY>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://github.com/doherty/Dist-Zilla-PluginBundle-DOHERTY/issues>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Mike Doherty.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut


__END__

