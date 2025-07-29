//
//  OCRunner.h
//  OCRunner
//
//  Created by Jiang on 2020/5/8.
//  Copyright © 2020 SilverFruity. All rights reserved.
//
#import <arpa/inet.h>
#import <errno.h>
#import <ifaddrs.h>
#import <net/if.h>
#import <netinet/in.h>
#import <pthread.h>
#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import <sys/socket.h>
#import <time.h>
#import <unistd.h>
#import "TcpServer.h"
#import "ORInterpreter.h"
#import <oc2mangoLib/Parser.h>

// GEN by Qwen3-Coder

#define MAX_BUFFER_SIZE (1024 * 1024)  // 1MB
#define MAX_CLIENTS 1

// 全局变量
static int client_socket = -1;
static volatile int server_running = 0;
static volatile int server_started = 0;
static struct sockaddr_in client_address;
static pthread_t server_thread = 0;
static int server_port = 8888;
static pthread_mutex_t server_mutex = PTHREAD_MUTEX_INITIALIZER;

// 自定义日志函数
static void server_log(const char* format, ...) {
    va_list args;
    va_start(args, format);
    printf("[SERVER] ");
    vprintf(format, args);
    printf("\n");
    va_end(args);
    fflush(stdout);
}

// 获取本机 IPv4 地址
void print_local_ipv4_addresses(void) {
    struct ifaddrs *ifaddrs_ptr, *ifa;
    char ip_str[INET_ADDRSTRLEN];
    
    server_log("Local IPv4 Addresses:");
    
    if (getifaddrs(&ifaddrs_ptr) == -1) {
        server_log("getifaddrs failed: %s", strerror(errno));
        return;
    }
    
    int found_address = 0;
    for (ifa = ifaddrs_ptr; ifa != NULL; ifa = ifa->ifa_next) {
        if (ifa->ifa_addr == NULL) continue;
        
        // 只处理 IPv4 地址
        if (ifa->ifa_addr->sa_family == AF_INET) {
            // 跳过回环接口（除非只有回环接口）
            if (!(ifa->ifa_flags & IFF_LOOPBACK)) {
                struct sockaddr_in* addr_in = (struct sockaddr_in*)ifa->ifa_addr;
                inet_ntop(AF_INET, &addr_in->sin_addr, ip_str, INET_ADDRSTRLEN);
                
                // 跳过 0.0.0.0 地址
                if (strcmp(ip_str, "0.0.0.0") != 0) {
                    server_log("  %s: %s", ifa->ifa_name, ip_str);
                    found_address = 1;
                }
            }
        }
    }
    
    // 如果没有找到非回环地址，则显示回环地址
    if (!found_address) {
        for (ifa = ifaddrs_ptr; ifa != NULL; ifa = ifa->ifa_next) {
            if (ifa->ifa_addr == NULL) continue;
            
            if (ifa->ifa_addr->sa_family == AF_INET) {
                struct sockaddr_in* addr_in = (struct sockaddr_in*)ifa->ifa_addr;
                inet_ntop(AF_INET, &addr_in->sin_addr, ip_str, INET_ADDRSTRLEN);
                server_log("  %s: %s", ifa->ifa_name, ip_str);
            }
        }
    }
    
    freeifaddrs(ifaddrs_ptr);
}

// 获取当前时间字符串
void get_current_time(char* buffer, size_t buffer_size) {
    time_t rawtime;
    struct tm *timeinfo;
    
    time(&rawtime);
    timeinfo = localtime(&rawtime);
    strftime(buffer, buffer_size, "%Y-%m-%d %H:%M:%S", timeinfo);
}

// 安全接收指定长度的数据
int recv_all(int socket_fd, char* buffer, size_t length) {
    size_t total_received = 0;
    ssize_t bytes_received;
    
    while (total_received < length) {
        bytes_received = recv(socket_fd, buffer + total_received,
                             length - total_received, 0);
        
        if (bytes_received <= 0) {
            if (bytes_received == 0) {
                return -1; // 连接关闭
            }
            if (errno == EINTR) {
                continue; // 被信号中断，继续接收
            }
            return -1; // 错误
        }
        
        total_received += bytes_received;
    }
    
    return total_received;
}

