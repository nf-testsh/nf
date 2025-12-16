#!/bin/bash

# --- 基础配置 ---
shopt -s expand_aliases
Font_Black="\033[30m"
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_Suffix="\033[0m"

UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36 Edg/112.0.1722.64"
UA_Dalvik="Dalvik/2.1.0 (Linux; U; Android 9; ALP-AL00 Build/HUAWEIALP-AL00)"

# --- 依赖检查 ---
if ! command -v jq &> /dev/null; then
    echo -e "${Font_Red}Error: 'jq' is not installed.${Font_Suffix}"
    echo -e "Please install it using: apt-get install jq -y (Debian/Ubuntu) or yum install jq -y (CentOS)"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo -e "${Font_Red}Error: 'curl' is not installed.${Font_Suffix}"
    exit 1
fi

# --- ChatGPT 检测函数 ---
function MediaUnlockTest_ChatGPT() {
    echo -e "Checking ChatGPT..."
    # 尝试连接 chatgpt.com
    local tmpresult=$(curl -4 --user-agent "${UA_Browser}" -SsLI --max-time 10 "https://chatgpt.com" 2>&1)
    # 尝试连接 ios 接口 (用于辅助判断)
    local tmpresult1=$(curl -4 --user-agent "${UA_Browser}" -SsL --max-time 10 "https://ios.chat.openai.com" 2>&1)
    
    # 网络连接失败检测
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r ChatGPT:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    # 尝试解析 Cloudflare 详情 (如果是非 JSON 响应，忽略错误)
    local cf_details=$(echo "$tmpresult1" | jq .cf_details 2>/dev/null)

    local result1=$(echo "$tmpresult" | grep 'location')
    
    if [ ! -n "$result1" ]; then
        # 没有 Location 头，通常意味着直接返回了 200 或者被拦截
        if [[ "$tmpresult1" == *"blocked_why_headline"* ]]; then
            echo -n -e "\r ChatGPT:\t\t\t\t${Font_Red}No (Blocked)${Font_Suffix}\n"
            return
        fi
        if [[ "$tmpresult1" == *"unsupported_country_region_territory"* ]]; then
            echo -n -e "\r ChatGPT:\t\t\t\t${Font_Red}No (Unsupported Region)${Font_Suffix}\n"
            return
        fi
        if [[ "$cf_details" == *"(1)"* ]]; then
            echo -n -e "\r ChatGPT:\t\t\t\t${Font_Red}No (Disallowed ISP[1])${Font_Suffix}\n"
            return
        fi
        if [[ "$cf_details" == *"(2)"* ]]; then
            echo -n -e "\r ChatGPT:\t\t\t\t${Font_Red}No (Disallowed ISP[2])${Font_Suffix}\n"
            return
        fi
        # 默认失败
        echo -n -e "\r ChatGPT:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        # 有 Location 头，通常是跳转到登录页或 CDN 验证通过
        local region1=$(curl -4 --user-agent "${UA_Browser}" -SsL --max-time 10 "https://chatgpt.com/cdn-cgi/trace" 2>&1 | grep "loc=" | awk -F= '{print $2}')
        
        if [[ "$cf_details" == *"(1)"* ]]; then
            echo -n -e "\r ChatGPT:\t\t\t\t${Font_Yellow}Web Only (Disallowed ISP[1])${Font_Suffix}\n"
            return
        fi
        if [[ "$cf_details" == *"(2)"* ]]; then
            echo -n -e "\r ChatGPT:\t\t\t\t${Font_Yellow}Web Only (Disallowed ISP[2])${Font_Suffix}\n"
            return
        fi
        
        if [ -n "$region1" ]; then
             echo -n -e "\r ChatGPT:\t\t\t\t${Font_Green}Yes (Region: ${region1})${Font_Suffix}\n"
        else
             echo -n -e "\r ChatGPT:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        fi
    fi
}

