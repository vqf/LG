#!/usr/bin/perl -w
use strict;
use JSON;
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
  'Human' => ['sp\|([^\|]+)', 'sp\|.+?\|(.+?)_HUMAN'],
  'George' => [$basic_name],
  'Turkey' => [$basic_name],
  'Mouse' => ['sp\|([^\|]+)', 'sp\|.+?\|(.+?)_MOUSE'],
  'Budgerigar' => [$basic_name],
  'Python' => [$basic_name],
  'Pelodiscus' => [$basic_name],
  'Habu' => [$basic_name],
  'Finch' => [$basic_name],
  'Sirtalis' => [$basic_name]
};



foreach my $sp (keys %$organisms){
  warn("Species $sp...\n");
  my $l = {};
  my $file = $organisms->{$sp};
  my $cprot = '';
  open (IN, $file);
  while (<IN>){
    if (/^>(.+)/){
      $cprot = getname($name_keys, $sp, $1);
    }
    else{
      s/\W//g;
      $l->{$cprot} += length($_);
    }
  }
  close IN;
  open (OUT, ">$sp\.length.json");
  print OUT $j->encode($l);
  close OUT;
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