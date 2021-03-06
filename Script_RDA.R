###################################################################################################
#### RDA-based genome scan method & application on simulations and Populus trichocarpa dataset ####
####                                               --                                          ####
####                Author : Thibaut Capblancq (thibaut.capblancq@gmail.com)                   ####
###################################################################################################

library(vegan)
library(robust)
library(qvalue)
library(ade4)
library(ggplot2)
library(ggpubr)
library(cowplot)
library(adegenet)
library(LEA)
library(pcadapt)
library(raster)
library(RColorBrewer)
library(splitstackshape)
library(sp)
library(gstat)
library(FactoMineR)
library(factoextra)

###########################################
#### Function of RDA-based genome scan ####

rdadapt<-function(rda,K)
{
  loadings<-rda$CCA$v[,1:as.numeric(K)]
  resscale <- apply(loadings, 2, scale)
  resmaha <- covRob(resscale, distance = TRUE, na.action= na.omit, estim="pairwiseGK")$dist
  lambda <- median(resmaha)/qchisq(0.5,df=K)
  reschi2test <- pchisq(resmaha/lambda,K,lower.tail=FALSE)
  qval <- qvalue(reschi2test)
  q.values_rdadapt<-qval$qvalues
  return(data.frame(p.values=reschi2test, q.values=q.values_rdadapt))
}

##############
#### Data ####

# Genet
geno<-t(read.table("./sim1/geno.pcadapt"))

geno<-read.csv("./sim1/sim1.csv")[,-c(1:14)]
sp <- apply(geno, 2, mean) 
geno <-  geno[ , sp > 0.05 & sp < 1.95]

# Env
env<-read.csv("./sim1/sim1.csv")
env<-as.data.frame(apply(env, 2, scale))


#############################
#### RDA on simulation 1 ####

RDA_tot <- rda(geno ~ env$envir1 + env$envir2 + env$envir3 + env$envir4 + env$envir5 + env$envir6 + env$envir7 + env$envir8 + env$envir9 + env$envir10,  env)
res_rdadapt<-rdadapt(RDA_tot, 4)

## Plot of SNPs and variables in the RDA space
coord_snps <- RDA_tot$CCA$v[, 1:5]
coord_env <- RDA_tot$CCA$biplot[, 1:5]
row.names(coord_env) <- colnames(env[,2:11])

Loci<-rep("Neutral", 1000)
Loci[c(1,11,21,31,41,51,61,71,81,91)]<-"QTL1"
Loci[c(101,111,121,131,141,151,161,171,181,191)]<-"QTL2"
Loci[c(201,211,221,231,241,251,261,271,281,291)]<-"QTL3"
Selected_Loci<-Loci[-which(Loci=="Neutral")]

p1 <- ggplot() +
  geom_point(aes(x=coord_snps[-which(Loci!="Neutral"),1], y=coord_snps[-which(Loci!="Neutral"),2]), col = "gray86") +
  geom_point(aes(x=coord_snps[which(Loci!="Neutral"),1], y=coord_snps[which(Loci!="Neutral"),2], colour = Selected_Loci), size = 2.5) +
  geom_segment(aes(xend=coord_env[,1]/10, yend=coord_env[,2]/10, x=0, y=0), colour="black", size=0.5, linetype=1, arrow=arrow(length = unit(0.02, "npc"))) +
  geom_text(aes(x=1.2*coord_env[,1]/10, y=1.2*coord_env[,2]/10, label = row.names(coord_env)), size=3) +
  xlab("RDA 1") + ylab("RDA 2") +
  theme_bw() +
  theme(legend.position="none")

p2 <- ggplot() +
  geom_point(aes(x=coord_snps[-which(Loci!="Neutral"),1], y=coord_snps[-which(Loci!="Neutral"),3]), col = "gray86") +
  geom_point(aes(x=coord_snps[which(Loci!="Neutral"),1], y=coord_snps[which(Loci!="Neutral"),3], colour = Selected_Loci), size = 2.5) +
  geom_segment(aes(xend=coord_env[,1]/10, yend=coord_env[,3]/10, x=0, y=0), colour="black", size=0.5, linetype=1, arrow=arrow(length = unit(0.02, "npc"))) +
  geom_text(aes(x=1.2*coord_env[,1]/10, y=1.2*coord_env[,3]/10, label = row.names(coord_env)), size=3) +
  xlab("RDA 1") + ylab("RDA 3") +
  theme_bw() +
  theme(legend.position="none")

