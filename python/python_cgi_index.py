#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# 脚本名称: python_cgi_index.py
# 　　版本: 1.0.0
# 　　作者: FNOSP/xieguanru
# 　协作者: FNOSP/MR_XIAOBO
# 创建日期: 2025-11-19
# 最后修改: 2025-11-19
# 　　描述: 这个脚本用于演示python脚本的各种注释方式
# 使用方式: 文件重命名，从python_cgi_index.py改成index.cgi
# 　　　　  放置应用包/ui路径下，记得 chmod +x index.cgi 赋权
# 　许可证: MIT

import os
import sys
import urllib.parse
import mimetypes

# 你自己的静态文件根目录
BASE_PATH = "/var/apps/aria2/target/ui"


# ----------------------------------------------------
# 1. 从 REQUEST_URI 里拿到 index.cgi 后面的路径
# ----------------------------------------------------
REQUEST_URI = os.environ.get("REQUEST_URI", "")

# 去掉 query string
URI_NO_QUERY = REQUEST_URI.split("?", 1)[0]

# 默认 REL_PATH
REL_PATH = "/"

# 找到 index.cgi 并切掉前面
if "index.cgi" in URI_NO_QUERY:
    # /xxx/index.cgi/index.html  → /index.html
    REL_PATH = URI_NO_QUERY.split("index.cgi", 1)[1]

# 如果为空或只有 /，就访问 index.html
if REL_PATH == "" or REL_PATH == "/":
    REL_PATH = "/index.html"

# 拼出真实文件路径
TARGET_FILE = BASE_PATH + REL_PATH


# ----------------------------------------------------
# 简单防御：禁止 .. 越级访问
# ----------------------------------------------------
if ".." in TARGET_FILE:
    print("Status: 400 Bad Request")
    print("Content-Type: text/plain; charset=utf-8")
    print("")
    print("Bad Request")
    sys.exit(0)


# ----------------------------------------------------
# 2. 判断文件是否存在
# ----------------------------------------------------
if not os.path.isfile(TARGET_FILE):
    print("Status: 404 Not Found")
    print("Content-Type: text/plain; charset=utf-8")
    print("")
    print(f"404 Not Found: {REL_PATH}")
    sys.exit(0)


# ----------------------------------------------------
# 3. 根据扩展名判断 MIME
# ----------------------------------------------------
ext = TARGET_FILE.split(".")[-1].lower()

mime_map = {
    "html": "text/html; charset=utf-8",
    "htm":  "text/html; charset=utf-8",
    "css":  "text/css; charset=utf-8",
    "js":   "application/javascript; charset=utf-8",
    "jpg":  "image/jpeg",
    "jpeg": "image/jpeg",
    "png":  "image/png",
    "gif":  "image/gif",
    "svg":  "image/svg+xml",
    "txt":  "text/plain; charset=utf-8",
    "log":  "text/plain; charset=utf-8",
}

mime = mime_map.get(ext, "application/octet-stream")


# ----------------------------------------------------
# 4. 输出头 + 文件内容（二进制）
# ----------------------------------------------------
print(f"Content-Type: {mime}")
print("")

with open(TARGET_FILE, "rb") as f:
    sys.stdout.buffer.write(f.read())
