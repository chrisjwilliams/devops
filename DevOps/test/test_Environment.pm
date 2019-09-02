# ----------------------------------
# class test_Environment
# Description:
#
#-----------------------------------


package test_Environment;
use strict;
use DevOps::Environment;
1;

sub new {
    my $class=shift;
    my $self={};
    bless $self, $class;
    return $self;
}

sub tests {
    return qw( test_size test_remove test_expand test_merge test_var test_self_refering_variable test_remove_empty_variables_from_string);
}

sub test_size {
    my $self=shift;
    my $env=$self->_initEnv();
    my $esize=3;
    my $size=$env->size();
    die("expecting $esize, got $size"), if( $esize != $size );

    # empty environment
    my $env2=DevOps::Environment->new();
    $size=$env2->size();
    die("expecting 0, got $size"), if( $size != 0 );

}

sub test_remove {
    my $self=shift;
    my $env=$self->_initEnv();
    my $esize=$env->size();
    my $env2=$self->_initEnv();

    # -- remove identical environment
    $env2->remove($env);
    my $size=$env2->size();
    die("expecting empty environment, got $size elements"), if( $size != 0 );

    # remove null environment
    my $env3=DevOps::Environment->new();
    $env->remove($env3);
    $size=$env->size();
    die("expecting $esize elements, got $size elements"), if( $size != $esize );

    # -- remove identical vars in a different namespace
    my $env4=$self->_initEnv();
    my $env5=$self->_initEnv();
    $env4->namespace("alpha");
    $env5->remove($env4);
    $size=$env5->size();
    die("expecting $esize elements, got $size elements"), if( $size != $esize );
}

sub test_expand {
    my $self=shift;

    # -- simple expand without namespaces
    my $env=$self->_initEnv();
    my $string='${a}+$${a}-${b}*$${b} ${bad} ${b}'."\n";
    my $estring='1+$${a}-2*$${b} ${bad} 2'."\n";
    $string=$env->expandString($string);
    die("expecting\n\t\t$estring\n\tgot\n\t\t$string"), if($estring ne $string);

    # -- simple expand with meta characters in name
    $string=$env->expandString('${c++}');
    my $cppstring='cpp';
    die("expecting\n\t\t$cppstring\n\tgot\n\t\t$string"), if($cppstring ne $string);

    # -- expand with namespaces
    $env->namespace("fred","george");
    $string='${fred::a}+$${a}-${george::b}*$${b} ${bad} ${fred::b}'."\n";
    $string=$env->expandString($string);
    die("expecting\n\t\t$estring\n\tgot\n\t\t$string"), if($estring ne $string);

    # -- expand mixed namespaces/no namespace
    my @enamesp=sort( "fred::","" );
    my @namespaces=sort($env->namespace("fred",""));
    die("expecting\n\t\t@enamesp\n\tgot\n\t\t@namespaces"), if("@namespaces" ne "@enamesp");

    $string='${fred::a}+$${a}-${b}*$${b} ${bad} ${b}'."\n";
    $string=$env->expandString($string);
    die("expecting\n\t\t$estring\n\tgot\n\t\t$string"), if($estring ne $string);
}

sub test_self_refering_variable {
    my $self=shift;
    my $env=$self->_initEnv();
    $env->set("some_var", 'abc${some_var}');
    die("unexpected value"), unless $env->var("some_var") eq 'abc${some_var}';
}

sub test_var {
    my $self=shift;
    my $env=$self->_initEnv();
    die("unexpected value"), unless $env->var("a") eq "1";
    my $subenv=DevOps::Environment->new( { "another_var" => "avvalue" } );
    $env->add($subenv);
    die("unexpected value"), unless $env->var("a") eq "1";
    die("unexpected value"), unless $env->var("another_var") eq "avvalue";
}

sub test_remove_empty_variables_from_string {
    my $self=shift;
    my $env=$self->_initEnv();
    $env->set("some_var", 'abc');
    my $string="a string with a) \${an_undefined} variable, b) \${another_undefined_var}, c) \${some_var}"; 
    my $sstring=$env->removeUndefined($string, $env);
    die("unexpected value \"$sstring\""), unless $sstring eq "a string with a)  variable, b) , c) \${some_var}";

    my $subenv=DevOps::Environment->new( { "another_undefined_var" => "fred" } );
    $env->add($subenv);
    $sstring=$env->removeUndefined($string, $env);
    die("unexpected value \"$sstring\""), unless $sstring eq "a string with a)  variable, b) \${another_undefined_var}, c) \${some_var}";
}

sub test_merge {
    my $self=shift;
    my $env=$self->_initEnv();

    # -- test merge of item with local variable
    $env->merge( { c=>'${a}', d=>'${c}' } );
    my $expect=1;
    my $val=$env->var("c");
    my $string=$env->expandString('${c}');
    die("expecting $expect, got $string"), if( $expect ne $string );
    die("expecting $expect, got $val"), if( $expect ne $val );
    $val=$env->var("d");
    $string=$env->expandString('${d}');
    die("expecting $expect, got $string"), if( $expect ne $string );
    die("expecting $expect, got $val"), if( $expect ne $val );

}

sub _initEnv {
    my $self=shift;
    my $env=DevOps::Environment->new(
                    { a=>1,
                      b=>2,
                      'c++'=>'cpp'
                    }
                );
    return $env;
}

