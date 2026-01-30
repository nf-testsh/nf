#!/bin/bash

# --- 配置区 ---
URL="https://www.netflix.com/title/70143836" # 绝命毒师
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Suffix="\033[0m"

# --- 核心检测函数 ---
Check_Netflix_Core() {
    local IP_VER=$1 
    local LABEL=""
    
    if [[ "$IP_VER" == "-4" ]]; then
        LABEL="[IPv4]"
    else
        LABEL="[IPv6]"
    fi

 
    local TEMP_BODY=$(mktemp)
    local STATUS_CODE=$(curl "$IP_VER" -r 0-10000 --no-keepalive -s -o "$TEMP_BODY" -w "%{http_code}" -L -A "$UA" --connect-timeout 5 --max-time 10 "$URL")

    if [[ "$STATUS_CODE" == "000" ]] || [[ -z "$STATUS_CODE" ]]; then
        echo -e "${LABEL} ${Font_Red}检测失败 (网络连接错误)${Font_Suffix}"

    elif [[ "$STATUS_CODE" == "404" ]]; then
        echo -e "${LABEL} ${Font_Yellow}您目前仅自制 (Originals Only)${Font_Suffix}"

    elif [[ "$STATUS_CODE" == "403" ]]; then
        echo -e "${LABEL} ${Font_Red}您目前不支持解锁 (Banned)${Font_Suffix}"

    elif [[ "$STATUS_CODE" == "200" ]]; then

        if grep -q "Oh no!" "$TEMP_BODY"; then
            echo -e "${LABEL} ${Font_Yellow}您目前仅自制 (Originals Only)${Font_Suffix}"
            rm -f "$TEMP_BODY"
            return
        fi

        if grep -q 'property="og:video"' "$TEMP_BODY" || \
           grep -q 'data-uia="episodes"' "$TEMP_BODY" || \
           grep -q 'playableVideo' "$TEMP_BODY"; then
            
            local REGION_URL=$(curl "$IP_VER" -fsSI -X GET -A "$UA" --max-time 5 --write-out %{redirect_url} --output /dev/null "https://www.netflix.com/login" 2>/dev/null)
            
            local REGION=$(echo "$REGION_URL" | cut -d '/' -f4 | cut -d '-' -f1 | tr '[:lower:]' '[:upper:]')
            
            if [[ -z "$REGION" ]]; then
                REGION="US"
            fi
            
            echo -e "${LABEL} ${Font_Green}您目前完整解锁非自制剧 || (解锁地区: ${REGION})${Font_Suffix}"
        else
            echo -e "${LABEL} ${Font_Red}您目前不支持解锁或仅支持自制${Font_Suffix}"
        fi
    else
        echo -e "${LABEL} ${Font_Red}检测异常(状态码: $STATUS_CODE)${Font_Suffix}"
    fi
    rm -f "$TEMP_BODY"
}

# --- 主程序执行 ---

echo "-------------------------------------"
echo -e "*Netflix解锁检测 By nfdns.top"
echo "-------------------------------------"

Check_Netflix_Core "-4"

if curl -6 -s --head --max-time 3 "http://ipv6.google.com" > /dev/null 2>&1; then
    Check_Netflix_Core "-6"
fi

echo "-------------------------------------"
