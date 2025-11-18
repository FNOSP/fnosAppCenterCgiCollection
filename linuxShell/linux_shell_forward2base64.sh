#!/bin/bash
# 脚本名称: index.cgi
# 　　版本: 1.0.0
# 　　作者: FNOSP/MR_XIAOBO
# 创建日期: 2025-11-18
# 最后修改: 2025-11-19
# 　　描述: 这个脚本用于演示Shell脚本的各种注释方式
# 使用方式: 文件重命名，从linux_shell_forward2base64.sh改成index.cgi,放置应用包/ui路径下，记得 chmod +x index.cgi 赋权
# 　许可证: MIT

# --- 安全配置 ---
# 定义允许访问的文件根目录。脚本只会从这个目录下寻找文件。
# 请确保这个路径是绝对路径，并且不包含符号链接。
# 例如，如果你的静态文件在 /var/www/my-site/static，就设置在这里。
DOCUMENT_ROOT="./"

# 默认首页
DEFAULT_FILE="index.html"

# --- 函数定义 ---

# 1. 解析 URL 参数
# 这个函数从环境变量 QUERY_STRING 中解析出指定参数的值。
get_query_param() {
    local param_name="$1"
    # QUERY_STRING 的格式是 "key1=value1&key2=value2..."
    # 我们使用 grep 和 sed 来提取 value
    echo "$QUERY_STRING" | grep -o "\b$param_name=[^&]*" | sed "s/^$param_name=//"
}

# 2. 获取文件的 MIME 类型
# 这个函数根据文件扩展名猜测 Content-Type。
get_content_type() {
    local file_path="$1"
    local ext="${file_path##*.}" # 获取文件扩展名

    case "$ext" in
        html|htm) echo "text/html; charset=UTF-8" ;;
        css) echo "text/css; charset=UTF-8" ;;
        js) echo "application/javascript; charset=UTF-8" ;;
        json) echo "application/json; charset=UTF-8" ;;
        png) echo "image/png" ;;
        jpg|jpeg) echo "image/jpeg" ;;
        gif) echo "image/gif" ;;
        svg) echo "image/svg+xml" ;;
        ico) echo "image/x-icon" ;;
        txt) echo "text/plain; charset=UTF-8" ;;
        # 可以根据需要添加更多类型
        *) echo "application/octet-stream" ;; # 默认二进制流
    esac
}

# 3. 发送 HTTP 错误响应
send_error() {
    local status_code="$1"
    local message="$2"
    echo "Status: $status_code $message"
    echo "Content-Type: text/plain; charset=UTF-8"
    echo ""
    echo "$message"
    exit 0
}

# --- 主逻辑开始 ---

# 检查 DOCUMENT_ROOT 是否存在且为目录
if [ ! -d "$DOCUMENT_ROOT" ]; then
    # 这是一个服务器配置错误，应该返回 500
    echo "Status: 500 Internal Server Error"
    echo "Content-Type: text/plain; charset=UTF-8"
    echo ""
    echo "服务器配置错误：文档根目录 '$DOCUMENT_ROOT' 不存在或不是一个目录。"
    exit 1
fi

# 初始化目标文件路径
target_file="$DOCUMENT_ROOT/$DEFAULT_FILE"

# 解析 forward 参数
forward_param=$(get_query_param "forward")

if [ -n "$forward_param" ]; then
    # 如果 forward 参数存在

    # 对参数值进行 Base64 解码
    # 使用 -d 进行解码，-i 忽略非 Base64 字符
    decoded_path=$(echo "$forward_param" | base64 -d -i 2>/dev/null)

    # 检查解码是否成功 (base64 命令在解码失败时会返回非零退出码)
    if [ $? -ne 0 ]; then
        send_error 400 "Bad Request: Invalid Base64 string."
    fi

    # --- 关键安全检查 ---
    # 防止路径遍历攻击 (Path Traversal)
    # 检查解码后的路径是否包含 '../'
    if [[ "$decoded_path" == *'../'* || "$decoded_path" == '../'* || "$decoded_path" == *'../' ]]; then
        send_error 403 "Forbidden: Path traversal detected."
    fi
    
    # 构建绝对路径
    target_file="$DOCUMENT_ROOT/$decoded_path"
fi

# 检查目标文件是否存在且为普通文件
if [ ! -f "$target_file" ]; then
    send_error 404 "Not Found: The requested file '$target_file' does not exist."
fi

# 检查是否有读取权限
if [ ! -r "$target_file" ]; then
    send_error 403 "Forbidden: Permission denied to read '$target_file'."
fi

# 一切正常，准备发送文件

# 获取并发送 Content-Type
content_type=$(get_content_type "$target_file")
echo "Content-Type: $content_type"
echo "" # 空行分隔头部和内容

# 发送文件内容
# 使用 cat 命令输出文件内容。对于二进制文件也同样有效。
cat "$target_file"

exit 0