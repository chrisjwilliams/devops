# -----------------------------------------------
# DevOps::TestUtils::TestWorkspace
# -----------------------------------------------
# Description: 
#
#
#
# -----------------------------------------------
# Copyright Chris Williams 2003
# -----------------------------------------------

package DevOps::TestUtils::TestWorkSpace;
use parent DevOps::WorkSpace;
use Paf::File::TempDir;
use DevOps::TestUtils::TestProject;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;

    my $tmpdir=Paf::File::TempDir->new();
    my $dir=$tmpdir->dir();
    if( ! -d $dir )
    {
        mkdir $dir or die "unable to create dir $dir $!";
    }

    my $self=$class->SUPER::new($dir);
    $self->{proj_dir}=$tmpdir; # keep the tmep dir object in scope

    $self->{test_project}=DevOps::TestUtils::TestProject->new(@_);
    $self->construct($self->{test_project});

	return $self;
}

# -- private methods -------------------------

