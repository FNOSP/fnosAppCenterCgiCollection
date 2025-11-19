import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;

/**
 * @ClassName:  javaCgiParsingService
 * @Version:    1.0.0
 * @Author:     MR_XIAOBO
 * @CreateTime: 2025/11/19 12:22
 * @Statement:  用于演示Java如何处理CGI并对请求的内容进行解析
 * @HowToUse:   使用JDK中javac工具将本源码编译为Class文件，放置应用包/ui路径下，记得chmod +x javaCgiParsingService.class
 * @License:    MIT
 */
public class javaCgiParsingService {

    // MIME 类型映射表
    private static final Map<String, String> MIME_TYPES = new HashMap<>();

    static {
        MIME_TYPES.put(".html", "text/html; charset=UTF-8");
        MIME_TYPES.put(".htm", "text/html; charset=UTF-8");
        MIME_TYPES.put(".css", "text/css; charset=UTF-8");
        MIME_TYPES.put(".js", "application/javascript; charset=UTF-8");
        MIME_TYPES.put(".png", "image/png");
        MIME_TYPES.put(".jpg", "image/jpeg");
        MIME_TYPES.put(".jpeg", "image/jpeg");
        MIME_TYPES.put(".gif", "image/gif");
        MIME_TYPES.put(".ico", "image/x-icon");
        MIME_TYPES.put(".txt", "text/plain; charset=UTF-8");
    }

    public static void main(String[] args) {
        // 1. 获取 CGI 环境变量
        Map<String, String> env = System.getenv();
        String requestUri = env.get("REQUEST_URI"); // 例如: /cgi/ThirdParty/demo1/index.cgi/ui/images/icon.png

        if (requestUri == null) {
            sendErrorResponse(500, "Internal Server Error", "REQUEST_URI environment variable is not set.");
            return;
        }

        // 2. 解析目标路径
        String cgiScriptName = "/index.cgi";
        int cgiIndex = requestUri.indexOf(cgiScriptName);
        String targetPath;

        if (cgiIndex != -1) {
            // 截取 index.cgi 后面的部分
            targetPath = requestUri.substring(cgiIndex + cgiScriptName.length());
        } else {
            // 如果请求的就是 index.cgi 本身
            targetPath = "/";
        }

        // 3. 映射到文件系统路径
        // CGI 程序所在的目录，即 /var/apps/demo1/ui
        // 在 CGI 中，可以通过 DOCUMENT_ROOT 或 SCRIPT_FILENAME 环境变量来获取
        // SCRIPT_FILENAME 通常指向当前执行的脚本路径，例如 /var/apps/demo1/ui/index.cgi
        String scriptFileName = env.get("SCRIPT_FILENAME");
        if (scriptFileName == null) {
            sendErrorResponse(500, "Internal Server Error", "SCRIPT_FILENAME environment variable is not set.");
            return;
        }
        File scriptFile = new File(scriptFileName);
        String webRoot = scriptFile.getParent(); // 获取脚本所在目录，即 /var/apps/demo1/ui

        File targetFile;
        if ("/".equals(targetPath)) {
            // 默认首页
            targetFile = new File(webRoot, "index.html");
        } else {
            // 拼接实际文件路径
            targetFile = new File(webRoot, targetPath);
        }

        // 4. 安全检查：防止路径穿越
        try {
            String canonicalPath = targetFile.getCanonicalPath();
            if (!canonicalPath.startsWith(new File(webRoot).getCanonicalPath())) {
                sendErrorResponse(403, "Forbidden", "Access denied. Path traversal attempt detected.");
                return;
            }
        } catch (IOException e) {
            sendErrorResponse(500, "Internal Server Error", "Failed to resolve file path.");
            e.printStackTrace();
            return;
        }

        // 5. 检查文件是否存在且可读
        if (!targetFile.exists() || !targetFile.canRead() || !targetFile.isFile()) {
            sendErrorResponse(404, "Not Found", "The requested resource was not found on this server.");
            return;
        }

        // 6. 发送 HTTP 响应头
        String contentType = getContentType(targetFile.getName());
        System.out.println("Content-Type: " + contentType);
        System.out.println("Content-Length: " + targetFile.length());
        System.out.println(); // 必须有一个空行分隔头部和主体

        // 7. 发送文件内容
        try (InputStream in = new FileInputStream(targetFile);
             OutputStream out = System.out) {

            byte[] buffer = new byte[4096];
            int bytesRead;
            while ((bytesRead = in.read(buffer)) != -1) {
                out.write(buffer, 0, bytesRead);
            }
            out.flush();

        } catch (IOException e) {
            // 注意：此时响应头可能已经发送，无法再发送 500 状态码
            // 服务器可能会自行处理这个错误
            e.printStackTrace();
        }
    }

    /**
     * getContentType
     * @功能表述: 根据文件名获取 MIME 类型
     * @Author: MR_XIAOBO
     * @Time: 2025/11/19 14:49
     */
    private static String getContentType(String fileName) {
        int dotIndex = fileName.lastIndexOf('.');
        if (dotIndex > 0) {
            String extension = fileName.substring(dotIndex).toLowerCase();
            if (MIME_TYPES.containsKey(extension)) {
                return MIME_TYPES.get(extension);
            }
        }
        return "application/octet-stream"; // 默认二进制流
    }

    /**
     * sendErrorResponse
     * @功能表述: 发送错误响应
     * @Author: MR_XIAOBO
     * @Time: 2025/11/19 14:32
     */
    private static void sendErrorResponse(int statusCode, String statusMessage, String message) {
        System.out.println("Status: " + statusCode + " " + statusMessage);
        System.out.println("Content-Type: text/html; charset=UTF-8");
        System.out.println();
        System.out.println("<html>");
        System.out.println("<head><title>" + statusCode + " " + statusMessage + "</title></head>");
        System.out.println("<body>");
        System.out.println("<h1>" + statusCode + " " + statusMessage + "</h1>");
        System.out.println("<p>" + message + "</p>");
        System.out.println("</body>");
        System.out.println("</html>");
    }
}
