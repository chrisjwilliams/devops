package test_Api;
use strict;
use DevOps::TestUtils::TestProject;
use DevOps::TestUtils::TestWorkSpace;
use DevOps::Api;
use DevOps::Dependency;
use FileHandle;
use File::Sync qw(sync);
use Paf::File::TempDir;
use Paf::Platform::TestHost;
1;

sub new {
    my $class=shift;
    my $self={};
    bless $self, $class;

    $self->{testproject_1_name}="testproject_1_name";
    $self->{testproject_2_name}="testproject_2_name";
    $self->{testproject_3_name}="testproject_3_name";
    $self->{testproject_1_version}="testproject_1_version";
    $self->{testproject_2_version}="testproject_2_version";
    $self->{testproject_3_version}="testproject_3_version";

    # set up a test configuration
    $self->{tmpdir}=Paf::File::TempDir->new();
    $self->{config}=DevOps::Config->new();
    $self->{config}->set_project_path($self->{tmpdir}->dir());
    my $workspace_dir=$self->{tmpdir}->dir()."/workspaces";
    mkdir $workspace_dir or die "unable to make $workspace_dir : $!";
    $self->{config}->set_workspace_dir($workspace_dir);
    
    return $self;
}

sub tests {
    return qw(test_list_no_projects test_list test_setup_workspace test_resolve_dependencies test_checkout_src test_get_environment test_build)
}

sub add_project {
    my $self=shift;
    my $name=shift;
    my $version=shift;

    my $loc=$self->{tmpdir}->dir()."/$name";
    if( ! -d $loc )
    {
        mkdir $loc or die "unable to create dir $loc $!";
    }
    $loc.="/$version";
    if( ! -d $loc )
    {
        mkdir $loc or die "unable to create dir $loc $!";
    }
    return new DevOps::TestUtils::TestProject($name, $version, $loc);
    
}

sub test_list_no_projects {
    my $self=shift;

    # -- no projects
    my $api=new DevOps::Api($self->{config});
    die "not expecting any projects", if($api->find_projects());
}

sub test_list {
    my $self=shift;
    
    # -- create multi-projects 
    $self->add_project($self->{testproject_1_name}, $self->{testproject_1_version});
    $self->add_project($self->{testproject_2_name}, $self->{testproject_2_version});
    $self->add_project($self->{testproject_3_name}, $self->{testproject_3_version});

    my $api=new DevOps::Api($self->{config});
    die ("expecting 3 projects, got ", scalar $api->find_projects()), if($api->find_projects() != 3);
}

sub test_setup_workspace {
    my $self=shift;

    $self->add_project($self->{testproject_1_name}, $self->{testproject_1_version});

    my $api=new DevOps::Api($self->{config});

    # -- known project requested
    my $ws=$api->setup_workspace($self->{testproject_1_name}, $self->{testproject_1_version});
    die("expecting a workspace"), unless (defined $ws);

    # -- already exisiting project requested
    my $ws2=$api->setup_workspace($self->{testproject_1_name}, $self->{testproject_1_version});
    die("expecting the same workspace"), unless ($ws == $ws2);

    # -- unknown project requested
    my $ws3=$api->setup_workspace("unknown_project", $self->{testproject_1_version});
    die("not expecting a workspace" ), if (defined $ws3);
}

sub test_resolve_dependencies {
    my $self=shift;

    $self->add_project($self->{testproject_1_name}, $self->{testproject_1_version});
    $self->add_project($self->{testproject_2_name}, $self->{testproject_1_version});
    $self->add_project($self->{testproject_2_name}, $self->{testproject_2_version});
    $self->add_project($self->{testproject_3_name}, $self->{testproject_3_version});

    my $api=new DevOps::Api($self->{config});
    my $ws_1=$api->setup_workspace($self->{testproject_1_name}, $self->{testproject_1_version});
    my $ws_2=$api->setup_workspace($self->{testproject_2_name}, $self->{testproject_2_version});
    my $ws_3=$api->setup_workspace($self->{testproject_3_name}, $self->{testproject_3_version});

    # add some dependenices
    $ws_1->add_dependency( $self->{testproject_2_name}, $self->{testproject_1_version} );
    $ws_1->add_dependency( $self->{testproject_3_name}, $self->{testproject_3_version} );
    $api->resolve_workspace_deps($ws_1);

    # verify dependencies
    my @deps=$ws_1->dependencies();
    die("expecting two dependencies, got @deps"), if( scalar @deps != 2 );
    foreach my $dep ( $ws_1->dependencies() ) {
    }
}

