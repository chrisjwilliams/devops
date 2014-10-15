package DevOps::Cli::Top;
use parent "Paf::Cli::Command";

use DevOps::Api;
use DevOps::Cli::Build;
use DevOps::Cli::Config;
use DevOps::Cli::Dependency;
use DevOps::Cli::Env;
use DevOps::Cli::Import;
use DevOps::Cli::Project;
use DevOps::Cli::List;
use DevOps::Cli::Checkout;
use Carp;
1;

sub new {
    my $class=shift;
    my $self={};
    my $config=shift;
    bless $self, $class;

    my $api=DevOps::Api->new($config);

    $self->add_cmds(DevOps::Cli::Build->new($api),
                    DevOps::Cli::Config->new($api),
                    DevOps::Cli::Env->new($api),
                    #DevOps::Cli::Import->new($api),
                    DevOps::Cli::Project->new($api),
                    DevOps::Cli::Dependency->new($api),
                    DevOps::Cli::List->new($api),
                    DevOps::Cli::Checkout->new($api));
    return $self;
}

sub synopsis {
    my $self=shift;
    return "interface to manage the development environment";
}
