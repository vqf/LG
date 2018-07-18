#!/usr/bin/perl -w
use strict;
use JSON;

my $js = JSON->new();
my $organisms = [
  'Duck',
  'Anolis',
  'Dog',
  'Mydas',
  'Picta',
  'Flycatcher',
  'Chicken',
  'Gekko',
  'Human',
  'George',
  'Turkey',
  'Mouse',
  'Budgerigar',
  'Python',
  'Pelodiscus',
  'Habu',
  'Finch',
  'Sirtalis',
];


my $true_orths = {};

for (my $i = 0 ; $i < scalar(@$organisms) - 1; $i++){
  my $org1 = $organisms->[$i];
  my $f1 = $org1 . '.json';
  my $sp1 = get_json($js, $f1);
  for (my $j = $i + 1; $j < scalar(@$organisms); $j++){
    my $org2 = $organisms->[$j];
    my $f2 = $org2 . '.json';
    my $sp2 = get_json($js, $f2);
    warn("Comparing $org1 and $org2\n");
    # Direct and reverse comparison
    foreach my $prot1 (keys %{$sp1->{$org1}{$org2}}){
      my $cand = get_best($sp1->{$org1}{$org2}{$prot1});
      if (exists($sp2->{$org2}{$org1}{$cand})){
        my $revcand = get_best($sp2->{$org2}{$org1}{$cand});
        if ($prot1 eq $revcand){
          $true_orths->{'prots'}{$org1}{$prot1}{$org2} = $cand;
          $true_orths->{'prots'}{$org2}{$cand}{$org1} = $prot1;
        }
      }
      else{
        warn("$cand not found\n");
      }
    }
  }
}

open (OUT, ">paired.json\n");
print OUT $js->encode($true_orths);
close OUT;

sub get_best{
  my $h = shift;
  my @sorted = sort {
    ($h->{$a}->{'eVal'}
    <=>
    $h->{$b}->{'eVal'})
    ||
    ($h->{$b}->{'bitScore'}
    <=>
    $h->{$a}->{'bitScore'})
  } keys %$h;
  my $result = shift @sorted;
  return $result;
}


sub get_json{
  my $j = shift;
  my $fname = shift;
  my $result = $j->decode(slurp($fname));
  return $result;
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