p3 <- ggplot() +
  geom_point(aes(x=coord_snps[-which(Loci!="Neutral"),1], y=coord_snps[-which(Loci!="Neutral"),4]), col = "gray86") +
  geom_point(aes(x=coord_snps[which(Loci!="Neutral"),1], y=coord_snps[which(Loci!="Neutral"),4], colour = Selected_Loci), size = 2.5) +
  geom_segment(aes(xend=coord_env[,1]/10, yend=coord_env[,4]/10, x=0, y=0), colour="black", size=0.5, linetype=1, arrow=arrow(length = unit(0.02, "npc"))) +
  geom_text(aes(x=1.2*coord_env[,1]/10, y=1.2*coord_env[,4]/10, label = row.names(coord_env)), size=3) +
  xlab("RDA 1") + ylab("RDA 4") +
  theme_bw()

plot_grid(p1, p2, p3, labels = "AUTO", align = "h", rel_widths = c(.6, .6, 1), ncol=3)


## Manhattan plot
ggplot() +
  geom_point(aes(x=which(Loci=="Neutral"), y=-log10(res_rdadapt[-which(Loci!="Neutral"),1])), col = "gray83") +
  geom_point(aes(x=which(Loci!="Neutral"), y=-log10(res_rdadapt[-which(Loci=="Neutral"),1]), colour = Selected_Loci)) +
  xlab("SNPs") + ylab("RDADAPT with condition)") +
  theme_bw()


#################################
#### PCADAPT on simulation 1 ####

setwd("./sim1/")
data<-read.pcadapt("geno.pcadapt", type = "pcadapt")

pcadapt <- pcadapt(data, K=10, method="mahalanobis", data.type="genotype", min.maf = 0.05, ploidy = 2, output.filename = "pcadaptSimu_output", clean.files = TRUE, cover.matrix = NULL)


##########################################
#### Comparison PCADAPT - RDA on sim1 ####

## Screeplots
p1 <- ggplot() +
  geom_line(aes(x=c(1:10), y=as.vector(pcadapt$singular.values)), linetype="dotted", size = 1.5, colour="black") +
  geom_point(aes(x=c(1:10), y=as.vector(pcadapt$singular.values)), size = 4, colour="black", shape=17) +
  scale_x_discrete(name = "Ordination axes", limits=c(1:10)) +
  ylab("Inertia") +
  ggtitle("PCA") +
  theme_bw()
p2 <- ggplot() +
  geom_line(aes(x=c(1:10), y=as.vector(RDA_tot$CCA$eig)), linetype="dotted", size = 1.5, colour="grey") +
  geom_point(aes(x=c(1:10), y=as.vector(RDA_tot$CCA$eig)), size = 4, colour="grey", shape=19) +
  scale_x_discrete(name = "Ordination axes", limits=c(1:10)) +
  ylab("Inertia") +
  ggtitle(label = "RDA") +
  theme_bw()
ggarrange(p1, p2, ncol=2, nrow = 1)

## Manhattan plot PCA & RDA with 4 axes
pcadapt <- pcadapt(data, K=4, method="mahalanobis", data.type="genotype", min.maf = 0.05, ploidy = 2, output.filename = "pcadaptSimu_output", clean.files = TRUE, cover.matrix = NULL)

Loci<-rep("Neutral", 1000)
Loci[c(1,11,21,31,41,51,61,71,81,91)]<-"QTL1"
Loci[c(101,111,121,131,141,151,161,171,181,191)]<-"QTL2"
Loci[c(201,211,221,231,241,251,261,271,281,291)]<-"QTL3"
p.values<-data.frame(index = c(1:1000), pcadapt = -log10(pcadapt$pvalues), rdadapt = -log10(res_rdadapt[,1]), Loci=Loci)
Selected_Loci<-p.values$Loci[-which(p.values$Loci=="Neutral")]

