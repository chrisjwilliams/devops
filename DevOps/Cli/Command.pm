package DevOps::Cli::Command;
use parent "Paf::Cli::Command";

use Carp;
1;

sub new {
    my $class=shift;
    my $api=shift;
	my $self=$class->SUPER::new(@_);
    $self->{api}=$api;
    return $self;
}

sub current_workspace {
    my $self=shift;

    my $wm=$self->{api}->get_workspace_manager();
    return $wm->current_workspace();
}

sub verbose_level {
    my $self=shift;
    return $self->{parent}->verbose_level(@_);
}

sub get_projects {
    my $self=shift;
    my $project=shift || $self->error("project name must be specified");
    my $version=shift || $self->error("project version must be specified");

    my $search={ "name" => $project,
                 "version" => $version };
    my $pm=$self->{api}->get_project_manager();
    my @projs=();
    foreach my $id ($self->{api}->find_projects($search)) {
        push @projs, $pm->get($id);
    }
    return @projs;
}
