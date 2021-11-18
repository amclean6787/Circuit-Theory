# #### Circuit Theory- Cost Surface ####
# Mount Packages

library(gdalUtils)
library(raster)
library(rgdal)
library(tidyverse)
library(reader)
library(ncdf4)

# #### Create Cost Surfaces Maps ####
Month_list <- as_vector(read_tsv("Data/Reference/Month_list.txt", col_names = FALSE)) # Set up Month List
Sea_extent <- readOGR(dsn=path.expand("Data/Cost_surface/Input"), layer="Sea_extent") # Import Sea Extent shapefile
Land_cost <- raster("Data/Cost_surface/Input/Land_time.tif") # Import terrestrial cost surface map to align resolution, projection etc.

# ==== UV Components ====
# ---- Get average U and V wind components derived from ERA5 hourly Datasets from the Copernicus Project ----
for (Month in 1:12) {
  u <- raster(paste0("Data/Cost_surface/Input/UV_components/", Month_list[Month], "_uv.nc"), varname='u10') %>%
    mean() # Get mean u component
  v <- raster(paste0("Data/Cost_surface/Input/UV_components/", Month_list[Month], "_uv.nc"), varname='v10') %>%
    mean() # Get mean v component
  
  raster::stack(c(u,v)) %>% # Combine U and V components into two band raster
    raster::projectRaster(Land_cost) %>% # Change reproject and resize U and V rasters
    mask(Sea_extent) %>% # Clip raster to sea extent
    writeRaster(file= paste0("Data/Cost_surface/Input/UV_components/Average/", Month_list[Month], "_average_uv.tif"), format = "GTiff") # Export rasters
  
  rm(list=c("u","v"))
}

# ---- Convert U and V wind components into wind speed (m/s) and direction (degrees) ----
browse_URL("http://colaweb.gmu.edu/dev/clim301/lectures/wind/wind-uv") # Sources for transforming u and v components
browse_URL("http://weatherclasses.com/uploads/3/6/2/3/36231461/computing_wind_direction_and_speed_from_u_and_v.pdf")

for (Month in 1:12) {
  r <- raster::stack(paste0("Data/Cost_surface/Input/UV_components/Average/", Month_list[Month], "_average_uv.tif")) # Import reprojected average u and v rasters
  
  u <- r[[1]] # unstack raster bands
  v <- r[[2]]
  
  wd <- 180 + (180/pi)*atan2(u,v) # Transform to get wind direction in degrees
  ws <- sqrt(u^2+v^2) # Transform to get wind speed in m/s
  
  raster::stack(c(wd,ws)) %>% # restack rasters with wind direction and speed as separate bands
    writeRaster(file= paste0("Data/Cost_surface/Input/Wind_patterns/", Month_list[Month], "_patterns.tif"))
  
  rm(list=c("r","u","v","wd","ws"))
}

# ==== Transform to sailing time ====

# ---- Assign sailing speed and direction ranges ----
WD_range_values <- c(0, 11.25, 1,  348.75, 360, 1,  11.25, 33.75, 2,  33.75, 56.25, 3, 56.25, 78.75, 4,  78.75, 101.25, 5,  101.25, 123.75, 6,  123.75, 146.25, 7,  146.25, 168.75, 8,  168.75, 191.25, 9,  191.25, 213.75, 10,  213.75, 236.25, 11,  236.25, 258.75, 12, 258.75, 281.25, 13,  281.25, 303.75, 14,  303.75, 326.25, 15,  326.25, 348.75, 16)
WD_range_values <- matrix(WD_range_values, ncol=3, byrow=TRUE) # Generate matrix for reclassifying wind direction in degree to 16 equal ranges

WS_range_values <- c(0, 0.514, 1,  0.514, 1.543, 2,  1.543, 3.087, 3,  3.087, 5.144, 4,  5.144, 8.231, 5,  8.231, 100, 6) 
WS_range_values <- matrix(WS_range_values, ncol=3, byrow=TRUE) # Generate matrix for reclassifying wind speed in m/s into 6 equal ranges

NA_values <- c(0, NA)
NA_values <- matrix(NA_values, ncol=2, byrow=TRUE) # Assign 0 values to NA to ensure overwrite while merging rasters

for (Month in 1:12) {
  wd <- raster::stack(paste0("Data/Cost_surface/Input/Wind_patterns/", Month_list[Month], "_patterns.tif"))[[1]] %>%
    reclassify(WD_range_values)
  
  ws <- raster::stack(paste0("Data/Cost_surface/Input/Wind_patterns/", Month_list[Month], "_patterns.tif"))[[2]] %>%
    reclassify(WS_range_values)
  
  stack(c(wd,ws)) %>%
    writeRaster(file= paste0("Data/Cost_surface/Input/Wind_patterns/Ranges/", Month_list[Month], "_ranges.tif"))
  
  rm(list=c("wd","ws"))
}

# ---- Convert wind pattern ranges to sailing time ----
Combined <- Land_cost*0
Combined <- reclassify(Combined, NA_values)

Sailing_speed_reference <- "Nothing"

while (Sailing_speed_reference!="Fast" & Sailing_speed_reference!="Middle" & Sailing_speed_reference!="Slow"){
  Sailing_speed_reference <- (readline(prompt="Enter sailing speeds rate, Fast, Middle or Slow: "))
} # Select sailing speed reference grid Fast, Middle or Slow

Direction_list <- as_vector(read_tsv("Data/Reference/Direction_list.txt", col_names = FALSE)) # Set up direction list

for (Month in 1:12) {
  for (Direction in 1:4) {
    Reference_Grid <- read_csv(paste("Data/Reference/Sailing_speed_reference_grids/", Sailing_speed_reference, "/Sailing_Grid_", Direction_list[Direction], "_.csv", sep="")) # Assign reference grid
    
    wd <- raster::stack(paste0("Data/Cost_surface/Input/Wind_patterns/Ranges/", Month_list[Month], "_ranges.tif"))[[1]]
    ws <- raster::stack(paste0("Data/Cost_surface/Input/Wind_patterns/Ranges/", Month_list[Month], "_ranges.tif"))[[2]]
    
    for (column_number in 3:18) {
      for (row_number in 2:7) {
        Current_raster <- (wd==as.numeric(Reference_Grid[1,column_number]) & ws==as.numeric(Reference_Grid[row_number,2]))*as.numeric(Reference_Grid[row_number,column_number])
        Combined <- raster::merge(Combined, Current_raster)
      }
    }
    
    reclassify(Combined, NA_values)
    
    Combined <- 250/Combined
    
    raster::merge(Land_cost, Combined) %>%
      writeRaster(file= paste0("Data/Cost_surface/Output/", Sailing_speed_reference, "/", Direction_list[Direction], "_", Month_list[Month], "_", Sailing_speed_reference, "_time.asc"), format = "GTiff")
    
    print(paste(Direction_list[Direction], Month_list[Month], "sailing time raster completed.", sep = " "))
  }
  print(paste(Month_list[Month], "sailing time rasters completed.", sep = " "))
}

# #### End ####