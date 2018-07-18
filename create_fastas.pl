#!/usr/bin/perl -w
use strict;
use JSON;
use Cwd;
use Archive::Tar;

my $tar = Archive::Tar->new();

my $path = Cwd->cwd();
if ($path !~ /\/$/){
  $path .= '/';
}
my $oname = "${path}aligs.tar.gz";
my $file = 'paired.json';

my $js = JSON->new();
my $h = $js->decode(slurp($file));

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

my $order = ['Human', 'Mouse',
             'Dog',
             'Anolis',
             'Sirtalis',
             'Habu',
             'Python',
             'Gekko',
             'Chicken', 'Turkey', 'Duck', 'Budgerigar',
             'Finch',
             'Flycatcher',
             'Mydas',
             'George',
             'Picta', 'Pelodiscus'];

my @fornames = keys %{$h->{'prots'}{$order->[0]}};

my $counter = 0;
my $skipped = 0;

my $result = {};

$result->{'species'} = $order;

foreach my $start (@fornames){
  my $lacking = 0;
  my $orths = {};
  $orths->{$order->[0]} = $start;
  my $addme = 1;
  for (my $i = 1; $i < scalar(@$order) - 1; $i++){
    my $sp1 = $order->[$i];
    my $g1 = $h->{'prots'}{$order->[0]}{$start}{$sp1};
    if ($g1){
      $orths->{$sp1} = $g1;
      if (exists($orths->{$sp1}) && $orths->{$sp1} ne $g1){
        $addme = 0;
        print "$start: conflict at $sp1\n";
      }
      for (my $j = $i + 1; $j < scalar(@$order); $j++){
        my $sp2 = $order->[$j];
        my $g2 = $h->{'prots'}{$order->[0]}{$start}{$sp2};
        if ($g2){
          if (!exists($h->{'prots'}{$sp1}{$g1}{$sp2}) ||
              !exists($h->{'prots'}{$sp2}{$g2}{$sp1}) ||
              $h->{'prots'}{$sp1}{$g1}{$sp2} ne $g2 ||
              $h->{'prots'}{$sp2}{$g2}{$sp1} ne $g1){
            $addme = 0;
          }
          $orths->{$sp2} = $g2;
        }
        else{
          #$addme = 0;
          print "$start does not exist in $sp2\n";
        }
      }
    }
    else{
      $lacking++;
      if ($sp1 eq 'George' || $lacking > 3){
        $addme = 0;
      }
      print "$start does not exist in $sp1\n";
    }
  }
  if ($addme){
    foreach my $sp (@$order){
      next unless (exists($orths->{$sp}));
      my $seq = getseq($organisms->{$sp}, $orths->{$sp}, $sp);
      push @{$result->{'orthologs'}{$start}}, $seq;
    }
    $counter++;
    $tar->add_data("$start\.fa", join("\n", @{$result->{'orthologs'}{$start}}));
  }
  else{
    $skipped++;
  }
}

print "$counter groups, skipped $skipped\n";

$tar->write($oname, COMPRESS_GZIP);

#open (OUT, ">${path}orth_table.json");
#print OUT $js->encode($result);
#close OUT;


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

sub getseq{
  my $species = shift;
  my $pname = shift;
  my $qual = shift || '';
  my $folder = 'togetseq/';
  my $seq = `fastacmd -d $folder$species -s \'$pname\'`;
  $seq =~ s/>.+/>${qual}_$pname/;
  return $seq;
}