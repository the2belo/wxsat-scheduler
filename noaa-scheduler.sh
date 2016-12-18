#!/bin/bash

#clear array
unset var1[@]

if [ -z $1 ]; then
    echo "Must specify which bird"
    exit 1
fi
if [ -z $2 ]; then
    echo "Must specify frequency in MHz"
    exit 1
fi

#get command line arg for bird/freq
bird=$1
freq=$2

#calculate best passes
for i in {00..23}
do
var1[10#$i]=$(predict -t ~/wxsat/weather.txt -p "NOAA ${bird}" $(date -d "+$i hour" +%s) | awk '{ if($5>=30) print $0}' |sort -u | head -1)
done

#calculate start-end for each pass
for x in $(printf -- '%s\n' "${var1[@]}" | grep : | awk '{print $1,$3$4}' | cut -d : -f 1,2 | sort -uk 2 | awk '{print $1}')
do
recstart=$(predict -t ~/wxsat/weather.txt -p "NOAA ${bird}" $x | awk '{ if($5>=10) print $0}' | head -1 | awk '{print $1}')
recend=$(predict -t ~/wxsat/weather.txt -p "NOAA ${bird}" $x | awk '{ if($5>=10) print $0}' | tail -1 | awk '{print $1}')
rectime=$(awk "BEGIN {print $recend-$recstart}")
init=$(date -d "@$recstart" +%y%m%d%H%M)
#create at file
cat << EOF > ~/wxsat/noaa${bird}.at
recdate=\$(date +%Y%m%d-%H%M)
mapdate=\$(date '+%d %m %Y %H:%M')
timeout $rectime /usr/local/bin/rtl_fm -d 0 -f ${freq}M -s 48000 -g 44 -p 1 -F 9 -A fast -E DC ~/wxsat/recordings/NOAA${bird}-\$recdate.raw
/usr/bin/sox -t raw -r 48000 -es -b16 -c1 -V1 ~/wxsat/recordings/NOAA${bird}-\$recdate.raw ~/wxsat/recordings/NOAA${bird}-\$recdate.wav rate 11025
touch -r ~/wxsat/recordings/NOAA${bird}-\$recdate.raw ~/wxsat/recordings/NOAA${bird}-\$recdate.wav
/usr/local/bin/wxmap -T "NOAA ${bird}" -H ~/wxsat/weather.txt -L "35.47/136.76/20" -p0 -o "\$mapdate" ~/wxsat/noaa${bird}map.png
/usr/local/bin/wxtoimg -e MCIR -m ~/wxsat/noaa${bird}map.png ~/wxsat/recordings/NOAA${bird}-\$recdate.wav ~/wxsat/images/NOAA${bird}-MCIR-\$recdate.png
/usr/local/bin/wxtoimg -e HVCT -m ~/wxsat/noaa${bird}map.png ~/wxsat/recordings/NOAA${bird}-\$recdate.wav ~/wxsat/images/NOAA${bird}-HVCT-\$recdate.png
#/usr/local/bin/wxtoimg -e MCIR-precip -m ~/wxsat/noaa${bird}map.png ~/wxsat/recordings/NOAA${bird}-\$recdate.wav ~/wxsat/images/NOAA${bird}-PRECIP-\$recdate.png
bash ~/wxsat/Dropbox-Uploader/dropbox_uploader.sh upload ~/wxsat/images/NOAA${bird}-*-\$recdate.png /
rm ~/wxsat/recordings/NOAA${bird}-\$recdate.raw
EOF
#schedule at
at -f ~/wxsat/noaa${bird}.at -t $init
done

#clear array
unset var1[@]
