#!/bin/bash

UA_BROWSER="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"
UA_SEC_CH_UA='"Google Chrome";v="125", "Chromium";v="125", "Not.A/Brand";v="24"'
UA_ANDROID="Mozilla/5.0 (Linux; Android 10; Pixel 4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36"

color_print() {
    Font_Black="\033[30m"
    Font_Red="\033[31m"
    Font_Green="\033[32m"
    Font_Yellow="\033[33m"
    Font_Blue="\033[34m"
    Font_Purple="\033[35m"
    Font_SkyBlue="\033[36m"
    Font_White="\033[37m"
    Font_Suffix="\033[0m"
}



count_run_times() {
    local tmpresult=$(curl ${CURL_OPTS} -s "https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fcheck.unclock.media&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=visit&edge_flat=false")
    TODAY_RUN_TIMES=$(echo "$tmpresult" | tail -3 | head -n 1 | awk '{print $5}')
    TOTAL_RUN_TIMES=$(($(echo "$tmpresult" | tail -3 | head -n 1 | awk '{print $7}') + 2527395))
}

download_extra_data() {
    MEDIA_COOKIE=$(curl ${CURL_OPTS} -s "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/cookies")
    IATACODE=$(curl ${CURL_OPTS} -s "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/reference/IATACode.txt")
    IATACODE2=$(curl ${CURL_OPTS} -s "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/reference/IATACode2.txt")
    if [ -z "$MEDIA_COOKIE" ] || [ -z "$IATACODE" ] || [ -z "$IATACODE2" ]; then
        echo -e "${Font_Red}Extra data download failed.${Font_Suffix}"
        delay 3
    fi
}


    # LEGO Ninjago
 result1=$(curl ${CURL_DEFAULT_OPTS} -fsL 'https://www.netflix.com/title/81280792' -w %{http_code} -o /dev/null -H 'host: www.netflix.com' -H 'accept-language: en-US,en;q=0.9' -H "sec-ch-ua: ${UA_SEC_CH_UA}" -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' -H 'sec-fetch-site: none' -H 'sec-fetch-mode: navigate' -H 'sec-fetch-user: ?1' -H 'sec-fetch-dest: document' --user-agent "${UA_BROWSER}")
    # Breaking bad
 result2=$(curl ${CURL_DEFAULT_OPTS} -fsL 'https://www.netflix.com/title/70143836' -w %{http_code} -o /dev/null -H 'host: www.netflix.com' -H 'accept-language: en-US,en;q=0.9' -H "sec-ch-ua: ${UA_SEC_CH_UA}" -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' -H 'sec-fetch-site: none' -H 'sec-fetch-mode: navigate' -H 'sec-fetch-user: ?1' -H 'sec-fetch-dest: document' --user-agent "${UA_BROWSER}")

    if [ "${result1}" == '000' ] || [ "$result2" == '000' ]; then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    fi
    if [ "$result1" == '404' ] && [ "$result2" == '404' ]; then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Yellow}Originals Only${Font_Suffix}\n"
    fi
    if [ "$result1" == '403' ] || [ "$result2" == '403' ]; then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    fi
    if [ "$result1" == '200' ] || [ "$result2" == '200' ]; then
         tmpresult=$(curl ${CURL_DEFAULT_OPTS} -sL 'https://www.netflix.com/' -H 'accept-language: en-US,en;q=0.9' -H "sec-ch-ua: ${UA_SEC_CH_UA}" -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' -H 'sec-fetch-site: none' -H 'sec-fetch-mode: navigate' -H 'sec-fetch-user: ?1' -H 'sec-fetch-dest: document' --user-agent "${UA_BROWSER}")
         region=$(echo "$tmpresult" | grep -woP '"requestCountry":{"id":"\K\w\w' | head -n 1)
        echo -n -e "\r Netflix:\t\t\t\t${Font_Green}Yes (Region: ${region})${Font_Suffix}\n"
    fi

    echo -n -e "\r Netflix:\t\t\t\t\t${Font_Red}Failed (Error: ${result1}_${result2})${Font_Suffix}\n"
