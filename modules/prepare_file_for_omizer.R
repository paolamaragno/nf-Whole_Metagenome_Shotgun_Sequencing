#!/usr/bin/env Rscript

suppressMessages(library("readr"))

### load input variables ###
args = commandArgs(trailingOnly=TRUE)

gene_fam_table <- data.frame(read_tsv(args[1]))
rownames(gene_fam_table) <- gene_fam_table[,1]
gene_fam_table[,1] <- NULL

colnames(gene_fam_table) <- gsub('X','',colnames(gene_fam_table))
colnames(gene_fam_table) <- gsub('_S.*', '',colnames(gene_fam_table))

gene_families <- rownames(gene_fam_table)

gene_fami_filt <- gene_families[!grepl("\\|", gene_families)] # Exclude gene families stratified by species
gene_fami_filt <- gene_fami_filt[!grepl("UNMAPPED", gene_fami_filt)] # Exclude "UNMAPPED"
gene_fami_filt <- gene_fami_filt[!grepl("UNGROUPED", gene_fami_filt)] # Exclude "UNINTEGRATED"

gene_fam_table <- gene_fam_table[gene_fami_filt,]

write.table(gene_fam_table, file='./all_genefamilies_KO_for_omixer.tsv', quote=F, col.names =TRUE, row.names = TRUE, sep = '\t')

