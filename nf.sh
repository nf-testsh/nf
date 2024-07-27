#!/bin/bash

VER='1.0.0'

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

gen_uuid() {
    if [ -f /proc/sys/kernel/random/uuid ]; then
        local genuuid=$(cat /proc/sys/kernel/random/uuid)
        echo "${genuuid}"
        return 0
    fi

    if command_exists uuidgen; then
        local genuuid=$(uuidgen)
        echo "${genuuid}"
        return 0
    fi

    if command_exists powershell && [ "$OS_WINDOWS" == 1 ]; then
        local genuuid=$(powershell -c "[guid]::NewGuid().ToString()")
        echo "${genuuid}"
        return 0
    fi

    return 1
}

gen_random_str() {
    if [ -z "$1" ]; then
        echo -e "${Font_Red}Length missing.${Font_Suffix}"
        exit 1
    fi
    local randomstr=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c "$1")
    echo "${randomstr}"
}

resolve_ip_address() {
    if [ -z "$1" ]; then
        echo -e "${Font_Red}Domain missing.${Font_Suffix}"
        exit 1
    fi
    if [ -z "$2" ]; then
        echo -e "${Font_Red}DNS Record type missing.${Font_Suffix}"
        exit 1
    fi

    local domain="$1"
    local recordType="$2"

    if command_exists nslookup && [ "$OS_WINDOWS" != 1 ]; then
        local nslookupExists=1
    fi
    if command_exists dig; then
        local digExists=1
    fi
    if [ "$OS_IOS" == 1 ]; then
        local nslookupExists=0
        local digExists=0
    fi

    if [ "$nslookupExists" == 1 ]; then
        if [ "$recordType" == 'AAAA' ]; then
            local result=$(nslookup -q=AAAA "${domain}" | grep -woP "Address: \K[\d:a-f]+")
            echo "${result}"
            return
        else
            local result=$(nslookup -q=A "${domain}" | grep -woP "Address: \K[\d.]+")
            echo "${result}"
            return
        fi
    fi
    if [ "$digExists" == 1 ]; then
        if [ "$recordType" == 'AAAA' ]; then
            local result=$(dig +short "${domain}" AAAA)
            echo "${result}"
            return
        else
            local result=$(dig +short "${domain}" A)
            echo "${result}"
            return
        fi
    fi

    if [ "$recordType" == 'AAAA' ]; then
        local pingArgs='-6 -c 1 -w 1 -W 1'
        [ "$OS_ANDROID" == 1 ] && pingArgs='-c 1 -w 1 -W 1'
        local result=$(ping6 ${pingArgs} "${domain}" 2>/dev/null | head -n 1 | grep -woP '\s\(\K[\d:a-f]+')
        echo "${result}"
        return
    else
        local pingArgs='-4 -c 1 -w 1 -W 1'
        [ "$OS_ANDROID" == 1 ] && pingArgs='-c 1 -w 1 -W 1'
        local result=$(ping ${pingArgs} "${domain}" 2>/dev/null | head -n 1 | grep -woP '\s\(\K[\d.]+')
        echo "${result}"
        return
    fi
}

validate_proxy() {
    if [ -z "$1" ]; then
        echo -e "${Font_Red}Param Proxy Address is missing.${Font_Suffix}"
        exit 1
    fi

    local tmpresult=$(echo "$1" | grep -P '^(socks|socks4|socks5|http)://([^:]+:[^@]+@)?(([0-9]{1,3}\.){3}[0-9]{1,3}|(\[[0-9a-fA-F:]+\]|([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|((([0-9a-fA-F]{1,4}:){1,6})|::(([0-9a-fA-F]{1,4}:){1,6}))([0-9a-fA-F]{1,4}))):(0|[1-9][0-9]{0,4})$')
    if [ -z "$tmpresult" ]; then
        echo -e "${Font_Red}Proxy IP invalid.${Font_Suffix}"
        exit 1
    fi

    local port=$(echo "$1" | grep -woP ':\K[0-9]+$')
    if [ "$port" -ge 65535 ]; then
        echo -e "${Font_Red}Proxy Port invalid.${Font_Suffix}"
        exit 1
    fi
}

validate_ip_address() {
    if [ -z "$1" ]; then
        echo -e "${Font_Red}Param IP Address is missing.${Font_Suffix}"
        exit 1
    fi

    if echo "$1" | awk '{$1=$1; print}' | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
        return 4
    fi
    echo "$1" | awk '{$1=$1; print}' | grep -Eq '^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^(([0-9a-fA-F]{1,4}:){1,7}|:):([0-9a-fA-F]{1,4}:){1,7}|:$|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}$|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}$|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}$|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}$|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}$|([0-9a-fA-F]{1,4}:){1}(:[0-9a-fA-F]{1,4}){1,6}$|:(:[0-9a-fA-F]{1,4}){1,7}$|((([0-9a-fA-F]{1,4}:){1,4}:|:):(([0-9a-fA-F]{1,4}:){0,1}[0-9a-fA-F]{1,4}){1,4})$'
    if [ "$?" == 0 ]; then
        return 6
    fi

    return 1
}