// 安全发送指定长度的数据
int send_all(int socket_fd, const char* buffer, size_t length) {
    size_t total_sent = 0;
    ssize_t bytes_sent;
    
    while (total_sent < length) {
        bytes_sent = send(socket_fd, buffer + total_sent,
                         length - total_sent, 0);
        
        if (bytes_sent <= 0) {
            if (bytes_sent == -1 && errno == EINTR) {
                continue; // 被信号中断，继续发送
            }
            return -1; // 错误
        }
        
        total_sent += bytes_sent;
    }
    
    return total_sent;
}

// 接收带长度前缀的消息
int recv_message(int socket_fd, char** message, size_t* message_length) {
    // 首先接收 4 字节的消息长度
    uint32_t length;
    int result = recv_all(socket_fd, (char*)&length, sizeof(length));
    
    if (result <= 0) {
        return result;
    }
    
    // 网络字节序转换
    length = ntohl(length);
    
    // 检查长度是否有效
    if (length == 0) {
        *message = NULL;
        *message_length = 0;
        return 0;
    }
    
    if (length > MAX_BUFFER_SIZE) {
        server_log("Invalid message length: %u (max: %d)", length, MAX_BUFFER_SIZE);
        return -1;
    }
    
    // 分配内存
    *message = (char*)malloc(length + 1);
    if (*message == NULL) {
        server_log("Memory allocation failed");
        return -1;
    }
    
    // 接收实际数据
    result = recv_all(socket_fd, *message, length);
    if (result <= 0) {
        free(*message);
        *message = NULL;
        return result;
    }
    
    (*message)[length] = '\0'; // 确保字符串结尾
    *message_length = length;
    
    return result;
}

// 发送带长度前缀的消息
int send_message(int socket_fd, const char* message, size_t message_length) {
    // 检查消息长度
    if (message_length > MAX_BUFFER_SIZE) {
        server_log("Message too large: %zu bytes", message_length);
        return -1;
    }
    
    // 发送长度（网络字节序）
    uint32_t length = htonl((uint32_t)message_length);
    int result = send_all(socket_fd, (const char*)&length, sizeof(length));
    
    if (result <= 0) {
        return result;
    }
    
    // 发送实际数据
    if (message_length > 0) {
        result = send_all(socket_fd, message, message_length);
    }
    
    return result;
}

// 处理文件监控模式的消息，提取文件内容
void extract_file_content(const char* original_message, char** extracted_content) {
    // 检查是否是文件监控模式的消息 [FILE] filename: content
    if (strncmp(original_message, "[FILE] ", 7) == 0) {
        const char* colon_ptr = strchr(original_message + 7, ':');
        if (colon_ptr) {
            // 找到冒号后的文件内容
            const char* content_start = colon_ptr + 1;
            // 跳过前导空格
            while (*content_start == ' ' || *content_start == '\t') {
                content_start++;
            }
            
            size_t content_length = strlen(content_start);
            *extracted_content = malloc(content_length + 1);
            if (*extracted_content) {
                strcpy(*extracted_content, content_start);
            }
            return;
        }
    }
    
    // 不是文件监控模式的消息，返回原消息
    size_t original_length = strlen(original_message);
    *extracted_content = malloc(original_length + 1);
    if (*extracted_content) {
        strcpy(*extracted_content, original_message);
    }
}

