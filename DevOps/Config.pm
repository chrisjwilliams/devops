# -----------------------------------------------
# DevOps::Config
# -----------------------------------------------
# Description: 
#   API for all configurable aspects of the application 
#
# -----------------------------------------------
# Copyright Chris Williams 2014
# -----------------------------------------------

package DevOps::Config;
use Paf::File::SearchPath;
use Paf::Configuration::IniFile;
use Cwd;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;

	my $self={};
	bless $self, $class;

    if( ! -d $self->config_dir() )
    {
        mkdir $self->config_dir() or die("unable to construct configuration directory", $self->config_dir());
    }
    $self->{config_path}=Paf::File::SearchPath->new( $self->config_dir(), "/usr/local/share/devops", "/usr/share/devops");
    $self->{config_file}=Paf::Configuration::IniFile->new($self->{config_path}->find("config.ini"));

    return $self;
}

sub _config_file {
    my $self=shift;
    my $location=shift;

    if( ! defined $self->{config_files}{$location} ) 
    {
        if( grep($location, $self->{config_path}->paths()) ) {
            my $config_file=$location."/config.ini";
            $self->{config_files}{$location}=Paf::Configuration::IniFile->new($config_file);
            $self->{config_files}{$location}->setDefaultFile($config_file);
        }
        else {
            die "$location not in project path";
        }
    }
    return $self->{config_files}{$location};
}

sub _home {
    my $self=shift;
    if( ! defined $self->{home} ) {
        if( defined $ENV{"HOME"} ) {
            $self->{home} = $ENV{HOME};
        }
        else {
            $self->{home} = Cwd::cwd();
        }
    }
    return $self->{home};
}

sub dump {
    my $self=shift;
    print "configuration path=", join(":", $self->{config_path}->paths()) ,"\n";
    print "project path=", join(":", $self->project_path()->paths()),"\n";
}

sub config_dir {
    my $self=shift;
    my $dir=($self->_home())."/.devops";
    return $dir;
}

sub project_path {
    my $self=shift;
    if(!defined $self->{project_path})
    {
        $self->{project_path}=Paf::File::SearchPath->new();
        $self->{project_path}->add($self->config_dir()."/Projects");
        foreach my $dir ( $self->{config_file}->list("ProjectPaths") )
        {
            $self->{project_path}->add($dir);
        }
    }
    return $self->{project_path};
}

#
# Adds a project path directory to the corresponding configuration file
# Will throw if the requested config location is not in the know configuration path
#
sub add_project_path {
    my $self=shift;
    my $location=shift;
    my $dir=shift||die "must supply a directory. usage add_project_path(config_file_location, \@dirs)";

    my @dirs=@_;
    unshift @dirs, $dir;

    # -- store in the required configuration file
    my $file=$self->_config_file($location);
    if( defined $file )
    {
        foreach my $dir ( @dirs )
        {
            if(!$file->itemExists("ProjectPaths", $dir)) {
                $file->setList("ProjectPaths", $dir);
            }
        }
        $file->save();
    }

    # -- add to the local configuration
    my $path=$self->project_path();
    $path->unshift(@dirs);
    $self->set_project_path($path);
}

sub set_project_path {
    my $self=shift;
    my $path=shift|| die "no path specified";
    if(ref($path) eq "Paf::File::SearchPath")
    {
        $self->{project_path}=$path;
    }
    else {
        $self->{project_path}=Paf::File::SearchPath->new($path, @_);
    }
}

sub workspace_dir {
    my $self=shift;
    if(!defined $self->{workspace_dir})
    {
        $self->{workspace_dir}=cwd();
    }
    return $self->{workspace_dir};
}

sub set_workspace_dir {
    my $self=shift;
    $self->{workspace_dir}=shift;
}

sub importer_plugins {
    my $self=shift;
    if(!defined $self->{importer_path})
    {
        $self->{importer_path}=Paf::File::SearchPath->new();
    }
    return $self->{importer_path};
}

sub workspace_manager_data {
    my $self=shift;
    if(@_) {
        $self->{workspace_mgr_data}=shift;
    }
    if(!defined $self->{workspace_mgr_data})
    {
        $self->{workspace_mgr_data}=$self->config_dir()."/workspace.db";
    }
    return $self->{workspace_mgr_data};
}

# -- private methods -------------------------

