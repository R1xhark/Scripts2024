#!/bin/bash

function show_loading() {
    local chars="/-\|"
    while true; do
        for (( i=0; i<${#chars}; i++ )); do
            sleep 0.1
            echo -en "${chars:$i:1}" "\r"
        done
    done
}


echo "Sorting email foldersca"
show_loading &
loading_pid=$!

email_output=$(du -h --max-depth 1 /var/mail/virtual | sort -h)

kill $loading_pid

echo "Generating CSV File...."
echo "Domain,Folder Size,Owner,Last Login" > output.csv


show_loading &
loading_pid=$!


while IFS= read -r line; do
  
    folder_size=$(echo "$line" | awk '{print $1}')
    domain_folder=$(echo "$line" | awk '{print $2}')

    domain_name=$(basename "$domain_folder")

    owner=$(whois "$domain_name" | grep -i 'org:.*')

    if echo "$owner" | grep -qE ""; then # insert org name between " "
        owner="You are the owner"
    else
        owner_dig=$(dig +short "$domain_name" | grep -iE '') # ""

	if echo "$owner_dig" | grep -qE ""; then
	    owner="You are the owner"
        else
            owner="Not owner"
        fi
    fi

    last_logins=$(grep 'dovecot:.*Login:.*user=<.*@'"$domain_name" /var/log/mail.log | awk '{print $1, $2, $3, $8}' | head -n 1)

    if [ -n "$last_logins" ]; then 
        last_login_info="$last_logins"
    else
        last_login_info="No logins found"
    fi

    echo "$domain_name,$folder_size,$owner,$last_login_info" >> output.csv

done <<< "$email_output"

kill $loading_pid

echo "Output saved to output.csv"

