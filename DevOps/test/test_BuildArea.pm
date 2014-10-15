package test_BuildArea;
use strict;
use DevOps::BuildArea;
use Paf::File::TempDir;
use Paf::Platform::TestHost;
use Paf::Platform::Task;
use Paf::Platform::TaskSeries;
1;

sub new {
    my $class=shift;
    my $self={};
    bless $self, $class;
    $self->{tmpdir}=Paf::File::TempDir->new();

    return $self;
}

sub tests {
    return qw(test_new_undef test_construct test_execute test_execute_sequence);
}

sub test_new_undef {
    my $self=shift;
    Paf::TestSuite::assert_throw("DevOps::BuildArea->new()");
    Paf::TestSuite::assert_throw("DevOps::BuildArea->new(undef)");
    Paf::TestSuite::assert_throw("DevOps::BuildArea->new('')");
}

sub test_construct {
    my $self=shift;

    my $tmpdir=$self->{tmpdir};
    my $build_area=DevOps::BuildArea->new($tmpdir->dir());

    # -- check the build area is constructed
    my $dir=$tmpdir->dir()."/info";
    die("expecting to find $dir"), unless ( -d $dir );
    $dir=$tmpdir->dir()."/work";
    die("expecting to find $dir"), unless ( -d $dir );

    # -- check build location
    my $loc=$build_area->work_location();
    die("expecting $dir, got ", $loc), if( $loc ne $dir );

    # -- check install location
    $loc=$build_area->install_location();
    $dir=$tmpdir->dir()."/install";
    die("expecting $dir, got ", $loc), if( $loc ne $dir );

    # -- last_task on new area
    die("expecting undef"), if($build_area->last_task());
}

sub test_execute {
    my $self=shift;

    my $tmpdir=$self->{tmpdir};
    my $platform=new Paf::Platform::TestHost;
    my $task_name="good_task";

    {
        my $build_area=DevOps::BuildArea->new($tmpdir->dir());

        # -- good task
        my $task=new Paf::Platform::Task($platform);
        $task->add("hello world");
        my $report=$build_area->execute($task_name, $task);
        die("not expecting has_failed"), if($report->has_failed());
        die("expecting good return value"), unless( $report->return_value()==0 );
        die("expecting last_task=good_task"), unless( $build_area->last_task() eq $task_name );

        # -- repeat the task, this time errors out
        my $error_msg="I dies horribly";
        $platform->error(3, $error_msg);
        $report=$build_area->execute($task_name, $task);
        die("expecting has_failed"), unless( $report->has_failed() );
        die("expecting return value = 3"), unless( $report->return_value()==3 );
        die("expecting last_task=good_task"), unless( $build_area->last_task() eq $task_name );
        my $msg=join("", $report->error_messages());
        die("expecting message = $error_msg, got ", $msg), unless( $msg eq $error_msg );
    }

    # -- persistency test
    my $build_area=DevOps::BuildArea->new($tmpdir->dir());
    die("expecting last_task=good_task"), unless( $build_area->last_task() eq $task_name );
    my $report=$build_area->report($task_name);
    die("expecting report"), unless( defined $report );
    die("expecting return value = 3"), unless( $report->return_value()==3 );
    my $log_file=$build_area->log_file($task_name);
    die("expecting to find $log_file"), unless ( -f $log_file );
}

sub test_execute_sequence {
    my $self=shift;

    my $tmpdir=$self->{tmpdir};
    my $platform=new Paf::Platform::TestHost;
    my $task_name="good_task";

    my $task=new Paf::Platform::Task($platform);
    my $cmd="hello world";
    $task->add($cmd);
    {
        my $build_area=DevOps::BuildArea->new($tmpdir->dir());

        my $ts=Paf::Platform::TaskSeries->new();
        $ts->add_task("task_name",$task);
        my $report=$build_area->execute_sequence("test", $ts);
        die("not expecting has_failed"), if($report->has_failed());
        die("expecting good return value"), unless( $report->return_value()==0 );
        my $executed=join("",$platform->executed_commands());
        die("expecting $cmd got $executed"), unless $cmd eq $executed;
    }

    # persistency between calls
    my $build_area=DevOps::BuildArea->new($tmpdir->dir());
    my $ts=Paf::Platform::TaskSeries->new();
    $ts->add_task("task_name",$task);
    my $report=$build_area->execute_sequence("test", $ts);
    die("not expecting has_failed"), if($report->has_failed());
    die("expecting good return value"), unless( $report->return_value()==0 );
}
