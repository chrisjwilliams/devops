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
use DevOps::Cli::VerboseOption;
use Carp;
1;

sub new {
    my $class=shift;
    my $config=shift;
	my $self=$class->SUPER::new(@_);

    my $api=DevOps::Api->new($config);

    $self->add_cmds(DevOps::Cli::Build->new($api),
                    DevOps::Cli::Config->new($api),
                    DevOps::Cli::Env->new($api),
                    #DevOps::Cli::Import->new($api),
                    DevOps::Cli::Project->new($api),
                    DevOps::Cli::Dependency->new($api),
                    DevOps::Cli::List->new($api),
                    DevOps::Cli::Checkout->new($api));

    # -- top level options
    $self->{verbose_opt}=DevOps::Cli::VerboseOption->new();
    $self->add_options($self->{verbose_opt});

    return $self;
}

sub verbose_level {
    my $self=shift;
    return $self->{verbose_opt}->level(@_);
}

sub synopsis {
    my $self=shift;
    return "interface to manage the development environment";
}
