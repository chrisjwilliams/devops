# -----------------------------------------------
# DevOps::TestUtils::TestProject
# -----------------------------------------------
# Description: 
#    Create a temporary Project Space for testing
#
#
# -----------------------------------------------
# Copyright Chris Williams 2014
# -----------------------------------------------

package DevOps::TestUtils::TestProject;
use parent DevOps::Project;
use DevOps::ProjectId;
use Paf::DataStore::Uid;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;
    my $name=shift||"testproject_name";
    my $version=shift||"testproject_version";
    my $dir=shift;

    my $tmpdir;
    if( ! $dir ) {
        $tmpdir=Paf::File::TempDir->new();
        $dir=$tmpdir->dir();
        if( ! -d $dir )
        {
            mkdir $dir or die "unable to create dir $dir $!";
        }
    }

    my $uid=Paf::DataStore::Uid->new("test_store_id", 
                                     { "name" => $name,
                                       "version" => $version
                                     });
    my $id=DevOps::ProjectId->new($uid);
    my $self=$class->SUPER::new($id, $dir);
    $self->{proj_dir}=$tmpdir; # keep the tmep dir object in scope

	return $self;
}

sub project_dir {
    my $self=shift;
    return $self->{proj_dir}->dir();
}

# -- private methods -------------------------

