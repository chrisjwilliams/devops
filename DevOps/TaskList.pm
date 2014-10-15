# -----------------------------------------------
# DevOps::TaskList
# -----------------------------------------------
# Description: 
#
#
#
# -----------------------------------------------
# Copyright Chris Williams 2003
# -----------------------------------------------
# Interface
# ---------
# new()	: new object
#
#

package DevOps::TaskList;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;

	my $self={};
	bless $self, $class;

	return $self;
}

# -- private methods -------------------------

