# -----------------------------------------------
# DevOps::Dependency
# -----------------------------------------------
# Description: 
#   Necessary state for a workspace dependency
#
#
# -----------------------------------------------
# Copyright Chris Williams 2014
# -----------------------------------------------

package DevOps::Dependency;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;

	my $self={};
	bless $self, $class;
    $self->{name}=shift;
    $self->{version}=shift;
    $self->{required}=shift||1;

	return $self;
}

sub name {
    my $self=shift;
    return $self->{name};
}

sub version {
    my $self=shift;
    return $self->{version};
}

sub is_required {
    my $self=shift;
    return $self->{required};
}

sub uid {
    my $self=shift;
    return $self->{name}."_".$self->{version};
}

# -- private methods -------------------------

