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
    my $config=shift;
    die "Dependency not passed a config node", if( ! defined $config );
    if( ref($config) ne "Paf::Configuration::Node" ) {
        $config=new Paf::Configuration::Node("dependency", { name => $config, version => shift, required => shift||1 });
    }
    $self->{config}=$config;
    $self->{name}=$config->meta()->{name};
    $self->{version}=$config->meta()->{version}||"undefined";
    $self->{required}=$config->meta()->{required}||1;

	return $self;
}

sub config {
    my $self=shift;
    return $self->{config};
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

