#!/bin/bash
#a quick and dirty script to grab chronological information from specified geolocation(country)

header(){
        echo $0
        date
        echo ''
}

export LOGFILE_PATH="/var/log"
export FILE_PREFIX="kern"
export LOG_TYPE=""
export COUNTRY_CODE="PH"

install_prerequisite(){
  set -e
  apt-get update
  apt-get install -y jq 
}

grab_all_ips() {
  #cat "$LOGFILE_PATH"/"$FILE_PREFIX".log "$LOGFILE_PATH"/"$FILE_PREFIX".log.[0-9] | awk -e '{print $1}' > "$LOG_TYPE"_"$FILE_PREFIX".ips
  cat "$LOGFILE_PATH"/"$FILE_PREFIX".log "$LOGFILE_PATH"/"$FILE_PREFIX".log.[0-9] | awk -F 'SRC=' {'print $2'} | awk -F 'DST=' {'print $1'} | sort -u > "$LOG_TYPE"_"$FILE_PREFIX".ips
  #zcat "$LOGFILE_PATH"/"$FILE_PREFIX".log.[0-9].gz | awk -e '{print $1}' >> "$LOG_TYPE"_"$FILE_PREFIX".ips
  zcat "$LOGFILE_PATH"/"$FILE_PREFIX".log.[0-9].gz | awk -F 'SRC=' {'print $2'} | awk -F 'DST=' {'print $1'} | sort -u >> "$LOG_TYPE"_"$FILE_PREFIX".ips
  sed -i 's/^[ \t]*//;s/[ \t]*$//' "$LOG_TYPE"_"$FILE_PREFIX".ips
  sort -o "$LOG_TYPE"_"$FILE_PREFIX".ips -u "$LOG_TYPE"_"$FILE_PREFIX".ips
}

identify_geo_ips(){
  > "$LOG_TYPE"_"$FILE_PREFIX".geo-ips
  while read ip
  do
    curl --silent freegeoip.net/json/"$ip"| jq 'select(.country_code == "PH")| .ip' --raw-output >> "$LOG_TYPE"_"$FILE_PREFIX".geo-ips
  done < "$LOG_TYPE"_"$FILE_PREFIX".ips
}

grab_activity_time(){
  while read ip
  do
    > $ip.unsorted
    cat "$LOGFILE_PATH"/"$FILE_PREFIX".log "$LOGFILE_PATH"/"$FILE_PREFIX".log.[0-9] | grep $ip | awk {'print $1, $2, $3'} >> $ip.unsorted
    zcat "$LOGFILE_PATH"/"$FILE_PREFIX".log.[0-9].gz | grep $ip |  awk {'print $1, $2, $3'} >> $ip.unsorted
  done < "$LOG_TYPE"_"$FILE_PREFIX".geo-ips
}

sort_sessions(){
while read ip
	do
	  while read time
	  do
  		date -d "$time" +%s >> $ip.epoch.unsorted
	  done < $ip.unsorted
	  sort -o $ip.epoch.sorted $ip.epoch.unsorted
	  while read time
	  do
	  	date -d @$time "+%d-%b-%Y %H:%M:%S" >> $ip.sorted
	  done < $ip.epoch.sorted
	  echo $ip
	  cat $ip.sorted
	  echo ''
	  rm -f $ip.unsorted $ip.epoch.unsorted $ip.epoch.sorted $ip.sorted
done < $(ls -A1 "$LOG_TYPE"_"$FILE_PREFIX".geo-ips)
}


#install_prerequisite
header
grab_all_ips
identify_geo_ips
grab_activity_time
sort_sessions
