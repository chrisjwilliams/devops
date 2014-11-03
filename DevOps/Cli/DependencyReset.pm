# -----------------------------------------------
# DevOps::Cli::DependencyReset
# -----------------------------------------------
# Description: 
#  resolve dependencies using the specified workspace
#
#
# -----------------------------------------------
# Copyright Chris Williams 2014
# -----------------------------------------------

package DevOps::Cli::DependencyReset;
use parent "DevOps::Cli::Command";
use Paf::Cli::Argument;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;
	my $self=$class->SUPER::new(@_);
    $self->add_argument(new Paf::Cli::Argument("dependency_name", "the name of the dependancy to reset"));
    $self->add_argument(new Paf::Cli::Argument("dependency_version", "the version of the dependancy to reset"));
	return $self;
}

sub synopsis {
    return "remove any workspaces assoicated with the specifed dependency\n"
}

sub name {
    return "reset";
}

sub run {
    my $self=shift;
    my $name=shift||return $self->error("no dependency name specified");
    my $version=shift||return $self->error("no dependency version specified");
    
    my $ws=$self->current_workspace();
    if( defined $ws ) {
        my $wm=$self->{api}->get_workspace_manager();
        return $ws->unset_dependent_workspace(new DevOps::Dependency($name, $version));
    }
    else {
        return $self->error("unable to determine the current project");
    }
}

# -- private methods -------------------------

