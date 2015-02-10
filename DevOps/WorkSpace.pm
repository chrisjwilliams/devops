# -----------------------------------------------
# DevOps::WorkSpace
# -----------------------------------------------
# Description: 
#   Manages a User workspace
#
# -----------------------------------------------
# Copyright Chris Williams 1996-2014
# -----------------------------------------------

package DevOps::WorkSpace;
use DevOps::DependencyManager;
use DevOps::ProjectId;
use DevOps::Project;
use DevOps::Environment;
use DevOps::EnvironmentManager;
use strict;
use Paf::Configuration::XmlFile;
use Carp;
use Cwd 'abs_path';
use Scalar::Util;
1;

# -- initialisation

sub new {
	my $class=shift;

	my $self={};
	bless $self, $class;

    $self->reset(@_);

	return $self;
}

sub reset {
    my $self=shift;

    $self->{location}=shift||die "no location passed for workdir";
    $self->{location}=Cwd::abs_path($self->{location});

    die "location does not exist", if( ! -d $self->{location} );

    $self->{checkout_location}=$self->{location}."/checkout";
    $self->{build_location}=$self->{location}."/build";
    $self->{devops_location}=$self->{location}."/devops";
    $self->{devops_cache_location}=$self->{devops_location}."/cache";
    $self->{devops_project_location}=$self->{devops_location}."/project";
    $self->{devops_config_file}=$self->{devops_location}."/config.devops";

    $self->{config}=Paf::Configuration::XmlFile->new($self->{devops_config_file});
    ($self->{node})=$self->{config}->root()->search(new Paf::Configuration::NodeFilter("DevOps"));

    if( !defined $self->{node} ) {
        $self->{node}=$self->{config}->root()->new_child("DevOps", { type => "workspace" } );
        $self->{node}->add_meta("version", "0.0.0");
    }

    # EnvironmentManager
    my $env_config=$self->{node}->get_child(new Paf::Configuration::NodeFilter("EnvironmentManager"));
    $self->{env}=DevOps::EnvironmentManager->new($env_config);
    $self->{needs_save}=0;

}

sub location {
    my $self=shift;
    return $self->{location};
}

sub is_constructed() {
    my $self=shift;
    return ( -f $self->{devops_config_file} );
}

sub construct {
    my $self=shift;
    my $project=defined($_[0]) ? shift : die("expecting a DevOps::Project object");

    # -- create a devops tool directory
    mkdir $self->{devops_location} || die "unable to create dir ", $self->{devops_location};
    mkdir $self->{devops_project_location} || die "unable to create dir ", $self->{devops_project_location};

    # -- take a snapshot of the current project
    $project->save_to_location($self->{devops_project_location});

    # -- create the config
    $self->{node}->new_child("project", { "id" => $project->id()->serialize() } );

    $self->{config}->save(); # make sure is_constructed returns true
    $self->{needs_save}=1;
}

sub project_id {
    my $self=shift;
    if(!defined $self->{proj_id})
    {
        (my $node)=$self->{node}->search(new Paf::Configuration::NodeFilter("project"));
        my $id;
        if($node) { $id=$node->meta()->{id} };
        $self->{proj_id}=new DevOps::ProjectId($id);
    }
    return $self->{proj_id};
}

sub project {
    my $self=shift;

    if(!defined $self->{project}) {
        $self->{project}=new DevOps::Project($self->project_id(), $self->{devops_project_location});
    }
    return $self->{project};
}

sub name {
    my $self=shift;
    return $self->project_id()->name();
}

sub version {
    my $self=shift;
    return $self->project_id()->version();
}

#
# fetch the build out area fo the specified platform and variants
# Will construct a new area if one does not already exist
#
sub build_out {
    my $self=shift;
    my $platform=shift;
    my $variants=shift;

    my $location=$self->_build_out_location($platform, $variants);
    return $self->_get_build_out($location);
}

#
# search for available build outs that match the variants
# returns undef if none found
#
sub search_build_out {
    my $self=shift;
    my $platform=shift;
    my $variants=shift;

    my $location=$self->_build_out_location($platform, $variants);
    if( -d $location ) {
        return $self->_get_build_out($location);
    }

    #  create a list of possible variants in order to search for
    my @search_variants=($variants);
    foreach my $rep_type ( $self->build_types() ) {
        for(my $i=0; $i <= $#{$variants->{type}}; ++$i) {
            my $v={ %$variants };
            for(my $j=0; $j <= $#{$variants->{type}}; ++$j) {
                if( $i == $j ) {
                    push @{$v->{types}}, $rep_type;
                }
                else {
                    push @{$v->{types}}, ${$variants->{type}[$j]};;
                }
                $location=$self->_build_out_location($platform, $variants);
                if( -d $location ) {
                    return $self->_get_build_out($location);
                }
            }
        }
    }
    return undef;
}

sub build_types {
    my $self=shift;
    return qw(release debug);
}

sub _get_build_out {
    my $self=shift;
    my $location=shift;

    if(!defined $self->{build_outs}{$location}) {
        # -- construct it if it doesn't exist
        require DevOps::BuildArea;
        $self->{build_outs}{$location}=new DevOps::BuildArea($location);
    }
    return $self->{build_outs}{$location};
}

