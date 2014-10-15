package DevOps::Api;
use strict;
use FindBin;
use Paf::File::PluginFactory;
use Paf::Platform::TaskSeries;
use DevOps::ProjectManager;
use DevOps::WorkSpaceManager;
use DevOps::Config;
use Carp;
1;

sub new {
    my $class=shift;
    my $self={};
    bless $self, $class;

    $self->{config}=shift || carp "no config provided";
    $self->{importers}=Paf::File::PluginFactory->new($self->{config}->importer_plugins(), "$FindBin::Bin/DevOps/VersionControl");

    return $self;
}

sub import
{
    my $self=shift;
    my $url=shift;
    #my $importer_type=shift || $url->type();

    # get importer plugin
    #my $importer=$self->{importers}->require($importer_type, $url);

    # pass it to the ProjectManager
    #my $pm=$self->get_project_manager();
    #$pm->import($importer, $url->basename());
}

sub resolve_workspace_deps {
    my $self=shift;
    my $workspace=shift;
    
    my $wm=$self->get_workspace_manager();
    foreach my $dep ( $workspace->dependencies() ) {
        (my $dep_ws)=$self->find_workspaces($dep->name(), $dep->version());
        if( defined $dep_ws ) {
            # - we found the dependency
            $workspace->set_dependent_workspace($dep, $dep_ws);
        }
    }
}

sub get_config {
    my $self=shift;
    return $self->{config};
}

sub get_project_manager
{
    my $self=shift;
    if(! defined $self->{pm})
    {
        $self->{pm}=DevOps::ProjectManager->new($self->{config}->project_path());
    }
    return $self->{pm};
}

sub get_workspace_manager
{
    my $self=shift;
    if(! defined $self->{wm})
    {
        $self->{wm}=DevOps::WorkSpaceManager->new($self->{config}->config_dir()."/workspace.db", $self->{config}->workspace_dir());
    }
    return $self->{wm};
}

# ------------- Application Functional Methods ---------------------------

sub build_workspace {
    my $self=shift;
    my $workspace=shift || carp "expecting workspace";
    my $task_list=shift;
    my $platform=shift || $self->_localhost();
    my $variants=shift || {};

    # -- check variants type is defined and set a default
    if( ! defined $variants->{type} ) {
        $variants->{type}=[ "release" ];
    }
    else {
        foreach my $elem ( @{$variants->{type}} ) {
            die("build type $elem not defined"), unless( grep($elem, $workspace->build_types()) );
        }
    }

    # -- construct the build environment
    my $wm=$self->get_workspace_manager();

    # -- create the local build area
    my $build_area=$workspace->build_out($platform, $variants);
    my $env=$build_area->env();
    $env->set("src_dir", $workspace->checkout_dir());

    # -- get dependents build environments
    foreach my $dep ( $workspace->dependencies() ) {
        if( defined (my $loc=$workspace->workspace_dependency($dep)) ) {
            # -- find the appropriate build area environment
            my $dep_ws=$self->get_workspace_manager()->get_workspace_from_location($loc);
            if( !defined $dep_ws ) {
                die "unable to find workspace at $loc\n";
            }
            my $dep_build_out=$workspace->search_build_out($platform, $variants);
            $env->merge_namespace( [ $dep->name(), $dep->version()], $dep_build_out->env());
            $env->merge_namespace( [ $dep->name() ], $dep_build_out->env());
        }
    }

    $env->merge($self->get_environment($workspace, "export", $platform));
    #$env->merge_namespace( [ "platform" ], new DevOps::Environment($platform->environment()) );

    # -- build a task list
    my $stop_task;
    if( !defined $task_list || scalar @$task_list == 0 ) {
        #@{$task_list}=$workspace->build_tasks();
        $stop_task=undef;
    }
    else {
        # -- verify passed task names exists
        foreach my $task_name ( @$task_list ) {
            die("task $task_name does not exist"), unless( grep($task_name, $workspace->build_tasks()) );
            $stop_task=$task_name;
        }
    }

    require Paf::Platform::Task;
    my $task_series=Paf::Platform::TaskSeries->new();

    foreach my $task_name ( $workspace->build_tasks() ) {
        my $task=new Paf::Platform::Task($platform);
        foreach my $line ( $workspace->build_commands($task_name, $platform, $variants) ) {
            $task->add($env->expandString($line));
        }
        $task_series->add_task( $task_name, $task );
    }

    # -- execute all our tasks
    my $report=$build_area->execute_sequence("build", $task_series, $stop_task);
    if( $report->has_failed() ) {
        print $report->error();
    }
    return $report;
}

