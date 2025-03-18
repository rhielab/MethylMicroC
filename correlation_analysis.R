library(data.table)
library(fuzzyjoin)
library(dplyr)
library(RColorBrewer)
library(ggplot2)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 7) {
  stop("usage: Rscript correlation_analysis.R methylation_data_1.bed methylation_data_2.bed min_CpG_read_count_dataset_1 min_CpG_read_count_dataset_2 dataset_1_label dataset_2_label output_file.png")
}

methylationData1 <- fread(args[1])
methylationData2 <- fread(args[2])
minCpGReadCountDataset1 <- as.integer(args[3])
minCpGReadCountDataset2 <- as.integer(args[4])
xLabel = args[5]
yLabel = args[6]
outputFilename = args[7]

colnames(methylationData1) <- c("Chromosome", "ChromStart", "ChromEnd", "Unused1", "Unused2", "Unused3", "Fraction", "Count")
colnames(methylationData2) <- colnames(methylationData1)
methylationData1n <- methylationData1[methylationData1$Count >= minCpGReadCountDataset1]
methylationData2n <- methylationData2[methylationData2$Count >= minCpGReadCountDataset2]

mergedData <- merge(x = methylationData1n, y = methylationData2n, by.x = c("Chromosome", "ChromStart"), by.y = c("Chromosome", "ChromStart"))

rf <- colorRampPalette(rev(brewer.pal(11,'Spectral')))
r <- rf(32)
shared <- nrow(mergedData)
c <- cor(mergedData$Fraction.x, mergedData$Fraction.y, use = "complete.obs")
sqc <- c^2

ff <- ggplot(mergedData, aes(Fraction.x, Fraction.y)) +
  geom_bin2d(bins=30, drop = FALSE) +
  scale_fill_gradientn(colors=r, trans="log10", na.value = "#5F50A2") +
  xlab(xLabel)+
  ylab(yLabel)+
  ggtitle("Heatmap Scatterplot of Methylation Fraction",
          subtitle = sprintf("Correlation Coef = %.3f R^2 = %.3f Shared CpG number = %d", c, sqc, shared))+
  theme(plot.title=element_text(size=15), plot.subtitle=element_text(size=9))

ggsave(filename = outputFilename, plot = ff)
