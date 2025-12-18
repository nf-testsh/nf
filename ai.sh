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

UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"

# --- 依赖检查 ---
if ! command -v jq &> /dev/null; then
    echo -e "${Font_Red}Error: 'jq' is not installed.${Font_Suffix}"
    exit 1
fi

# --- ChatGPT 检测 ---
function MediaUnlockTest_ChatGPT() {
    echo -e "Checking ChatGPT..."
    local tmpresult=$(curl -4 --user-agent "${UA_Browser}" -SsLI --max-time 10 "https://chatgpt.com" 2>&1)
    local tmpresult1=$(curl -4 --user-agent "${UA_Browser}" -SsL --max-time 10 "https://ios.chat.openai.com" 2>&1)
    
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -e "\r ChatGPT:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}"
        return
    fi

    local cf_details=$(echo "$tmpresult1" | jq .cf_details 2>/dev/null)
    if [[ "$tmpresult" == *"location"* ]]; then
        local region1=$(curl -4 -s --max-time 5 "https://chatgpt.com/cdn-cgi/trace" | grep "loc=" | awk -F= '{print $2}')
        if [[ "$cf_details" == *"(1)"* ]] || [[ "$cf_details" == *"(2)"* ]]; then
            echo -e "\r ChatGPT:\t\t\t\t${Font_Yellow}Web Only (Disallowed ISP)${Font_Suffix}"
        else
            echo -e "\r ChatGPT:\t\t\t\t${Font_Green}Yes (Region: ${region1:-Unknown})${Font_Suffix}"
        fi
    else
        echo -e "\r ChatGPT:\t\t\t\t${Font_Red}No${Font_Suffix}"
    fi
}

# --- Sora 检测 ---
function MediaUnlockTest_Sora() {
    echo -e "Checking Sora..."
    local tmpresult=$(curl -4 --user-agent "${UA_Browser}" -SsLI --max-time 10 "https://sora.com" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -e "\r Sora:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}"
        return
    fi
    if [[ "$tmpresult" == *"location"* ]]; then
        local region1=$(curl -4 -s --max-time 5 "https://sora.com/cdn-cgi/trace" | grep "loc=" | awk -F= '{print $2}')
        echo -e "\r Sora:\t\t\t\t\t${Font_Green}Yes (Region: ${region1:-Unknown})${Font_Suffix}"
    else
        echo -e "\r Sora:\t\t\t\t\t${Font_Red}No${Font_Suffix}"
    fi
}

# --- Gemini 检测 ---
function AIUnlockTest_Gemini_location() {
    echo -e "Checking Google Gemini..."
    local tmpresult=$(curl -4 --user-agent "${UA_Browser}" -sL "https://gemini.google.com" --max-time 10)
    if [[ "$tmpresult" == "" ]]; then
        echo -e "\r Google Gemini:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}"
        return
    fi
    # 查找地区代码特征
    local countrycode=$(echo "$tmpresult" | grep -o ',2,1,200,"[A-Z]\{3\}"' | head -n 1 | sed 's/,2,1,200,"//;s/"//')
    if echo "$tmpresult" | grep -q '45631641,null,true'; then
        echo -e "\r Google Gemini:\t\t\t\t${Font_Green}Yes (Region: ${countrycode:-Unknown})${Font_Suffix}"
    else
        echo -e "\r Google Gemini:\t\t\t\t${Font_Red}No${Font_Suffix}"
    fi
}

# --- Claude 检测 ---
function AIUnlockTest_Claude() {
    echo -e "Checking Claude AI..."
    local response=$(curl -4 -s -L -A "${UA_Browser}" -o /dev/null -w '%{url_effective}' --max-time 10 "https://claude.ai/")
    if [ -z "$response" ]; then
        echo -e "\r Claude:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}"
        return
    fi
    if [[ "$response" == "https://claude.ai/" ]]; then
        echo -e "\r Claude:\t\t\t\t${Font_Green}Yes${Font_Suffix}"
    elif [[ "$response" == *"unavailable-in-region"* ]]; then
        echo -e "\r Claude:\t\t\t\t${Font_Red}No${Font_Suffix}"
    else
        echo -e "\r Claude:\t\t\t\t${Font_Yellow}Unknown${Font_Suffix}"
    fi
}

# --- Copilot 检测 ---
function AIUnlockTest_Copilot() {
    echo -e "Checking Microsoft Copilot..."
    # 获取主页和响应头
    local tmp=$(curl -4 -sS -i -L -A "${UA_Browser}" --max-time 10 "https://copilot.microsoft.com/" 2>&1)
    
    if [[ "$tmp" == "curl"* ]]; then
        echo -e "\r Microsoft Copilot:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}"
        return
    fi

    # 尝试从多个字段提取地区
    local region=$(echo "$tmp" | grep -oEi 'RevIpCC:"([A-Z]{2})"' | head -n 1 | cut -d'"' -f2)
    # 如果源码没有，尝试从 X-MSEdge-ClientID 等头信息或跳转特征判断（增强逻辑）
    if [ -z "$region" ]; then
        region=$(echo "$tmp" | grep -i "location:" | grep -oEi "/[a-z]{2}-[a-z]{2}/" | head -n 1 | tr -d '/' | cut -d'-' -f2)
    fi

    # 判定支持情况
    if echo "$tmp" | grep -iq "Edge_C_Chat" || echo "$tmp" | grep -iq "Copilot"; then
        echo -e "\r Microsoft Copilot:\t\t\t${Font_Green}Yes (Region: ${region^^:-Unknown})${Font_Suffix}"
    else
        echo -e "\r Microsoft Copilot:\t\t\t${Font_Red}No (Region: ${region^^:-Unknown})${Font_Suffix}"
    fi
}

# --- 主程序执行 ---
echo "-------------------------------------"
echo -e "*AI解锁检测 By nfdns.top"
MediaUnlockTest_ChatGPT
MediaUnlockTest_Sora
AIUnlockTest_Gemini_location
AIUnlockTest_Claude
AIUnlockTest_Copilot
echo "-------------------------------------"
