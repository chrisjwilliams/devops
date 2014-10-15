# -----------------------------------------------
# DevOps::Cli::List
# -----------------------------------------------
# Description: 
#   The list command
#
#
# -----------------------------------------------
# Copyright Chris Williams 1996 - 2014
# -----------------------------------------------

package DevOps::Cli::List;
use parent "DevOps::Cli::Command";
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;
	my $self=$class->SUPER::new(@_);

	return $self;
}

sub run {
    my $self=shift;
    my @projects=$self->{api}->find_projects();

    # -- print out list of projects and versions available
    my $last_name="";
    foreach my $project ( @projects )
    {
        if($last_name ne $project->name())
        {
            $last_name=$project->name();
            print $project->name(), "\n";
        }
        print "\t", $project->version(), "\n";
    }
    return 0;
}

sub synopsis {
    return "return a list of know projects";
}

sub name {
    return "list";
}

# -- private methods -------------------------

