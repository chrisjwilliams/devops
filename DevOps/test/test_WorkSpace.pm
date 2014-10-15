package test_WorkSpace;
use strict;
use DevOps::WorkSpace;
use DevOps::TestUtils::TestProject;
use Paf::File::TempDir;
use Paf::Platform::TestHost;;
1;

sub new {
    my $class=shift;
    my $self={};
    bless $self, $class;
    $self->{tmpdir}=Paf::File::TempDir->new();

    return $self;
}

sub tests {
    return qw(test_new test_construct test_empty_environment test_environment test_dependency_persistence test_workspace_dependencies test_environment_from_project test_build_out test_build_tasks test_build_commands);
}

sub test_new {
    my $self=shift;
    Paf::TestSuite::assert_throw("DevOps::WorkSpace->new()");
    Paf::TestSuite::assert_throw("DevOps::WorkSpace->new(undef)");
    Paf::TestSuite::assert_throw("DevOps::WorkSpace->new('')");
}

sub test_construct {
    my $self=shift;

    my $tmpdir=$self->{tmpdir};
    my $ws=DevOps::WorkSpace->new($tmpdir->dir());

    # -- bad project passed
    eval { $ws->construct(undef) };
    die "expecting throw", if( ! $@ );

    # -- good project passed
    my $project=DevOps::TestUtils::TestProject->new();
    die("not expecting is_constructed() true"), if ($ws->is_constructed());
    $ws->construct($project);
    
    my $dir=$tmpdir->dir()."/devops";
    die("expecting to find $dir"), unless ( -d $dir );
    my $file=$dir."/config.devops";
    die("expecting to find $file"), unless ( -f $file );

    die("expecting is_constructed() true"), unless ($ws->is_constructed());
}

sub create_test_area {
    my $self=shift;
    my $name=shift||"name";
    my $version=shift||"version";

    # - get a new directory for the workspace
    my $tmpdir;
    my $count=0;
    do {
        $tmpdir=$self->{tmpdir}->dir()."/".$name."_".$version."_".$count;
        $count++;
    }
    while( -d $tmpdir );
    mkdir $tmpdir or die "unable to make dir $tmpdir $!\n";

    my $ws=DevOps::WorkSpace->new($tmpdir);
    my $project=DevOps::TestUtils::TestProject->new(@_);
    $ws->construct($project);

    return $ws;
}

sub test_empty_environment {
    my $self=shift;

    my $ws=$self->create_test_area();

    my $env=$ws->environment("test");
    my $env2=$ws->environment("test");
    die("expecting consitent environment object"), unless( $env == $env2 );
    die("expecting consitent environment object"), unless( $env == $env2 );
    die("expecting an empty environment"), unless( $env->size() == 0 );

    my $env3=$ws->environment("runtime");
    die("not expecting same environment object"), if( $env == $env3 );
}

sub test_environment {
    my $self=shift;

    my $tmpdir="";
    {
        my $ws=$self->create_test_area();
        $tmpdir=$ws->location();
        my $env=$ws->environment("test");
        $env->set("variable", "value");
        die("not expecting an empty environment"), unless( $env->size() == 1 );
    }

    # -- test persistency
    my $ws=DevOps::WorkSpace->new($tmpdir);
    die("expecting is_constructed() true"), unless ($ws->is_constructed());
    my $env=$ws->environment("test");
    die("not expecting an empty environment"), unless( $env->size() == 1 );
}

sub test_environment_from_project {
    my $self=shift;

    my $ws=$self->create_test_area();
    my $project=$ws->project();
    my $project_env=DevOps::Environment->new();
    my $project_value="project_value";
    my $project_var="library_dir";
    $project_env->set($project_var, $project_value);
    $project->add_environment("base", $project_env);
    die("problem with project"), if ($project->environment("base") ne $project_env);
    die("problem with project"), if ($project->environment("base")->var($project_var) ne $project_value);
    
    # -- workspace should import projects environment
    my $env2=$ws->environment("base");
    my $value=$env2->var($project_var);
    die("expecting $project_value, got undef"), if ( ! defined $value );
    die("expecting $project_value, got $value"), if ( $project_value ne $value );

    my $workspace_value="workspace_value";
    $env2->set($project_var, $workspace_value);
    $ws->save();
    die("value should not be exported to project"), if ($project->environment("base")->var($project_var) ne $project_value);

    # -- ensure workspace variables override projects
    my $ws2=DevOps::WorkSpace->new($ws->location());
    my $env3=$ws->environment("base");
    $value=$env3->var($project_var);
    die("expecting $workspace_value, got undef"), if ( ! defined $value );
    die("expecting $workspace_value, got $value"), if ( $workspace_value ne $value );
}

