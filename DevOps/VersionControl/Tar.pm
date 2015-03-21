# -----------------------------------------------
# DevOps::VersionControl::Tar
# -----------------------------------------------
# Description: 
#    Tar ball download and unpack wrapped in the 
# Version Control Interface
#
# -----------------------------------------------
# Copyright Chris Williams 2014
# -----------------------------------------------
#

package DevOps::VersionControl::Tar;
use Paf::File::PushDir;
use Paf::File::DownloadCache;
use File::Basename;
use Carp;
use Archive::Tar;
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
        carp "tar - url required";
    }
    if( ! defined $self->{config}{tar_cmd} ) {
        $self->{config}{tar_cmd}="tar";
    }
    if( ! defined $self->{config}{unzip_cmd} ) {
        $self->{config}{unzip_cmd}="unzip";
    }
    if( ! defined $self->{config}{cache_location} ) {
        carp "cache location undefined";
    }

    $self->{cache}=Paf::File::DownloadCache->new($self->{config}{cache_location});

    return $self;
}

sub checkout {
    my $self=shift;
    my $destination=shift || carp "destination not passed";
    my $version=shift;

    if(!File::Spec->file_name_is_absolute($destination)) {
        carp "$destination is not a full path";
    }

    # -- fetch the tar ball
    my $uri=$self->{config}{url};
    my $tarball=$self->{cache}->get($uri);
    if(!$tarball) { die("could not download $uri"); }

    # -- unpack it
    if( ! -d $destination ) {
        mkdir $destination or die "cannot create dir $destination : $!";
    }
    $self->_unpack($destination, $tarball);
}

sub _unpack {
    my $self=shift;
    my $workspace=shift;
    my $file = shift;

    my($filename, $directories, $suffix) = fileparse($file, '\..*');
    my $cmd="";
    my $tar=$self->{config}{tar_cmd}." -o";
    my $unzip=$self->{config}{unzip_cmd};
    if( $suffix =~ /zip/i ) {
        $cmd="$unzip";
    }
    elsif( $file =~ /tar\.gz$/i || $suffix=~/tgz$/i )
    {
        if( -e $tar ) {
            $cmd="$tar -xzf";
        }
        elsif(Archive::Tar->has_zlib_support) {
            my $dirstack=Paf::File::PushDir->new($workspace);
            my $tar=Archive::Tar->new();
            $tar->extract_archive("$file", COMPRESS_GZIP) or warn "extraction failed :", $tar->error();
            return $workspace;
        }
	else {
	    die ("unable to untar zipped file - not available");
	}
    }
    elsif( $file =~ /tar\.bz2$/i || $suffix=~/tbz$/i ) {
        if( -e $tar )
            $cmd="$tar -xjf";
        }
        elsif(Archive::Tar->has_bzip2_support) {
            my $dirstack=Paf::File::PushDir->new($workspace);
            my $tar=Archive::Tar->new();
            $tar->extract_archive("$file", COMPRESS_BZIP) or warn "extraction failed :", $tar->error();
            return $workspace;
        }
	else {
	    die ("unable to untar bzip2 file - not available");
	}
    }
    elsif( $suffix =~ /tar$/i )
    {
        if( -e $tar ) {
            $cmd="$tar -xf";
	}
	else {
            my $dirstack=Paf::File::PushDir->new($workspace);
	    my $tar=Archive::Tar->new();
	    $tar->extract_archive("$file") or warn "extraction failed :", $tar->error();
	    return $workspace;
	}
    }

    if( $cmd ne "" ) {
        my $dirstack=Paf::File::PushDir->new($workspace);
        #print "unpacking $tarball to $workspace\n";
        ( system("$cmd $file") == 0 )  or die "unable to execute $cmd $file";
    }
    else {
        die ("Unknown file type ( $suffix )");
    }
    return $workspace;
}

# -- private methods -------------------------

