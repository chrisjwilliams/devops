# -----------------------------------------------
# DevOps::Cli::Config
# -----------------------------------------------
# Description: 
#   the config command
#
#
# -----------------------------------------------
# Copyright Chris Williams 2013
# -----------------------------------------------

package DevOps::Cli::ConfigLocationOption;
use parent "Paf::Cli::Option";
use strict;
1;

sub new {
	my $class=shift;

	my $self=$class->SUPER::new(@_);
}

sub name {
    return "location";
}

sub help {
    return "restrict the following commands to the config specified at the specifed location";
}

sub synopsis {
    return "restrict the following commands to the config specified at the specifed location";
}

sub run {
    my $self=shift;
    my $args=shift;
    my $location=shift @$args || die "no location specified";
    die "$location does not exist", if( ! -d $location );
    $self->{config_location}=$location;
}

sub config_location {
    my $self=shift;
    return $self->{config_location};
}
    
package DevOps::Cli::Config;
use parent "DevOps::Cli::Command";
use DevOps::Cli::ConfigAdd;
use DevOps::Cli::ConfigList;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;

	my $self=$class->SUPER::new(@_);

    $self->add_cmds(DevOps::Cli::ConfigAdd->new($self->{api}),
                    DevOps::Cli::ConfigList->new($self->{api}));

    $self->{loc_opt}=DevOps::Cli::ConfigLocationOption->new();
    $self->add_options($self->{loc_opt});
	return $self;
}

sub name {
    return "config";
}

sub synopsis {
    return "view or update application level configuration\n"
}

sub config {
    my $self=shift;
    return $self->{api}->get_config();
}

sub config_location {
    my $self=shift;
    if( ! defined $self->{config_location} ) {
        $self->{config_location}=$self->{loc_opt}->config_location();
        if( ! defined $self->{config_location} ) {
            $self->{config_location}=$self->config()->config_dir();
        }
    }
    return $self->{config_location};
}


# -- private methods -------------------------