sub test_checkout_src {
    my $self=shift;

    my $api=new DevOps::Api($self->{config});
    my $ws=new DevOps::TestUtils::TestWorkSpace;
    my $project=$ws->project();
    
    # case : empty src list
    $api->checkout_src($ws);
    die("not expecting checkout dir"), if ( -d $ws->checkout_dir() );

    # case : unknown Source type
    my $unknown=new DevOps::Source(undef, "unknown", {});
    $project->add_sources($unknown);
    eval { $api->checkout_src($ws); };
    die "expecting failure because of unknown type : @_", if(@_);
    $project->remove_sources($unknown);
    die("not expecting checkout dir"), if ( -d $ws->checkout_dir() );

    # -- create a "repo" to copy form
    my $repo_dir=new Paf::File::TempDir;
    my $repo_file="test_file";
    my $full_repo_file=$repo_dir->dir()."/".$repo_file;
    my $fh=FileHandle->new(">".$full_repo_file) || die ("unable to create file $full_repo_file $!");
    print $fh "$repo_file";
    $fh->close();
    sync();

    # case : no sub_dir -> checkout directly to the src file
    my $src=new DevOps::Source(undef, "copy", { src => $repo_dir->dir() });
    $project->add_sources($src);
    $api->checkout_src($ws);
    die("expecting checkout dir"), unless ( -d $ws->checkout_dir() );
    die("expecting checkout file $repo_file"), unless ( -f $ws->checkout_dir()."/$repo_file" );
    $project->remove_sources($src);
    unlink $ws->checkout_dir()."/$repo_file";
    rmdir $ws->checkout_dir() || die "unable to remove directory $!";

    # case : only sub_dir src
    my $subdir_src=new DevOps::Source("test_sub_dir", "copy", { src => $repo_dir->dir() });
    $project->add_sources($subdir_src);
    $api->checkout_src($ws);
    die("expecting checkout dir"), unless ( -d $ws->checkout_dir() );
    die("expecting checkout dir"), unless ( -d $ws->checkout_dir()."/test_sub_dir" );
    die("expecting checkout file $repo_file"), unless ( -f $ws->checkout_dir()."/test_sub_dir/$repo_file" );
    unlink $ws->checkout_dir()."/test_sub_dir/$repo_file";
    rmdir $ws->checkout_dir()."/test_sub_dir" || die "unable to remove directory $!";
    rmdir $ws->checkout_dir() || die "unable to remove directory $!";

    # case : mix sub dir and top level src
    $project->add_sources($src);
    $api->checkout_src($ws);
    die("expecting checkout dir"), unless ( -d $ws->checkout_dir() );
    die("expecting checkout file $repo_file"), unless ( -f $ws->checkout_dir()."/$repo_file" );
    die("expecting checkout dir"), unless ( -d $ws->checkout_dir()."/test_sub_dir" );
    die("expecting checkout file $repo_file"), unless ( -f $ws->checkout_dir()."/test_sub_dir/$repo_file" );
}

sub test_get_environment {
    my $self=shift;

    my $api=new DevOps::Api($self->{config});
    my $ws=new DevOps::TestUtils::TestWorkSpace;

    my $test_env_name="test_env_name";
    my $test_name="test_name";
    my $test_value="test_value";

    # -- empty env
    my $env=$api->get_environment($ws, $test_env_name);
    die ("expecting zero size env"), if ( $env->size() != 0 );

    # -- unresolved project deps
    my $project=new DevOps::TestUtils::TestProject;
    my $project_env=DevOps::Environment->new( { $test_name, $test_value } );
    $project->add_environment($test_env_name, $project_env);

    my $pm=$api->get_project_manager();
    $pm->import_project($project, $pm->store_ids());

    my $dep=new DevOps::Dependency($project->name(), $project->version());
    $ws->add_dependencies($dep);

    $env=$api->get_environment($ws, $test_env_name);
    die ("expecting size env=2, got ", $env->size() ), if ( $env->size() != 2 );
    my $namespace=$project->name()."::";
    my $variable=$namespace.$test_name;
    # TODO die ("expecting $variable=$test_value, got ", $env->var($variable)), unless ( $test_name eq $env->var($variable) );
    $namespace.=$project->version()."::";
    $variable=$namespace.$test_name;
    # TODO die ("expecting $variable=$test_value, got ", $env->var($variable)), unless ( $test_name eq $env->var($variable) );
}

sub test_build {
    my $self=shift;

    my $api=new DevOps::Api($self->{config});
    $self->add_project($self->{testproject_1_name}, $self->{testproject_1_version});
    my $ws_1=$api->setup_workspace($self->{testproject_1_name}, $self->{testproject_1_version});

    my $platform = Paf::Platform::TestHost->new();

    # undefined toolchain
    eval { $api->build_workspace($ws_1, undef, $platform, {}) };
    die("expecting throw"), unless "$@";
    die("expecting toolchain error, got ", $@), unless $@=~/toolchain/;

    # defined toolchain, empty commands
    my $variants = { toolchain => [ "test_compiler" ] };
    #$api->build_workspace($ws_1, undef, $platform, $variants);

    # with commands
    my $setup_cmd="setup_cmd";
    my $build_cmd="build_cmd";
    my $install_cmd="install_cmd";

    $ws_1->project()->add_task_code("build", "setup", $platform, undef, $setup_cmd);
    $ws_1->project()->add_task_code("build", "build", $platform, undef, $build_cmd);
    $ws_1->project()->add_task_code("build", "install", $platform, undef, $install_cmd);

    $api->build_workspace($ws_1, [ "setup" ], $platform, $variants);
    my @exec=$platform->executed_commands();
    die("expecting $setup_cmd, got @exec"), unless $setup_cmd eq "@exec";

    my $report=$api->build_workspace($ws_1, [ "build" ], $platform, $variants);
    @exec=$platform->executed_commands();
    die("expecting $build_cmd, got @exec"), unless $build_cmd eq "@exec";
    die("not expecting has_failed"), if $report->has_failed();

    $api->build_workspace($ws_1, [ "install" ], $platform, $variants);
    @exec=$platform->executed_commands();
    die("expecting $install_cmd, got @exec"), unless $install_cmd eq "@exec";
}

sub build_environment {
    my $self=shift;
}