p1 <- ggplot() +
  geom_point(aes(x=p.values$index[-which(p.values$Loci!="Neutral")], y=p.values$pcadapt[-which(p.values$Loci!="Neutral")]), col = "gray83") +
  geom_point(aes(x=as.vector(p.values$index[-which(p.values$Loci=="Neutral")]), y=as.vector(p.values$pcadapt[-which(p.values$Loci=="Neutral")]), colour = Selected_Loci)) +
  xlab("SNP (with maf > 0.05)") + ylab("PCADAT -log10(p-values)") +
  ylim(0,12.5) +
  theme_bw()
p2 <- ggplot() +
  geom_point(aes(x=p.values$index[-which(p.values$Loci!="Neutral")], y=p.values$rdadapt[-which(p.values$Loci!="Neutral")]), col = "gray83") +
  geom_point(aes(x=as.vector(p.values$index[-which(p.values$Loci=="Neutral")]), y=as.vector(p.values$rdadapt[-which(p.values$Loci=="Neutral")]), colour = Selected_Loci)) +
  xlab("SNP (with maf > 0.05)") + ylab("RDADAT -log10(p-values)") +
  ylim(0,12.5) +
  theme_bw()

ggarrange(p1, p2, labels = c("A", "B"), ncol=2, common.legend = TRUE, legend="right")


####################################################
#### Comparison PCA & RDA axes~env correlations ####

# Correlation env ~ PC or env ~ RDA
r2_PCA<-NULL
r2_RDA<-NULL
for (i in 2:11)
{
  r2_PCA<-c(r2_PCA,summary(lm(env[,i] ~ pcadapt$scores[,1:4]))$r.squared)
  r2_RDA<-c(r2_RDA,summary(lm(env[,i] ~ RDA_tot$CCA$u[,1:4]))$r.squared)
}

prop_axes<-data.frame(env=factor(colnames(env[,2:11]), levels=colnames(env[,2:11])), variance_expl = c(r2_PCA, r2_RDA), Method = c(rep("PCA",10), rep("RDA",10)))

ggplot(prop_axes, aes(y=variance_expl, x=env, fill=Method)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.8) +
  scale_fill_manual(values=c('black','lightgray')) +
  ylab("Variance explained") +
  xlab("") +
  theme(axis.text.x=element_text(size=10, angle = 60, hjust=1), axis.text.y=element_text(size=7), axis.title.y = element_text(size=9), legend.text = element_text(size=7), legend.title = element_text(size=10))


var_PCA<-matrix(nrow = 10, ncol = 4)
var_RDA<-matrix(nrow = 10, ncol = 4)
for (i in 1:10)
{for (j in 1:4)
{
  var_PCA[i,j]<-summary(lm(env[,i+1] ~ pcadapt$scores[,j]))$r.squared
  var_RDA[i,j]<-summary(lm(env[,i+1] ~ RDA_tot$CCA$u[,j]))$r.squared
}
}

grid <- NULL
grid <- expand.grid(x=1:10, y=1:4)
grid$z <- as.vector(var_PCA)
p1 <- ggplot(grid, aes(x, y)) + 
  geom_raster(aes(fill=z)) +
  scale_y_continuous(breaks=c(1:4), labels=c("PC1", "PC2", "PC3", "PC4"), expand = c(0,0)) + 
  scale_x_continuous(breaks=c(1:10), labels=c("env1", "env2", "env3", "env4", "env5", "env6", "env7","env8", "env9", "env10"), expand = c(0,0)) +
  xlab("") + ylab("") +
  scale_fill_gradient(low = "yellow", high = "red", limits = c(0,1)) +
  theme(axis.text.x=element_text(size=10, angle = 60, hjust=1), axis.line = element_blank(), panel.border = element_rect(fill=NA, colour = "black", size=1, linetype="solid"), plot.title = element_text(size=10)) +
  guides(fill=guide_legend(title="Correlation scores")) +
  ggtitle("PCA")

