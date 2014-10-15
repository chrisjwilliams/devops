# -----------------------------------------------
# DevOps::Cli::ProjectInfo
# -----------------------------------------------
# Description: 
#   The info command
#
#
# -----------------------------------------------
# Copyright Chris Williams 2003 - 2014
# -----------------------------------------------

package DevOps::Cli::ProjectInfo;
use parent "DevOps::Cli::Command";
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;
	return $class->SUPER::new(@_);
}

sub run {
    my $self=shift;

    my @projects=$self->get_projects(@_);
    foreach my $project ( @projects ) {
        print $project->name(), " ", $project->version(), " :\n";
        print "\tlocation=\"", $project->location(), "\"\n";
    }
    return 0;
}

sub synopsis {
    return "return info of a particular project";
}

sub usage {
    return "<project_name> <project_version>"
}

sub name {
    return "info";
}

# -- private methods -------------------------