# --- Sora 检测函数 ---
function MediaUnlockTest_Sora() {
    echo -e "Checking Sora..."
    local tmpresult=$(curl -4 --user-agent "${UA_Browser}" -SsLI --max-time 10 "https://sora.com" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Sora:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    
    local result1=$(echo "$tmpresult" | grep 'location')
    if [ ! -n "$result1" ]; then
        echo -n -e "\r Sora:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        local region1=$(curl -4 --user-agent "${UA_Browser}" -SsL --max-time 10 "https://sora.com/cdn-cgi/trace" 2>&1 | grep "loc=" | awk -F= '{print $2}')
        if [ -n "$region1" ]; then
            echo -n -e "\r Sora:\t\t\t\t\t${Font_Green}Yes (Region: ${region1})${Font_Suffix}\n"
        else
            echo -n -e "\r Sora:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
        fi
    fi
}

# --- Gemini 检测函数 ---
function AIUnlockTest_Gemini_location() {
    echo -e "Checking Google Gemini..."
    # 这里的 POST 数据和接口可能会随 Google 更新而失效
    local tmp=$(curl -4 --user-agent "${UA_Browser}" -SsL --max-time 10 'https://gemini.google.com/_/BardChatUi/data/batchexecute' -H 'accept-language: en-US' --data-raw 'f.req=[[["K4WWud","[[0],[\"en-US\"]]",null,"generic"]]]' 2>&1)
    
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r Google Gemini Location:\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    
    # 尝试提取地区代码
    local region=$(echo "$tmp" | grep K4WWud | sed 's/\\"/\"/g' | grep -Eo '\["([A-Z]{2})","S' | cut -d '"' -f 2)
    
    if [ -n "$region" ]; then
        echo -n -e "\r Google Gemini Location:\t\t${Font_Green}Yes (Region: ${region})${Font_Suffix}\n"
    else
        # 尝试另一种提取方式，或者判定为 No
        echo -n -e "\r Google Gemini Location:\t\t${Font_Red}No / Unknown${Font_Suffix}\n"
    fi
}

# --- Copilot 检测函数 ---
function AIUnlockTest_Copilot() {
    echo -e "Checking Microsoft Copilot..."
    local tmp=$(curl -4 --user-agent "${UA_Browser}" -SsL --max-time 10 "https://copilot.microsoft.com/" 2>&1)
    # Copilot 的 API 经常变动，这里的检测仅供参考
    local tmp2=$(curl -4 --user-agent "${UA_Browser}" -SsL --max-time 10 "https://copilot.microsoft.com/turing/conversation/chats?bundleVersion=1.1342.3-cplt.12" 2>&1)
    
    if [[ "$tmp" == "curl"* ]]; then
        echo -n -e "\r Microsoft Copilot:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    
    # 屏蔽 jq 错误，防止脚本崩溃
    local result=$(echo "$tmp2" | jq .result.value 2>/dev/null | tr -d '"')
    local region=$(echo "$tmp" | sed -n 's/.*RevIpCC:"\([^"]*\)".*/\1/p')
    
    if [[ "$result" == "Success" ]]; then
        echo -n -e "\r Microsoft Copilot:\t\t\t${Font_Green}Yes (Region: ${region^^})${Font_Suffix}\n"
    else 
        # 即使 API 返回非 Success，如果有 Region 代码，通常也意味着可以访问首页
        if [ -n "$region" ]; then
             echo -n -e "\r Microsoft Copilot:\t\t\t${Font_Yellow}Maybe (Region: ${region^^}) - API Check Failed${Font_Suffix}\n"
        else
             echo -n -e "\r Microsoft Copilot:\t\t\t${Font_Red}No${Font_Suffix}\n"
        fi
    fi
}

# --- 主程序执行 ---
echo "-------------------------------------"
echo -n -e "\r *AI解锁检测  By nfdns.top \n"
MediaUnlockTest_ChatGPT
MediaUnlockTest_Sora
AIUnlockTest_Gemini_location
AIUnlockTest_Copilot
echo "-------------------------------------"