grid <- NULL
grid <- expand.grid(x=1:10, y=1:4)
grid$z <- as.vector(var_RDA)
p2 <- ggplot(grid, aes(x, y)) + 
  geom_raster(aes(fill=z)) +
  scale_y_continuous(breaks=c(1:4), labels=c("RDA1", "RDA2", "RDA3", "RDA4"), expand = c(0,0)) + 
  scale_x_continuous(breaks=c(1:10), labels=c("env1", "env2", "env3", "env4", "env5", "env6", "env7","env8", "env9", "env10"), expand = c(0,0)) +
  xlab("") + ylab("") +
  scale_fill_gradient(low = "yellow", high = "red", limits = c(0,1)) +
  theme(axis.text.x=element_text(size=10, angle = 60, hjust=1), axis.line = element_blank(), panel.border = element_rect(fill=NA, colour = "black", size=1, linetype="solid"), plot.title = element_text(size=10)) +
  guides(fill=guide_legend(title="Correlation scores")) +
  ggtitle("RDA")

ggarrange(p1, p2, ncol=2, legend = "right", common.legend = T)


###########################################################
#### Comparison PCADAPT & RDA over the 100 simulations ####

#RDA
fich_simu<-list.files(recursive = T, path="./", pattern="geno.pcadapt", full.names = TRUE)
genos<-lapply(fich_simu, function(x) t(read.table(x)))
env<-read.csv("./sim1/sim1.csv")#[,1:10]

RDA_res <- lapply(genos, function(x) {rda(x ~ env$envir1 + env$envir2 + env$envir3 + env$envir4 + env$envir5 + env$envir6 + env$envir7 + env$envir8 + env$envir9 + env$envir10,  env)})
q.values_rdadapt_simus <- lapply(RDA_res, function(x) {rdadapt(x, 5)[,2]})

# PCADAPT
genos_pcadapt<-lapply(fich_simu, function(x) read.pcadapt(x, type = "pcadapt"))
pcadapt <- lapply(genos_pcadapt, function(x) pcadapt(x, K=10, method="mahalanobis", data.type="genotype", min.maf = 0.05, ploidy = 2, output.filename = "pcadaptSimu_output", clean.files = TRUE, cover.matrix = NULL))
q.values_pcadapt_simus <- lapply(pcadapt, function(x) qvalue(x$pvalues)$qvalues)

## Power = number of true positive found by the analysis for each QTL
Loci<-rep("Neutral", 1000)
Loci[c(1,11,21,31,41,51,61,71,81,91)]<-"QTL1"
Loci[c(101,111,121,131,141,151,161,171,181,191)]<-"QTL2"
Loci[c(201,211,221,231,241,251,261,271,281,291)]<-"QTL3"

Tpos_pcadapt_QTL1<-unlist(lapply(q.values_pcadapt_simus, function(x) length(which(x < 0.1 & Loci=="QTL1"))))
Tpos_pcadapt_QTL2<-unlist(lapply(q.values_pcadapt_simus, function(x) length(which(x < 0.1 & Loci=="QTL2"))))
Tpos_pcadapt_QTL3<-unlist(lapply(q.values_pcadapt_simus, function(x) length(which(x < 0.1 & Loci=="QTL3"))))

Tpos_rdadapt_QTL1<-unlist(lapply(q.values_rdadapt_simus, function(x) length(which(x < 0.1 & Loci=="QTL1"))))
Tpos_rdadapt_QTL2<-unlist(lapply(q.values_rdadapt_simus, function(x) length(which(x < 0.1 & Loci=="QTL2"))))
Tpos_rdadapt_QTL3<-unlist(lapply(q.values_rdadapt_simus, function(x) length(which(x < 0.1 & Loci=="QTL3"))))

## False discovery rate 
Fpos_pcadapt<-unlist(lapply(q.values_pcadapt_simus, function(x) length(which(x < 0.1 & Loci=="Neutral"))))
Fpos_rdadapt<-unlist(lapply(q.values_rdadapt_simus, function(x) length(which(x < 0.1 & Loci=="Neutral"))))

