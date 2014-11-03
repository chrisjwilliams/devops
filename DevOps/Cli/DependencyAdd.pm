# -----------------------------------------------
# DevOps::Cli::DependecyAdd
# -----------------------------------------------
# Description: 
#   the dependency add sub-command
#
#
# -----------------------------------------------
# Copyright Chris Williams 2013
# -----------------------------------------------

package DevOps::Cli::DependencyAdd;
use Paf::Cli::Argument;
use parent "DevOps::Cli::Command";
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;
	my $self=$class->SUPER::new(@_);
    $self->add_argument(new Paf::Cli::Argument("dependency_name", "the name of the dependancy to add"));
    $self->add_argument(new Paf::Cli::Argument("dependency_version", "the version of the dependancy to add"));
	return $self;
}

sub name {
    return "add";
}

sub synopsis {
    return "add a dependency to the current workspace\n"
}

sub run {
    my $self=shift;
    my $name=shift;
    my $version=shift;

    if( ! defined $name ) { return $self->error("Must specify a dependency name"); }
    if( ! defined $version ) { return $self->error("Must specify a dependency version"); }

    my $ws=$self->current_workspace();
    if( defined $ws ) {
        $ws->add_dependency($name, $version);
    }
    else {
        return $self->error("unable to determine the current project");
    }
}

# -- private methods -------------------------

