
#step 2 : check the data

library(data.table)
library(lubridate)
library(zoo)

# Remove ALL objects from your workspace
rm(list = ls())

# Force garbage collection (frees up unused memory)
gc()

# Path to the folder containing your accel data logs
#accel_dir <-'C:/Users/User/Desktop/Impala behaviour analysis/Collar data/Collar 2'
accel_dir <-'G:/Project files/ImpalaProject-main/ImpalaProject-main/RawData/Collar2'

accel_dir <- 'G:/Project files/ImpalaProject-main/ImpalaProject-main/RawData/Collar8'

setwd(accel_dir)

# ---- 1. Load accel data ----
load("accel_data_merged_collar08.RDA")  # loads accel_data
setDT(accel_data)       # ensure it's a data.table

# Clean up
accel_data[, V17 := NULL]

# ---- 2. Convert accel timestamps in-place ----
# Combine date and time columns and parse in one step
accel_data[, rtc_datetime := mdy_hms(paste(rtcDate, rtcTime), tz = "UTC")]


# # Clean just in case (commas as decimal separators)
# accel_data[, rtcTime := sub(",", ".", rtcTime, fixed = TRUE)]
# 
# # Split "HH:MM:SS.ff" quickly (C-level), then numeric
# accel_data[, c("hh","mm","ss") := tstrsplit(rtcTime, ":", fixed = TRUE)]
# accel_data[, `:=`(
#   hh = as.integer(hh),
#   mm = as.integer(mm),
#   ss = as.numeric(ss)   # keeps fractions
# )]
# 
# # Date -> days since epoch (fast) using your known format "%m/%d/%Y"
# accel_data[, date_days := as.numeric(as.IDate(rtcDate, format = "%m/%d/%Y"))]
# 
# # Build epoch seconds as double, then POSIXct once (fast)
# accel_data[, rtc_datetime := as.POSIXct(
#   date_days * 86400 + hh * 3600 + mm * 60 + ss,
#   origin = "1970-01-01", tz = "UTC"
# )]
# 
# # Tidy up
# accel_data[, c("hh","mm","ss","date_days") := NULL]


head(accel_data)

# Check duplicate accel times
#ideally we want zero, but we will use first time that time code appears. 
#Should be correct to within a second 
sum(duplicated(accel_data$rtc_datetime))

# ---- 2. Read GPS data ----
gps_data <- fread("Sat_board_GPS_collar08.csv")
setDT(gps_data)

# ---- 3. Convert timestamps to POSIXct if not done ----
# (this should already be done for GPS, but double-check)
gps_data[, internal_timestamp := as.POSIXct(internal_timestamp, tz = "UTC")]
gps_data[, gps_timestamp := as.POSIXct(gps_timestamp, tz = "UTC")]

#head(gps_data)


#Step 4: Align Accel & GPS
setkey(accel_data, rtc_datetime)
setkey(gps_data, internal_timestamp)


accel_data[, gps_flag := FALSE]

accel_data[gps_data,
           on = .(rtc_datetime = internal_timestamp),
           roll = "nearest",
           mult = "first",
           `:=`(
             gps_timestamp = i.gps_timestamp,
             gps_lon       = i.lon,
             gps_lat       = i.lat,
             gps_flag      = TRUE
           )
]



# Find the closest accel row for each GPS fix
# nearest_idx <- accel_data[gps_data, roll = "nearest", which = TRUE]
# 
# # Mark only those accel rows
# accel_data[, gps_flag := FALSE]
# accel_data[nearest_idx, gps_flag := TRUE]
# 
# # Copy GPS info to those rows
# # Copy GPS info to those rows: use gps_timestamp, lon, lat
# #option 1 try this first, but if errors, try code with nearest.,
# accel_data[nearest_idx, c("gps_timestamp", "gps_lon", "gps_lat") :=
#              gps_data[, .(gps_timestamp, lon, lat)]]

# accel_data[gps_data,
#            on = .(rtc_datetime = internal_timestamp),
#            roll = "nearest",
#            mult = "first",             # choose one accel row per match to avoid fanning out
#            `:=`(
#              gps_timestamp = i.gps_timestamp,
#              gps_lon       = i.lon,
#              gps_lat       = i.lat,
#              gps_flag      = TRUE
#            )
# ]




###error checking 

# Check the sizes
# nrow(gps_data)
# length(nearest_idx)
# sum(is.na(nearest_idx))
# 
# # Check duplicate accel or GPS times
# sum(duplicated(accel_data$rtc_datetime))
# sum(duplicated(gps_data$internal_timestamp))
# 
# # Look for obvious RTC resets (big backward jumps)
# accel_jumps <- which(diff(accel_data$rtc_datetime) < 0)
# accel_data[head(accel_jumps, 10), .(row=.I, rtc_datetime)][]


#Should be the same as the number of GPS hits
sum(accel_data$gps_flag)


head(accel_data)


# Convert GPS times to numeric seconds
accel_data[, gps_time_sec := as.numeric(gps_timestamp)]

# Interpolate GPS times linearly
accel_data[, gps_time_est_sec := na.approx(gps_time_sec, na.rm = FALSE)]

# Convert back to POSIXct
accel_data[, gps_time_est := as.POSIXct(gps_time_est_sec, origin = "1970-01-01", tz = "UTC")]


# Clean up
accel_data[, c("gps_time_sec", "gps_time_est_sec") := NULL]



# Plot a subset to visually inspect interpolation
# library(ggplot2)
# 
# first_fix <- which(!is.na(accel_data$gps_time_est))[1]
# ggplot(accel_data[first_fix:(first_fix+5000)], 
#        aes(x = rtc_datetime, y = gps_time_est)) +
#   geom_line() +
#   geom_point(aes(color = gps_flag)) +
#   labs(title = "Interpolated GPS time vs RTC", y = "GPS Time Estimate")




# Save aligned accel + GPS data for faster future loading
save(accel_data, file = "collar2_accel_data_aligned.RDA")
save(accel_data, file = "collar08_accel_data_aligned.RDA")

# Extract date from estimated GPS time
accel_data[, date := as.Date(gps_time_est)]
unique(accel_data$date)

# Split by date (creates a list of data.tables)
accel_list <- split(accel_data, by = "date", keep.by = TRUE)

# Save each element of the list to a separate RDA file
invisible(lapply(names(accel_list), function(d) {
  dt <- accel_list[[d]]      # assign to a local variable
  save(dt, file = paste0("collar08_accel_data_", d, ".Rda"))
}))


