#!/bin/bash -e

if [ $# != 4 ]; then
	echo "usage: $0 output_folder input_bam output_filename_prefix <MMC or Micro-C>" >&2
 	exit 1
fi

mkdir -p "$1"
full_prefix="$1/$3"

## The sequences searched for below are, in order, the middle, left end, and right end of the bridge, and the full bridge.
## This increases the chance that reads containing only part of the bridge are found.

## Extract read 1 headers with and without bridge
if [ "$4" = "Micro-C" ]; then
	samtools view "$2" | awk 'NR % 2 == 1' | grep "CATCGATCGAT" > "$full_prefix".withbridge.sam
	samtools view "$2" | awk 'NR % 2 == 1' | grep "GATGGACGAACCT" >> "$full_prefix".withbridge.sam
	samtools view "$2" | awk 'NR % 2 == 1' | grep "AGGTTCGTCCATC" >> "$full_prefix".withbridge.sam
	samtools view "$2" | awk 'NR % 2 == 1' | grep "AGGTTCGTCCATCGATCGATGGACGAACCT" >> "$full_prefix".withbridge.sam
else
	samtools view "$2" | awk 'NR % 2 == 1' | grep "TATTGATTGAT" > "$full_prefix".withbridge.sam
	samtools view "$2" | awk 'NR % 2 == 1' | grep "GATGGATGAATTT" >> "$full_prefix".withbridge.sam
	samtools view "$2" | awk 'NR % 2 == 1' | grep "AGGTTTGTTTATT" >> "$full_prefix".withbridge.sam
	samtools view "$2" | awk 'NR % 2 == 1' | grep "AGGTTTGTTTATTGATTGATGGATGAATTT" >> "$full_prefix".withbridge.sam
fi
sort -u "$full_prefix".withbridge.sam | awk -F '\t' '{print $1}' | sed 's/\s.*$//' > "$full_prefix".withbridge.headers.txt
## It is not necessary to exclude the full bridge with grep -v since it will be excluded by the checks for the partial bridge
if [ "$4" = "Micro-C" ]; then
	samtools view "$2" | awk 'NR % 2 == 1' | grep -v "CATCGATCGAT" | grep -v "GATGGACGAACCT" | grep -v "AGGTTCGTCCATC" | awk -F '\t' '{print $1}' | sed 's/\s.*$//' > "$full_prefix".withoutbridge.headers.txt
else
	samtools view "$2" | awk 'NR % 2 == 1' | grep -v "TATTGATTGAT" | grep -v "GATGGATGAATTT" | grep -v "AGGTTTGTTTATT" | awk -F '\t' '{print $1}' | sed 's/\s.*$//' > "$full_prefix".withoutbridge.headers.txt
fi

## Extract read 2 headers with and without bridge
if [ "$4" = "Micro-C" ]; then
	samtools view "$2" | awk 'NR % 2 == 0' | grep "CATCGATCGAT" > "$full_prefix".withbridge.2.sam
	samtools view "$2" | awk 'NR % 2 == 0' | grep "GATGGACGAACCT" >> "$full_prefix".withbridge.2.sam
	samtools view "$2" | awk 'NR % 2 == 0' | grep "AGGTTCGTCCATC" >> "$full_prefix".withbridge.2.sam
	samtools view "$2" | awk 'NR % 2 == 0' | grep "AGGTTCGTCCATCGATCGATGGACGAACCT" >> "$full_prefix".withbridge.2.sam
else
	samtools view "$2" | awk 'NR % 2 == 0' | grep "ATCAATCAATA" > "$full_prefix".withbridge.2.sam
	samtools view "$2" | awk 'NR % 2 == 0' | grep "AAATTCATCCATC" >> "$full_prefix".withbridge.2.sam
	samtools view "$2" | awk 'NR % 2 == 0' | grep "AATAAACAAACCT" >> "$full_prefix".withbridge.2.sam
	samtools view "$2" | awk 'NR % 2 == 0' | grep "AAATTCATCCATCAATCAATAAACAAACCT" >> "$full_prefix".withbridge.2.sam
fi
sort -u "$full_prefix".withbridge.2.sam | awk -F '\t' '{print $1}' | sed 's/\s.*$//' >> "$full_prefix".withbridge.headers.txt
## It is not necessary to exclude the full bridge with grep -v since it will be excluded by the checks for the partial bridge
if [ "$4" = "Micro-C" ]; then
	samtools view "$2" | awk 'NR % 2 == 0' | grep -v "CATCGATCGAT" | grep -v "GATGGACGAACCT" | grep -v "AGGTTCGTCCATC" | awk -F '\t' '{print $1}' | sed 's/\s.*$//' >> "$full_prefix".withoutbridge.headers.txt
else
	samtools view "$2" | awk 'NR % 2 == 0' | grep -v "ATCAATCAATA" | grep -v "AAATTCATCCATC" | grep -v "AATAAACAAACCT" | awk -F '\t' '{print $1}' | sed 's/\s.*$//' >> "$full_prefix".withoutbridge.headers.txt
fi

## Find unique headers
cat "$full_prefix".withbridge.headers.txt | sort -u > "$full_prefix".withbridge.unique.headers.txt
cat "$full_prefix".withoutbridge.headers.txt | sort -u > "$full_prefix".withoutbridge.unique.headers.temp.txt

## Filter out with bridge reads in without bridge reads
grep -F -x -v -f "$full_prefix".withbridge.unique.headers.txt "$full_prefix".withoutbridge.unique.headers.temp.txt > "$full_prefix".withoutbridge.unique.headers.txt
wc -l "$full_prefix".withbridge.unique.headers.txt
wc -l "$full_prefix".withoutbridge.unique.headers.txt
samtools view "$2" | grep -Fwf "$full_prefix".withbridge.unique.headers.txt > "$full_prefix".withbridge.tmp.sam
wc -l "$full_prefix".withbridge.tmp.sam
samtools view "$2" | grep -Fwf "$full_prefix".withoutbridge.unique.headers.txt > "$full_prefix".withoutbridge.tmp.sam
wc -l "$full_prefix".withoutbridge.tmp.sam

## Make a file for the header and combine
samtools view -H "$2" > "$full_prefix".tmp.header.for.bam
cat "$full_prefix".tmp.header.for.bam "$full_prefix".withbridge.tmp.sam > "$full_prefix".withbridge.f.sam
samtools view -bS "$full_prefix".withbridge.f.sam > "$full_prefix".withbridge.bam
cat "$full_prefix".tmp.header.for.bam "$full_prefix".withoutbridge.tmp.sam > "$full_prefix".withoutbridge.f.sam
samtools view -bS "$full_prefix".withoutbridge.f.sam > "$full_prefix".withoutbridge.bam

rm "$full_prefix".withbridge.sam "$full_prefix".withbridge.2.sam "$full_prefix".withbridge.headers.txt "$full_prefix".withoutbridge.headers.txt "$full_prefix".withoutbridge.f.sam "$full_prefix".withoutbridge.tmp.sam "$full_prefix".withbridge.f.sam "$full_prefix".withbridge.tmp.sam "$full_prefix".withoutbridge.unique.headers.txt "$full_prefix".withbridge.unique.headers.txt  "$full_prefix".withoutbridge.unique.headers.temp.txt "$full_prefix".tmp.header.for.bam
