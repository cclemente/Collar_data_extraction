
# Remove ALL objects from your workspace
rm(list = ls())

# Force garbage collection (frees up unused memory)
gc()


library(lubridate)
library(av)
library(data.table)
library(ggplot2)

library(dplyr)
library(lubridate)

# Reshape for plotting
library(tidyr)



#Collar 02  Example inputs
###########################################################################################

setwd('G:/Project files/ImpalaProject-main/ImpalaProject-main/RawData/Collar2/Collar2')

video_file <- "20240629_133300_collar2.mp4"
video_file <- "20240629_133131_collar2.mp4"
video_file <- "20240704_111420_collar2.mp4"
video_file <- '20240704_111832_collar2.mp4'
video_file <- '_DSC7581.MOV'

setwd('H:/Africa impala july 2024/Drone 04072024')
video_file <- "DJI_20240704092742_0046_D_collar2.mp4"
video_file <- "DJI_20240704093550_0047_D_collar2.mp4"

setwd('H:/Africa impala july 2024/Drone 07072024')
video_file <- "DJI_20240707123516_0071_D_collar2.mp4"

#local time for DSLR camera and chris's phone 
video_start_local <- as.POSIXct("2024-06-29 13:33:00", tz = "Africa/Johannesburg")
video_start_local <- as.POSIXct("2024-06-29 13:31:31", tz = "Africa/Johannesburg")
video_start_local <- as.POSIXct("2024-07-04 11:14:20", tz = "Africa/Johannesburg")
video_start_local <- as.POSIXct("2024-07-04 11:18:32", tz = "Africa/Johannesburg")
video_start_local <- as.POSIXct("2024-07-06 11:39:24", tz = "Africa/Johannesburg") #'_DSC7581.MOV'

#Drone footage in UTC
video_start_local <- as.POSIXct("2024-07-04 09:27:42", tz = "UTC")
video_start_local <- as.POSIXct("2024-07-04 09:35:50", tz = "UTC")

###########################################################################################


##Collar 08
setwd('G:/Project files/ImpalaProject-main/ImpalaProject-main/RawData/Collar8/videos')

video_file <- '20240629_120341.mp4'
video_file <- '20240629_120439.mp4'

##manually set time zones chris Mob in local time 
video_start_local <- as.POSIXct("2024-06-29 12:03:41", tz = "Africa/Johannesburg") #20240629_120341.mp4
video_start_local <- as.POSIXct("2024-06-29 12:04:39", tz = "Africa/Johannesburg") #20240629_120341.mp4


##Collar 08 drone videos
setwd('G:/Project files/ImpalaProject-main/ImpalaProject-main/RawData/Collar8/videos/Drone 20240702')

video_file <- 'DJI_20240702082054_0038_D_recoded.mp4'
video_file <- 'DJI_20240702082301_0039_D.mp4'

##manually set time zones Drone in UTC
video_start_local <- as.POSIXct("2024-07-02 08:20:54", tz = "UTC") #DJI_20240702082054_0038_D_recoded.mp4
Drone_delay = -23

video_start_local <- video_start_local + Drone_delay

###########################################################################################




# Convert to UTC
video_start_utc <- with_tz(video_start_local, "UTC")
video_info <- av::av_media_info(video_file)
video_length <- video_info$duration  # seconds
#video_length <- 90
video_end <- video_start_utc + video_length


# ---- Load accel chunk for that UTC day ----
#you only have to do this if you are choosing a different day
#accel_dir <- "G:/Project files/ImpalaProject-main/ImpalaProject-main/RawData/Collar2"
accel_dir <- "G:/Project files/ImpalaProject-main/ImpalaProject-main/RawData/Collar8"
day_date <- as.Date(video_start_utc, tz="UTC")

accel_file <- file.path(accel_dir, paste0("collar08_accel_data_", format(day_date, "%Y-%m-%d"), ".Rda"))

if (!file.exists(accel_file)) stop("Accel file not found: ", accel_file)

tmp_env <- new.env()
load(accel_file, envir = tmp_env)
accel_data <- tmp_env[[ls(tmp_env)]]

# Make sure gps_time_est is POSIXct
if (!inherits(accel_data$gps_time_est, "POSIXct")) {
  accel_data$gps_time_est <- as.POSIXct(accel_data$gps_time_est, tz="UTC")
}

setDT(accel_data)

# ---- Extract segment matching video ----
accel_segment <- accel_data[gps_time_est >= video_start_utc & gps_time_est <= video_end]






#################################
# manually subset data
#video_start_utc <- as.POSIXct("2024-06-29 12:04:00", tz = "Africa/Johannesburg")
#video_end       <- as.POSIXct("2024-06-29 12:05:00", tz = "Africa/Johannesburg")
# 
# # ---- Extract segment matching video ----
#accel_segment <- accel_data[gps_time_est >= video_start_utc & gps_time_est <= video_end]
###########################


# Convert raw counts to g
accel_segment$AX_g <- accel_segment$RawAX / 8192
accel_segment$AY_g <- accel_segment$RawAY / 8192
accel_segment$AZ_g <- accel_segment$RawAZ / 8192

# seconds from video start (POSIXct difference → seconds)
accel_segment$t_sec <- as.numeric(accel_segment$gps_time_est - video_start_utc)

plot_data <- tidyr::pivot_longer(
  accel_segment,
  cols = c(AX_g, AY_g, AZ_g),
  names_to = "Axis",
  values_to = "Accel_g"
)

#for plotting in seconds. Good for short videos
ggplot(plot_data, aes(x = t_sec, y = Accel_g, color = Axis)) +
  geom_line(alpha = 0.7) +
  labs(x = "Seconds since video start", y = "Acceleration (g)",
       title = "Accelerometer Data") +
  theme_minimal()+
  scale_x_continuous(
    breaks = function(lims) seq(ceiling(lims[1]/5)*5, floor(lims[2]/5)*5, by = 10),
    minor_breaks = function(lims) seq(ceiling(lims[1]),  floor(lims[2]),  by = 5)
  )


#plots minutes and seconds 
ggplot(plot_data, aes(x = t_sec, y = Accel_g, color = Axis)) +
  geom_line(alpha = 0.7) +
  labs(x = "Time since video start (MM:SS)", y = "Acceleration (g)",
       title = "Accelerometer Data") +
  theme_minimal() +
  scale_x_continuous(
    breaks = function(lims) seq(ceiling(lims[1]/5)*5, floor(lims[2]/5)*5, by = 10),
    labels = function(x) {
      x <- floor(x + 0.5)                 # round to nearest second
      sprintf("%02d:%02d", x %/% 60, x %% 60)
    }
  )



###cleaning up accel files
matlab_origin <- 719529  # MATLAB datenum for 1970-01-01
# Convert to MATLAB fractional days
accel_segment[, t_matlab := as.numeric(gps_time_est) / 86400 + matlab_origin]
# Keep just MATLAB time and g-columns
out <- accel_segment[, .(t_matlab, AX_g, AY_g, AZ_g)]
# quick sanity check
head(out)

write.csv(out, 'DJI_20240702082054_0038_D_recoded.csv')





