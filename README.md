# LG


This repository provides the scripts and data used to produce multiple alignments that later served for analysis of positive selection and copy number variation.

## Data

You can find 18 `.fa` files with the protein databases used. The key is:
```
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
```
Here, `George` refers to *Chelonoidis abindgonii*. The index files for BLAST2 comparisons are also provided. 

## Run blasts

First, a small script produces `.sh` files to automate the `blastp` runs between every pair of `fa` files:

```
perl make_basts.pl [n=8]
```
This will create `n` files with the commands to run every `blastp` comparison (8 by default). Depending on the processing resources, they all may be run at the same time. An example of those commands is:

```
blastall -p blastp -e 1e-10 -m 8 -d Canis_familiaris.CanFam3.1.pep.all.fa -i Ficedula_albicollis.FicAlb_1.4.pep.all.fa | gzip >results/Ficedula_albicollis.FicAlb_1.4.pep.all.fa__Canis_familiaris.CanFam3.1.pep.all.fa.blast.gz
(>&2 echo "Finished comparing Ficedula_albicollis.FicAlb_1.4.pep.all.fa with Canis_familiaris.CanFam3.1.pep.all.fa")
blastall -p blastp -e 1e-10 -m 8 -d mund.pep.all.fa -i Ficedula_albicollis.FicAlb_1.4.pep.all.fa | gzip >results/Ficedula_albicollis.FicAlb_1.4.pep.all.fa__mund.pep.all.fa.blast.gz
(>&2 echo "Finished comparing Ficedula_albicollis.FicAlb_1.4.pep.all.fa with mund.pep.all.fa")
```
The results will be gzipped and written into a subfolder called `results`. With these input files, 306 (17x18) files will be created.

## Read blasts

Second, create hit information tables in `json` format.

```
perl orth_groups.pl
```
This script will read the blast results and populate one table per organism with each protein and its best hits (as measured by the lowest `expect` values) in every other organism. It will output 18 `json` files (`Anolis.json`, `Chicken.json`, ...).

## Create orthology groups
### Multiple alignments
First, create the consolidated table, where each protein in each organism is related with one protein in every other organism if their direct and reciprocal hits are the best ones.
```
perl build_table.pl
```
The script will output that table in a file called `paired.json`.
Second, create the multiple alignments themselves. 
```
perl create_fastas.pl
```
This will read `paired.json` and the initial `fa` files to create the multifasta files. These files will be gzipped and tarred in a file called `aligs.tar.gz`. Multiple alignments can lack up to 3 species not including *C. abingdonii*. This behavior can be tweaked at line 97 of the script.
### *A priori* families
For copy-number variations, first get the lengths of each protein.
```
perl plen.pl
```
This will create one `json` file per organism with protein lengths (`{org}.length.json`).
Second, set high-quality alignments.
```
cd grouping
perl grouping.pl Human George
perl grouping.pl Human Pelodiscus
```
The parameters for the alignment are set at lines 5 and 6 of the script. They describe how much of the longest protein must be aligned and the minimum percentage of identities it must present to be accepted. This will create two `json` files: `good_alignments_Human_George.json` and `good_alignments_Human_Pelodiscus.json`.
Then, consolidate the results into families.
```
perl families.pl Human George
perl families.pl Human Pelodiscus
```
This will create two `json` files: `families_Human_George.json` and `families_Human_Pelodiscus.json`. Finally, you can filter those families with an *ad hoc* filter. 
```
perl filter_fams.pl Human George Pelodiscus
```
It only checks that the second species has more copies in the family than the first species, and then shows the family members of the third species alongside. Manual filtering is required afterwards. Also, the human symbols are not official.