sub _build_out_location {
    my $self=shift;
    my $platform=shift;
    my $variants=shift;

    # -- analyse parameters
    my $arch=$platform->arch() || die "unable to determine arch of the current platform: ", ref($platform);
    die ("build type not specified"), if( ! defined $variants->{type} );
    my $type=join("_", sort @{$variants->{type}});

    die ("toolchain not specified"), if( ! defined $variants->{toolchain} );
    my $toolchain=join("_", sort @{$variants->{toolchain}});

    my $variants_string="";
    if( defined $variants->{variants} ) {
        $variants_string=join("_", sort @{$variants->{variants}})."/";
    }

    my $location=$self->{build_location}."/".$arch."/".$variants_string.$toolchain."/".$type;
    return $location;
}

sub build_tasks {
    my $self=shift;

    # TODO make configurable
    if( ! defined $self->{tasks_list}{build} ) {
        @{$self->{task_list}{build}}=qw(setup);
        # TODO create in_source_build()
        #if( $self->project()->in_source_build() ) {
        #    push @{$self->{task_list}{build}}, "sync_src";
        #}
        push @{$self->{task_list}{build}}, ("build", "install");
    }
    return @{$self->{task_list}{build}};
}

sub build_commands {
    my $self=shift;
    my $task_name=shift || carp ("task_name unspecified");
    my $platform=shift; # optional - use undef

    my $workflow="build";
    
    # -- deduce evironments for each resolved dependency
    my @filters=();
    foreach my $dep ( $self->resolved_dependencies() ) {
        if( defined $platform ) {
            push @filters, new Paf::Configuration::NodeFilter("environment", { arch => $platform->arch(), dependency => $dep->name(), version => $dep->version() });
            push @filters, new Paf::Configuration::NodeFilter("environment", { arch => $platform->arch(), dependency => $dep->name() });
        }
        push @filters, new Paf::Configuration::NodeFilter("environment", { dependency => $dep->name(), version => $dep->version() });
        push @filters, new Paf::Configuration::NodeFilter("environment", { dependency => $dep->name() });
    }
    my $env=$self->project()->task_environment( $workflow, $task_name, @filters);

    return $self->project()->task_code($workflow, $task_name, $env, $platform, @_);
}

sub checkout_dir {
    my $self=shift;
    return $self->{checkout_location};
}

sub cache_location {
    my $self=shift;
    return $self->{devops_cache_location};
}

sub set_dependent_workspace {
    my $self=shift;
    my $dep=shift || die "expecting a dependency";
    my $workspace=shift || die "expecting a workspace";

    if(!$self->project()->has_dependency($dep))
    {
        die ($dep->name(), " ", $dep->version(), " is not a recognized dependency for project ", $self->name(), " ", $self->version());
    }
    my $workspaces=$self->{node}->get_child(new Paf::Configuration::NodeFilter("Workspaces"));
    my $node=$workspaces->get_child(new Paf::Configuration::NodeFilter("Workspace", { uid => $dep->uid() } ));
    $node->add_meta( "location", $workspace->{location} );
    $self->{needs_save}=1;
    return 0;
}

sub unset_dependent_workspace {
    my $self=shift;
    my $dep=shift|| carp("no dependency provided");
    (my $node)=$self->{node}->search(new Paf::Configuration::NodeFilter("Workspaces"), new Paf::Configuration::NodeFilter("Workspace", { uid => $dep->uid() } ));
    if( $node ) { $node->unhook() }
    $self->{needs_save}=1;
    return 0;
}

sub workspace_dependency {
    my $self=shift;
    my $dep=shift|| carp("no dependency provided");
    (my $node)=$self->{node}->search(new Paf::Configuration::NodeFilter("Workspaces"), new Paf::Configuration::NodeFilter("Workspace", { uid => $dep->uid() } ));
    return undef, unless $node;
    return $node->meta()->{location};
}

sub environment {
    my $self=shift;
    my $name=shift || carp "no environment specified";

    my $env=$self->{env}->environment($name);
    my $penv=$self->project()->environment($name);
    $env->merge($penv);

    return $env;
}

sub add_dependency {
    my $self=shift;
    $self->{needs_save}=1;
    $self->project()->add_dependency(@_);
}

sub add_dependencies {
    my $self=shift;
    $self->{needs_save}=1;
    $self->project()->add_dependencies(@_);
}

sub remove_dependencies {
    my $self=shift;
    $self->{needs_save}=1;
    $self->project()->remove_dependencies(@_);
}

sub dependencies {
    my $self=shift;
    return $self->project()->dependencies();
}

sub unresolved_dependencies {
    my $self=shift;

    my @deps=();
    foreach my $dep ( $self->dependencies() ) {
        if( ! defined $self->workspace_dependency($dep) ) {
            push @deps, $dep;
        }
    }
    return @deps;
}

sub resolved_dependencies {
    my $self=shift;

    my @deps=();
    foreach my $dep ( $self->dependencies() ) {
        if( defined $self->workspace_dependency($dep) ) {
            push @deps, $dep;
        }
    }
    return @deps;
}

sub save {
    my $self=shift;

    if( $self->{needs_save} && defined $self->{config} && $self->is_constructed() ) {

        $self->project()->save();

        # -- save any environments to the config object
        $self->{env}->save();

        # -- save the config object 
        $self->{config}->save();
    }
}

# -- private methods -------------------------

sub DESTROY {
    my $self=shift;
    $self->save();
}

