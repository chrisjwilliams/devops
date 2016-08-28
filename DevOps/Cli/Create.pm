# -----------------------------------------------
# DevOps::Cli::Create
# -----------------------------------------------
# Description: 
#   The create command
#
#
# -----------------------------------------------
# Copyright Chris Williams 2016
# -----------------------------------------------


package DevOps::Cli::Create;
use parent "DevOps::Cli::Command";
use Paf::Cli::Argument;
use DevOps::Cli::Config;
use strict;
1;

# -- initialisation

sub new {
    my $class=shift;
    my $self=$class->SUPER::new(@_);

    $self->add_argument(new Paf::Cli::Argument("project_name", "specify the name of the project"));
    $self->add_argument(new Paf::Cli::Argument("project_version", "specify the version of the project to create"));

    $self->{loc_opt}=DevOps::Cli::ConfigLocationOption->new($self->{api});
    $self->add_options($self->{loc_opt});
    return $self;
}

sub run {
    my $self=shift || die "must be called as an object";
    my $name=shift;
    my $version=shift;

    # -- check to see we are outside an existing workspace
    my $ws=$self->current_workspace();
    if( $ws ) {
        return $self->error("cannot create a new project inside an existing workspace");
    }

    # -- create the project in the specified store
    my $project;
    my $store=$self->{loc_opt}->config_location();
    eval { $project=$self->{api}->create_project($store, $name, $version); };
    if(@_)
    {
        return $self->error(@_);
    }

    # -- create the project checkout area
    $ws=$self->{api}->get_workspace_manager()->construct_workspace($project);
    if( ! defined $ws ) {
        return $self->error("error setting up workspace for $name $version : $!");
    }
    
    return 0;
}

sub synopsis {
    return "create a new devops configuration for some project";
}

sub name {
    return "create";
}

# -- private methods -------------------------

