package test_Tar;
use strict;
use Paf::File::DirectoryContent;
use DevOps::VersionControl::Tar;
use DevOps::TestUtils::TestSourceContent;
use Archive::Tar;
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
    return qw(test_checkout)
}

sub test_checkout {
    my $self=shift;

    my $srcdir=$self->{tmpdir}->dir()."/original_src";
    my $src=DevOps::TestUtils::TestSourceContent->new($srcdir);

    # create a tar archive
    my $filename=$self->{tmpdir}->{dir}."/test.tar";
    my $tar=Archive::Tar->new();
    $tar-chdir($srcdir);
    $tar->add_files($src->relative_file_list());
    $tar->write($filename) or die "unable to create tar $filename";

    # create our object to test
    my $destination=$self->{tmpdir}->dir()."/destination";
    my $vc=DevOps::VersionControl::Tar->new( { cache_location => $self->{tmpdir}->dir()."/cache", 
                                               url => "file:$filename" } );
    $vc->checkout($destination);
    die("expecting $destination to exist"), unless -d $destination;

    # verify checkout is as expected
    my $dc=Paf::File::DirectoryContent->new($destination);
    my $files=join(",",sort($dc->files()));
    my $expected=join(",",sort($src->relative_file_list()));
    die("expecting $expected got $files"), unless $expected eq $files;
    
}
