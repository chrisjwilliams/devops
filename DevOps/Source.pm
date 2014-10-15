# -----------------------------------------------
# DevOps::Source
# -----------------------------------------------
# Description: 
#   Information about the src and location
#
#
# -----------------------------------------------
# Copyright Chris Williams 2003
# -----------------------------------------------

package DevOps::Source;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;

	my $self={};
	bless $self, $class;

    $self->{sub_dir}=shift;
    $self->{type}=shift;
    $self->{vcs_config}=shift;
    $self->{vcs_version}=shift;

    # -- sanity checking
    if(defined $self->{sub_dir}) {
        # -- cut any preceding /
        $self->{sub_dir}=~s/^\/*(.*)/$1/;

        # -- ensure empty is undef
        $self->{sub_dir}=undef, if($self->{sub_dir} eq "");
    }

	return $self;
}

sub vcs_type {
    my $self=shift;
    return $self->{type};
}

sub vcs_config {
    my $self=shift;
    return $self->{vcs_config};
}

sub version {
    my $self=shift;
    return $self->{vcs_version};
}

sub sub_dir {
    my $self=shift;
    return $self->{sub_dir};
}

# -- private methods -------------------------

