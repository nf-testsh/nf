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

command_exists() {
    command -v "$1" > /dev/null 2>&1
}



process() {
    local iface=''
    local xip=''
    local proxy=''
    USE_NIC=''
    NETWORK_TYPE=''
    LANGUAGE=''
    X_FORWARD=''
    USE_PROXY=''

    while [ $# -gt 0 ]; do
        case "$1" in
        -I | --interface)
            local iface="$2"
            USE_NIC="--interface $2"
            shift
            ;;
        -M | --network-type)
            local netType="$2"
            shift
            ;;
        -E | --language)
            LANGUAGE="$2"
            shift
            ;;
        -X | --x-forwarded-for)
            local xip="$2"
            shift
            ;;
        -P | --proxy)
            local proxy="$2"
            shift
            ;;
        -R | --region)
            local regionid="$2"
            shift
            ;;
        *)
            echo -e "${Font_Red}Unknown error while processing options.${Font_Suffix}"
            exit 1
            ;;
        esac
        shift
    done

    if [ -z "$iface" ]; then
        USE_NIC=''
    fi

    if [ -z "$xip" ]; then
        X_FORWARD=''
    fi

    if [ -n "$xip" ]; then
        local xip=$(echo "$xip" | awk '{$1=$1; print}')
        validate_ip_address "$xip"
        local result="$?"
        if [ "$result" == 4 ] || [ "$result" == 6 ]; then
            X_FORWARD="--header X-Forwarded-For:$xip"
        fi
    fi

    if [ -z "$proxy" ]; then
        USE_PROXY=''
    fi

    if [ -n "$proxy" ]; then
        local proxy=$(echo "$proxy" | awk '{$1=$1; print}')
        if validate_proxy "$proxy"; then
            USE_PROXY="-x $proxy"
        fi
    fi

    if [ -z "$netType" ]; then
        NETWORK_TYPE=''
    fi

    if [ -n "$netType" ]; then
        local netType=$(echo "$netType" | awk '{$1=$1; print}')
        if validate_net_type "$netType"; then
            NETWORK_TYPE="$netType"
        fi
    fi

    if [ -z "$LANGUAGE" ]; then
        LANGUAGE='zh'
    fi

    if [ -n "$regionid" ]; then
        if validate_region_id "$regionid"; then
            REGION_ID="$regionid"
        fi
    fi

    CURL_OPTS="$USE_NIC $USE_PROXY $X_FORWARD ${CURL_SSL_CIPHERS_OPT} --max-time 10 --retry 3 --retry-max-time 20"
}

delay() {
    if [ -z $1 ]; then
        exit 1
    fi
    local val=$1
    if [ "$USE_USLEEP" == 1 ]; then
        usleep $(awk 'BEGIN{print '$val' * 1000000}')
        return 0
    fi
    sleep $val
    return 0
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
    local result1=$(curl ${CURL_DEFAULT_OPTS} -fsL 'https://www.netflix.com/title/81280792' -w %{http_code} -o /dev/null -H 'host: www.netflix.com' -H 'accept-language: en-US,en;q=0.9' -H "sec-ch-ua: ${UA_SEC_CH_UA}" -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' -H 'sec-fetch-site: none' -H 'sec-fetch-mode: navigate' -H 'sec-fetch-user: ?1' -H 'sec-fetch-dest: document' --user-agent "${UA_BROWSER}")
    # Breaking bad
    local result2=$(curl ${CURL_DEFAULT_OPTS} -fsL 'https://www.netflix.com/title/70143836' -w %{http_code} -o /dev/null -H 'host: www.netflix.com' -H 'accept-language: en-US,en;q=0.9' -H "sec-ch-ua: ${UA_SEC_CH_UA}" -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' -H 'sec-fetch-site: none' -H 'sec-fetch-mode: navigate' -H 'sec-fetch-user: ?1' -H 'sec-fetch-dest: document' --user-agent "${UA_BROWSER}")

    if [ "${result1}" == '000' ] || [ "$result2" == '000' ]; then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    if [ "$result1" == '404' ] && [ "$result2" == '404' ]; then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Yellow}Originals Only${Font_Suffix}\n"
        return
    fi
    if [ "$result1" == '403' ] || [ "$result2" == '403' ]; then
        echo -n -e "\r Netflix:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
        return
    fi
    if [ "$result1" == '200' ] || [ "$result2" == '200' ]; then
        local tmpresult=$(curl ${CURL_DEFAULT_OPTS} -sL 'https://www.netflix.com/' -H 'accept-language: en-US,en;q=0.9' -H "sec-ch-ua: ${UA_SEC_CH_UA}" -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' -H 'sec-fetch-site: none' -H 'sec-fetch-mode: navigate' -H 'sec-fetch-user: ?1' -H 'sec-fetch-dest: document' --user-agent "${UA_BROWSER}")
        local region=$(echo "$tmpresult" | grep -woP '"requestCountry":{"id":"\K\w\w' | head -n 1)
        echo -n -e "\r Netflix:\t\t\t\t${Font_Green}Yes (Region: ${region})${Font_Suffix}\n"
        return
    fi

    echo -n -e "\r Netflix:\t\t\t\t\t${Font_Red}Failed (Error: ${result1}_${result2})${Font_Suffix}\n"



color_print

check_os_type

check_dependencies

process "$@"

clear

count_run_times

showSupportOS

showScriptTitle

if [ -z "$REGION_ID" ]; then
    inputOptions
fi

download_extra_data

clear

runScript

showGoodbye
