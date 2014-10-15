# -----------------------------------------------
# DevOps::EnvironmentManager
# -----------------------------------------------
# Description: 
#    Manage environment data object persistency
#
#
# -----------------------------------------------
# Copyright Chris Williams 2014
# -----------------------------------------------

package DevOps::EnvironmentManager;
use DevOps::Environment;
use Paf::Configuration::NodeFilter;
use DevOps::Configuration::VariableBlock;
use Carp;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;

	my $self={};
	bless $self, $class;

    $self->{node}=shift || die "expecting a config node";

	return $self;
}

sub environment {
    my $self=shift;
    my $name=shift || carp "no environment specified";

    if( !defined $self->{env}{$name} )
    {
        $self->{env}{$name}=new DevOps::Environment;
        my @envs=$self->_env_nodes($name);
        foreach my $node ( @envs ) {
            my $vars=new DevOps::Configuration::VariableBlock($node);
            $self->{env}{$name}->merge($vars->vars());
        }
    }
    return $self->{env}{$name};
}

sub add
{
    my $self=shift;
    my $name=shift || carp "no environment name specified";
    my $env=shift || carp "no env supplied";

    $self->{env}{$name}=$env;
}

sub save {
    my $self=shift;

    foreach my $env_name ( keys %{$self->{env}} )
    {
        my $vars=$self->{env}{$env_name}->env();
        (my $node)=$self->_env_nodes($env_name);
        $node=$self->{node}->new_child("Environment", { name => $env_name }), if( ! defined $node );
        my $v_block=new DevOps::Configuration::VariableBlock($node);

        foreach my $var ( sort(keys %$vars) ) {
            $v_block->set_var($var, $vars->{$var});
        }
        $v_block->save();
    }
}

# -- private methods -------------------------
sub _env_nodes {
    my $self=shift;
    my $name=shift;
    return $self->{node}->search(new Paf::Configuration::NodeFilter("Environment", { name => $name }));
}

