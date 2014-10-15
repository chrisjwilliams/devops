# -----------------------------------------------
# DevOps::Cli::DependencyResolve
# -----------------------------------------------
# Description: 
#  reolve dependencies corresponding to the current workspace
#
#
# -----------------------------------------------
# Copyright Chris Williams 2014
# -----------------------------------------------

package DevOps::Cli::DependencyResolve;
use parent "DevOps::Cli::Command";
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;
	my $self=$class->SUPER::new(@_);
	return $self;
}

sub synopsis {
    return "resolve the current workspaces dependencies\n"
}

sub name {
    return "resolve";
}

sub run {
    my $self=shift;

    my $ws=$self->current_workspace();
    if( defined $ws ) {
        $self->{api}->resolve_workspace_deps($ws);
    }
    else {
        return $self->error("unable to determine the current project");
    }
}

# -- private methods -------------------------

