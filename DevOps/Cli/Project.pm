package DevOps::Cli::Project;
use parent "DevOps::Cli::Command";

use DevOps::Api;
use DevOps::Cli::ProjectInfo;
use Carp;
use strict;
1;

sub new {
    my $class=shift;
	my $self=$class->SUPER::new(@_);

    $self->add_cmds(DevOps::Cli::ProjectInfo->new($self->{api}));

    return $self;
}

sub name {
    return "project";
}

sub synopsis {
    my $self=shift;
    return "commands to manipulate specific projects";
}