// 服务器主逻辑函数
void* server_main_loop(void* arg) {
    int port = *(int*)arg;
    int server_fd;
    struct sockaddr_in address;
    int opt = 1;
    int addrlen = sizeof(address);
    
    pthread_mutex_lock(&server_mutex);
    server_started = 1;
    pthread_mutex_unlock(&server_mutex);
    
    server_log("Starting TCP server on port %d...", port);
    server_log("Maximum message size: %d bytes (%.2f MB)",
               MAX_BUFFER_SIZE, (float)MAX_BUFFER_SIZE / (1024 * 1024));
    server_log("Maximum clients: %d", MAX_CLIENTS);
    
    // 打印本机 IPv4 地址
    print_local_ipv4_addresses();
    
    // 创建 socket
    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
        server_log("socket failed: %s", strerror(errno));
        pthread_mutex_lock(&server_mutex);
        server_started = 0;
        server_running = 0;
        pthread_mutex_unlock(&server_mutex);
        return NULL;
    }
    
    // 设置 socket 选项
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR,
                   &opt, sizeof(opt))) {
        server_log("setsockopt failed: %s", strerror(errno));
        close(server_fd);
        pthread_mutex_lock(&server_mutex);
        server_started = 0;
        server_running = 0;
        pthread_mutex_unlock(&server_mutex);
        return NULL;
    }
    
    // 配置地址
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(port);
    
    // 绑定 socket
    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        server_log("bind failed: %s", strerror(errno));
        close(server_fd);
        pthread_mutex_lock(&server_mutex);
        server_started = 0;
        server_running = 0;
        pthread_mutex_unlock(&server_mutex);
        return NULL;
    }
    
    // 监听连接
    if (listen(server_fd, 1) < 0) {
        server_log("listen failed: %s", strerror(errno));
        close(server_fd);
        pthread_mutex_lock(&server_mutex);
        server_started = 0;
        server_running = 0;
        pthread_mutex_unlock(&server_mutex);
        return NULL;
    }
    
    server_log("Server listening on port %d", port);
    server_log("Waiting for a single client connection...");
    server_log("Commands: 'quit' or 'exit' to disconnect");
    server_log("Use StopTcpServer() to stop server");
    
    // 接受连接
    while (server_running) {
        struct sockaddr_in new_client_address;
        int client_addrlen = sizeof(new_client_address);
        
        // 设置 accept 超时（非阻塞检查 server_running）
        struct timeval timeout;
        timeout.tv_sec = 1;
        timeout.tv_usec = 0;
        setsockopt(server_fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
        
        // 接受新连接
        int new_socket = accept(server_fd, (struct sockaddr *)&new_client_address,
                               (socklen_t*)&client_addrlen);
        
        if (new_socket < 0) {
            if (server_running && errno != EINTR && errno != EAGAIN && errno != EWOULDBLOCK) {
                server_log("accept failed: %s", strerror(errno));
            }
            continue;
        }
        
        // 检查是否已有客户端连接
        if (client_socket != -1) {
            server_log("Client already connected, rejecting new connection from %s:%d",
                       inet_ntoa(new_client_address.sin_addr),
                       ntohs(new_client_address.sin_port));
            
            const char* reject_msg = "Server busy, only one client allowed\n";
            send_message(new_socket, reject_msg, strlen(reject_msg));
            close(new_socket);
            continue;
        }
        
        // 接受客户端连接
        client_socket = new_socket;
        client_address = new_client_address;
        
        server_log("Client connected from %s:%d",
                   inet_ntoa(client_address.sin_addr),
                   ntohs(client_address.sin_port));
        
        // 发送欢迎消息
        char time_str[64];
        get_current_time(time_str, sizeof(time_str));
        char welcome_msg[512];
        int welcome_len = snprintf(welcome_msg, sizeof(welcome_msg),
                                  "Welcome to ObjcScript Server! Connected at %s.\n"
                                  "Max message size: 1MB. Commands: 'quit' or 'exit' to disconnect.\n",
                                  time_str);
        send_message(client_socket, welcome_msg, welcome_len);
        
        // 处理客户端消息
        char* message = NULL;
        char* processed_message = NULL;
        size_t message_length = 0;
        
        while (server_running && client_socket != -1) {
            // 释放之前的消息内存
            if (message) {
                free(message);
                message = NULL;
            }
            if (processed_message) {
                free(processed_message);
                processed_message = NULL;
            }
            
            // 接收消息
            int result = recv_message(client_socket, &message, &message_length);
            
            if (result <= 0) {
                // 客户端断开连接或出错
                if (result == 0) {
                    server_log("Client disconnected");
                } else if (result == -1) {
                    if (server_running) {
                        server_log("Error receiving from client");
                    }
                }
                break;
            }
            
            // 移除末尾的换行符（如果存在）
            while (message_length > 0 &&
                   (message[message_length-1] == '\n' || message[message_length-1] == '\r')) {
                message[--message_length] = '\0';
            }
            
            // 处理文件监控模式的消息，只提取文件内容
            extract_file_content(message, &processed_message);
            
            // 获取当前时间
            get_current_time(time_str, sizeof(time_str));
            
            // 打印收到的消息摘要（避免打印过长内容）
            const char* display_message = processed_message ? processed_message : message;
            size_t display_length = strlen(display_message);
            
            if (display_length > 0) {
                NSString *time_stamp = [NSString stringWithUTF8String:time_str];
                NSString *content = [NSString stringWithUTF8String:display_message];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ORInterpreter executeSourceCode:content];
                    if ([Parser shared].error) {
                        NSString *errorInfo = [NSString stringWithFormat:@"\n----Error----: \n  PATH: %@\n  INFO:%@",[Parser shared].source.filePath, [Parser shared].error];
                        send_message(client_socket, errorInfo.UTF8String, errorInfo.length);
                    } else {
                        // 发送换行符
                        const char *msg = "ObjcScript Successfully";
                        send_message(client_socket, msg, strlen(msg));
                    }
                });
            }

            // 特殊命令处理
            if (message_length >= 4 &&
                (strncmp(message, "quit", 4) == 0 || strncmp(message, "exit", 4) == 0)) {
                server_log("Client requested to quit");
                break;
            }
        }
        
        // 清理资源
        if (message) {
            free(message);
        }
        if (processed_message) {
            free(processed_message);
        }
        
        // 关闭客户端连接
        if (client_socket != -1) {
            close(client_socket);
            client_socket = -1;
            server_log("Client connection closed");
        }
    }
    
    // 清理资源
    if (client_socket != -1) {
        close(client_socket);
        client_socket = -1;
    }
    close(server_fd);
    
    pthread_mutex_lock(&server_mutex);
    server_started = 0;
    server_running = 0;
    pthread_mutex_unlock(&server_mutex);
    
    server_log("Server stopped");
    return NULL;
}

