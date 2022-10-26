#!/bin/sh
## Mass Edit Audio Track Language if those are set not correctly
## Required tool -> apt-get install mkvtoolnix
find '/PathToMediaFiles' -name \*.mkv | while read file 
do
    ffmpeg -i "$file" | grep -q 'Language: eng' 
    if [ $? = 0 ] 
    then 
      echo $file 
      mkvpropedit --edit track:v1 --set language=de --edit track:a1 --set language=de "$file"
    fi
done
