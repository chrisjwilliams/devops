# -----------------------------------------------
# DevOps::Cli::ConfigList
# -----------------------------------------------
# Description: 
#   the config list command
#
#
# -----------------------------------------------
# Copyright Chris Williams 2014
# -----------------------------------------------

package DevOps::Cli::ConfigList;
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
    return "list the configuration settings\n"
}

sub run {
    my $self=shift;
    my $config=$self->{api}->get_config();
    print $config->dump();
    return 0;
}

# -- private methods -------------------------

