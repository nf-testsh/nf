#!/bin/bash

# 终端输出颜色
Green='\033[0;32m'
Red='\033[0;31m'
NC='\033[0m'

# 全局通用参数与请求头 (统一设置 10 秒超时)
UA_BROWSER="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36"

echo "----------------------------------------"
echo " TW流媒体解锁测试 https://nfdns.top/"
echo "----------------------------------------"

# 1. KKTV
function check_KKTV() {
    local res=$(curl -sL -m 10 -A "${UA_BROWSER}" "https://api.kktv.me/v3/ipcheck" -H "accept: application/json")
    [ -z "$res" ] && { echo -e " KKTV:                   ${Red}Failed (Network)${NC}"; return; }
    
    if echo "$res" | grep -q '"country":"TW"'; then
        echo -e " KKTV:                   ${Green}Yes (TW)${NC}"
    else
        echo -e " KKTV:                   ${Red}No${NC}"
    fi
}

# 2. LiTV
function check_LiTV() {
    local res=$(curl -sL -m 10 -A "${UA_BROWSER}" -X POST 'https://www.litv.tv/api/get-urls' \
        -H 'content-type: application/json' -H 'origin: https://www.litv.tv' \
        -d '{"AssetId":"iNEWS","MediaType":"channel"}')
    [ -z "$res" ] && { echo -e " LiTV:                   ${Red}Failed (Network)${NC}"; return; }
 
    local error_code=$(echo "$res" | grep -oP '"code":\s*\K\d+')
    if [ "$error_code" = "42000026" ]; then
        echo -e " LiTV:                   ${Green}Yes${NC}"
    elif [ "$error_code" = "42000087" ]; then
        echo -e " LiTV:                   ${Red}No${NC}"
    else
        echo -e " LiTV:                   ${Red}Failed (Code: ${error_code:-unknown})${NC}"
    fi
}

# 3. MyVideo
function check_MyVideo() {
    local res=$(curl -sL -m 10 -A "${UA_BROWSER}" -I "https://www.myvideo.net.tw/")
    [ -z "$res" ] && { echo -e " MyVideo:                ${Red}Failed (Network)${NC}"; return; }
    
    if echo "$res" | grep -qi 'HTTP/1.1 403'; then
        echo -e " MyVideo:                ${Red}No${NC}"
    else
        echo -e " MyVideo:                ${Green}Yes${NC}"
    fi
}

# 4. 4GTV
function check_4GTV() {
    local code=$(curl -sS -o /dev/null -I -m 5 -A "${UA_BROWSER}" \
        -w "%{http_code}" "https://www.4gtv.tv/channel")

    case "$code" in
        200) echo -e " 4GTV:                   ${Green}Yes (TW)${NC}" ;;
        403) echo -e " 4GTV:                   ${Red}No${NC}" ;;
        000) echo -e " 4GTV:                   ${Red}Failed (Network)${NC}" ;;
        *)   echo -e " 4GTV:                   ${Red}Failed (Code: ${code})${NC}" ;;
    esac
}

# 5. LINE TV
function check_LINETV() {
    local res=$(curl -sL -m 10 -A "${UA_BROWSER}" "https://www.linetv.tw/api/geo")
    [ -z "$res" ] && { echo -e " LINE TV:                ${Red}Failed (Network)${NC}"; return; }
    
    if echo "$res" | grep -q '"country":"TW"'; then
        echo -e " LINE TV:                ${Green}Yes (TW)${NC}"
    else
        echo -e " LINE TV:                ${Red}No${NC}"
    fi
}

# 6. Hami Video
function check_HamiVideo() {
    local res=$(curl -sL -m 10 -A "${UA_BROWSER}" "https://hamivideo.hinet.net/index.do")
    [ -z "$res" ] && { echo -e " Hami Video:             ${Red}Failed (Network)${NC}"; return; }
    
    if echo "$res" | grep -q '只限台灣地區\|The service is only available in Taiwan'; then
        echo -e " Hami Video:             ${Red}No${NC}"
    else
        echo -e " Hami Video:             ${Green}Yes${NC}"
    fi
}

