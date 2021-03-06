# -----------------------------------------------
# DevOps::Cli::DependencyUse
# -----------------------------------------------
# Description: 
#  resolve dependencies using the specified workspace
#
#
# -----------------------------------------------
# Copyright Chris Williams 2014
# -----------------------------------------------

package DevOps::Cli::DependencyUse;
use Paf::Cli::Argument;
use Paf::Cli::OptionalArgument;
use parent "DevOps::Cli::Command";
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;
	my $self=$class->SUPER::new(@_);
    $self->add_argument(new Paf::Cli::Argument("workspace_location", "The path to the devops workspace that should be used to satisfy a dependency" ));
    $self->add_argument(new Paf::Cli::OptionalArgument("dependency_name", "dependency name to satisfy" ));
    $self->add_argument(new Paf::Cli::OptionalArgument("dependency_version", "dependency version to satisfy" ));
	return $self;
}

sub synopsis {
    return "resolve the specifed dependency with a devops workspace at the speccified location\n"
}

sub name {
    return "use";
}

sub run {
    my $self=shift;
    my $location=shift||return $self->error("no location specified");
    my $name=shift;
    my $version=shift;
    
    my $ws=$self->current_workspace();
    if( defined $ws ) {
        my $wm=$self->{api}->get_workspace_manager();
        my $dep_ws;
        if( -d $location ) {
            $dep_ws=$wm->get_workspace_from_location($location);
        }
        if( ! defined $dep_ws ) {
            return $self->error("No workspace found at '$location'");
        }
        $name=$dep_ws->name(), if( ! defined $name );
        $version=$dep_ws->version(), if( ! defined $version );
        return $ws->set_dependent_workspace(new DevOps::Dependency($name, $version), $dep_ws);
    }
    else {
        return $self->error("unable to determine the current project");
    }
}

# -- private methods -------------------------