#
# @brief create a workspace associated with the specified project
# @param search passed as a hash of search terms
#
sub setup_workspace {
    my $self=shift;
    my $name=shift;
    my $version=shift;

    # -- check we are not already in a workspace
    my $wm=$self->get_workspace_manager();
    if( defined ( my $ws=$wm->current_workspace( )) ) 
    {
        # -- if the workspace matches that requested then return it
        if( $ws->project_id()->name() eq $name && $ws->project_id()->version() eq $version )
        {
            return $ws;
        }
        die "refusing to construct a workspace inside another";
        return undef;
    }

    my $pm=$self->get_project_manager();
    (my $pid)=$pm->list( { "name" => $name, "version" => $version } );
    if(defined $pid) {
        my $ws=$wm->get_workspace($pid);
        if( ! defined $ws ) {

            # -- we need to create the workspace
            $ws=$wm->construct_workspace($pm->get($pid));

            # -- create the src directory
            $self->checkout_src($ws);

            # -- resolve dependencies
            $self->resolve_workspace_deps($ws);
        }
        return $ws;
    }
    return undef;
}

sub find_workspaces {
    my $self=shift;
    my $name=shift;
    my $version=shift;

    my $pm=$self->get_project_manager();
    my @pids=$pm->list( { "name" => $name, "version" => $version } );
    my @workspaces=();
    my $wm=$self->get_workspace_manager();
    foreach my $pid ( @pids ) {
        my $ws=$wm->get_workspace($pid);
        if( defined $ws ) {
            push @workspaces, $ws;
        }
    }
    return @workspaces;
}

#
# @brief return a list of all projects that match the search criteria 
# @param search passed as a hash of search terms
#        An empty or undefined search hash will return all the projects
#
sub find_projects {
    my $self=shift;
    my $pm=$self->get_project_manager();
    return $pm->list(@_);
}

#
# @brief construct the src directory inside the provided workspace
#
sub checkout_src {
    my $self=shift;
    my $workspace=shift || carp "no workspace provided";
    
    foreach my $src ( $workspace->project()->sources() ) {
        my $dest_dir=$workspace->checkout_dir();

        # -- create the parent directory if the checkout code is to be installed in a sub dir
        if( defined $src->sub_dir() ) {
            if( ! -d $dest_dir ) {
                mkdir $dest_dir || die "unable to create dir ", $dest_dir;
            }
            $dest_dir.="/".($src->sub_dir()); 
        }

        # -- checkout the code
        if( defined $src->vcs_type() && $src->vcs_type() ne "" )
        {
            my $type=$src->vcs_type();
            if($type!~/.*::.+/) { 
                $type=~s/\b(\w)/\U$1/; # capitalise the first letter 
                $type="DevOps::VersionControl::".$type; # -- default namespace
            }

            # -- setup configuration object for the plugins
            my $config=$src->vcs_config();

            # -- dont't let user overide these
            $config->{cache_location} = $workspace->cache_location();

            my $vcs=$self->{importers}->newPlugin($type, $config);
            if(defined $vcs) {
                $vcs->checkout($dest_dir, $src->version());
            }
        }
    }
}

#
# @brief construct the environment for the specified workspace
#
sub get_environment {
    my $self=shift;
    my $workspace=shift || carp "no workspace provided";
    my $name=shift || carp "no environment name provided";
    my $platform=shift || $self->_localhost();

    # -- fetch environments from the all workspaces
    my $wm=$self->get_workspace_manager();
    my $env=$wm->environment($workspace, $name);
    
    # -- fill in any dependencies we don't have local workspaces for with project environment info
    my $pm=$self->get_project_manager();
    foreach my $dep ( $workspace->dependencies() ) {
        if( ! defined $workspace->workspace_dependency($dep) ) {
            (my $project_id)=$pm->list( { name=>$dep->name(), version=>$dep->version() } );
            if(defined $project_id)
            {
                my $project=$pm->get($project_id);
                my $proj_env=$project->environment($name);
                $env->merge_namespace( [ $dep->name(), $dep->version()], $proj_env);
                $env->merge_namespace( [ $dep->name() ], $proj_env);
                $env->dump();
            }
            else {
                print "warning: unresolved dependency ", $dep->name(), " ", $dep->version(), "\n";
            }
        }
    }

    return $env;
}

sub _localhost {
    require Paf::Platform::LocalHost;
    my $self=shift;
    if( ! defined $self->{localhost} ) {
        $self->{localhost}=new Paf::Platform::LocalHost;
    }
    return $self->{localhost};
}