validate_intranet() {
    if [ -z "$1" ]; then
        echo -e "${Font_Red}Param missing.${Font_Suffix}"
    fi
    # See https://en.wikipedia.org/wiki/Reserved_IP_addresses
    local tmpresult=$(echo "$1" | grep -E '(^|\s)(10\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])|172\.(1[6-9]|2[0-9]|3[01])\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])|192\.168\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])|100\.([6-9][4-9]|1[0-2][0-7])\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])|169\.254\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])|192\.88\.99\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])|192\.0\.(0|2)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])|198\.(1[89])\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])|198\.51\.100\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])|203\.0\.113\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])|2[23][4-9]\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])|233\.252\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])|(24[0-9]|25[0-5])\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9]))(\s|$)')
    if [ -z "$tmpresult" ]; then
        return 1
    fi

    return 0
}

validate_region_id() {
    if [ -z "$1" ]; then
        echo -e "${Font_Red}Param missing.${Font_Suffix}"
        exit 1
    fi
    local regionid="$1"
    local result=$(echo "$regionid" | grep -E '^[0-9]$|^1[0-1]$|^99$|^66$')
    if [ -z "$result" ]; then
        return 1
    fi
    return 0
}

validate_net_type() {
    if [ -z "$1" ]; then
        echo -e "${Font_Red}Param missing.${Font_Suffix}"
        exit 1
    fi
    local netType="$1"
    local result=$(echo "$netType" | grep -E '^4$|^6$|^0$')
    if [ -z "$result" ]; then
        echo -e "${Font_Red}Invalid Network Type.${Font_Suffix}"
        exit 1
    fi
    return 0
}

check_proxy_connectivity() {
    local result1=$(curl $USE_NIC $USE_PROXY -s 'https://ip.sb' --user-agent "${UA_BROWSER}" )
    local result2=$(curl $USE_NIC $USE_PROXY -s 'https://1.0.0.1/cdn-cgi/trace' --user-agent "${UA_BROWSER}")
    if [ -n "$result1" ] && [ -n "$result2" ]; then
        return 0
    fi

    return 1
}

check_net_connctivity() {
    if [ -z "$1" ]; then
        echo -e "${Font_Red}Param missing.${Font_Suffix}"
        exit 1
    fi

    if [ "$1" == 4 ]; then
        local result1=$(curl -4 ${CURL_OPTS} -fs 'http://www.msftconnecttest.com/connecttest.txt' -w '%{http_code}' -o /dev/null --user-agent "${UA_BROWSER}")
        if [ "$result1" == '200' ]; then
            return 0
        fi
    fi

    if [ "$1" == 6 ]; then
        local result2=$(curl -6 ${CURL_OPTS} -fs 'http://ipv6.msftconnecttest.com/connecttest.txt' -w '%{http_code}' -o /dev/null --user-agent "${UA_BROWSER}")
        if [ "$result2" == '200' ]; then
            return 0
        fi
    fi

    return 1
}

check_os_type() {
    OS_TYPE=''
    local ifLinux=$(uname -a | grep -i 'linux')
    local ifFreeBSD=$(uname -a | grep -i 'freebsd')
    local ifTermux=$(echo "$PWD" | grep -i 'termux')
    local ifMacOS=$(uname -a | grep -i 'Darwin')
    local ifMinGW=$(uname -a | grep -i 'MINGW')
    local ifCygwin=$(uname -a | grep -i 'CYGWIN')
    local ifAndroid=$(uname -a | grep -i 'android')
    local ifiSh=$(uname -a | grep -i '\-ish')

    if [ -n "$ifLinux" ] && [ -z "$ifAndroid" ] && [ -z "$ifiSh" ]; then
        OS_TYPE='linux'
        OS_LINUX=1
        return
    fi
    if [ -n "$ifTermux" ]; then
        OS_TYPE='termux'
        OS_TERMUX=1
        OS_ANDROID=1
        return
    fi
    if [ -n "$ifMacOS" ]; then
        OS_TYPE='macos'
        OS_MACOS=1
        return
    fi
    if [ -n "$ifMinGW" ]; then
        OS_TYPE='msys'
        OS_WINDOWS=1
        return
    fi
    if [ -n "$ifCygwin" ]; then
        OS_TYPE='cygwin'
        OS_WINDOWS=1
        return
    fi
    if [ -n "$ifFreeBSD" ]; then
        OS_TYPE='freebsd'
        OS_FREEBSD=1
        return
    fi
    if [ -n "$ifAndroid" ]; then
        OS_TYPE='android'
        OS_ANDROID=1
        return
    fi
    if [ -n "$ifiSh" ]; then
        OS_TYPE='ish'
        OS_IOS=1
        return
    fi

    echo -e "${Font_Red}Unsupported OS Type.${Font_Suffix}"
    exit 1
}

