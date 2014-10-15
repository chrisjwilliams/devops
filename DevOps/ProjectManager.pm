package DevOps::ProjectManager;
use DevOps::Project;
use DevOps::ProjectId;
use Paf::DataStore::DirStore;
use Scalar::Util 'blessed';
use strict;
use Carp;
1;

sub new {
    my $class=shift;
    my $self={};

    $self->{path}=shift || die "no path provided";
    bless $self, $class;

    $self->add_dir( $self->{path}->paths() );

    return $self;
}

sub add_dir {
    my $self=shift;

    foreach my $dir ( @_ ) {
        if( -d $dir ) {
            $self->add_store(new Paf::DataStore::DirStore($dir, qw(name version)));
        }
    }
}

sub store_ids {
    my $self=shift;
    return keys %{$self->{store_lookup}};
}

sub add_store {
    my $self=shift;
    my $store=shift || carp "undef passed as a store";

    push @{$self->{stores}}, $store;
    $self->{store_lookup}{$store->id()}=$store;
}

sub list {
    my $self=shift;

    # -- get matching items from each store
    my @iterators=();
    foreach my $store ( @{$self->{stores}} )
    {
        push @iterators, $store->find(@_);
    }

    my @items=();
    foreach my $it ( @iterators )
    {
        while(defined (my $uid=$it->next()))
        {
            unshift @items, new DevOps::ProjectId($uid);
        }
    }
    
    return @items;
}

sub get {
    my $self=shift;
    my $id=shift;

    if(!(blessed $id && $id->isa("DevOps::ProjectId"))) {
        die "need to specify a ProjectId";
    }

    my $uid=$id->uid();
    if(!defined $self->{projects}{$uid}) {
        $self->{projects}{$uid}=DevOps::Project->new($id, $self->project_location($id->uid()));
    }
    return $self->{projects}{$uid};
}

sub import_project {
    my $self=shift;
    my $project=shift;
    my $store_id=shift||die("must specify store id");

    my $store=$self->{store_lookup}{$store_id};
    die("store with id $store_id not found: have ", keys %{$self->{store_lookup}}), if( ! defined $store );

    my $uid=$store->add( { name=>$project->name(), version=>$project->version() });
    my $filename=$self->project_location($uid);
    $project->save_to_location($filename);
    print "saving to location $filename\n";
}

sub project_location {
    my $self=shift;
    my $uid=shift;

    my $store=$self->{store_lookup}{$uid->store_id()};
    if(defined $store) {
        return $store->get($uid);
    }
    return undef;
}
