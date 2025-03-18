#!/bin/bash -e

if [ $# != 5 ]; then
	echo "usage: $0 input_bigwig.bw regions_of_interest.bed output_file_prefix distance_surrounding_regions number_of_CPU_cores_to_use" >&2
 	exit 1
fi

computeMatrix reference-point --referencePoint center -b $4 -a $4 -S "$1" -R "$2" -p $5 -o "$3.gz"
plotHeatmap -m "$3.gz" -o "$3.pdf" --legendLocation none --yMin 0 --yMax 100
