# -----------------------------------------------
# DevOps::Cli::Import
# -----------------------------------------------
# Description: 
#   the import command
#
#
# -----------------------------------------------
# Copyright Chris Williams 2013
# -----------------------------------------------

package DevOps::Cli::Import;
use parent "Paf::Cli::Command";
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;

	my $self={};
    $self->{api}=shift;
	bless $self, $class;

	return $self;
}

sub name {
    return "import";
}

sub synopsis {
    return "download project description files from the specified url\n"
}

sub run {
    my $self=shift;
    my $url=shift;

    $self->{api}->import($url);
}


# -- private methods -------------------------

