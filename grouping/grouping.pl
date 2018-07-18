#!/usr/bin/perl -w
use strict;
use JSON;

my $minAln = 0.8;
my $minId  = 0.6;

my $sp1 = shift;
my $sp2 = shift;



my $j = JSON->new();

my $organisms = {
  'Duck' => 'Anas_platyrhynchos.BGI_duck_1.0.pep.all.fa',
  'Anolis' => 'Anolis_carolinensis.AnoCar2.0.pep.all.fa',
  'Dog' => 'Canis_familiaris.CanFam3.1.pep.all.fa',
  'Mydas' => 'cmyd.pep.all.fa',
  'Picta' => 'cpic.pep.all.fa',
  'Flycatcher' => 'Ficedula_albicollis.FicAlb_1.4.pep.all.fa',
  'Chicken' => 'Gallus_gallus.Gallus_gallus-5.0.pep.all.fa',
  'Gekko' => 'gjap.pep.all.fa',
  'Human' => 'hsap.uniprot.swissprot.fa',
  'George' => 'lgeorge.augustus.func_protein.fa',
  'Turkey' => 'Meleagris_gallopavo.UMD2.pep.all.fa',
  'Mouse' => 'mmus.uniprot.swissprot.fa',
  'Budgerigar' => 'mund.pep.all.fa',
  'Python' => 'pbiv.pep.all.fa',
  'Pelodiscus' => 'Pelodiscus_sinensis.PelSin_1.0.pep.all.fa',
  'Habu' => 'pmuc.pep.all.fa',
  'Finch' => 'Taeniopygia_guttata.taeGut3.2.4.pep.all.fa',
  'Sirtalis' => 'tsir.pep.all.fa'
};

my $infile1 = '../' . $sp1 . '.json';
my $infile2 = '../' . $sp2 . '.json';

warn("Reading $infile1\n");
my $info1 = $j->decode(slurp($infile1));
warn("Reading $infile2\n");
my $info2 = $j->decode(slurp($infile2));


#$sp1 = 'Human'; $sp2 = 'George'; # DEBUG


my $plen1 = '../' . $sp1 . '.length.json';
my $plen2 = '../' . $sp2 . '.length.json';

my $l1 = $j->decode(slurp($plen1));
my $l2 = $j->decode(slurp($plen2));

# 80% of prot aligned, 60% id

my $grouping = {};

my $scheme = [[$info1, $l1, $l2, $sp1, $sp2],[$info2, $l2, $l1, $sp2, $sp1]];

foreach my $tmp (@$scheme){
  my $tinfo = $tmp->[0];
  my $tlp1 = $tmp->[1];
  my $tlp2 = $tmp->[2];
  my $tsp1 = $tmp->[3];
  my $tsp2 = $tmp->[4];
  warn("$tsp1 with $tsp2\n");
  foreach my $prot1 (keys %{$tinfo->{$tsp1}{$tsp2}}){
    #warn("$prot1\n");
    my $lp1 = $tlp1->{$prot1};
    warn("$prot1 in $tsp1 does not have a length\n") unless ($lp1);
    foreach my $prot2 (keys %{$tinfo->{$tsp1}{$tsp2}{$prot1}}){
      #warn("$prot2\n");
      my $lp2 = $tlp2->{$prot2};
      warn("$prot2 in $tsp2 does not have a length\n") unless ($lp2);
      my $tlen = max($lp1, $lp2) || 1;
      my $p = $tinfo->{$tsp1}{$tsp2}{$prot1}{$prot2};
      my $lAln = $p->{'alnLength'} / $tlen;
      my $pId = $p->{'percIdentity'} / 100;
      $p->{'aln'} = $tlen;
      if ($lAln >= $minAln && $pId >= $minId){
        $grouping->{$tsp1}{$tsp2}{$prot1}{$prot2} = $p;
      }
    }
  }
}

warn("Writing...\n");
open (OUT, ">good_alignments_$sp1\_$sp2.json");
print OUT $j->encode($grouping);
close OUT;

sub min{
  my $result = shift;
  foreach my $v (@_){
    $result = $v if ($v && $v < $result);
  }
  return $result;
}


sub max{
  my $result = shift;
  foreach my $v (@_){
    $result = $v if ($v > $result);
  }
  return $result;
}
sub slurp{
  my $file = shift;
  my $h    = shift;
  local $/ = undef;
  open (IN, $file) or die ("Could not open file $file: $!");
  my $result = <IN>;
  close IN;
  return $result;
}

sub debug{
  my $hash = shift;
  my $i = 0;
  my $level = 0;
  my $MAX = 10;
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