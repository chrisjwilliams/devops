# -----------------------------------------------
# DevOps::Cli::ToolChain
# -----------------------------------------------
# Description: 
#    Describe a toolchain with command line parameters
#
#
# -----------------------------------------------
# Copyright Chris Williams 2014
# -----------------------------------------------

package DevOps::Cli::ToolChain;
use parent "Paf::Cli::Option";
use File::Basename;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;

	my $self=$class->SUPER::new(@_);
	bless $self, $class;

	return $self;
}

sub name {
    return "tool";
}

sub help {
    return "set toolchain overrides (default gcc)";
}

sub synopsis {
    return "tool <tool_name> override the default toolchain";
}

sub run {
    my $self=shift;
    my $args=shift;
    my $v=shift @$args;
    if( ! defined $v ) { print "no tool chain specified"; return 1; }
    push @{$self->{tc}}, $v, @$args;
    return 0;
}

sub toolchain {
    my $self=shift;
    if( !defined $self->{tc} ) {
        if( defined $ENV{CXX} && $ENV{CXX} ne "" ) {
            @{$self->{tc}}=( basename($ENV{CXX}) );
        }
        else {
            @{$self->{tc}}=qw(gcc);
        }
    }
    return @{$self->{tc}};
}

# -- private methods -------------------------

