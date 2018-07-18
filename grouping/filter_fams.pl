#!/usr/bin/perl -w
use strict;

use JSON;

my $sp1 = shift;
my $sp2 = shift;
my $sp3 = shift;

my $j = JSON->new();

my $infile = "families_$sp1\_$sp2.json";
my $infile2 = "families_$sp1\_$sp3.json";

die("$infile does not exist\n") unless (-e $infile);
die("$infile2 does not exist\n") unless (-e $infile2);

my $g = $j->decode(slurp($infile));
my $grouping = $g->{'result'};
my $g2 = $j->decode(slurp($infile2));
my $grouping2 = $g2->{'result'};
my $index2 = $g2->{'index'}; #Getting results for third species
my $orphans = shift @$grouping;

my $counter = {};

my $large = [];

foreach my $fam (@$grouping){
  my @k1 = keys(%{$fam->{$sp1}});
  next unless ($k1[0]);
  die(debug($fam)) if ($k1[0] =~ /EEF/);
  my $k3 = $index2->{$k1[0]} || -1;
  if ($k3 > -1){
    my $fam3 = $grouping2->[$k3];
    my @k3 = keys(%{$fam3->{$sp1}});
    my $n3 = scalar(@k3);
    my @k4 = keys(%{$fam3->{$sp3}});
    my $n4 = scalar(@k4);
    my $n1 = scalar(@k1);
    my $ex1 = shift(@k1);
    my @k2 = keys(%{$fam->{$sp2}});
    my $n2 = scalar(@k2);
    #print "$n1\t$n2\n";
    if ($n1 < $n2){
      #push @$large, $fam;
      my $p1 = join(', ', @k1);
      my $p2 = join(', ', @k2);
      my $p3 = join(', ', @k3);
      my $p4 = join(', ', @k4);
      print "$ex1\t$n1\t$n2\t$sp1: $p1\t$sp2: $p2\t$n3\t$n4\t$sp1: $p3\t$sp3: $p4\n";
    }
  }
}

#print debug($large);






sub slurp{
  my $file = shift;
  my $h    = shift;
  local $/ = undef;
  open (IN, $file) or die ("Could not open file: $!");
  my $result = <IN>;
  close IN;
  return $result;
}

sub debug{
  my $hash = shift;
  my $i = 0;
  my $level = 0;
  my $MAX = 50;
  my $uid = "\&__$i\__";
  my $xml = '<root>'.$uid.'</root>';
  my $id_list = {$uid => $hash};
  while (scalar keys %$id_list){
    my $new_id_list = {};
    $level++;
    foreach my $id (keys %$id_list){
      my $temp_xml = '';
      my $href = $id_list->{$id};
      if (ref($href) eq 'ARRAY'){
        my $counter = 0;
        foreach my $val (@$href){
          $i++;
          $uid = "\&__$i\__";
          $new_id_list->{$uid} = $val;
          $temp_xml .= "\<c_$level\_$counter\>$uid\<\/c_$level\_$counter\>";
          $counter++;
          last if ($counter > $MAX);
        }
      }
      elsif (ref($href) eq 'HASH' || ref($href) eq __PACKAGE__){
        my $counter = 0;
        foreach my $key (keys %$href){
          $i++;
          $uid = "\&__$i\__";
          $new_id_list->{$uid} = $href->{$key};
          my $safe = '';
          if (substr($key,0,1) =~ /[^a-zA-Z]/){
            $safe = 'a';
          }
          $temp_xml .= "\<$safe$key\>$uid\<\/$safe$key\>";
          $counter++;
          last if ($counter > $MAX);
        }
      }
      else{
        $href =~ s/[<>]//g;
        $href = '<![CDATA['.$href.']]>';
        $temp_xml .= $href;
      }
      $temp_xml = '_empty_' unless ($temp_xml);
      die ("$id\t$temp_xml\n") unless ($xml =~ /$id/);
      $xml =~ s/$id/$temp_xml/;
    }
    $id_list = $new_id_list;
  }
  return $xml;
}