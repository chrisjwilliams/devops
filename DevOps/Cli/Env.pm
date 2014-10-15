# -----------------------------------------------
# DevOps::Cli::Env
# -----------------------------------------------
# Description: 
#
#  The environment display command for a standard terminal
#
# -----------------------------------------------
# Copyright Chris Williams 2003-2014
# -----------------------------------------------

package DevOps::Cli::Env;
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
    return "env";
}

sub synopsis {
    return "print out the current working area environment"
}

sub run {
    my $self=shift;
    my @names=@_;
    if (!defined $names[0]) {
        push @names, "runtime", "build";
    }
    
    my $ws=$self->current_workspace();
    if( defined $ws ) {
        foreach my $name ( @names ) {
            my $env=$self->{api}->get_environment($ws, $name);
            $env->dump();
        }
    }
    else {
        return $self->error("no project has been selected");
    }
    return 0;
}

# -- private methods -------------------------

