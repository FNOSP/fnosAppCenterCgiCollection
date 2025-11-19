#!/bin/sh

# 脚本名称: javaCgi.sh
# 　　版本: 1.0.1
# 　　作者: FNOSP/MR_XIAOBO
# 创建日期: 2025-11-19
# 最后修改: 2025-11-19
# 　　描述: CGI 脚本，用于调用 Java 程序
# 使用方式: 文件重命名，从javaCgi.sh改成index.cgi
# 　　　　  放置应用包/ui路径下，记得 chmod +x index.cgi 赋权
# 　许可证: MIT

# ----------------------------------------------------
# 根据应用中心已发布的OpenJDK 选择适合的版本
# 【注意】版本要高于本地编译时jdk环境版本！！
# ----------------------------------------------------
export PATH=/var/apps/java-11-openjdk/target/bin:$PATH
#export PATH=/var/apps/java-17-openjdk/target/bin:$PATH
#export PATH=/var/apps/java-21-openjdk/target/bin:$PATH

# ----------------------------------------------------
# 设置 Java 程序所在的 classpath
# 如果你的 .class 文件就在当前目录，可以设置为 .
# 如果在其他目录，需要指定完整路径
# 以demo1应用为例：/var/apps/demo1/target/class/
# ----------------------------------------------------
CLASSPATH=.
#CLASSPATH=/var/apps/demo1/target/class/

# ----------------------------------------------------
# 调用 Java 虚拟机执行主类，替换当前shell进程
# ----------------------------------------------------
exec java -classpath "$CLASSPATH" javaCgiParsingService