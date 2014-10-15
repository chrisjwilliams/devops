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
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;

	my $self=$class->SUPER::new(@_);

    # -- set some default variants
    $self->{variants} = { toolchain => [ qw(gcc) ] };

	return $self;
}

sub name {
    return "build";
}

sub synopsis {
    return "build the current project"
}

sub run {
    my $self=shift;

    my $ws=$self->current_workspace();
    if( $ws ) {
        # -- parse the command line arguments
        $self->{api}->build_workspace($ws, [ @_ ], undef, $self->{variants});
    }
    else {
        $self->error("unable to determine workspace to build");
    }
}

# -- private methods -------------------------

