package test_Project;
use strict;
use DevOps::Project;
use DevOps::TestUtils::TestProject;
use Paf::File::TempDir;
use Paf::Platform::TestHost;
use File::Sync;
1;

sub new {
    my $class=shift;
    my $self={};
    bless $self, $class;
    $self->{tmpdir}=Paf::File::TempDir->new();

    return $self;
}

sub tests {
    return qw(test_new test_empty_environment test_environment test_sources test_dependency_persistence test_task_code);
}

sub test_new {
    my $self=shift;
    Paf::TestSuite::assert_throw("DevOps::Project->new()");
    Paf::TestSuite::assert_throw("DevOps::Project->new(undef)");
    Paf::TestSuite::assert_throw("DevOps::Project->new('')");
}

sub test_empty_environment {
    my $self=shift;

    my $project=DevOps::TestUtils::TestProject->new();
    my $env=$project->environment("test");
    my $env2=$project->environment("test");
    die("expecting consitent environment object"), unless( $env == $env2 );
    die("expecting consitent environment object"), unless( $env == $env2 );
    die("expecting an empty environment"), unless( $env->size() == 0 );

    my $env3=$project->environment("runtime");
    die("not expecting same environment object"), if( $env == $env3 );
}

sub test_environment {
    my $self=shift;

    my $project=DevOps::TestUtils::TestProject->new();
    my $tmpdir=$project->location();
    my $uid=$project->id();
    {
        my $env=$project->environment("test");
        $env->set("variable", "value");
        die("not expecting an empty environment"), unless( $env->size() == 1 );
        $project->save();
    }

    # -- test persistency
    my $project2=DevOps::Project->new($uid, $tmpdir);
    my $env=$project2->environment("test");
    die("not expecting an empty environment : \"", $env->dump(), "\""), unless( $env->size() == 1 );
}

