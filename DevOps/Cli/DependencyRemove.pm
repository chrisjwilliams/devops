# -----------------------------------------------
# DevOps::Cli::DependecyRemove
# -----------------------------------------------
# Description: 
#   the dependency command
#
#
# -----------------------------------------------
# Copyright Chris Williams 2013
# -----------------------------------------------

package DevOps::Cli::DependencyRemove;
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
    return "remove";
}

sub synopsis {
    return "remove a dependency from the current project\n"
}

sub run {
    my $self=shift;
    my $name=shift;
    my $version=shift;

    if( ! defined $name ) { return $self->error("Must specify a dependency name"); }
    if( ! defined $version ) { return $self->error("Must specify a dependency version"); }

    my $ws=$self->current_workspace();
    if( defined $ws ) {
        my $dep=DevOps::Dependency->new($name, $version);
        return $ws->remove_dependencies($dep);
    }
    else {
        return $self->error("unable to determine the current project");
    }
}

# -- private methods -------------------------

