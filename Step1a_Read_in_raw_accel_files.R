# Remove ALL objects from your workspace
rm(list = ls())

# Force garbage collection (frees up unused memory)
gc()

library(data.table)

# Path to the folder containing your accel data logs
accel_dir <-'C:/Users/User/Desktop/Impala behaviour analysis/Collar data/Collar 2'
accel_dir <-'F:/Africa impala july 2024/Collar data/Collar 8'
accel_dir <-'F:/Africa impala july 2024/Collar data/Collar 9'
accel_dir <-'F:/Africa impala july 2024/Collar data/Collar 10'

# List all matching files
accel_files <- list.files(
  path = accel_dir,
  pattern = "^dataLog\\d+\\.TXT$",  # matches dataLog00000.TXT etc.
  full.names = TRUE
)

# Read & combine all files
accel_data <- rbindlist(
  lapply(accel_files, function(f) fread(f, skip = 0)),  # fread auto-skips blank lines
  use.names = TRUE,
  fill = TRUE
)


setwd('G:/Project files/ImpalaProject-main/ImpalaProject-main/RawData/Collar9')
save(accel_data, file = "accel_data_merged_collar09.RDA")

setwd('G:/Project files/ImpalaProject-main/ImpalaProject-main/RawData/Collar10')
save(accel_data, file = "accel_data_merged_collar10.RDA")

# Remove the accel data from memory
rm(accel_data)

# Force R to free memory
gc()


# Folder containing both accel and GPS files
