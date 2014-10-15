# -----------------------------------------------
# DevOps::BuildArea
# -----------------------------------------------
# Description: 
#    Manages the build area
#
# -----------------------------------------------
# Copyright Chris Williams 2014
# -----------------------------------------------

package DevOps::BuildArea;
use File::Path;
use Paf::Configuration::IniFile;
use Paf::Configuration::XmlFile;
use Paf::Platform::Report;
use Paf::File::PushDir;
use Carp;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;

	my $self={};
	bless $self, $class;
    $self->{location}=shift || die "no location specified";
    $self->{work_location}=$self->{location}."/work";
    $self->{info_location}=$self->{location}."/info";
    $self->{install_location}=$self->{location}."/install";

    # create the location if necessary
    if( ! -d $self->{work_location} ) {
        mkpath $self->{work_location} or die ("unable to make directory '", $self->{work_location}, "'");
    }
    if( ! -d $self->{info_location} ) {
        mkdir $self->{info_location} or die ("unable to make directory '", $self->{info_location}, "'");
    }
    if( ! -d $self->{install_location} ) {
        mkdir $self->{install_location} or die ("unable to make directory '", $self->{install_location}, "'");
    }

    $self->{config_file}=$self->{info_location}."/status.ini";
    $self->{config}=Paf::Configuration::IniFile->new($self->{config_file});
    $self->{config}->setDefaultFile($self->{config_file});

	return $self;
}

sub env {
    my $self=shift;
    if( ! defined $self->{env} ) {
        my $env=DevOps::Environment->new();
        $env->set("install_dir", $self->install_location());
        $env->set("work_dir", $self->work_location());
        $self->{env}=$env;
    }
    return $self->{env};
}

sub work_location {
    my $self=shift;
    return $self->{work_location};
}

sub install_location {
    my $self=shift;
    return $self->{install_location};
}

sub log_file {
    my $self=shift;
    my $task_name=shift || die ("expecting a task name");

    return $self->{info_location}."/$task_name.log";
}

sub execute {
    my $self=shift;
    my $task_name=shift || die ("expecting a task name");
    my $task=shift || die ("expecting a task object");

    die("empty task name"), if ( $task_name eq "" );

    # -- execute everything inside the work directory --
    my $push_dir=new Paf::File::PushDir( $self->work_location() );

    # -- open a log file --
    my $log_name=$self->log_file($task_name);
    my $log=FileHandle->new(">".$log_name) or die "unable to open log file $log_name";

    my $report=Paf::Platform::Report->new($log);
    eval { $report=$task->execute($report); };
    if(@_) {
        my $msg="Error executing task '$task_name': @_";
        $report->error(1, $msg);
        print $log $msg;
    }

    $log->close();

    # -- save status info
    $self->{config}->setVar("task::$task_name", "failed", $report->has_failed());
    $self->{config}->setVar("status", "last_task", $task_name);
    $self->save();

    # -- save the report
    my $report_filename=$self->{info_location}."/".$task_name.".report";
    my $report_file=FileHandle->new(">$report_filename") || warn "could not save report for task $task_name : $!";
    if($report_file) {
        $report->serialize($report_file);
    }

    return $report;
}

sub execute_sequence {
    my $self=shift;
    my $sequence_name=shift || die ("expecting a sequence name");
    my $task_manager=shift || die ("expecting a task manager");
    my $stop_task=shift; # optional task to halt at in sequence

    # -- restore any reports from previos, so we know what needs to be run
    my $report_filename=$self->{info_location}."/$sequence_name.reports";
    my $xml_file=Paf::Configuration::XmlFile->new($report_filename);
    $task_manager->restore_reports($xml_file->root());

    # -- execute everything inside the work directory --
    my $push_dir=new Paf::File::PushDir( $self->work_location() );

    # -- we want a special report that redirects output to a local log file
    my @logs=();
    $task_manager->set_report_factory( 
        sub {
            my $task_name=shift;
            # -- open a log file --
            my $log_name=$self->log_file($task_name);
            my $log=FileHandle->new(">".$log_name) or die "unable to open log file $log_name";
            push @logs, $log;

            my $report=Paf::Platform::Report->new($log);
            return $report;
        });

    my $report=$task_manager->execute($stop_task);

    foreach my $log ( @logs ) {
        $log->close();
    }

    # -- save the reports
    $task_manager->store_reports($xml_file->root());
    $xml_file->save();

    return $report;
}


sub last_task {
    my $self=shift;
    return $self->{config}->var("status", "last_task");
}

sub report {
    my $self=shift;
    my $task_name=shift || confess "task name not specified";
    my $report=new Paf::Platform::Report;
    my $report_filename=$self->{info_location}."/".$task_name.".report";
    my $report_file=FileHandle->new("<$report_filename") || warn "could not open report for task $task_name ($report_filename) : $!";
    if($report_file) {
        $report->deserialize($report_file);
    }
    return $report;
}

sub task_status {
    my $self=shift;
    my $task_name=shift;

    return $self->{config}->var("task::$task_name", "failed");
}

sub save {
    my $self=shift;
    $self->{config}->save();
}

# -- private methods -------------------------

