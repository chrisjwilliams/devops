# -----------------------------------------------
# DevOps::Cli::ConfigAdd
# -----------------------------------------------
# Description: 
#   the config add sub-command
#
#
# -----------------------------------------------
# Copyright Chris Williams 2014
# -----------------------------------------------

package DevOps::Cli::ConfigAdd;
use parent "DevOps::Cli::Command";
use Paf::Cli::Argument;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;
	my $self=$class->SUPER::new(@_);
    $self->add_argument(new Paf::Cli::Argument("path", "A path to a directory containing project descriptions"));

	return $self;
}

sub name {
    return "add";
}

sub synopsis {
    return "add a path to search for projects\n"
}

sub run {
    my $self=shift;
    my $dir=shift;

    my $config=$self->{parent}->config();
    my $config_loc=$self->{parent}->config_location();
    eval { $config->add_project_path($config_loc, $dir); };
    if(@_)
    {
        return $self->error(@_);
    }
    return 0;
}

# -- private methods -------------------------

