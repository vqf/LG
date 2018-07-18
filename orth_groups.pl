#!/usr/bin/perl -w
use strict;
use JSON;

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

my $basic_name = '([^\|]+)';

my $name_keys = {
  'Duck' => [$basic_name],
  'Anolis' => [$basic_name],
  'Dog' => [$basic_name],
  'Mydas' => [$basic_name],
  'Picta' => [$basic_name],
  'Flycatcher' => [$basic_name],
  'Chicken' => [$basic_name],
  'Gekko' => [$basic_name],
  'Human' => ['sp\|([^\|]+)', 'sp\|.+?\|(.+?)_HUMAN\|'],
  'George' => [$basic_name],
  'Turkey' => [$basic_name],
  'Mouse' => ['sp\|([^\|]+)', 'sp\|.+?\|(.+?)_MOUSE\|'],
  'Budgerigar' => [$basic_name],
  'Python' => [$basic_name],
  'Pelodiscus' => [$basic_name],
  'Habu' => [$basic_name],
  'Finch' => [$basic_name],
  'Sirtalis' => [$basic_name]
};


foreach my $sp1 (keys %$organisms){
  my $table = {};
  foreach my $sp2 (keys %$organisms){
    #$sp1 = 'Human'; $sp2 = 'George';
    next if ($sp1 eq $sp2);
    warn("$sp1 vs $sp2\n");
    my $fname = 'results/' .
                $organisms->{$sp1} .
                '__' .
                $organisms->{$sp2} .
                '.blast.gz';
    open (IN, "-|", "zcat $fname") or die ("Problem opening $fname: $!\n");
    #open (IN, "delme2");
    while (<IN>){
      chomp;
      my ($queryId, $subjectId, $percIdentity, $alnLength,
          $mismatchCount, $gapOpenCount, $queryStart, $queryEnd,
          $subjectStart, $subjectEnd, $eVal, $bitScore) = split(/\t/);
      my $q1 = getname($name_keys, $sp1, $queryId);
      my $q2 = getname($name_keys, $sp2, $subjectId);
      if (exists($table->{$sp1}{$sp2}{$q1}{$q2})){
        my $h = $table->{$sp1}{$sp2}{$q1}{$q2};
        if ($h->{'eVal'} > $eVal){
          populate_table(\$table->{$sp1}{$sp2}{$q1}{$q2}, $percIdentity, $alnLength,
                        $mismatchCount, $gapOpenCount, $queryStart, $queryEnd,
                        $subjectStart, $subjectEnd, $eVal, $bitScore);
        }
      }
      else{
        populate_table(\$table->{$sp1}{$sp2}{$q1}{$q2}, $percIdentity, $alnLength,
                        $mismatchCount, $gapOpenCount, $queryStart, $queryEnd,
                        $subjectStart, $subjectEnd, $eVal, $bitScore);
      }
    }
    close IN;
  }
  warn("Writing results to json\n");
  open (OUT, ">$sp1\.json");
  print OUT $j->encode($table);
  close OUT;

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



sub populate_table{
  my $href = shift;
  my ($percIdentity, $alnLength,
      $mismatchCount, $gapOpenCount, $queryStart, $queryEnd,
      $subjectStart, $subjectEnd, $eVal, $bitScore) = @_;
  
  $$href = {
    'percIdentity' => $percIdentity,
    'alnLength' => $alnLength,
    'mismatchCount' => $mismatchCount,
    'gapOpenCount' => $gapOpenCount,
    'queryStart' => $queryStart,
    'queryEnd' => $queryEnd,
    'subjectStart' => $subjectStart,
    'subjectEnd' => $subjectEnd,
    'eVal' => $eVal,
    'bitScore' => $bitScore
  }
}

sub getname{
  my $dict = shift;
  my $species = shift;
  my $header = shift;
  my $regexes = $dict->{$species};
  my $results = [];
  foreach my $regex (@$regexes){
    if ($header =~ /$regex/){
      push @$results, $1;
    }
  }
  my $result = pop @$results;
  warn("Cannot read $header in $species\n") unless ($result);
  return $result;
}