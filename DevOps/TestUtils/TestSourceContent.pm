# -----------------------------------------------
# DevOps::TestUtils::TestSourceContent
# -----------------------------------------------
# Description: 
#   Creates a directory structure with some files
#  for testing purposes
#
# -----------------------------------------------
# Copyright Chris Williams 2003
# -----------------------------------------------

package DevOps::TestUtils::TestSourceContent;
use strict;
1;

# -- initialisation

sub new {
	my $class=shift;

	my $self={};
	bless $self, $class;
    my $location=shift;
    $self->{location}=$location;

    if( ! -d $location ) {
        mkdir $location or die ("unable to create dir", $self->{location});
    }

    foreach my $dir ( qw(dir1 dir2 dir3) ) {
        my $d=$location."/".$dir;
        mkdir $location."/$dir" or die ("unable to create dir $location/$dir");
        foreach my $file ( qw(file1 file2 file3) ) {
            my $f=$d."/".$file;
            $self->_touch($f);
            push @{$self->{file_list}}, $f;
            push @{$self->{relative_files}}, $dir."/".$file;
        }
    }

	return $self;
}

sub file_list {
    my $self=shift;
    return @{$self->{file_list}};
}

sub relative_file_list {
    my $self=shift;
    return @{$self->{relative_files}};
}

# -- private methods -------------------------

sub _touch {
    my $self=shift;
    my $file=shift;
    my $fh=FileHandle->new(">".$file) or die("error creating file $file : $!");
    print $fh "Filename: $file\n";
    $fh->close();
    return $file;
}
