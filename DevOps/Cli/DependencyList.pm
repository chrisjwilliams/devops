# -----------------------------------------------
# DevOps::Cli::DependecyList
# -----------------------------------------------
# Description: 
#   the dependency command
#
#
# -----------------------------------------------
# Copyright Chris Williams 2014
# -----------------------------------------------

package DevOps::Cli::DependencyList;
use parent "DevOps::Cli::Command";
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;
	my $self=$class->SUPER::new(@_);
	return $self;
}

sub name {
    return "list";
}

sub synopsis {
    return "list the project dependencies\n"
}

sub run {
    my $self=shift;
    my $ws=$self->current_workspace();
    if( defined $ws ) {
        foreach my $dep ( $ws->dependencies() ) {
            print $dep->name(), " ", $dep->version(), "\n";
        }
    }
    else {
        return $self->error("no project has been selected");
    }
    return 0;
}

# -- private methods -------------------------

