#!/usr/bin/julia

using Pkg
Pkg.add("Circuitscape")
using Circuitscape

# 1. create folders

if (isdir("tmp"))
    rm("tmp", recursive=true, force=true)
end    
mkdir("tmp")

if (isdir("logs"))
    rm("logs", recursive=true, force=true)
end    
mkdir("logs")

if (isdir("output"))
    rm("output", recursive=true, force=true)
end    
mkdir("output")


#directions = ["E", "N", "S", "W"]
#speeds = ["Fast", "Middle", "Slow"]
#months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
directions = ["E", "N"]
speeds = ["Fast", "Slow"]
months = ["Jan", "Mar"]

# 2. transform geotiff Source raster maps from GEOTIFF to ASC with GDAL
for direction in directions
	filename = "source/" * direction * "_Source.tif"
	println("translating source ",filename," to asc")
	translated = "tmp/" * direction * "_Source.asc"
	run(`gdal_translate -of AAIGrid $filename $translated`)
end

# 3. write the config file
for direction in directions
    println("Dir: " * direction)
    source = ""

	if direction == 'E'
		source = 'W'
	elseif direction == 'W'
		source = 'E'
	elseif direction == 'N'
		source = 'S'
	else
		source = 'N'
	end

    for speed in speeds
        println("\tspeed: " * speed)
        for month in months
            println("\t\tmonth: " * month)

            print("writing config for direction: ")
            configFile = "tmp/config.ini"
	        config =  open(configFile,"w")

            directionFile = "tmp/" * direction * "_Source.asc"
            sourceFile = "tmp/" * source * "_Source.asc"
            outputFile = "tmp/" * direction * "_" * speed * "_" * month * ".out"
            outputFileTiff = "output/" * direction * "_" * speed * "_" * month * ".tif"
            outputFileAsc = "tmp/" * direction * "_" * speed * "_" * month * "_curmap.asc"
            logFile = "logs/log"  * direction * "_" * speed * "_" * month * ".log"

            costFile = "cost/" * speed * "_Sailing_Times/_" * direction * "_/_" * direction * "_" * month * "_Sailing_Time_Land_and_Sea_" * speed * ".asc"


        	write(config, "[Options for advanced mode]
ground_file_is_resistances = False
remove_src_or_gnd = False
use_unit_currents = False
use_direct_grounds = False\n")

            # add ground and source file
            write(config, "ground_file = " * directionFile * "\n")
            write(config, "source_file = " * sourceFile * "\n")

            write(config, "[Mask file]
mask_file = 
use_mask = False

[Calculation options]
low_memory_mode = False
parallelize = True
solver = cholmod
print_timings = True
preemptive_memory_release = False
print_rusages = False
max_parallel = 8

[Short circuit regions (aka polygons)]
polygon_file = 
use_polygons = False

[Options for one-to-all and all-to-one modes]
use_variable_source_strengths = False
variable_source_file = 

[Output options]
set_null_currents_to_nodata = False
set_focal_node_currents_to_zero = False
set_null_voltages_to_nodata = False
compress_grids = False
write_cur_maps = True
write_volt_maps = True
write_cum_cur_map_only = False
log_transform_maps = False
write_max_cur_maps = False\n")

            # add output file
            write(config, "output_file = " * outputFile * "\n")
        
            write(config, "[Options for reclassification of habitat data]
reclass_file = 
use_reclass_table = False

[Logging Options]
log_level = DEBUG
profiler_log_file = None
screenprint_log = True\n")

            write(config, "log_file = " * logFile * "\n")

            write(config, "[Options for pairwise and one-to-all and all-to-one modes]
included_pairs_file = 
use_included_pairs = False
point_file = 

[Connection scheme for raster habitat data]
connect_using_avg_resistances = False
connect_four_neighbors_only = False
    
[Habitat raster or graph]
habitat_map_is_resistances = True\n")

            write(config, "habitat_file = " * costFile * "\n")

            write(config, "[Circuitscape mode]
data_type = raster
scenario = advanced\n")

            close(config)

            print("computing CT for direction: " * direction * " speed: " * speed * " month: " * month * "\n")
            compute(configFile)

            # translate to geotiff
            run(`gdal_translate -of GTiff $outputFileAsc $outputFileTiff`)

        end
    end
end