# 7. CatchPlay+
function check_CatchPlay() {
    local res=$(curl -sL -m 10 -A "${UA_BROWSER}" "https://sunapi.catchplay.com/geo")
    [ -z "$res" ] && { echo -e " CatchPlay+:             ${Red}Failed (Network)${NC}"; return; }
    
    if echo "$res" | grep -qi "UnauthorizedException\|unauthorized\|\"countryCode\":\"TW\"\|\"country\":\"TW\""; then
        echo -e " CatchPlay+:             ${Green}Yes (TW)${NC}"
    else
        echo -e " CatchPlay+:             ${Red}No${NC}"
    fi
}

# 8. HBO Max
function check_HBOMax() {
    local hdr=$(curl -sS -o /dev/null -D - -m 10 -A "${UA_BROWSER}" -L "https://www.hbomax.com/")
    [ -z "$hdr" ] && { echo -e " HBO Max:                ${Red}Failed (Network)${NC}"; return; }

    local region=$(echo "$hdr" | grep -woiP 'countryCode=\K[A-Za-z]{2}' | head -n 1 | tr a-z A-Z)
    if [ -n "$region" ]; then
        echo -e " HBO Max:                ${Green}Yes (${region})${NC}"
    else
        echo -e " HBO Max:                ${Red}No${NC}"
    fi
}

# 9. Bahamut Anime
function check_Bahamut() {
    local device_res=$(curl -sL -m 10 -A "${UA_BROWSER}" "https://ani.gamer.com.tw/ajax/getdeviceid.php")
    [ -z "$device_res" ] && { echo -e " Bahamut Anime:          ${Red}Failed (Network)${NC}"; return; }
    
    local device_id=$(echo "$device_res" | grep -oP '"deviceid":"\K[^"]+')
    local res=$(curl -sL -m 10 -A "${UA_BROWSER}" "https://ani.gamer.com.tw/ajax/token.php?sn=14667&device=${device_id}")
    
    if echo "$res" | grep -q '僅限台灣地區'; then
        echo -e " Bahamut Anime:          ${Red}No${NC}"
    else
        echo -e " Bahamut Anime:          ${Green}Yes${NC}"
    fi
}

# 10. Bilibili TW
function check_BilibiliTW() {
    local res=$(curl -sL -m 10 -A "${UA_BROWSER}" "https://api.bilibili.com/pgc/player/web/playurl?avid=50762638&cid=100270702&qn=0&type=&otype=json&ep_id=268176&fourk=1&fnver=0&fnval=16" -H 'referer: https://www.bilibili.com')
    [ -z "$res" ] && { echo -e " Bilibili TW:            ${Red}Failed (Network)${NC}"; return; }
    
    if echo "$res" | grep -q '"code":0\|"code":-404'; then
        echo -e " Bilibili TW:            ${Green}Yes${NC}"
    else
        echo -e " Bilibili TW:            ${Red}No${NC}"
    fi
}

# 11. ofiii
function check_ofiii() {
    local res=$(curl -sL -m 10 -A "${UA_BROWSER}" "https://www.ofiii.com/")
    [ -z "$res" ] && { echo -e " ofiii:                  ${Red}Failed (Network)${NC}"; return; }
    
    if echo "$res" | grep -qi 'HTTP/1.1 403\|不提供服務\|只限台灣地區'; then
        echo -e " ofiii:                  ${Red}No${NC}"
    else
        echo -e " ofiii:                  ${Green}Yes${NC}"
    fi
}

# 12. Friday Video
function check_FridayVideo() {
    local res=$(curl -sL -m 10 -A "${UA_BROWSER}" -X POST "https://video.friday.tw/api2/streaming/get" \
        -H "content-type: application/x-www-form-urlencoded" -d "streamingType=2&contentType=1&contentId=116347")
    [ -z "$res" ] && { echo -e " Friday Video:           ${Red}Failed (Network)${NC}"; return; }
    
    if echo "$res" | grep -q '授權區域限制'; then
        echo -e " Friday Video:           ${Red}No${NC}"
    else
        echo -e " Friday Video:           ${Green}Yes${NC}"
    fi
}

# 顺序执行所有检测
check_KKTV
check_LiTV
check_MyVideo
check_4GTV
check_LINETV
check_HamiVideo
check_CatchPlay
check_HBOMax
check_Bahamut
check_BilibiliTW
check_ofiii
check_FridayVideo

echo "----------------------------------------"
