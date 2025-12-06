#!/bin/bash

# --- 配置区 ---
URL="https://www.netflix.com/title/70143836" # 绝命毒师
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
TEMP_BODY=$(mktemp) # 创建临时文件

# 定义颜色
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Suffix="\033[0m"

echo -n -e "\r *Netflix解锁检测  By nfdns.top \n"

# 统一的清理函数
cleanup() {
    rm -f "$TEMP_BODY"
}
trap cleanup EXIT

# 请求页面
STATUS_CODE=$(curl -s -o "$TEMP_BODY" -w "%{http_code}" -L -A "$UA" --max-time 10 "$URL")

# --- 逻辑判断 ---

if [[ "$STATUS_CODE" == "000" ]] || [[ -z "$STATUS_CODE" ]]; then
    echo -e "${Font_Red}检测失败 (网络连接错误)${Font_Suffix}"

elif [[ "$STATUS_CODE" == "404" ]]; then
    echo -e "${Font_Yellow}您目前仅自制 (Originals Only)${Font_Suffix}"

elif [[ "$STATUS_CODE" == "403" ]]; then
    echo -e "${Font_Red}您目前不支持解锁 (Banned)${Font_Suffix}"

elif [[ "$STATUS_CODE" == "200" ]]; then
    # 状态码 200，检查 Body 内容
    
    # 1. 检查是否是虚假 200 (Oh no!)
    if grep -q "Oh no!" "$TEMP_BODY"; then
        echo -e "${Font_Yellow}您目前仅自制 (Originals Only)${Font_Suffix}"
        exit 0
    fi

    # 2. 检查解锁特征
    if grep -q 'property="og:video"' "$TEMP_BODY" || \
       grep -q 'data-uia="episodes"' "$TEMP_BODY" || \
       grep -q 'playableVideo' "$TEMP_BODY"; then
        
        # --- 确认解锁成功，现在才检测地区 (优化速度) ---
        # 尝试访问 login 页面看跳转地址
        REGION_URL=$(curl -fsSI -X GET -A "$UA" --max-time 5 --write-out %{redirect_url} --output /dev/null "https://www.netflix.com/login" 2>/dev/null)
        
        # 提取地区: 从 https://www.netflix.com/jp-en/login 提取 'jp'
        REGION=$(echo "$REGION_URL" | cut -d '/' -f4 | cut -d '-' -f1 | tr '[:lower:]' '[:upper:]')
        
        if [[ -z "$REGION" ]]; then
            REGION="US"
        fi
        
        echo -e "${Font_Green}您目前完整解锁非自制剧 || (解锁地区: ${REGION})${Font_Suffix}"
    else
        # 200 OK 但没有特征码
        echo -e "${Font_Red}检测异常 (ip无法解锁或仅支持自制)${Font_Suffix}"
    fi

else
    # 其他状态码
    echo -e "${Font_Red}检测失败 (状态码: $STATUS_CODE)${Font_Suffix}"
fi
