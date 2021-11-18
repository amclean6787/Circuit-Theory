# #### Circuit Theory- Current Values ####
# Mount Packages

library(raster)
library(rgdal)
library(readr)
library(reader)
library(tidyverse)
library(ggrepel)

# Import City Buffers
Cities <- readOGR(dsn=path.expand("Data/Current_values/Input/"), layer="Cities_3km_Buffer")

# Set up city data frame
All_cv <- Cities@data 
All_cv <- cmcv[,c(2,4,5,6,13,14)]

All_cv$City_number <- 1:169

# ==== Get tmcv ====
tmcv <- data.frame(NA)
names(tmcv) <- "tmcv"
row.names(tmcv) <- "N_Middle_Jan"

for (Direction in 1:4) {
  for (Month in 1:12) {
    
    row.names(tmcv) <- c(paste(row.names(tmcv)), paste(Direction_list[Direction], Sailing_speed_reference, Month_list[Month], sep= "_"))
    
    CT_raster <- raster(paste0("Data/Current_values/Input/CT_rasters/output_", Direction_list[Direction], "/", Direction_list[Direction], "_", Sailing_speed_reference, "_", Month_list[Month],  ".tif"))
    
    tmcv[paste(Direction_list[Direction], Sailing_speed_reference, Month_list[Month], sep= "_"),"tmcv"] <- as.numeric(raster::cellStats(CT_raster, stat='mean', na.rm=TRUE))
    
  }
}

write_csv(tmcv, "Data/Current_values/Output/tmcv.csv")

# ==== Get mean current values for each city and every scenario 

for (Month in 1:12) {
  for (Direction in 1:4) {
    CT_raster <- raster(paste0("Data/Current_values/Input/CT_rasters/output_", Direction_list[Direction], "/", Direction_list[Direction], "_", Sailing_speed_reference, "_", Month_list[Month],  ".tif"))
    
    Current_data <- as.data.frame(raster::extract(CT_raster, Cities, fun=mean))
    names(Current_data) <- paste(Month_list[Month], Direction_list[Direction], "CT_mean", sep="_")
    
    Current_data$City_number <- 1:169
    
    All_cv <- merge(All_cv, Current_data)
    print(paste(Sys.time(), Month_list[Month], Direction_list[Direction], "Complete.", sep=" "))
    
  }
  
  print(paste(Sys.time(), Month_list[Month], "Complete.", sep=" "))
  
}

write_csv(All_cv, "Data/Current_values/Output/All_cv.csv")

# ---- Get cmcv values ----
cmcv <- colMeans(All_cv[,3:50]) %>%
  data.frame()

write_csv(cmcv, "Data/Current_values/Output/cmcv.csv")

# cmcv difference values
cmcv_diff <- cmcv-tmcv
names(cmcv_diff) <- "cmcv difference"

write_csv(cmcv_diff, "Data/Current_values/Output/cmcv_difference.csv")

# ---- Get imcv values ----
imcv <- data.frame(All_cv$Ancient.To)

imcv$imcv <- rowMeans(All_cv[,3:50])

names(imcv) <- c("Site", "imcv")

imcv %>%
  arrange(desc(imcv)) %>%
  write_csv("Data/Current_values/Output/imcv.csv")


# imcv difference values
imcv_diff <- imcv

imcv_diff$imcv <- imcv_diff$imcv-(mean(tmcv$tmcv))

imcv_diff <- All_cv[,2:50]
imcv_diff2[170,1] <- "tmcv"

for (Scenario in 1:48) {
  
  imcv_diff[170,Scenario+1] <- tmcv[Scenario,1]
}

imcv_diff_2 <- imcv_diff

for (Scenario in 1:48) {
  for (City in 1:169) {
    
    imcv_diff_2[City,Scenario+1] <- (imcv_diff[City,Scenario+1])-imcv_diff[170,Scenario+1]
    
  }
}

imcv_diff <- imcv_diff_2[1:169,]
imcv_diff$imcv_difference <- NA

# By sum
for (City in 1:169) {
  
  imcv_diff$imcv_difference[City] <- sum(imcv_diff[City,2:49])
  
}

imcv_diff <- imcv_diff[,c(1,50)]

imcv_diff %>%
  arrange(desc(imcv_difference)) %>%
  write_csv("Data/Current_values/Output/imcv_difference_sum.csv")

# By mean
for (City in 1:169) {
  
  imcv_diff$imcv_difference[City] <- mean(as.numeric(imcv_diff[City,2:49]))
  
}

imcv_diff <- imcv_diff[,c(1,50)]

imcv_diff %>%
  arrange(desc(imcv_difference)) %>%
  write_csv("Data/Current_values/Output/imcv_difference_mean.csv")

# ==== Plot results ====

urban <- read_csv("Data/Current_values/Input/Cities_detail.csv")
urban_known <- subset(urban, urban$Size_known=='Y')

urban <- merge(urban, imcv_diff, by= 'Ancient.To')

urban_known <- merge(urban_known, imcv_diff, by= 'Ancient.To')

png("Data/Current_values/Output/urban.png", width=10, height=6, units="in", res=150)
ggplot(urban_known, aes(x= imcv_difference, y= Population, col="indianred4")) + geom_vline(xintercept =c(mean(urban_known$imcv_difference)+sd(urban_known$imcv_difference), mean(urban_known$imcv_difference)-sd(urban_known$imcv_difference)), color=c('blue', 'red'), size=0.75) + geom_hline(yintercept = mean(urban_known$Population)+sd(urban_known$Population), size=1) + geom_point(size=2)  + geom_label_repel(label = urban_known$Label, fill="indianred2", col="white", na.rm=T, min.segment.length = 0, segment.colour="indianred2") + theme_bw() + theme(legend.position="none") + xlab("Difference Value") + ylab("Estimated Population")
dev.off()

# Get tables

hi_pop <- subset(urban_known, urban_known$Population>(mean(urban_known$Population)+sd(urban_known$Population)))
lo_pop <- subset(urban_known, urban_known$Population<(mean(urban_known$Population)+sd(urban_known$Population)))

hi_dif <- subset(urban_known, urban_known$imcv_difference>(mean(urban_known$imcv_difference)+sd(urban_known$imcv_difference)))
lo_dif <- subset(urban_known, urban_known$imcv_difference<(mean(urban_known$imcv_difference)-sd(urban_known$imcv_difference)))

hi_dif <- arrange(hi_dif, desc(imcv_difference))
names(hi_dif) <- c("Site", "Size Known", "Population", "Label", "Difference Value")

write_csv(hi_dif[,c(1,5,3)], 'Data/Current_values/Output/Tables/Highest_Diff.csv')

hi_pop <- arrange(hi_pop, desc(Population))
names(hi_pop) <- c("Site", "Size Known", "Population", "Label", "Difference Value")

write_csv(hi_pop[,c(1,3,5)], 'Data/Current_values/Output/Tables/Largest_Pop.csv')

urban <- arrange(urban, desc(imcv_difference))

write_csv(urban, 'Data/Current_values/Output/Tables/ApendixB_Cities_Detail.csv')

# #### End ####
