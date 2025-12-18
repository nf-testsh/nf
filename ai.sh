#!/bin/bash

# --- 配置 ---
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Suffix="\033[0m"
# 使用最新版 Chrome UA
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"

# --- 核心请求函数 (增强 Header) ---
curl_get() {
    curl -4 --user-agent "${UA_Browser}" \
         -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" \
         -H "Accept-Language: en-US,en;q=0.9" \
         -s --max-time 10 "$1"
}

# --- ChatGPT ---
Check_ChatGPT() {
    local ios_result=$(curl_get "https://ios.chat.openai.com/public-api/mobile/server_status/v1")
    local trace_result=$(curl_get "https://chatgpt.com/cdn-cgi/trace")
    local region=$(echo "$trace_result" | grep "loc=" | cut -d= -f2)
    local cf_details=$(echo "$ios_result" | sed -n 's/.*"cf_details"\s*:\s*"\([^"]*\)".*/\1/p')

    if echo "$ios_result" | grep -qE "unsupported_country|vpn_detected"; then
        echo -e "ChatGPT:\t\t${Font_Red}No${Font_Suffix}"
        return
    fi
    
    if [[ "$cf_details" == *"(1)"* ]] || [[ "$cf_details" == *"(2)"* ]]; then
        echo -e "ChatGPT:\t\t${Font_Yellow}Web Only (ISP Blocked)${Font_Suffix}"
        return
    fi

    if [ -n "$region" ]; then
        echo -e "ChatGPT:\t\t${Font_Green}Yes (Region: ${region})${Font_Suffix}"
    elif [[ "$ios_result" == *"status"* ]]; then
        echo -e "ChatGPT:\t\t${Font_Green}Yes${Font_Suffix}"
    else
        echo -e "ChatGPT:\t\t${Font_Red}No${Font_Suffix}"
    fi
}

# --- Sora (稳定性增强) ---
Check_Sora() {
    local region=""
    
    # 方法1：Trace 接口重试机制 (最多尝试 3 次)
    for i in {1..3}; do
        local trace_result=$(curl_get "https://sora.com/cdn-cgi/trace")
        region=$(echo "$trace_result" | grep "loc=" | cut -d= -f2)
        
        # 如果成功获取到地区，立即跳出循环
        if [ -n "$region" ]; then
            break
        fi
        # 失败则等待 0.5 秒后重试
        sleep 0.5
    done

    # 判定逻辑
    if [ -n "$region" ]; then
        echo -e "Sora:\t\t\t${Font_Green}Yes (Region: ${region})${Font_Suffix}"
        return
    fi

    # 方法2：降级检测 (如果 Trace 3次都失败，检查主页 HTTP 状态码)
    local login_check=$(curl -4 --user-agent "${UA_Browser}" -sLI --max-time 10 -o /dev/null -w "%{http_code}" "https://sora.com/")
    if [[ "$login_check" == "200" ]] || [[ "$login_check" == "302" ]]; then
        echo -e "Sora:\t\t\t${Font_Green}Yes${Font_Suffix}"
    else
        echo -e "Sora:\t\t\t${Font_Red}No${Font_Suffix}"
    fi
}

# --- Gemini ---
Check_Gemini() {
    local tmpresult=$(curl_get "https://gemini.google.com")
    local countrycode=$(echo "$tmpresult" | sed -n 's/.*,2,1,200,"\([A-Z]\{2,3\}\)".*/\1/p' | head -n 1)
    
    if [ -z "$tmpresult" ]; then
        echo -e "Google Gemini:\t\t${Font_Red}Failed${Font_Suffix}"
        return
    fi

    if echo "$tmpresult" | grep -q '45631641,null,true'; then
        echo -e "Google Gemini:\t\t${Font_Green}Yes (Region: ${countrycode:-Unknown})${Font_Suffix}"
    elif [[ -n "$countrycode" ]] && [[ "$countrycode" != "CN" ]]; then
        echo -e "Google Gemini:\t\t${Font_Green}Yes (Region: $countrycode)${Font_Suffix}"
    else
        echo -e "Google Gemini:\t\t${Font_Red}No${Font_Suffix}"
    fi
}

# --- Claude ---
Check_Claude() {
    local response=$(curl -4 -s -L -A "${UA_Browser}" -o /dev/null -w '%{url_effective}' --max-time 10 "https://claude.ai/login")
    
    if [[ "$response" == *"claude.ai/login"* ]] || [[ "$response" == "https://claude.ai/" ]]; then
        echo -e "Claude AI:\t\t${Font_Green}Yes${Font_Suffix}"
    elif [[ "$response" == *"unavailable"* ]]; then
        echo -e "Claude AI:\t\t${Font_Red}No${Font_Suffix}"
    else
        echo -e "Claude AI:\t\t${Font_Red}No${Font_Suffix}"
    fi
}

# --- Copilot (极简版) ---
Check_Copilot() {
    # 仅检测可用性，不显示地区
    local api_res=$(curl_get "https://copilot.microsoft.com/turing/conversation/chats?bundleVersion=1.1342.3-cplt.12")
    local web_res=$(curl_get "https://copilot.microsoft.com/")

    if echo "$api_res" | grep -q '"value":"Success"'; then
        echo -e "Microsoft Copilot:\t${Font_Green}Yes${Font_Suffix}"
    elif echo "$web_res" | grep -iqE "Edge_C_Chat|Copilot"; then
        echo -e "Microsoft Copilot:\t${Font_Green}Yes${Font_Suffix}"
    else
        echo -e "Microsoft Copilot:\t${Font_Red}No${Font_Suffix}"
    fi
}

# --- 执行 ---
echo "-------------------------------------"
echo -e "*AI解锁检测 By nfdns.top"
Check_ChatGPT
Check_Sora
Check_Gemini
Check_Claude
Check_Copilot
echo "-------------------------------------"
