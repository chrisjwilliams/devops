# -----------------------------------------------
# DevOps::Cli::Dependency
# -----------------------------------------------
# Description: 
#   the dependency command
#
#
# -----------------------------------------------
# Copyright Chris Williams 2013
# -----------------------------------------------

package DevOps::Cli::Dependency;
use parent "DevOps::Cli::Command";
use DevOps::Cli::DependencyAdd;
use DevOps::Cli::DependencyList;
use DevOps::Cli::DependencyRemove;
use DevOps::Cli::DependencyResolve;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;

	my $self=$class->SUPER::new(@_);

    $self->add_cmds(DevOps::Cli::DependencyAdd->new($self->{api}),
                    DevOps::Cli::DependencyList->new($self->{api}),
                    DevOps::Cli::DependencyRemove->new($self->{api}),
                    DevOps::Cli::DependencyResolve->new($self->{api}));
	return $self;
}

sub name {
    return "dependency";
}

sub synopsis {
    return "view and manipulate dependency information of a project\n"
}

# -- private methods -------------------------

