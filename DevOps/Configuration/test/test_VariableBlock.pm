package test_VariableBlock;
use strict;
use DevOps::Configuration::VariableBlock;
use Paf::File::TempDir;
1;

sub new {
    my $class=shift;
    my $self={};
    bless $self, $class;
    $self->{tmpdir}=Paf::File::TempDir->new();

    return $self;
}

sub tests {
    return qw(test_vars)
}

sub test_vars {
    my $self=shift;

    my $node=Paf::Configuration::Node->new("test");
    my $var_name="var_name";
    my $var_value="var_value";
    my $var_name2="var_name2";
    my $var_value2="\"var_value2\"";
    {
        my $vb=DevOps::Configuration::VariableBlock->new($node);
        die("not expecting any vars"), if(scalar keys %{$vb->vars()});

        $vb->set_var($var_name, $var_value);
        $vb->set_var($var_name2, $var_value2);
        my $value=$vb->value($var_name);
        die "expecting $var_value got $value", unless( $value eq $var_value );
        $vb->save();
    }

    # -- persistency check
    my $vb=DevOps::Configuration::VariableBlock->new($node);
    my $value=$vb->value($var_name);
    my $value2=$vb->value($var_name2);
    die "expecting $var_value got $value", unless( $value eq $var_value );
    die "expecting $var_value2 got $value2", unless( $value2 eq $var_value2 );
    
}

