# -----------------------------------------------
# DevOps::WorkSpaceManager
# -----------------------------------------------
# Description: 
#   Manage local workspaces
#
#
# -----------------------------------------------
# Copyright Chris Williams 2008-2014
# -----------------------------------------------

package DevOps::WorkSpaceManager;
use DevOps::WorkSpace;
use strict;
use Carp;
use Cwd;
use File::Basename;
use File::Path;
use Storable;
1;

# -- initialisation

sub new {
    my $class=shift;

    my $self={};
    bless $self, $class;

    $self->{file}=shift || carp ("expecting a filename");
    $self->{base}=shift || carp ("expecting a base directory");

    if( !File::Spec->file_name_is_absolute($self->{file}) ) { die ("storage filename must be a fullpath : ", $self->{file}) };

    $self->_read(), if( -f $self->{file} );

    return $self;
}

sub get_workspace
{
    my $self=shift;
    my $project_id=shift;

    my $uid=$project_id->uid();

    my $key=$project_id->serialize();
    return $self->{ws}{$key}, if(defined $self->{ws}{$key});

    my $location=$self->{locations}{$key};
    if( ! defined $location ) {
        # search for matching keys
        foreach my $uid_key ( keys %{$self->{locations}} ) {
            next, unless $project_id->match(new DevOps::ProjectId($uid_key));
            $location = $self->{locations}{$uid_key};
            last;
        }
    }
    if( defined $location )
    {
        if(! -d $location ) {
            # ---- corrupted database - fix it -----
	    print "removing corrupted entry", $location;
            $self->remove_entry($project_id);
        }
        else
        {
            # ---- return the pre-exisitng object
            return $self->_add_workspace(new DevOps::WorkSpace($location));
        }
    }
    return undef;
}

sub construct_workspace
{
    my $self=shift;
    my $project=shift || carp "expecting a project";
    my $location=shift;

    my $project_id=$project->id();
    my $key=$project_id->serialize();

    if( ! defined $location ) {
        $location=$self->{base}."/".$project_id->name()."/".$project_id->version();
    }
    if( ! -d $location ) {
        mkpath $location || die("unable to construct workspace ", $location);
    }
    my $workspace=new DevOps::WorkSpace($location);
    $workspace->construct($project);
    $self->{ws}{$key}=$workspace;
    $self->{locations}{$key}=$location;
    $self->_save();
    return $workspace;
}

sub remove_entry 
{
    my $self=shift;
    my $project_id=shift;

    my $key=$project_id->serialize();
    if( defined $self->{locations}{$key} )
    {
        delete $self->{locations}{$key};
        $self->_save();
    }
}

sub current_workspace 
{
    my $self=shift;
    my $path=getcwd();
    my $workspace=new DevOps::WorkSpace($path);
    while( ! $workspace->is_constructed() ) {
        $path=dirname $path;
        $workspace->reset($path);
        return undef, if( $path eq dirname $path );
    }

    # -- check this area is registered
    my $proj_id=$workspace->project_id();
    if( defined $proj_id ) {
        my $key=$proj_id->serialize();
        if( ! defined $self->{locations}{$key} )
        {
            $self->{locations}{$key}=$path;
            $self->_save();
        }
    }
    return $workspace;
}
    
# return the named environment for the specified workspace, including all dependent workspaces
sub environment {
    my $self=shift;
    my $workspace=shift;
    my $name=shift;
    my $namespace=shift||1;
    my $env=$workspace->environment($name);
    foreach my $dep ( $workspace->dependencies() )
    {
        my $ws_id=$workspace->workspace_dependency($dep);
        if( defined $ws_id ) {
            # -- only immediate dependencies are included so we don't recursively call this method
            my $ws=$self->get_workspace_from_location($ws_id);
            if($namespace == 1) {
                $env->merge_namespace( [ $dep->name() , $dep->version() ], $ws->environment($name) );
                $env->merge_namespace( [ $dep->name() ], $ws->environment($name) );
            }
            else {
                $env->merge( $ws->environment($name, $namespace) );
            }
        }
    }

    return $env;
}

sub get_workspace_from_location {
    my $self=shift;
    my $location=shift || die "expecting a location";

    if(! defined $self->{workspaces_by_loc}{$location}) {
        if( -d $location ) {
            my $workspace=new DevOps::WorkSpace($location);
            $self->_add_workspace($workspace);
        }
        else {
            return undef;
        }
    }
    return $self->{workspaces_by_loc}{$location};
}
    
# -- private methods -------------------------

sub _save {
    my $self=shift;
    store $self->{locations}, $self->{file};
}

sub _read {
    my $self=shift;
    $self->{locations} = retrieve $self->{file};
}

# unit testing only
sub _add_workspace {
    my $self=shift;
    my $ws=shift;

    my $key=$ws->project_id()->serialize();
    if( ! defined $self->{ws}{$key} ) {
        $self->{ws}{$key}=$ws;
        $self->{locations}{$key}=$ws->location();
        $self->{workspaces_by_loc}{$ws->location()} = $ws;
    }
    return $self->{ws}{$key};
}