## Visualisation
Tpos<-data.frame(Tpos=c(Tpos_pcadapt_QTL1/10, Tpos_pcadapt_QTL2/10, Tpos_pcadapt_QTL3/10, Tpos_rdadapt_QTL1/10, Tpos_rdadapt_QTL2/10, Tpos_rdadapt_QTL3/10), Method=c(rep("PCA", 300), rep("RDA", 300)), Loci=c(rep("QTL1", 100), rep("QTL2", 100), rep("QTL3", 100), rep("QTL1", 100), rep("QTL2", 100), rep("QTL3", 100)))
Tpos_meansd<-cbind(aggregate(Tpos$Tpos, by=list(Tpos$Method,Tpos$Loci), FUN = "mean"), sd=aggregate(Tpos$Tpos, by=list(Tpos$Method,Tpos$Loci), FUN = "sd")$x)
colnames(Tpos_meansd)[1:3]<-c("Method", "Loci", "Rate")

p1 <- ggplot(Tpos_meansd, aes(y=Rate, x=Loci, fill=Method)) +
  geom_bar(stat = "identity", position = "dodge") +
  geom_errorbar(aes(ymin=Rate-sd, ymax=Rate+sd), width=.1, position = position_dodge(.9)) +
  scale_fill_manual(values=c('black', 'lightgray')) +
  ylab("Percentage of True Positive") +
  guides(fill=FALSE) +
  xlab("") +
  theme_classic()

Fpos<-data.frame(Fpos=c(Fpos_pcadapt/100, Fpos_rdadapt/100), Method=c(rep("PCA", 100), rep("RDA", 100)))
Fpos<- cbind(aggregate(Fpos$Fpos, by=list(Fpos$Method), FUN = "mean"), sd=aggregate(Fpos$Fpos, by=list(Fpos$Method), FUN = "sd")$x)
colnames(Fpos)[1:2]<-c("Method", "Rate")

p2 <- ggplot(Fpos, aes(y=Rate, x=1, fill=Method)) +
  geom_bar(stat = "identity", position = "dodge") +
  geom_errorbar(aes(ymin=Rate-sd, ymax=Rate+sd), width=.1, position = position_dodge(.9)) +
  scale_fill_manual(values=c('black', 'lightgray')) +
  ylab("False Discovery Rate") +
  ylim(0,0.1) +  
  theme_classic() +
  theme(axis.title.x=element_blank(), axis.text.x=element_blank(), axis.ticks.x=element_blank())

plot_grid(p1, p2, labels = "AUTO", align = "h", rel_widths = c(1, .7))


##############################
#### Real dataset Populus ####

## Data
data<-read.table("./TableInput_Populustrichocarpa")
data[,6:26]<-apply(data[,6:26], 2, scale)
geno<-data[,27:ncol(data)]

## Filter on MAF and standardisation of genotypes
frequences <- colSums(geno) / (2*nrow(geno))
MAF <- 0.05
maf <- which(frequences > MAF & frequences < (1 - MAF))
geno <- geno[,maf]

################################
#### RDA on Populus dataset ####

RDA_Pop_tri <- rda(geno ~ data$MAT + data$MWMT + data$MCMT + data$TD + data$MAP + data$MSP + data$AHM + data$SHM + data$DD_0 + data$DD5 + data$DD_18 + data$DD18 + data$NFFD + data$bFFP + data$eFFP + data$FFP + data$PAS + data$EMT + data$EXT + data$Eref + data$CMD,  data)
plot(RDA_Pop_tri$CCA$eig)
res_rdadapt<-rdadapt(RDA_Pop_tri, 3)

ggplot() +
  geom_point(aes(x=c(1:length(res_rdadapt[,2])), y=-log10(res_rdadapt[,2])), col="gray83") +
  geom_point(aes(x=c(1:length(res_rdadapt[,2]))[which(res_rdadapt[,2] < 0.1)], y=-log10(res_rdadapt[which(res_rdadapt[,2] < 0.1),2])), col="orange") +
  xlab("SNPs") + ylab("-log10(q.values") +
  theme_bw()