sub test_dependency_persistence {
    my $self=shift;

    my $name="name_1";
    my $version="version_1";
    my $name_2="name_2";
    my $version_2="version_2";
    my $tmpdir="";
    {
        my $ws=$self->create_test_area();
        $tmpdir=$ws->location();
        
        $ws->add_dependency($name, $version);
        my @deps=$ws->dependencies();
        die("expecting 1 dep, got ", $#deps + 1), unless($#deps == 0);

        my $dep=DevOps::Dependency->new( $name_2, $version_2);
        $ws->add_dependencies($dep);

        @deps=$ws->dependencies();
        die("expecting 2 deps, got ", $#deps + 1), unless($#deps == 1);
    }

    # -- test persistency
    my $ws=DevOps::WorkSpace->new($tmpdir);
    die("expecting is_constructed() true"), unless ($ws->is_constructed());

    my @deps=$ws->dependencies();
    die("expecting 2 deps, got ", $#deps + 1), unless($#deps == 1);
}

sub test_workspace_dependencies {
    my $self=shift;
    my $name="name_1";
    my $version="version_1";
    my $name_2="name_2";
    my $version_2="version_2";
    my $ws_location="";
    my $ws2_location="";
    {
        my $ws=$self->create_test_area();
        $ws_location=$ws->location();
        my $ws2=$self->create_test_area($name_2, $version_2);
        $ws2_location=$ws2->location();
        
        my $dep1=DevOps::Dependency->new( $name, $version );
        my $dep2=DevOps::Dependency->new( $name_2, $version_2 );

        # -- no dependencies
        eval { $ws->set_dependent_workspace($dep2, $ws2); };
        die "expecting throw because of unknown workspace", unless ("$@");

        # -- wrong dependency
        $ws->add_dependencies($dep1);
        eval { $ws->set_dependent_workspace($dep2, $ws2); };
        die "expecting throw because of unknown workspace", unless ("$@");

        # -- correct dependency
        $ws->add_dependencies($dep2);
        $ws->set_dependent_workspace($dep2, $ws2);

        my $dep_ws=$ws->workspace_dependency($dep2);
        die("unexpected workspace"), unless( $dep_ws eq $ws2_location );
        
    }

    # -- test persistency
    my $ws=DevOps::WorkSpace->new($ws_location);
    die("expecting is_constructed() true"), unless ($ws->is_constructed());
    my $dep2=DevOps::Dependency->new( $name_2, $version_2 );
    my $dep_ws=$ws->workspace_dependency($dep2);
    die("unexpected workspace"), unless( $dep_ws eq $ws2_location );

}

sub test_build_out {
    my $self=shift;
    my $ws=$self->create_test_area();

    my $platform=Paf::Platform::TestHost->new();
    my $build_out=$ws->build_out($platform, { type => ["debug", "prof"],
                                              toolchain => ["gcc", "gfortran"],
                                              variants => [ "multithreaded" ]
                                            });

    die("no build_out"), unless( $build_out );
    die("expecting debug in location"), unless( $build_out->work_location()=~/debug/ );
    die("expecting gcc in location"), unless( $build_out->work_location()=~/gcc/ );
    die("expecting gfortran in location"), unless( $build_out->work_location()=~/gfortran/ );
    die("expecting multithreaded in location"), unless( $build_out->work_location()=~/multithreaded/ );
    die("execting loction to exist"), unless ( -d $build_out->work_location() );
}

sub test_build_tasks {
    my $self=shift;
    my $ws=$self->create_test_area();

    my @tasks=$ws->build_tasks();
    die("expecting 3 tasks, got @tasks"), unless ( scalar @tasks == 3 );
    die("expecting setup, got '", $tasks[0], "'" ), unless ( $tasks[0] eq "setup" );
    die("expecting build, got '", $tasks[1], "'" ), unless ( $tasks[1] eq "build" );
    die("expecting install, got '", $tasks[2], "'" ), unless ( $tasks[2] eq "install" );
}

sub test_build_commands {
    my $self=shift;
    my $ws=$self->create_test_area();

    my $task_name="task_name";
    #assert_throw($ws->build_commands());

    # no task defined shouldn't throw
    my @cmds=$ws->build_commands($task_name);
    die("not expecting any commands"), if(@cmds);
    
}

sub dump_node {
    my $self=shift;
    my $node=shift;

    require Paf::Configuration::XmlWriter;
    my $writer=new Paf::Configuration::XmlWriter;
    $writer->write($node, \*STDOUT);
}
