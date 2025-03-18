#!/bin/bash -e

if [ $# != 3 ]; then
	echo "usage: $0 number_of_reads input.bam output.bam" >&2
 	exit 1
fi

NUMBER=$1
INPUT_BAM="$2"

## Calculate the number of lines of data to retrieve (the number of reads times 2)
TOTAL_LEN=$(($1 * 2))

## Get the name of the output file without the extension
OUTPUT_NAME=$(basename "$3" .bam)

## Subset the BAM file and save it as a new SAM file (it was not working to pipe directly into samtools view -bS due to memory issues)
## -H gets only the header, which is output separately so as to not count its length in the number of lines to subset
(samtools view -H "$INPUT_BAM"; samtools view "$INPUT_BAM" | head -n $TOTAL_LEN) > "$OUTPUT_NAME.tmp.sam"

## Convert it to a BAM file
samtools view -bS -o "$OUTPUT_NAME.bam" "$OUTPUT_NAME.tmp.sam"

## The SAM file is no longer needed
rm "$OUTPUT_NAME.tmp.sam"
