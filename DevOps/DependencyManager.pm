# -----------------------------------------------
# DevOps::DependencyManager
# -----------------------------------------------
# Description: 
#   Maintain dependency state information
#
#
# -----------------------------------------------
# Copyright Chris Williams 2014
# -----------------------------------------------

package DevOps::DependencyManager;
use DevOps::Dependency;
use DevOps::Configuration::VariableBlock;
use Paf::Configuration::IniFile;
use Carp;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;

	my $self={};
	bless $self, $class;

    $self->{node}=shift || die "expecting a config node";
    $self->{config}=new DevOps::Configuration::VariableBlock($self->{node});
    $self->_read();

	return $self;
}

sub add {
    my $self=shift;
    my $name=shift || carp("name not specified");
    my $version=shift || carp("version not specified");

    if(! defined $self->{deps}{$name}{$version} ) {
        $self->{deps}{$name}{$version}=DevOps::Dependency->new($name, $version);
    }
}

sub add_dependencies {
    my $self=shift;
    foreach my $dep ( @_ ) {
        $self->{deps}{$dep->name()}{$dep->version()}=$dep;
    }
}

sub has_dependency {
    my $self=shift;
    my $dep=shift;
    return defined $self->{deps}{$dep->name()}{$dep->version()};
}

sub dependencies {
    my $self=shift;

    my @deps=();
    foreach my $key ( keys %{$self->{deps}} ) {
        foreach my $val ( keys %{$self->{deps}{$key}} ) {
            push @deps, $self->{deps}{$key}{$val};
        }
    }
    return @deps;
}

sub remove {
    my $self=shift;
    my $name=shift || die("name not specified");
    my $version=shift || die("version not specified");

    if( ! defined $self->{deps}{$name}{$version} ) {
        delete $self->{deps}{$name}{$version};
    }
}

sub remove_dependencies {
    my $self=shift;
    foreach my $dep ( @_ ) {
        delete $self->{deps}{$dep->name()}{$dep->version()};
    }
}

sub save {
    my $self=shift;
    $self->{config}->clear();
    foreach my $dep ( $self->dependencies() ) {
        $self->{config}->set_var($dep->name(), $dep->version());
    }
    $self->{config}->save();
}

# -- private methods -------------------------

sub _read {
    my $self=shift;
    foreach my $key ( keys %{$self->{config}->vars()} ) {
        $self->add($key, $self->{config}->value($key));
    }
}
