package test_ProjectId;
use strict;
use DevOps::ProjectId;
use Paf::DataStore::Uid;
1;

sub new {
    my $class=shift;
    my $self={};
    bless $self, $class;

    return $self;
}

sub tests {
    return qw(test_new);
}

sub test_new {
    my $self=shift;

    my $uid=Paf::DataStore::Uid->new("test_store_id", { name => "name", version => "version"} );
    my $uid_string=$uid->serialize();

    my $id1=DevOps::ProjectId->new($uid);
    my $id2=DevOps::ProjectId->new($uid_string);

    die "expecting name", if ($id1->name() ne "name");
    die "expecting version", if ($id1->version() ne "version");

    die "expecting name", if ($id2->name() ne "name");
    die "expecting version", if ($id2->version() ne "version");

    die "match() failed", if ( ! $id1->match($id2) );
    die "match() failed", if ( ! $id2->match($id1) );
}
