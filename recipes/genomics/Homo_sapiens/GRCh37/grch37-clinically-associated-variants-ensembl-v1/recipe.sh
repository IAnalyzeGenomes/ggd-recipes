#!/bin/sh
set -eo pipefail -o nounset

## Get the .genome  file
genome=https://raw.githubusercontent.com/gogetdata/ggd-recipes/master/genomes/Homo_sapiens/GRCh37/GRCh37.genome

## Get ref genome
ref_genome=$(ggd get-files grch38-reference-genome-ensembl-v1 --pattern "*.fa" )
fai_file=$(ggd get-files grch38-reference-genome-ensembl-v1 --pattern "*.fai" )

## Get chain file:
wget --quiet ftp://ftp.ensembl.org/pub/assembly_mapping/homo_sapiens/GRCh38_to_GRCh37.chain.gz
zgrep -v "PATCH" GRCh38_to_GRCh37.chain.gz > GRCh38_to_GRCh37.chain

## Get the clinically associated variant file,
wget --quiet ftp://ftp.ensembl.org/pub/release-99/variation/vcf/homo_sapiens/homo_sapiens_clinically_associated.vcf.gz 

## Add contig header
## Decompose 
## Normalize
bcftools reheader --fai $fai_file homo_sapiens_clinically_associated.vcf.gz \
    | gzip -dc \
    | vt decompose -s - \
    | vt normalize -r $ref_genome -n - -o grch38-decomposed-normalized-clinically-associated.vcf 

rm homo_sapiens_clinically_associated.vcf.gz

## Get the reference genome 
ref_genome=$(ggd get-files grch37-reference-genome-ensembl-v1 --pattern "*.fa")

## VCF Liftover 
CrossMap.py vcf GRCh38_to_GRCh37.chain grch38-decomposed-normalized-clinically-associated.vcf $ref_genome liftover_grch37_clinically_associated.vcf

## Sort, bgzip, and tabix the lifted over vcf file
gsort liftover_grch37_clinically_associated.vcf $genome \
    | bgzip -c > grch37-clinically-associated-variants-ensembl-v1.vcf.gz

tabix grch37-clinically-associated-variants-ensembl-v1.vcf.gz

## Remove temp files
rm GRCh38_to_GRCh37.chain.gz 
rm GRCh38_to_GRCh37.chain
rm liftover_grch37_clinically_associated.vcf
rm liftover_grch37_clinically_associated.vcf.unmap
rm grch38-decomposed-normalized-clinically-associated.vcf


