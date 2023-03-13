#!/usr/bin/env bash

# Sample invocation
#./parse_tabs.sh
## Pop ID        cae     can     mos     ulm
#apo_R236-14     10      19      46      30
#apo_R394-18     13      25      58      16
#apo_R5-21       25      27      37      58
#apo_R74-19      9       8       18      21
#apo_R92-19      29      28      30      44


tab1=tab1.tsv
tab2=tab2.tsv

# Column 21 in TSV file is equal to 1 if allel is private
filter_private_alleles() {
  grep -v '#' "${tab1}" | awk '$21 == 1 { print }'
}

# Copy column 6 to column 7 if column 7 is equal to '-', then merge column 1,4,7
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

# Prepare prep_tab2.tsv
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
  #echo "Checking for $private_allel..."
  #awk --assign=private_allel=$private_allel --assign=population=$population '{ if ($1==private_allel) { printf "%s\t%s\n", $0, population } }' prep_tab2.tsv
  printf "%s\t%s\t%s\n" "$allel" "$sample" $(grep "^$allel" prep_tab1.tsv | cut -f2)
done < prep_tab2.tsv | sort -k2 > result_tab2.tsv

# Prepare matrix where columns are populations and rows are samples
samples=$(cut -f2 result_tab2.tsv | uniq | grep -v '^$')
populations=$(cut -f3 result_tab2.tsv | sort | uniq)

# Print matrix header
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

