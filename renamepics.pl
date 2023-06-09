#!/usr/bin/env perl

use strict;
use warnings;
use experimental 'say';

use Image::ExifTool qw(:Public);
use Path::Tiny qw(cwd path);
use Time::Moment;

# we should process images with these suffixes
my @extensions = qw(jpg cr2 cr3);

# get parent directory
my $parent = cwd->parent;

# processed directory can optionally be supplied on the command-line
if($ARGV[0]) {
  my $userdir = path $ARGV[0];
  die "'$userdir' is not a directory" unless $userdir->is_dir;
  $parent = $userdir;
}

# verify that _incoming subdirectory exists
my $incoming = $parent->child('_incoming');
die "Directory '$incoming' does not exists" unless $incoming->is_dir;

# create list of images we will operate on
my @images = grep {
  my $f = 0;
  foreach my $e (@extensions) {
    $f = 1 if $_ =~ /\.$e$/i;
  }
  $f;
} grep {
  !$_->is_dir;
} $incoming->children;

# iterate over images
foreach my $image (@images) {

  # get image metadata
  my $inf = ImageInfo($image);
  my $tm = Time::Moment->from_string(
    $inf->{SubSecDateTimeOriginal} =~ s/^([^:]*):([^:]*):/$1-$2-/r,
    lenient => 1
  );

  # get image extension
  $image->basename =~ /\.(\w+)$/;
  my $ext = $1;

  # get image index
  $image->basename =~ /[-_](\d+)/;
  my $idx = $1;
  die 'Failed at ' . $image->basename if length($idx) != 4;

  # get complete new basename
  my $newname = $tm->strftime('%Y%m%d');

  # get image directory name
  my $dir = $parent->child($tm->strftime('%Y-%m-%d'));
  $dir->mkdir unless $dir->exists;
  my $dst = $dir->child(sprintf('%s-%s.%s', $newname, $idx, $ext));

  # rename
  $image->move($dst);
}
