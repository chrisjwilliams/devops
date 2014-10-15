# -----------------------------------------------
# DevOps::VersionControl::Copy
# -----------------------------------------------
# Description: 
#    Simple Version Control system that just makes
# a copy of the provided src tree
#
# -----------------------------------------------
# Copyright Chris Williams 2013-2014
# -----------------------------------------------

package DevOps::VersionControl::Copy;
use Paf::File::DirIterator;
use File::Copy;
use Carp;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;

	my $self={};
	bless $self, $class;

    $self->{config}=shift;

	return $self;
}

sub checkout {
    my $self=shift;
    my $destination=shift || carp "destination not passed";
    my $version=shift; # ignored

    if($destination!~/^\/.*/) {
        carp "$destination is not a full path";
    }
    if( ! -d $destination ) {
        mkdir $destination;
    }

    my $src=$self->{config}->{src};
    if( defined $src ) {
        if( -d $src ) {
            my $it=Paf::File::DirIterator->new($src);
            $it->relativePath();
            while( my $item=$it->next() ) {
                my $copy=$destination."/$item";
                if( -d $src."/".$item ) {
                    mkdir $copy || die "unable to make dir $copy";
                }
                else {
                    File::Copy::copy( $src."/".$item, $copy );
                }
            }
        }
    }
}

# -- private methods -------------------------