sub test_dependency_persistence {
    my $self=shift;

    my $name="name_1";
    my $version="version_1";
    my $name2="name_2";
    my $version2="version_2";
    my $project=DevOps::TestUtils::TestProject->new();
    my $tmpdir=$project->location();
    my $uid=$project->id();
    {
        my @deps=$project->dependencies();
        die("expecting 0 dep, got ", $#deps + 1), unless($#deps == -1);

        my $dep=DevOps::Dependency->new($name, $version);
        $project->add_dependencies($dep);

        @deps=$project->dependencies();
        die("expecting 1 deps, got ", $#deps + 1), unless($#deps == 0);

        my $dep2=DevOps::Dependency->new($name2, $version2);
        $project->add_dependencies($dep2);

        @deps=$project->dependencies();
        die("expecting 2 deps, got ", $#deps + 1), unless($#deps == 1);
    }
    $project->save();
    File::Sync::sync();

    # -- test persistency
    my $project2=DevOps::Project->new($uid, $tmpdir);

    my @deps=$project2->dependencies();
    die("expecting 2 deps, got ", $#deps + 1), unless($#deps == 1);
}

sub test_sources {
    my $self=shift;

    my $project=DevOps::TestUtils::TestProject->new();
    my $tmpdir=$project->location();
    my $uid=$project->id();
    my $sub_dir="sub_dir";
    my $type="type";
    my $src=DevOps::Source->new(undef, $type);
    my $sub_src=DevOps::Source->new($sub_dir, $type);

    # -- empty sources
    my @srcs=$project->sources();
    die("expecting 0 srcs, got ", $#srcs + 1), unless($#srcs == -1);

    # - add sources
    $project->add_sources($sub_src);
    @srcs=$project->sources();
    die("expecting 1 src, got ", $#srcs + 1), unless($#srcs == 0);
    die("expecting sub_dir=$sub_dir, got ", $srcs[0]->sub_dir() ), unless( $srcs[0]->sub_dir() eq $sub_dir );
    die("expecting vcs_type=$type, got ", $srcs[0]->vcs_type() ), unless( $srcs[0]->vcs_type() eq $type );
    $project->add_sources($src);
    @srcs=$project->sources();
    die("expecting 2 src, got ", $#srcs + 1), unless($#srcs == 1);

    # -- verify ordering (undef src_dir first)
    die("expecting no sub_dir, got ", $srcs[0]->sub_dir() ), if( defined $srcs[0]->sub_dir() );
    die("expecting sub_dir=$sub_dir, got ", $srcs[1]->sub_dir() ), unless( $srcs[1]->sub_dir() eq $sub_dir );

    $project->save();

    my $project2=DevOps::Project->new($uid, $tmpdir);
    @srcs=$project2->sources();
    die("expecting 2 src, got ", $#srcs + 1), unless($#srcs == 1);
    die("expecting no sub_dir, got ", $srcs[0]->sub_dir() ), if( defined $srcs[0]->sub_dir() );
    die("expecting 2 src, got ", $#srcs + 1), unless($#srcs == 1);
    die("expecting vcs_type=$type, got ", $srcs[0]->vcs_type() ), unless( $srcs[0]->vcs_type() eq $type );
}

sub test_task_code {
    my $self=shift;

    my $project=DevOps::TestUtils::TestProject->new();

    my $workflow="test_workflow";
    my $task_name="test_task";
    my @code=qw(line_1 line_2 line_3);
    my $platform=new Paf::Platform::TestHost;

    # generic put/get with different params
    $project->add_task_code($workflow, $task_name, undef, undef, @code);
    my @saved_code=$project->task_code($workflow, $task_name, undef, undef);
    die("expecting @code, got @saved_code"), unless ("@code" eq "@saved_code" );
    @saved_code=$project->task_code($workflow, $task_name, $platform, undef);
    die("expecting @code, got @saved_code"), unless ("@code" eq "@saved_code" );
    @saved_code=$project->task_code($workflow, $task_name, $platform, { type => [ qw( debug profiled ) ] } );
    die("expecting @code, got @saved_code"), unless ("@code" eq "@saved_code" );

    # -- specialization put/get with different params
    print "specialization test\n";
    my @specialized_code=qw(line_1 line_2 specialized_line_3);
    $project->add_task_code($workflow, $task_name, undef, { type => [ qw( debug profiled ) ] }, @specialized_code );

    @saved_code=$project->task_code($workflow, $task_name, $platform, { type => [ qw( debug profiled ) ] } );
    die("expecting @specialized_code, got @saved_code"), unless ("@specialized_code" eq "@saved_code" );

    @saved_code=$project->task_code($workflow, $task_name, undef, { type => [ qw( debug profiled ) ] } );
    die("expecting @specialized_code, got @saved_code"), unless ("@specialized_code" eq "@saved_code" );

    @saved_code=$project->task_code($workflow, $task_name, $platform, undef);
    die("expecting @code, got @saved_code"), unless ("@code" eq "@saved_code" );

    @saved_code=$project->task_code($workflow, $task_name, undef, undef);
    die("expecting @code, got @saved_code"), unless ("@code" eq "@saved_code" );

    # -- platform specific parameters
    my @platform_code=qw(platform_line_1 platform_line_2 platform_line_3);
    $project->add_task_code($workflow, $task_name, $platform, undef, @platform_code );

    @saved_code=$project->task_code($workflow, $task_name, $platform, undef );
    die("expecting @platform_code, got @saved_code"), unless ("@platform_code" eq "@saved_code" );

    @saved_code=$project->task_code($workflow, $task_name, undef, undef);
    die("expecting @code, got @saved_code"), unless ("@code" eq "@saved_code" );

    @saved_code=$project->task_code($workflow, $task_name, $platform, { type => [ qw( debug profiled ) ] } );
    die("expecting @specialized_code, got @saved_code"), unless ("@specialized_code" eq "@saved_code" );
}
