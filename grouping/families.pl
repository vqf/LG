#!/usr/bin/perl -w
use strict;
use JSON;

my $sp1 = shift;
my $sp2 = shift;

my $j = JSON->new();

my $infile = "good_alignments_$sp1\_$sp2.json";

die("$infile does not exist\n") unless (-e $infile);

my $grouping = $j->decode(slurp($infile));


my $nfam = 1;

foreach my $prot1 (keys %{$grouping->{$sp1}{$sp2}}){
  my $where = $grouping->{$sp1}{$sp2}{$prot1};
  my $fam = $nfam;
  #$fam = $where->{'nfam'} if (istrue($where, 'nfam'));
  get_fam($grouping, $sp1, $sp2, $prot1, $fam);
  #delinuse($grouping, $sp1, $sp2, $prot1);
  $nfam++;
}

my $result = {'result' => [], 'index' => {}};

foreach my $prot1 (keys %{$grouping->{$sp1}{$sp2}}){
  my $where = $grouping->{$sp1}{$sp2}{$prot1};
  foreach my $p2 (keys %$where){
    my $f = 0;
    if ($where->{$p2}{'nfam'}){
      $f = $where->{$p2}{'nfam'};
    }
    else{
      warn("No fam for $prot1-$p2\n");
    }
    $result->{'result'}[$f]{$sp1}{$prot1}++;
    $result->{'result'}[$f]{$sp2}{$p2}++;
    $result->{'index'}{$prot1} = $f;
    $result->{'index'}{$p2} = $f;
  }
}

open (OUT, ">families_$sp1\_$sp2.json");
print OUT $j->encode($result);
close OUT;

sub get_fam{
  my $g = shift;
  my $sp1 = shift;
  my $sp2 = shift;
  my $p1 = shift;
  my $nfam = shift;
  my $where = $g->{$sp1}{$sp2}{$p1};
  foreach my $p2 (keys %$where){
    my $w2 = $g->{$sp2}{$sp1}{$p2};
    next if (istrue($w2->{$p1}, 'inuse'));
    #warn("$p1\t$p2\n");
    #print debug($w2);
    #<STDIN>;
    $where->{$p2}{'inuse'} = 1;
    $w2->{$p1}{'inuse'} = 1;
    $where->{$p2}{'nfam'} = $nfam;
    $w2->{$p1}{'nfam'} = $nfam;
    get_fam($g, $sp2, $sp1, $p2, $nfam);
  }
}

sub delinuse{
  my $g = shift;
  my $sp1 = shift;
  my $sp2 = shift;
  my $p1 = shift;
  my $where = $g->{$sp1}{$sp2}{$p1};
  foreach my $p2 (keys %$where){
    my $w2 = $g->{$sp2}{$sp1}{$p2};
    $where->{$p2}{'inuse'} = 0;
    delinuse($g, $sp2, $sp1, $p2, $nfam) if (istrue($w2->{$p1}, 'inuse'));
  }
}

sub istrue{
  my $h = shift;
  my $k = shift;
  if (exists($h->{$k}) && $h->{$k}){
    return 1;
  }
  else{
    return 0;
  }
}

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