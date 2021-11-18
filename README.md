# Beyond Least Cost Paths: Circuit Theory, Maritime Mobility and Patterns of Urbanism in the Roman Adriatic

## Table of Contents
* [General Info](#general-info)
* [Requirements](#requirements)
* [Process](#process)
* [Data Structure](#data-structure)
* [Authors and Contact](#author-and-contact)

## General Info
This repository contains the source code for the paper submitted to the Journal of Archaeological Science.

## Requirements
The setup for the Circuit theory analysis was conducted in R, the CT analysis itself in Julia, and the processing of the outputs again in R. R and Julia are all that are required to reproduce this analysis. R packages used include- 

* gdalUtils
* raster
* rgdal
* tidyverse
* reader
* ncdf4
* ggrepel

## Process
* Download the datasets from : https://figshare.com/s/54520aef258b61ce1e10
* Ensure inputs and source code are within the same root folder
* Run the cost surface maps R script to set up raster data
* Run the Julia scripts to perform CT analysis
* Run the current values R script to calulate and visualise the current values for various scenarios and sites
* Outputs are stored in the respecitve output folders (the original results are included

## Data Structure
* Cost Surface -> Data for generating cost surface raster maps
  * Input -> U V Components -> Raw U and V wind components from Copernicus- Hersbach, H., Bell, B., Berrisford, P., Biavati, G., Horányi, A., Muñoz Sabater, J., Nicolas, J., Peubey, C., Radu, R., Rozum, I., Schepers, D., Simmons, A., Soci, C., Dee, D., Thépaut, J-N. (2018): ERA5 hourly data on single levels from 1979 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS). (Accessed on < 27-JUL-2021>), 10.24381/cds.adbb2d47
   * Input -> Wind Patterns -> Wind speed and direction in m/s and degrees
   * Input -> Wind Patters -> Ranges -> Rasters for wind patterns converted into numerical ranges as per Tables 1 and 2
   * Output -> Cost surface raster maps for Fast, Middle and Slow sailing times. Middle was used for the analysis in the paper

* Current Values -> Data for analysing the current values of various scenarios and sites
  * Input -> The shapefile for 3 km city radii, general information on cities and the CT outputs
  * Output -> The outputs detailing the current values. Including Appendix B and tables 4 and 5 used in the paper

* Reference -> Reference data, including sailing speed reference grids (Appendix A) and direction, speed ranges and month lists. These are used for the R code

## Authors and Contact
This repository was created by Andrew McLean, in order to provide access to source code and supplementary data.

Andrew McLean-


   University of Edinburgh
  
  
   Andrew.McLean@ed.ac.uk