check_dependencies() {
    CURL_SSL_CIPHERS_OPT=''

    if [ "$OS_TYPE" == 'linux' ]; then
        source /etc/os-release
        if [ -z "$ID" ]; then
            echo -e "${Font_Red}Unsupported Linux OS Type.${Font_Suffix}"
            exit 1
        fi

        case "$ID" in
        debian|devuan|kali)
            OS_NAME='debian'
            PKGMGR='apt'
            ;;
        ubuntu)
            OS_NAME='ubuntu'
            PKGMGR='apt'
            ;;
        centos|fedora|rhel|almalinux|rocky|amzn)
            OS_NAME='rhel'
            PKGMGR='dnf'
            ;;
        arch|archarm)
            OS_NAME='arch'
            PKGMGR='pacman'
            ;;
        alpine)
            OS_NAME='alpine'
            PKGMGR='apk'
            ;;
        *)
            OS_NAME="$ID"
            PKGMGR='apt'
            ;;
        esac
    fi

    if [ -z $(echo 'e' | grep -P 'e' 2>/dev/null) ]; then
        echo -e "${Font_Red}command 'grep' function is incomplete, please install the full version first.${Font_Suffix}"
        exit 1
    fi

    if ! command_exists curl; then
        echo -e "${Font_Red}command 'curl' is missing, please install it first.${Font_Suffix}"
        exit 1
    fi

    if ! gen_uuid >/dev/null; then
        echo -e "${Font_Red}command 'uuidgen' is missing, please install it first.${Font_Suffix}"
        exit 1
    fi

    if ! command_exists openssl; then
        echo -e "${Font_Red}command 'openssl' is missing, please install it first.${Font_Suffix}"
        exit 1
    fi

    if [ "$OS_MACOS" == 1 ]; then
        if ! command_exists md5sum; then
            echo -e "${Font_Red}command 'md5sum' is missing, please install it first.${Font_Suffix}"
            exit 1
        fi
        if ! command_exists sha256sum; then
            echo -e "${Font_Red}command 'sha256sum' is missing, please install it first.${Font_Suffix}"
            exit 1
        fi
    fi

    if [ "$OS_NAME" == 'debian' ] || [ "$OS_NAME" == 'ubuntu' ]; then
        local os_version=$(echo "$VERSION_ID" | tr -d '.')
        if [ "$os_version" == "2004" ] || [ "$os_version" == "10" ] || [ "$os_version" == "11" ]; then
            CURL_SSL_CIPHERS_OPT='-k --ciphers DEFAULT@SECLEVEL=1'
        fi
    fi

    if command_exists usleep; then
        USE_USLEEP=1
    fi
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

get_ip_info() {
    LOCAL_IP_ASTERISK=''
    LOCAL_ISP=''
    local local_ip=$(curl ${CURL_DEFAULT_OPTS} -s https://api64.ipify.org --user-agent "${UA_BROWSER}")
    local get_local_isp=$(curl ${CURL_DEFAULT_OPTS} -s "https://api.ip.sb/geoip/${local_ip}" -H 'accept: */*;q=0.8,application/signed-exchange;v=b3;q=0.7' -H 'accept-language: en-US,en;q=0.9' -H "sec-ch-ua: ${UA_SEC_CH_UA}" -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' -H 'sec-fetch-dest: document' -H 'sec-fetch-mode: navigate' -H 'sec-fetch-site: none' -H 'sec-fetch-user: ?1' -H 'upgrade-insecure-requests: 1' --user-agent "${UA_BROWSER}")

    if [ -z "$local_ip" ]; then
        echo -e "${Font_Red}Failed to Query IP Address.${Font_Suffix}"
    fi
    if [ -z "$get_local_isp" ]; then
        echo -e "${Font_Red}Failed to Query IP Info.${Font_Suffix}"
    fi

    validate_ip_address "$local_ip"
    local resp="$?"
    if [ "$resp" == 4 ]; then
        LOCAL_IP_ASTERISK=$(awk -F"." '{print $1"."$2".*.*"}' <<<"${local_ip}")
    fi
    if [ "$resp" == 6 ]; then
        LOCAL_IP_ASTERISK=$(awk -F":" '{print $1":"$2":"$3":*:*"}' <<<"${local_ip}")
    fi

    LOCAL_ISP=$(echo "$get_local_isp" | grep 'organization' | cut -f4 -d '"')
}

show_region() {
    echo -e "${Font_Yellow} ---${1}---${Font_Suffix}"
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
