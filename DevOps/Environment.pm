# ----------------------------------
# class DevOps::Environment
# Description:
#   A convenience class to copy and merge hashes representing environment variables
#-----------------------------------
# Methods:
# new(@list_of_hashref) :
# namespace(name) : set/return the namespace of the variables
# deleteVar(name) : remove the named variable from the environment
# diff(Environment) : returns a new Environment containing values in this
#                     object that differ from the one passed
# env() : return a hash ref of the environment
# expand(Environment)  : expand all variables in the object by any definitions in the passed env
# expandString(string) : expand the variables in the passed string
#                        marked with curly brackets e.g. ${varname} 
#                        use $$ to escape the $ identifier
# merge(hashref|Environment) : merge in the data, exisitng variables are not overriden. Namespaces are ignored.
# remove(hashref|Environment) : remove the variables specified in the provided Environment
# removeUndefined(string)     : remove any undefined variables from the string
# set(var,value) : set a single variable
# size() : return the number of variables
# var(name) : return the value of the specified variable
# dump() : output to filestream
#-----------------------------------

package DevOps::Environment;
use strict;
1;

sub new {
    my $class=shift;
    my $self={};
    bless $self, $class;
    $self->{env}={};
    for(@_) {
        $self->merge($_);
    }
    @{$self->{ns}}=("");
    return $self;
}

sub clone {
    my $self=shift;
    my $env=new DevOps::Environment($self->{env});
    @{$env->{ns}}=@{$self->{ns}};
    return $env;
}

sub namespace {
    my $self=shift;
    if(@_) {
       @{$self->{ns}}=();
       for(@_){
           if($_ eq "" ) {
               push @{$self->{ns}},"";
           }
           else {
               push @{$self->{ns}},($_=~/.+::$/?$_:$_."::");
           }
       }
    }
    return (@{$self->{ns}});
}

sub env {
    my $self=shift;
    return $self->{env};
}

sub add {
    my $self=shift;
    push @{$self->{environments}}, @_;
}

sub raw_var {
    my $self=shift;
    my $name=shift;
    return $self->{env}{$name};
}

sub var {
    my $self=shift;
    my $name=shift;

    if( defined $self->{env}{$name} ) {
        return $self->_expandStringExclude($self->{env}{$name},[ $name ], "");
    }

    # -- not found locally so parse through other envs
    foreach my $e ( @{$self->{environments}} ) {
        my $ns_string=join("",@{$e->{ns}});
        if($name=~/$ns_string(.*)/) {
            my $val=$e->var($1);
            return $val, if( $val );
        }
    }
    return undef;
}

sub removeUndefined {
    my $self=shift;
    my $string=shift;

    if( not defined $string ) {
        return $string;
    }

   if( $string=~/(.*?)\$\{(.*?)\}(.*(\n?))/g ) {
        my $f1=$1;
        my $f2=$2; 
        if(defined $self->var($f2) || defined $ENV{$f2} ) {
            $string=$f1."\${$f2\}".($self->removeUndefined($3));
        }
        else {
            $string=$f1.($self->removeUndefined($3));
        }
    }
    return $string;
}

sub set {
    my $self=shift;
    my $name=shift;
    $self->{env}{$name}=shift;
}

sub expand {
    my $self=shift;
    my $env=shift;

    foreach my $key ( keys %{$self->{env}} ) {
        $self->{env}{$key}=$env->_expandStringExclude($self->{env}{$key}, [ $key ] );
    }
}

sub expandString {
    my $self=shift;
    my $string=shift;
    $self->_expandString($string,[ keys %{$self->{env}} ], @_);
}

sub _expandStringExclude {
    my $self=shift;
    my $string=shift;
    my $excluded=shift;
    
    my @keys=();
    foreach my $key ( keys %{$self->{env}} ) {
        next, if( grep(/^$key$/, @{$excluded}) );
        push @keys, $key;
    }
    return $self->_expandString( $string, \@keys, @_);
}

sub _expandString {
    my $self=shift;
    my $string=shift;
    my $expansion_list=shift;

    my @ns;
    if(@_) {
        @ns=@_;
    }
    else {
        @ns=@{$self->{ns}};
    }
    if( defined $string ) {
        foreach my $v ( @{$expansion_list} ) {
            foreach my $namesp ( @ns ) {
                while( $string=~/(.*?)(?<!\$)\$\{\Q$namesp$v\E\}(.*(\n?))/g ) {
                    my $f1=$1;
                    my $f2=$2; 
                    $string=$f1.($self->expandString($self->{env}{$v},"")).$f2;
                }
                #$string=~s/(.*?)(?<!\$)\$\{$namesp$v\}(.*?)/$1$self->{env}{$v}$2/g;
            }
        }
        # -- send through other environments
        foreach my $e ( @{$self->{environments}} ) {
            $string=$e->expandString($string);
        }
    }
    return $string;
}

sub deleteVar {
    my $self=shift;
    my $var=shift;
    delete $self->{env}{$var};
}

sub merge {
    my $self=shift;

    foreach my $hash ( @_ ) {
        if( defined $hash ) {
            if( ref($hash) eq "DevOps::Environment" ) {
                $hash=$hash->{env};
            }
            foreach my $key ( keys %$hash ) {
                if( ! defined $self->{env}{$key} ) {
                    $self->{env}{$key}=$hash->{$key};
                    next;
                }
                # deal with any self referencing vars
                if( $hash->{$key}=~/(.*?)(?<!\$)\$\{\Q$key\E\}(.*(\n?))/ ) {
                    my $string=$hash->{$key};
                    my $val=$self->{env}{$key};
                    $string=~s/(.*?)(?<!\$)\$\{\Q$key\E\}(.*(\n?))/$1$val$2/g;
                    $self->{env}{$key}=$string;
                }
            }
        }
    }
}

sub merge_namespace {
    my $self=shift;
    my $namespace_array=shift||die "expecting an array refernece for the namespace";
    my $env=shift||die "expecting an Environment";

    my $clone=$env->clone();
    $clone->namespace(@{$namespace_array});
    $self->add($clone);
}

sub size {
    my $self=shift;
    my $size=scalar keys %{$self->{env}};
    foreach my $env ( @{$self->{environments}} )
    {
        $size+=$env->size();
    }
    return $size;
}

# returns a new Environment containing values in this
# object that differ from the one passed
sub diff {
    my $self=shift;
    my $env=shift;

    my $new={};
    for( keys %{$self->{env}} ) {
        my $r=$env->var($_);
        if( ! defined $r || $self->var($_) ne $r ) {
            $new->{$_}=$self->{env}{$_};
        }
    }
    return DevOps::Environment->new($new);
}

sub remove {
    my $self=shift;
    my $hash=shift;
    if( defined $hash ) {
        if( ref($hash) eq "DevOps::Environment" ) {
            return, if("@{$hash->{ns}}" ne "@{$self->{ns}}");
            $hash=$hash->{env};
        }
        foreach my $key( keys %$hash ) {
             delete $self->{env}{$key};
        }
    }
}

sub dump {
    my $self=shift;
    my $fh=shift||\*STDOUT;
    my $sep=shift;
    $sep="=", if( !defined $sep);
    my $ns_string=join("",@{$self->{ns}});
    
    for( keys %{$self->{env}} ) {
        print $fh $ns_string.$_.$sep.$self->var($_),"\n";
    }
    foreach my $e ( @{$self->{environments}} ) {
        $e->dump($fh, $sep);
    }
}