## Outlier loci
locilist.names <- unlist(lapply(strsplit(colnames(geno), ".", fixed = TRUE), function(x) x[1]))
outliers_rdadapt <- locilist.names[which(res_rdadapt[,2] < 0.1)]

## Adaptative enriched space
outliers <- colnames(geno)[which(res_rdadapt[,2] < 0.1)]
geno_enrich<-geno[,outliers]
RDA_Pop_tri_enrich <- rda(geno_enrich ~ data$MAT + data$MWMT + data$MCMT + data$TD + data$MAP + data$MSP + data$AHM + data$SHM + data$DD_0 + data$DD5 + data$DD_18 + data$DD18 + data$NFFD + data$bFFP + data$eFFP + data$FFP + data$PAS + data$EMT + data$EXT + data$Eref + data$CMD,  data)

p0 <- ggplot() +
  geom_point(aes(x=RDA_Pop_tri_enrich$CCA$v[,1]*2, y=RDA_Pop_tri_enrich$CCA$v[,2]*2), col="orange") +
  geom_segment(aes(xend=RDA_Pop_tri_enrich$CCA$biplot[,1]/2, yend=RDA_Pop_tri_enrich$CCA$biplot[,2]/2, x=0, y=0), colour="black", size=0.2, linetype=1, arrow=arrow(length = unit(0.02, "npc"))) +
  geom_text(aes(x=1.1*RDA_Pop_tri_enrich$CCA$biplot[,1]/2, y=1.2*RDA_Pop_tri_enrich$CCA$biplot[,2]/2, label = colnames(data[,6:26])), size=3) +
  xlab("RDA 1") + ylab("RDA 2") +
  xlim(-0.55, 0.5) +
  theme_bw()

## Spatialisation of the RDA results along the Northern America
fond<-rasterToPoints(crop(raster("./NorthAmerica.img"), extent(c(-170,-119,40,62))))
pop<-factor(unlist(lapply(strsplit(row.names(data), ".", fixed=T), function(x) x[1])))
env_pop<-as.data.frame(apply(data[,3:27], 2, function(x) by(as.vector(x),pop, mean)))

table<-data.frame(Longitude=env_pop$Longitude, Latitude=env_pop$Latitude, apply(RDA_Pop_tri_enrich$CCA$u, 2, function(x) by(as.vector(x),pop, mean)))

p1 <- ggplot() + 
  geom_raster(aes(x=fond[,1],y=fond[,2],fill=as.factor(fond[,3]))) + 
  scale_fill_manual(values="#FFEDA0") +
  geom_point(data=table, aes(x= table$Longitude, y=table$Latitude, colour = RDA1), size=3) + 
  scale_color_gradient(low="black", high = "white") +
  geom_point(aes(x= c(-122.33, -122.667, -149.886), y=c(47.60, 45.525, 61.2120)), size=1) +
  geom_text(aes(x= c(-130.33, -130.667, -157.886), y=c(47.60, 45.525, 61.2120), label=c("Vancouver", "Portland", "Anchorage")), size=3.5) +
  xlab("Longitude") + ylab("Latitude") +
  theme_bw() +
  theme(panel.grid.major = element_blank())

p2 <- ggplot() + 
  geom_raster(aes(x=fond[,1],y=fond[,2],fill=as.factor(fond[,3]))) + 
  scale_fill_manual(values="#FFEDA0") +
  geom_point(data=table, aes(x= table$Longitude, y=table$Latitude, colour = RDA2), size=3) + 
  scale_color_gradient(low="black", high = "white") +
  geom_point(aes(x= c(-122.33, -122.667, -149.886), y=c(47.60, 45.525, 61.2120)), size=1) +
  geom_text(aes(x= c(-130.33, -130.667, -157.886), y=c(47.60, 45.525, 61.2120), label=c("Vancouver", "Portland", "Anchorage")), size=3.5) +
  xlab("Longitude") + ylab("Latitude") +
  theme_bw() +
  theme(panel.grid.major = element_blank())

ggarrange(p0, p1, p2, ncol=3, widths = c(1,1,1), labels = c("A", "B", "C"), common.legend = T, legend= "right")

