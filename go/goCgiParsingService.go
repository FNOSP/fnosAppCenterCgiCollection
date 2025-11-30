package main

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

/**
 * @ClassName:  goCgiParsingService
 * @Version:    1.0.0
 * @Author:     Jankin Wu (based on MR_XIAOBO)
 * @CreateTime: 2025/11/30
 * @Statement:  用于演示Go如何处理CGI并对请求的内容进行解析
 * @HowToUse:   go build goCgiParsingService.go
 * @License:    MIT
 */

var mimeTypes = map[string]string{
	".html": "text/html; charset=UTF-8",
	".htm":  "text/html; charset=UTF-8",
	".css":  "text/css; charset=UTF-8",
	".js":   "application/javascript; charset=UTF-8",
	".png":  "image/png",
	".jpg":  "image/jpeg",
	".jpeg": "image/jpeg",
	".gif":  "image/gif",
	".ico":  "image/x-icon",
	".txt":  "text/plain; charset=UTF-8",
}

func main() {
	// 1. 获取 CGI 环境变量
	requestUri := os.Getenv("REQUEST_URI")
	// 某些环境下可能是空或者测试需要，这里严谨处理
	if requestUri == "" {
		sendErrorResponse(500, "Internal Server Error", "REQUEST_URI environment variable is not set.")
		return
	}

	// 2. 解析目标路径
	cgiScriptName := "/index.cgi"
	cgiIndex := strings.Index(requestUri, cgiScriptName)
	var targetPath string

	if cgiIndex != -1 {
		targetPath = requestUri[cgiIndex+len(cgiScriptName):]
	} else {
		targetPath = "/"
	}

	// 3. 映射到文件系统路径
	scriptFileName := os.Getenv("SCRIPT_FILENAME")
	if scriptFileName == "" {
		sendErrorResponse(500, "Internal Server Error", "SCRIPT_FILENAME environment variable is not set.")
		return
	}

	webRoot := filepath.Dir(scriptFileName)
	var targetFile string

	if targetPath == "/" {
		targetFile = filepath.Join(webRoot, "index.html")
	} else {
		// 去掉开头的 / 以便正确拼接
		cleanPath := strings.TrimPrefix(targetPath, "/")
		targetFile = filepath.Join(webRoot, cleanPath)
	}

	// 4. 安全检查：防止路径穿越
	absTarget, err := filepath.Abs(targetFile)
	if err != nil {
		sendErrorResponse(500, "Internal Server Error", "Failed to resolve file path.")
		return
	}
	absWebRoot, err := filepath.Abs(webRoot)
	if err != nil {
		sendErrorResponse(500, "Internal Server Error", "Failed to resolve web root path.")
		return
	}

	// 确保目标文件在 webRoot 目录下
	// 注意：Windows下路径不区分大小写，但Go的HasPrefix区分。这里为了简单直接匹配。
	// 在生产环境可能需要 evalSymlinks 等更严格的检查
	if !strings.HasPrefix(absTarget, absWebRoot) {
		sendErrorResponse(403, "Forbidden", "Access denied. Path traversal attempt detected.")
		return
	}

	// 5. 检查文件是否存在且可读
	info, err := os.Stat(absTarget)
	if os.IsNotExist(err) || info.IsDir() {
		sendErrorResponse(404, "Not Found", "The requested resource was not found on this server.")
		return
	}

	file, err := os.Open(absTarget)
	if err != nil {
		sendErrorResponse(404, "Not Found", "The requested resource was not found on this server or not readable.")
		return
	}
	defer file.Close()

	// 6. 发送 HTTP 响应头
	contentType := getContentType(info.Name())
	fmt.Printf("Content-Type: %s\n", contentType)
	fmt.Printf("Content-Length: %d\n", info.Size())
	fmt.Println() // 空行

	// 7. 发送文件内容
	_, err = io.Copy(os.Stdout, file)
	if err != nil {
		// 头部已发送，无法再发 500
		// fmt.Fprintf(os.Stderr, "Error sending file: %v\n", err)
	}
}

func getContentType(fileName string) string {
	ext := strings.ToLower(filepath.Ext(fileName))
	if mime, ok := mimeTypes[ext]; ok {
		return mime
	}
	return "application/octet-stream"
}

func sendErrorResponse(statusCode int, statusMessage string, message string) {
	fmt.Printf("Status: %d %s\n", statusCode, statusMessage)
	fmt.Println("Content-Type: text/html; charset=UTF-8")
	fmt.Println()
	fmt.Println("<html>")
	fmt.Printf("<head><title>%d %s</title></head>\n", statusCode, statusMessage)
	fmt.Println("<body>")
	fmt.Printf("<h1>%d %s</h1>\n", statusCode, statusMessage)
	fmt.Printf("<p>%s</p>\n", message)
	fmt.Println("</body>")
	fmt.Println("</html>")
}