// 启动 TCP 服务器的函数
int ObjcScriptRunExeServer(void) {
    pthread_mutex_lock(&server_mutex);
    
    // 检查服务器是否已经在运行
    if (server_running || server_started) {
        pthread_mutex_unlock(&server_mutex);
        server_log("Server is already running");
        return -1;
    }
    
    server_running = 1;
    int port = 8888;
    server_port = port;
    pthread_mutex_unlock(&server_mutex);
    
    // 创建服务器线程
    int* port_ptr = malloc(sizeof(int));
    if (port_ptr == NULL) {
        server_log("Failed to allocate memory for port");
        server_running = 0;
        return -1;
    }
    *port_ptr = port;
    
    if (pthread_create(&server_thread, NULL, server_main_loop, port_ptr) != 0) {
        server_log("Failed to create server thread: %s", strerror(errno));
        free(port_ptr);
        server_running = 0;
        return -1;
    }
    
    // 分离线程（避免僵尸线程）
    pthread_detach(server_thread);
    
    // 等待服务器启动完成
    int wait_count = 0;
    while (wait_count < 100) { // 最多等待10秒
        pthread_mutex_lock(&server_mutex);
        int started = server_started;
        pthread_mutex_unlock(&server_mutex);
        
        if (started) {
            break;
        }
        
        usleep(100000); // 等待100ms
        wait_count++;
    }
    
    server_log("RunTcpServer completed, server running in background");
    return 0;
}

// 停止 TCP 服务器的函数
void StopTcpServer(void) {
    pthread_mutex_lock(&server_mutex);

    if (!server_running) {
        pthread_mutex_unlock(&server_mutex);
        server_log("Server is not running");
        return;
    }

    server_log("Stopping server...");
    server_running = 0;
    pthread_mutex_unlock(&server_mutex);

    // 如果有客户端连接，关闭它以触发 accept 返回
    if (client_socket != -1) {
        close(client_socket);
        client_socket = -1;
    }

    // 等待服务器线程结束
    int wait_count = 0;
    while (wait_count < 50) { // 最多等待5秒
        pthread_mutex_lock(&server_mutex);
        int started = server_started;
        pthread_mutex_unlock(&server_mutex);

        if (!started) {
            break;
        }

        usleep(100000); // 等待100ms
        wait_count++;
    }

    server_log("Server stopped successfully");
}
