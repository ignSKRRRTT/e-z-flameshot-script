#!/bin/bash -e

auth="API KEY HERE."
url="https://api.e-z.host/files"

temp_file="/tmp/screenshot.png"
flameshot gui -r > $temp_file

if [[ $(file --mime-type -b $temp_file) != "image/png" ]]; then
    rm $temp_file
    exit 1
fi

response_file="/tmp/upload.json"
http --verify=no --form POST $url "key:$auth" file@"$temp_file" > $response_file

if ! jq -e . >/dev/null 2>&1 < $response_file; then
    notify-send "Error occurred while uploading. Please try again later." -a "Flameshot"
    rm $temp_file
    rm $response_file
    exit 1
fi

success=$(cat $response_file | jq -r ".success")
if [[ "$success" != "true" ]] || [[ "$success" == "null" ]]; then
    error=$(cat $response_file | jq -r ".error")
    if [[ "$error" == "null" ]]; then
        notify-send "Error occurred while uploading. Please try again later." -a "Flameshot"
        rm $temp_file
        rm $response_file
        exit 1
    else
        notify-send "Error: $error" -a "Flameshot"
        rm $temp_file
        rm $response_file
        exit 1
    fi
fi

cat $response_file | jq -r ".imageUrl" | xclip -sel c
notify-send "Image URL copied to clipboard" -a "Flameshot" -i $temp_file
rm $temp_file
