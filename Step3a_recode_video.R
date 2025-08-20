
#Step 3a recode videos for matlab 


##Collar 08 drone videos
dir_path <- 'G:/Project files/ImpalaProject-main/ImpalaProject-main/RawData/Collar8/videos/Drone 20240702'
setwd(dir_path)

video_file <- 'DJI_20240702082054_0038_D.mp4'
video_file <- 'DJI_20240702082301_0039_D.mp4'

# List all matching files
video_files <- list.files(
  path = dir_path,
  pattern = "*.mp4",  # maybe MP4? .
  full.names = TRUE
)



##Optional recoding of video for matlab. 

infile  <- normalizePath(file.path(dir_path, video_file), winslash = "/", mustWork = FALSE)
outfile <- sub("\\.[^.]+$", "_recoded.mp4", infile)

#for regular phone videos
# system(sprintf(
#   'ffmpeg -y -i %s -c:v libx264 -pix_fmt yuv420p -c:a copy -movflags +faststart %s',
#   shQuote(infile), shQuote(outfile)
# ))

#for downgrading the drone videos to 1080p
system(sprintf(
  'ffmpeg -y -probesize 100M -analyzeduration 100M -i %s -map 0:v:0 -an -dn -vf scale=1920:-2 -c:v libx264 -pix_fmt yuv420p -preset ultrafast -tune zerolatency -threads 1 -movflags +faststart %s',
  shQuote(infile), shQuote(outfile)
))



