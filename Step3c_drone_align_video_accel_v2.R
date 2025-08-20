
# Remove ALL objects from your workspace
rm(list = ls())

# Force garbage collection (frees up unused memory)
gc()


library(lubridate)
library(av)
library(data.table)
library(ggplot2)
library(tidyr)

##Collar 08 drone videos
vid_path <- 'G:/Project files/ImpalaProject-main/ImpalaProject-main/RawData/Collar8/videos/Drone 20240702/recoded'
vid_path <- 'G:/Project files/ImpalaProject-main/ImpalaProject-main/RawData/Collar8/videos/Drone 20240706'
##Collar 08 accel files
accel_dir <- "G:/Project files/ImpalaProject-main/ImpalaProject-main/RawData/Collar8"




# All MP4s (case-insensitive), absolute paths
video_files <- list.files(
  path = vid_path,
  pattern = "(?i)\\.mp4$",  
  full.names = TRUE
)

# All accel files (case-insensitive), absolute paths
accel_files <- list.files(
  path = accel_dir,
  pattern = "(?i)\\.rd[aA]$",  
  full.names = TRUE
)

Drone_delay <- -25  # seconds

last_accel_path <- NULL
accel_data      <- NULL  # cached accel data
matlab_origin   <- 719529  # MATLAB datenum for 1970-01-01

for (video_file in video_files) {
  
  ## --- Parse start time from filename (Drone in UTC) ---
  video_start_local <- as.POSIXct(
    sub("^.*?_(\\d{14}).*$", "\\1", basename(video_file)),
    format = "%Y%m%d%H%M%S",
    tz = "UTC"
  ) + Drone_delay
  video_start_utc <- lubridate::with_tz(video_start_local, "UTC")
  
  ## --- Video end time ---
  video_length <- av::av_media_info(video_file)$duration
  video_end    <- video_start_utc + video_length
  
  ## --- Pick accel file for that UTC date (no collar hardcode) ---
  day_date  <- as.Date(video_start_utc, tz = "UTC")
  date_str  <- format(day_date, "%Y-%m-%d")
  accel_file <- accel_files[grepl(
    paste0("(?i)collar\\d+_accel_data_", date_str, "\\.rd[aA]$"),
    basename(accel_files)
  )][1]
  
  if (is.na(accel_file) || !file.exists(accel_file)) {
    message("No accel file for ", date_str, " — skipping: ", basename(video_file))
    next
  }
  
  ## --- Load accel only if needed (cache by path) ---
  if (is.null(last_accel_path) || !identical(accel_file, last_accel_path)) {
    tmp_env <- new.env()
    load(accel_file, envir = tmp_env)
    accel_data <- tmp_env[[ls(tmp_env)[1]]]
    rm(tmp_env)
    
    if (!inherits(accel_data$gps_time_est, "POSIXct")) {
      accel_data$gps_time_est <- as.POSIXct(accel_data$gps_time_est, tz = "UTC")
    }
    data.table::setDT(accel_data)
    data.table::setkey(accel_data, gps_time_est)  # speeds up subsetting
    
    last_accel_path <- accel_file
    message("Loaded accel: ", basename(accel_file))
  }
  
  ## --- Extract segment matching video interval ---
  accel_segment <- accel_data[data.table::between(gps_time_est, video_start_utc, video_end)]
  if (nrow(accel_segment) < 2) {
    message("No accel overlap — skipping: ", basename(video_file))
    next
  }
  
  ## --- Convert to g and relative time ---
  accel_segment[, `:=`(
    AX_g = RawAX / 8192,
    AY_g = RawAY / 8192,
    AZ_g = RawAZ / 8192,
    t_sec = as.numeric(gps_time_est - video_start_utc)
  )]
  
  ## --- Plot to PNG (saved next to video) ---
  plot_data <- tidyr::pivot_longer(accel_segment,
                                   cols = c(AX_g, AY_g, AZ_g),
                                   names_to = "Axis", values_to = "Accel_g"
  )
  
  g <- ggplot(plot_data, aes(x = t_sec, y = Accel_g, color = Axis)) +
    geom_line(alpha = 0.7) +
    labs(x = "Time since video start (MM:SS)", y = "Acceleration (g)",
         title = "Accelerometer Data") +
    theme_minimal() +
    scale_x_continuous(
      breaks = function(lims) seq(ceiling(lims[1]/5)*5, floor(lims[2]/5)*5, by = 10),
      labels = function(x) sprintf("%02d:%02d", floor(x + 0.5) %/% 60, floor(x + 0.5) %% 60)
    )
  
  
  # build base path without extension
  base_noext <- tools::file_path_sans_ext(basename(video_file))
  out_base   <- file.path(dirname(video_file), base_noext)
  
  # PNG
  png_path <- paste0(out_base, ".png")
  ggsave(filename = png_path, plot = g, width = 9, height = 4.5, dpi = 150, bg = "white")
  
  # CSV
  accel_segment[, t_matlab := as.numeric(gps_time_est) / 86400 + matlab_origin]
  out <- accel_segment[, .(t_matlab, AX_g, AY_g, AZ_g)]
  csv_path <- paste0(out_base, ".csv")
  data.table::fwrite(out, csv_path)
  
  
  message("Done: ", basename(video_file))
}




