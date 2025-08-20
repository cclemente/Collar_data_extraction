# Collar data extraction. 

## This was built to try to get the data out of the impala collars collected in June 2024 in africa, but should work for other data sets. 

### Workflow

This code is designed to work best one collar at a time. Its up to oak to put it into a larger loop to work for multiple collars 

### Step 1a
This code should be directed towards the raw collar data and should extract all the accel fiels and their timestamp. So far it seems to be working ok. 
The output should be a single .RDA file to call in later. 

### Step 1b
Orignally oak combined this with above, but it was a bit of a pain.
The GPS data is a mess. There are numerous random characters thrown in and the format can change. It should have a format like the following (i.e. the GPS data, followed by an internal timestamp) 


+ 06/07/2024 09:15:25 - Lon:31.707413, Lat:-25.432672

+ ^01/09/2000,12:54:39.93

But in other times (like Collar 08) its formated wrong like this 

+ Lat:-25.427173
+ 03/07/2024 20:30:06 - Lon:31.696799,
+ ^01/07/2000,00:09:17.67

The code as written should be able to handle both, but beware of any other possible combination of bullshit
The output should be a single .csv file to call in later

### Step 2
In this step we merge the GPS and accel together based on the timestamps. 
For whatever reason the timestamp only goes to the nearest second, so there are some repeats. The GPS will match to the first of any repeated times, at most this will put it off by 1 second. 
The output of this is saved as both a single aligned.RDA file (this step might be removed) 
And is then broken down into day long chunks and each saved as a separate file to make reading in easier later. 
It will need to be edited for each collar, particularly with regard to the collar labels which are currently hardcoded in cause i am a lazy POS. 

### Step 3 
This step is where i try to extract the accel segment which corresponds to each video. It desperately needs to be automated, but right now i am doing it manually since i have only got it to work. Its currently at the debugging stage, since this is where i have been finding the errors in the steps above. 
To use it you need to direct it to the video file of interest 
Then manually give it the start time for that video. 
Output is a file with matlab fractional days, + XYZ accel data

+ Step 3c_drone_align_video_accel
  
I have now added a file which aligns the drone videos automatically, and outputs the .csv and an image of the accel graph

### Notes on step 3
+ use local time for DSLR camera and chris's phone 
+ e.g. video_start_local <- as.POSIXct("2024-06-29 13:33:00", tz = "Africa/Johannesburg")
+ use UTC for Drone footage 
+ video_start_local <- as.POSIXct("2024-07-04 09:27:42", tz = "UTC")






