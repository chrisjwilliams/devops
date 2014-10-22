# -----------------------------------------------
# DevOps::Cli::VerboseOption
# -----------------------------------------------
# -----------------------------------------------
# Copyright Chris Williams 2014
# -----------------------------------------------

package DevOps::Cli::VerboseOption;
use parent "Paf::Cli::Option";
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;
	my $self=$class->SUPER::new(@_);
    $self->{level}=0;
	return $self;
}

sub name {
    return "verbose";
}

sub help {
    return "set verbosity level (default 0)";
}

sub synopsis {
    return "verbose <level>";
}

sub run {
    my $self=shift;
    my $args=shift;
    my $v=shift @$args;
    if( ! defined $v ) { print "no verbosity level specified"; return 1; }
    $self->{level}=$v;
    print "verbosity level set to $v\n", if ( $v > 0 );
    return 0;
}

sub level {
    my $self=shift;
    return $self->{level};
}

# -- private methods -------------------------

