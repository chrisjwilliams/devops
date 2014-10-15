# -----------------------------------------------
# DevOps::VersionControl::Git
# -----------------------------------------------
# Description: 
#    access to a git repository
#
#
# -----------------------------------------------
# Copyright Chris Williams 2003
# -----------------------------------------------

package DevOps::VersionControl::Git;
use Paf::File::DownloadCache;
use Carp;
use warnings;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;

	my $self={};
	bless $self, $class;

    $self->{config}=shift;
    if( ! defined $self->{config}{url} ) {
        carp "git - url required";
    }
    if( ! defined $self->{config}{git_cmd} ) {
        $self->{config}{git_cmd}="git";
    }

	return $self;
}

sub checkout {
    my $self=shift;
    my $destination=shift || carp "destination not passed";
    my $version=shift;

    if($destination!~/^\/.*/) {
        carp "$destination is not a full path";
    }

    # clone the repository
    my $cmd=$self->{config}{git_cmd}." clone ".$self->{config}{url}." ".$destination;
    my @out=`$cmd`;
    foreach my $line ( @out ) {
        print $line, "\n";
    }
    if( $? == -1 ) {
        die "FAILED: $cmd \n\t$!";
    }

    # checkout required version
    if( defined $version ) {
        my $version_cmd=$self->{config}{git_cmd}." checkout ".$version;
        @out=`$version_cmd`;
        foreach my $line ( @out ) {
            print $line, "\n";
        }
        if( $? == -1 ) {
            die "FAILED: $version_cmd \n\t$!";
        }
    }

}

# -- private methods -------------------------

