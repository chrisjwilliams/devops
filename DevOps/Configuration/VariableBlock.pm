# -----------------------------------------------
# DevOps::Configuration::VariableBlock
# -----------------------------------------------
# Description: 
#    Interpret the contents of a ConfigNode as a set of variables
#
#
# -----------------------------------------------
# Copyright Chris Williams 2014
# -----------------------------------------------

package DevOps::Configuration::VariableBlock;
use Paf::Configuration::Node;
use Carp;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;

	my $self={};
	bless $self, $class;
    $self->{node}=shift || confess "no node specified";
    $self->{need_save}=0;

    $self->{vars}={};

    $self->read();

	return $self;
}

sub set_var {
    my $self=shift;
    my $name=shift;
    my $value=shift;

    $self->{vars}{$name}=$value;
    $self->{need_save}=1;
}

sub vars {
    my $self=shift;
    return $self->{vars};
}

sub value {
    my $self=shift;
    my $name=shift;

    return $self->{vars}{$name}
}

sub save {
    my $self=shift;
    if( $self->{need_save} ) {
        $self->{node}->clear_content();
        foreach my $var ( keys %{$self->{vars}} ) {
            my $val=$self->{vars}{$var};
            $self->{node}->add_content($var.'="'.$val.'"'."\n");
        }
        $self->{need_save}=0;
    }
}

sub clear {
    my $self=shift;
    
    $self->{vars}={};
    $self->{need_save}=1;
}

sub read {
    my $self=shift;

    foreach my $line (@{$self->{node}->content()}) {
        next, if $line=~/^\s*#.*/; # -- skip comments
        next, if $line=~/^\s*\/\/.*/; # -- skip c++ style comments
        if ( $line=~/(.+?)\s*=\s*(.*)\s*$/o ) {
            my $var=$1;
            my $val=$2;
            if ( $val=~/^\s*"(.+)\"\s*$/o ) {
                $val=$1;
            }
            $self->{vars}{$var}=$val;
        }
        else {
            croak "syntax error : $line\n";
        }
    }
}

# -- private methods -------------------------

