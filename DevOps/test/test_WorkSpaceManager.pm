package test_WorkSpaceManager;
use strict;
use warnings;
use DevOps::WorkSpaceManager;
use DevOps::TestUtils::TestProject;
use DevOps::TestUtils::TestWorkSpace;
use Paf::File::TempDir;
use Paf::File::TempFile;
1;

sub new {
    my $class=shift;
    my $self={};
    bless $self, $class;

    return $self;
}

sub tests {
    return qw(test_new test_get_workspace test_construct_workspace test_environment);
}

sub test_new {
    my $self=shift;
    Paf::TestSuite::assert_throw("DevOps::WorkSpaceManager->new()");
    Paf::TestSuite::assert_throw("DevOps::WorkSpaceManager->new(undef)");
    Paf::TestSuite::assert_throw("DevOps::WorkSpaceManager->new('')");

    my $tmpdir=Paf::File::TempDir->new();
    my $dir=$tmpdir->dir();
    eval { DevOps::WorkSpaceManager->new("badfilename", $dir); };
    die("expecting throw"), if ( ! $@ );
    eval { DevOps::WorkSpaceManager->new(undef, $dir) };
    die("expecting throw"), if ( ! $@ );
}

sub test_get_workspace {
    my $self=shift;
    my $tmpdir=Paf::File::TempDir->new();
    my $tmpfile=Paf::File::TempFile->new($tmpdir->dir());
    my $wm=DevOps::WorkSpaceManager->new($tmpfile->filename(), $tmpdir->dir());

    # -- bad project passed
    eval { $wm->get_workspace(undef) };
    die "expecting throw", if( ! $@ );
    eval { $wm->get_workspace() };
    die "expecting throw", if( ! $@ );
}

sub test_construct_workspace {
    my $self=shift;

    my $tmpdir=Paf::File::TempDir->new();
    my $tmpfile=Paf::File::TempFile->new();
    my $project=DevOps::TestUtils::TestProject->new();
    my $project2=DevOps::TestUtils::TestProject->new("project_2");
    my $location=$tmpdir->dir()."/".$project->name()."/".$project->version();
    {
        my $wm=DevOps::WorkSpaceManager->new($tmpfile->filename(), $tmpdir->dir());

        # -- bad project passed
        eval { $wm->construct_workspace(undef) };
        die "expecting throw", if( ! $@ );
        eval { $wm->construct_workspace() };
        die "expecting throw", if( ! $@ );

        # -- good project passed
        my $ws=$wm->construct_workspace($project);
        die("expecting is_constructed() true"), unless ($ws->is_constructed());
        
        die("expecting to find $location"), unless ( -d $location );

        my $ws2=$wm->construct_workspace($project2);
    }

    # -- check persistency
    my $wm=DevOps::WorkSpaceManager->new($tmpfile->filename(), $tmpdir->dir());
    my $ws=$wm->get_workspace($project->id());
    die("expecting is_constructed() true"), unless ($ws->is_constructed());
    die("unexpected project id"), unless ( $ws->project_id()->match($project->id()) );
    my $ws2=$wm->get_workspace($project2->id());
    die("expecting is_constructed() true"), unless ($ws2->is_constructed());
    die("unexpected project id"), unless ( $ws2->project_id()->match($project2->id()) );

}

sub test_environment {
    my $self=shift;
    
    my $tmpdir=Paf::File::TempDir->new();
    my $tmpfile=Paf::File::TempFile->new();

    my $ws1=DevOps::TestUtils::TestWorkSpace->new("ws1", "test_version_1");
    my $ws2=DevOps::TestUtils::TestWorkSpace->new("ws2", "test_version_2");

    my $wm=DevOps::WorkSpaceManager->new($tmpfile->filename(), $tmpdir->dir());
    $wm->_add_workspace($ws1);
    $wm->_add_workspace($ws2);

    # -- set ws2 as the dependent workspace
    my $dep=DevOps::Dependency->new($ws2->name(), $ws2->version());
    $ws1->add_dependencies($dep);
    $ws1->set_dependent_workspace($dep, $ws2);

    # -- empty environment
    my $env=$wm->environment($ws1, "test");
    die("expecting an empty environment"), unless( $env->size() == 0 );

    # -- dependency only has an environment
    my $test_var="test_var";
    my $test_value="test_value";
    $ws2->environment("test2")->set($test_var, $test_value);
    $env=$wm->environment($ws1, "test2");
    die("expecting 2 environment vars, got ", $env->size()), unless( $env->size() == 2 );

    my $vname=$ws2->name()."::";
    my $value=$env->var($vname.$test_var);

    die("expecting $test_value , got ", $env->var($vname.$test_var)), unless( $env->var($vname.$test_var) eq $test_value );
    $vname.=$ws2->version()."::";
    die("expecting $test_value , got ", $env->var($vname.$test_var)), unless( $env->var($vname.$test_var) eq $test_value );

}
