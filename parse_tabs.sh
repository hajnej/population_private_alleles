#!/usr/bin/env bash

# This script is intended to detect private alleles of ancestral species/populations in derived (e.g. hybrid) individuals. It is designed for RADseq. data and analysis in Stacks.
# To use the script, you have to run Populations of Stacks twice. First, use only the putative ancestors assigned into species/populations; populations.sumstats.tsv will be the first table used by the script. This file can also be used for creating whitelist for the second run of Populations (this leads to significantly shorter table 2). Run this command to generate the whitelist: cat populations.sumstats.tsv | grep -v "#" | awk '$21 == 1 { print }' | cut -f 1,4 | uniq > whitelist.tsv
# The second run of Populations is performed with the same cataloque and only the samples of interest (derived individuals), each assigned to its own population. populations.sumstats.tsv from this run is table 2.

# Adjust the table names here:

tab1=populations.sumstats1.tsv
tab2=populations.sumstats2.tsv


# Column 21 in TSV file is equal to 1 if allele is private
filter_private_alleles() {
  grep -v '#' "${tab1}" | awk '$21 == 1 { print }'
}

# Since the private allele seems always to be the alternative one, only Qnuc is considered; only if Qnuc is "-", Pnuc is used: copy column 6 to column 7 if column 7 is equal to '-', then merge column 1,4,7 to create a unique ID of each allele.

# Sample input
#4       HiC_scaffold_163_RagTag 9354    18      can     A       C       2       0.50000000      0.00000 1.00000 0.50000 0.50000 0.66667 0.00000 0.00000 1.00000 0.00000 0.00000 0.00000 0
#4       HiC_scaffold_163_RagTag 9355    19      can     G       T       2       0.50000000      0.00000 1.00000 0.50000 0.50000 0.66667 0.00000 0.00000 1.00000 0.00000 0.00000 0.00000 1
#4       HiC_scaffold_163_RagTag 9355    19      mos     G       -       1       1.00000000      0.00000 1.00000 0.00000 1.00000 0.00000 0.00000 0.00000 0.00000 0.00000 0.00000 0.00000 0
#4       HiC_scaffold_163_RagTag 9365    29      can     T       C       2       0.50000000      0.00000 1.00000 0.50000 0.50000 0.66667 0.00000 0.00000 1.00000 0.00000 0.00000 0.00000 1
# Sample output
#4_19_T  can
#4_29_C  can

prepare_table_1() {
  filter_private_alleles | awk '{ printf "%s_%s_%s\t%s\n", $1, $4, ( $7 == "-" ) ? $6 : $7, $5 }'
}

# Prepare prep_tab2.tsv: ID of each allele is formed by merging col. 1+4+6 or 1+4+7.
# Sample input
#7       HiC_scaffold_163_RagTag 10757   9       apo_R236-14     A       G       1       0.50000000      1.00000 0.00000 0.50000 0.50000 1.00000 0.00000 0.00000 0.00000 0.00000 0.00000 0.00000 0
#7       HiC_scaffold_163_RagTag 10757   9       apo_R394-18     A       G       1       0.50000000      1.00000 0.00000 0.50000 0.50000 1.00000 0.00000 0.00000 0.00000 0.00000 0.00000 0.00000 0
#7       HiC_scaffold_163_RagTag 10757   9       apo_R5-21       -       G       1       0.00000000      0.00000 1.00000 0.00000 1.00000 0.00000 0.00000 0.00000 0.00000 0.00000 0.00000 0.00000 0
#7       HiC_scaffold_163_RagTag 10757   9       apo_R74-19      A       -       1       1.00000000      0.00000 1.00000 0.00000 1.00000 0.00000 0.00000 0.00000 0.00000 0.00000 0.00000 0.00000 0
# Sample output
#7_9_A   apo_R236-14
#7_9_G   apo_R236-14
#7_9_A   apo_R394-18
#7_9_G   apo_R394-18

prepare_table_2() {
  grep -v '#' "${tab2}" | awk '{ printf "%s_%s_%s\t%s\n%s_%s_%s\t%s\n", $1, $4, $6, $5, $1, $4, $7, $5 }' | sort
}

prepare_table_1 > prep_tab1.tsv
prepare_table_2 > prep_tab2.tsv

# Read samples from prep_tab2 and search for its matching private allel in prep_tab1.tsv, add its population if found to last column
while read allel sample; do
  #echo "Checking for $private_allele..."
  #awk --assign=private_allel=$private_allel --assign=population=$population '{ if ($1==private_allel) { printf "%s\t%s\n", $0, population } }' prep_tab2.tsv
  printf "%s\t%s\t%s\n" "$allel" "$sample" $(grep "^$allel" prep_tab1.tsv | cut -f2)
done < prep_tab2.tsv | sort -k2 > result_tab2.tsv

# Prepare matrix where columns are populations and rows are samples
samples=$(cut -f2 result_tab2.tsv | uniq | grep -v '^$')
populations=$(cut -f3 result_tab2.tsv | sort | uniq)

# Print matrix header
final_table() {
printf "# Pop ID"
for j in $populations; do
  printf "\t%s" "$j"
done
printf "\n"
for i in $samples; do
  printf "%s" "$i"
  for j in $populations; do
   printf "\t%s" $(grep -w "$i" result_tab2.tsv | grep -wc "$j")
  done
  printf "\n"
done
}
final_table > results.tsv


# Remove intermediate files
rm prep_tab1.tsv
rm prep_tab2.tsv
rm result_tab2.tsv

