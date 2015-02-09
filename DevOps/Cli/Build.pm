# -----------------------------------------------
# DevOps::Cli::Build
# -----------------------------------------------
# Description: 
#    The build command
#
#
# -----------------------------------------------
# Copyright Chris Williams 2003-2014
# -----------------------------------------------

package DevOps::Cli::Build;
use parent "DevOps::Cli::Command";
use Paf::Cli::Argument;
use Paf::Cli::OptionalArgument;
use DevOps::Cli::ToolChain;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;

	my $self=$class->SUPER::new(@_);
    $self->{toolchain}=DevOps::Cli::ToolChain->new();

    # -- set some default variants
    $self->add_argument(new Paf::Cli::OptionalArgument("project_name", "specify the name of the project to build (outside of a project workspace)"));
    $self->add_argument(new Paf::Cli::OptionalArgument("project_version", "specify the version of the project to build (outside of a project workspace)"));
    $self->add_options($self->{toolchain});

	return $self;
}

sub name {
    return "build";
}

sub synopsis {
    return "build the current project (or that specified)"
}

sub run {
    my $self=shift;

    $self->{variants} = { toolchain => [ $self->{toolchain}->toolchain() ] };
    if( @_ ) {
        $self->{variants}{extra_params}{setup} = [ @_ ];
    }

    my $ws=$self->current_workspace();
    if( ! $ws ) {
        # -- maybe the arguments specify the project to build
        my $name=shift;
        my $version=shift;
        if( $name && $version ) {
            ($ws)=$self->{api}->find_workspaces($name, $version);
            if( ! $ws ) {
                return $self->error("unable to find workspace for project '$name' version '$version'");
            }
        }
    }
    if( $ws ) {
        # -- parse the command line arguments
        my $report=$self->{api}->build_workspace($ws, [ @_ ], undef, $self->{variants}, $self->verbose_level());
        if( $self->verbose_level() ) {
            $report->print();
        }
        return $report->has_failed();
    }
    else {
        return $self->error("unable to determine workspace to build");
    }
}

# -- private methods -------------------------

