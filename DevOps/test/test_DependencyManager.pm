package test_DependencyManager;
use strict;
use DevOps::DependencyManager;
use DevOps::TestUtils::TestProject;
use Paf::File::TempDir;
1;

sub new {
    my $class=shift;
    my $self={};
    bless $self, $class;
    $self->{tmpdir}=Paf::File::TempDir->new();

    return $self;
}

sub tests {
    return qw(test_dependencies);
}

sub test_dependencies {
    my $self=shift;

    my $name="name_1";
    my $version="version_1";
    my $name_2="name_2";
    my $version_2="version_2";
    my $dep=DevOps::Dependency->new( $name_2, $version_2);

    my $config=Paf::Configuration::Node->new("test");

    {
        my $dm=DevOps::DependencyManager->new($config);
        $dm->add($name, $version);

        my @deps=$dm->dependencies();
        die("expecting 1 dep, got ", $#deps + 1), unless($#deps == 0);

        $dm->add_dependencies($dep);

        @deps=$dm->dependencies();
        die("expecting 2 deps, got ", $#deps + 1), unless($#deps == 1);

        die "expecting true", unless( $dm->has_dependency($dep) );

        $dm->save();
    }

    # -- test persistency
    my $dm=DevOps::DependencyManager->new($config);
    die "expecting true", unless( $dm->has_dependency($dep) );

    my @deps=$dm->dependencies();
    die("expecting 2 deps, got ", $#deps + 1), unless($#deps == 1);
}
