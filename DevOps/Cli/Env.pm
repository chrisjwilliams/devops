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

    $self->{toolchain}=DevOps::Cli::ToolChain->new();
    $self->add_argument(new Paf::Cli::OptionalArgument("project_name", "specify the name of the project"));
    $self->add_argument(new Paf::Cli::OptionalArgument("project_version", "specify the version of the project"));
    $self->add_argument(new Paf::Cli::OptionalArgument("build_type", "default release"));
    $self->add_options($self->{toolchain});
    return $self;
}

sub name {
    return "env";
}

sub synopsis {
    return "print out the current working area environment, or the environment for the project specified"
}

sub run {
    my $self=shift;
    my $ws=$self->current_workspace();
    if( ! $ws ) {
        # -- no workspace so the arguments should specify the project to build
        my $name=shift;
        my $version=shift;
        if( $name && $version ) {
            ($ws)=$self->{api}->find_workspaces($name, $version);
            if( ! $ws ) {
                return $self->error("unable to find workspace for project '$name' version '$version'");
            }
        }
    }
    my @names=@_;
    my $variants = { toolchain => [ $self->{toolchain}->toolchain() ] };
    if (!defined $names[0]) {
        # default build flavours
        push @names, "release";
    }
    $variants->{type}=\@names;
    
    if( defined $ws ) {
        my $env=$self->{api}->runtime_environment($ws, undef, $variants );
        $env->dump();
    }
    else {
        return $self->error("no project has been selected");
    }
    return 0;
}

# -- private methods -------------------------

