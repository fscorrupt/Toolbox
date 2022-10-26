#!/bin/sh
## Mass Convert avi or mp4 to mkv
## Required tool -> apt-get install ffmpeg
## cd into directory where the files are located, then run the script
## after script run do a `rm *.mp4` & `rm *.avi`

#!/bin/sh
for i in *.mp4;
  do name=`echo "$i" | cut -d'.' -f1`
  echo "$name"
  ffmpeg -i "$i" -c copy "${name}.mkv"
done

for i in *.avi;
  do name=`echo "$i" | cut -d'.' -f1`
  echo "$name"
  ffmpeg -i "$i" -c copy "${name}.mkv"
done
