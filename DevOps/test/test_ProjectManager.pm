package test_ProjectManager;
use strict;
use DevOps::ProjectManager;
use File::Sync qw( sync );
use Paf::File::SearchPath;
use Paf::File::TempDir;
#use DevOps::TestUtils::DevOpsRepo;
1;

sub new {
    my $class=shift;
    my $self={};
    bless $self,$class;

    $self->{config}=Paf::File::SearchPath->new();
    $self->{testproject_1_name}="tp1_name";
    $self->{testproject_2_name}="tp2_name";
    $self->{testproject_3_name}="tp3_name";
    $self->{testproject_1_version}="tp1_version";
    $self->{testproject_2_version}="tp2_version";
    $self->{testproject_3_version}="tp3_version";
    return $self;
}

sub tests {
    return qw(test_import test_list_empty_pm test_duplicate_ids);
}

sub test_import {
    my $self=shift;
}

sub test_list_empty_pm {
    my $self=shift;
    my $pm=DevOps::ProjectManager->new($self->{config});
    die ("expecting no entries , got ", $self->print_projects()), if($pm->list());
}

sub test_duplicate_ids {
    my $self=shift;


    my $id={ name => $self->{testproject_1_name}, 
             version => $self->{testproject_1_version}
           };

    # -- create multiple file stores each with objects that match the id
    my $loc1=Paf::File::TempDir->new();
    my $loc2=Paf::File::TempDir->new();
    my $f1 = new Paf::DataStore::DirStore($loc1->dir(), ("name", "version"));
    my $f2 = new Paf::DataStore::DirStore($loc2->dir(), ("name", "version"));

    $f1->add($id, undef);
    $f2->add($id, undef);

    my $path=Paf::File::SearchPath->new();
    my $pm=DevOps::ProjectManager->new($path);
    $pm->add_store($f1);
    $pm->add_store($f2);

    my @uids=$pm->list();
    die ("expecting two entries, got ", $#uids + 1), if ($#uids != 1);
    foreach my $uid ( @uids ) {
        die("expecting a matching id"), unless ($uid->match($id));
    }

    # check reverse order to filestore additions
    die "out of order", if($uids[0]->uid()->store_id() ne $f2->id());
    die "out of order", if($uids[1]->uid()->store_id() ne $f1->id());

    # check get() returns in the correct object (last added store is priority)
    my $obj1=$pm->get($uids[0]);
    my $obj2=$pm->get($uids[1]);
    die("expected object"), if (! defined $obj1);
    die("expected object"), if (! defined $obj2);
}
