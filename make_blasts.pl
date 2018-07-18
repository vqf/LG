#!/usr/bin/perl -w
use strict;

use Cwd;

my $dir = getcwd;

my $n = shift || 8;

my $rname = "results";

my @files = ();
opendir(DIR, $dir);
while (my $f = readdir(DIR)){
  if ($f =~ /\.fa$/){
    push @files, $f;
  }
}
closedir DIR;

my $rfold = compose_path($dir, $rname);

if (!-d $rfold){
  mkdir($rfold);
}

my $i = iterator((1 .. $n));
my $commands = [];

foreach my $f (@files){
  foreach my $g (@files){
    next if ($f eq $g);
    my $command = "blastall -p blastp -e 1e-10 -m 8 -d $g -i $f | gzip >$rname\/$f\__$g\.blast.gz";
    $command .= "\n(>&2 echo \"Finished comparing $f with $g\")";
    my $n = $i->();
    push @{$commands->[$n]}, $command;
  }
}

for (my $c = 1; $c < scalar(@$commands); $c++){
  my $fname = "blastme$c.sh";
  my $cs = $commands->[$c];
  open (OUT, ">$fname");
  print OUT join("\n", @$cs);
  close OUT;
  `chmod 755 $fname`;
}

sub compose_path{
  my $p = shift;
  my $f = shift;
  $p =~ s/[\/\s]*$//;
  my $result = "$p\/$f";
  return $result;
}




sub iterator{
  my $elements = \@_;
  my $i = 0;
  return sub{
    my $result = $elements->[$i];
    if ($i >= scalar(@$elements) - 1){
      $i = 0;
    }
    else{
      $i++;
    }
    return $result;
  };
}
