# -----------------------------------------------
# DevOps::Cli::Checkout
# -----------------------------------------------
# Description: 
#   The checkout command
#
#
# -----------------------------------------------
# Copyright Chris Williams 2003-2014
# -----------------------------------------------

package DevOps::Cli::Checkout;
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
    return "checkout";
}

sub run {
    my $self=shift;
    my $name=shift;
    my $version=shift;
    my $location=shift; # optional

    if( ! defined $name ) { return $self->error("no name specified") };
    if( ! defined $version ) { return $self->error("no version specified") };

    my $ws=$self->{api}->setup_workspace($name, $version, $location);
    if( ! defined $ws ) {
        return $self->error("error setting up workspace for $name $version : $!");
    }
}

sub synopsis {
    return "checkout a working environment for a project"
}

# -- private methods -------------------------

