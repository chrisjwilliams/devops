# -----------------------------------------------
# DevOps::ProjectId
# -----------------------------------------------
# Description: 
#   Basic Information about a Project to identify it
#
# -----------------------------------------------
# Copyright Chris Williams 1996-2014
# -----------------------------------------------

package DevOps::ProjectId;
use Paf::DataStore::Uid;
use Scalar::Util 'blessed';
use Carp;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;
    my $uid=shift||die "expecting an identifier";

	my $self={};
	bless $self, $class;

    if( ! blessed($uid) )
    {
        $self->{uid}=new Paf::DataStore::Uid($uid);
        confess ("unable to determine project id"), if( ! defined $self->{uid} );
    }
    else {
        $self->{uid}=$uid;
    }
    $self->{name}=$self->{uid}->value("name");
    $self->{version}=$self->{uid}->value("version");

	return $self;
}

sub devops_version {
    my $self=shift;
    return undef;
}

sub name {
    my $self=shift;
    if(@_)
    {
        $self->{name}=shift;
    }
    return $self->{name};
}

sub version {
    my $self=shift;
    if(@_)
    {
        $self->{version}=shift;
    }
    return $self->{version};
}

sub uid {
    my $self=shift;
    return $self->{uid};
}

sub match {
    my $self=shift;
    my $proj_id=shift || carp "no project id";;

    return 1, if( $self->{name} eq $proj_id->{name} &&
                  $self->{version} eq $proj_id->{version} );
    return 0;
}

sub serialize {
    my $self=shift;
    return $self->{uid}->serialize();
}

# -- private methods -------------------------

