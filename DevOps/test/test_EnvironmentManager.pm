package test_EnvironmentManager;
use strict;
use DevOps::EnvironmentManager;
use DevOps::TestUtils::TestProject;
use Paf::File::TempDir;
1;

sub new {
    my $class=shift;
    my $self={};
    bless $self, $class;
    $self->{tmpdir}=Paf::File::TempDir->new();

    return $self;
}

sub tests {
    return qw(test_environment);
}

sub test_environment {
    my $self=shift;

    my $name="name_1";
    my $env=DevOps::Environment->new();
    $env->set("variable", "value");

    my $config=Paf::Configuration::Node->new("test");
    {
        my $em=DevOps::EnvironmentManager->new($config);
        $em->add($name, $env);
        die("unexpected env"), unless($env == $em->environment($name));
        $em->save();
    }

    # -- test persistency
    my $em=DevOps::EnvironmentManager->new($config);
    my $saved_env=$em->environment($name);

    die("expecting variable in env, got ", $saved_env->var("variable")), unless($saved_env->var("variable") eq $env->var("variable") );
}
