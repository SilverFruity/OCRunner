#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import socket
import threading
import sys
import time
import struct
import os
import argparse
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
# Gen by Qwen3-Coder
class FileMonitorHandler(FileSystemEventHandler):
    def __init__(self, client):
        self.client = client
        
    def on_modified(self, event):
        if not event.is_directory and self.client.monitoring_file:
            if os.path.abspath(event.src_path) == os.path.abspath(self.client.monitoring_file):
                print(f"[CLIENT] File {event.src_path} modified, sending content...")
                self.client.send_file_content()

class TCPClient:
    def __init__(self, host='localhost', port=8888):
        self.host = host
        self.port = port
        self.socket = None
        self.connected = False
        self.running = False
        self.max_message_size = 1024 * 1024  # 1MB
        self.monitoring_file = None
        self.observer = None
        self.file_handler = None
        self.mode = 'interactive'  # 'interactive' or 'file_monitor'
        self.reconnect_delay = 5  # 重连间隔秒数
        self.should_reconnect = True
        
    def connect(self):
        """连接到服务器"""
        while self.should_reconnect and self.running:
            try:
                print(f"[CLIENT] Attempting to connect to {self.host}:{self.port}...")
                self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                # 设置连接超时
                self.socket.settimeout(10)
                # 设置 socket 选项
                self.socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
                self.socket.connect((self.host, self.port))
                self.connected = True
                
                print(f"[CLIENT] Connected to server {self.host}:{self.port}")
                print(f"[CLIENT] Maximum message size: {self.max_message_size} bytes")
                
                # 启动接收消息的线程
                receive_thread = threading.Thread(target=self.receive_messages)
                receive_thread.daemon = True
                receive_thread.start()
                
                # 如果是文件监控模式，发送初始文件内容
                if self.mode == 'file_monitor' and self.monitoring_file:
                    self.send_file_content()
                
                return True
                
            except Exception as e:
                print(f"[CLIENT] Connection failed: {e}")
                if self.should_reconnect and self.running:
                    print(f"[CLIENT] Retrying in {self.reconnect_delay} seconds...")
                    time.sleep(self.reconnect_delay)
                else:
                    break
                    
        return False
    
    def send_message_with_length(self, message):
        """发送带长度前缀的消息"""
        if isinstance(message, str):
            message_bytes = message.encode('utf-8')
        else:
            message_bytes = message
            
        # 检查消息长度
        if len(message_bytes) > self.max_message_size:
            raise ValueError(f"Message too large: {len(message_bytes)} bytes (max: {self.max_message_size})")
        
        # 发送长度（4字节，网络字节序）
        length_bytes = struct.pack('!I', len(message_bytes))
        self.socket.sendall(length_bytes)
        
        # 发送实际数据
        if len(message_bytes) > 0:
            self.socket.sendall(message_bytes)
    
    def receive_message_with_length(self):
        """接收带长度前缀的消息"""
        # 首先接收4字节的长度
        length_bytes = self._recv_all(4)
        if not length_bytes:
            return None
            
        # 解析长度
        length = struct.unpack('!I', length_bytes)[0]
        
        # 检查长度是否有效
        if length == 0:
            return b''
        if length > self.max_message_size:
            raise ValueError(f"Received message too large: {length} bytes")
        
        # 接收实际数据
        message_bytes = self._recv_all(length)
        return message_bytes
    
    def _recv_all(self, length):
        """确保接收指定长度的所有数据"""
        data = b''
        while len(data) < length:
            packet = self.socket.recv(length - len(data))
            if not packet:
                return None
            data += packet
        return data
    
    def receive_messages(self):
        """接收服务器消息的线程函数"""
        while self.running and self.connected:
            try:
                message_bytes = self.receive_message_with_length()
                if message_bytes is not None:
                    # 尝试解码为 UTF-8
                    try:
                        message = message_bytes.decode('utf-8')
                        if len(message) <= 200:
                            print(f"{message.strip()}")
                        else:
                            print(f"{message[:200]}... (truncated, {len(message)} chars total)")
                    except UnicodeDecodeError:
                        print(f"[CLIENT] Received {len(message_bytes)} bytes of binary data")
                else:
                    # 服务器关闭连接
                    print("[CLIENT] Server disconnected")
                    self.connected = False
                    break
            except ValueError as e:
                print(f"[CLIENT] Protocol error: {e}")
                self.connected = False
                break
            except socket.timeout:
                continue  # 继续循环
            except Exception as e:
                if self.running:
                    print(f"[CLIENT] Error receiving message: {e}")
                self.connected = False
                break
        
        # 如果应该重连，启动重连过程
        if self.should_reconnect and self.running and not self.connected:
            self.handle_disconnect()
    
    def send_message(self, message):
        """发送消息到服务器"""
        if not self.connected:
            print("[CLIENT] Not connected to server")
            return False
            
        try:
            self.send_message_with_length(message)
            return True
        except Exception as e:
            print(f"[CLIENT] Error sending message: {e}")
            self.connected = False
            return False
    
    def disconnect(self):
        """断开连接"""
        print("[CLIENT] Disconnecting...")
        self.should_reconnect = False
        self.running = False
        self.connected = False
        
        # 停止文件监控
        if self.observer:
            self.observer.stop()
            self.observer.join()
            self.observer = None
            
        if self.socket:
            try:
                self.socket.close()
            except:
                pass
        print("[CLIENT] Disconnected from server")
    
    def handle_disconnect(self):
        """处理断开连接并尝试重连"""
        if not self.should_reconnect or not self.running:
            return
            
        self.connected = False
        if self.socket:
            try:
                self.socket.close()
            except:
                pass
            self.socket = None
            
        print("[CLIENT] Connection lost. Attempting to reconnect...")
        
        # 在新线程中重连，避免阻塞接收线程
        reconnect_thread = threading.Thread(target=self.reconnect_worker)
        reconnect_thread.daemon = True
        reconnect_thread.start()
    
    def reconnect_worker(self):
        """重连工作线程"""
        if self.connect() and self.mode == 'file_monitor' and self.monitoring_file:
            # 重连成功后重新发送文件内容
            time.sleep(1)  # 等待连接稳定
            self.send_file_content()
    
    def start_file_monitoring(self, file_path):
        """开始文件监控模式"""
        if not os.path.exists(file_path):
            print(f"[CLIENT] File {file_path} does not exist")
            return False
            
        self.monitoring_file = file_path
        self.mode = 'file_monitor'
        
        # 设置文件监控
        self.file_handler = FileMonitorHandler(self)
        self.observer = Observer()
        self.observer.schedule(self.file_handler, os.path.dirname(os.path.abspath(file_path)), recursive=False)
        self.observer.start()
        
        print(f"[CLIENT] Started monitoring file: {file_path}")
        print("[CLIENT] File changes will be automatically sent to server")
        print("[CLIENT] Type 'stop' to stop monitoring and disconnect")
        
        return True
    
    def send_file_content(self):
        """发送文件内容到服务器"""
        if not self.monitoring_file or not os.path.exists(self.monitoring_file) or not self.connected:
            return
            
        try:
            with open(self.monitoring_file, 'r', encoding='utf-8') as f:
                content = f.read()
                
            if content:
                message = f"[FILE] {os.path.basename(self.monitoring_file)}: {content}"
                if self.send_message(message):
                    print(f"[CLIENT] File content sent ({len(content)} chars)")
                else:
                    print("[CLIENT] Failed to send file content")
        except Exception as e:
            print(f"[CLIENT] Error reading file: {e}")
    
    def interactive_mode(self):
        """交互模式"""
        print("[CLIENT] Enter messages (type 'quit' or 'exit' to disconnect)")
        print("[CLIENT] Special commands:")
        print("  - 'quit' or 'exit': Disconnect")
        print("  - 'help': Show this help")
        
        try:
            while self.running:
                if self.connected:
                    try:
                        message = input()
                        if not message.strip():
                            continue
                            
                        # 处理特殊命令
                        if message.lower() in ['quit', 'exit']:
                            self.should_reconnect = False
                            self.send_message(message)
                            time.sleep(0.1)  # 等待服务器响应
                            break
                        elif message.lower() == 'help':
                            print("Special commands:")
                            print("  - 'quit' or 'exit': Disconnect")
                            print("  - 'help': Show this help")
                        else:
                            self.send_message(message)
                    except EOFError:
                        # Ctrl+D
                        self.should_reconnect = False
                        self.send_message('quit')
                        break
                else:
                    # 未连接时的命令处理
                    try:
                        command = input("[CLIENT] Disconnected. Commands: 'reconnect', 'quit': ")
                        if command.lower() in ['quit', 'exit']:
                            self.should_reconnect = False
                            break
                        elif command.lower() == 'reconnect':
                            if self.connect():
                                print("[CLIENT] Reconnected successfully")
                    except EOFError:
                        self.should_reconnect = False
                        break
                        
        except KeyboardInterrupt:
            print("\n[CLIENT] Interrupted by user")
        finally:
            self.disconnect()
    
    def file_monitor_mode(self, file_path):
        """文件监控模式"""
        if not self.start_file_monitoring(file_path):
            return
            
        try:
            while self.running:
                if self.connected:
                    try:
                        command = input()
                        if command.lower() == 'stop':
                            print("[CLIENT] Stopping file monitoring...")
                            self.should_reconnect = False
                            break
                    except EOFError:
                        self.should_reconnect = False
                        break
                else:
                    # 未连接时等待重连
                    time.sleep(1)
                        
        except KeyboardInterrupt:
            print("\n[CLIENT] Interrupted by user")
        finally:
            self.disconnect()

def get_server_info():
    """交互式获取服务器信息"""
    print("[CLIENT] TCP Client Configuration")
    print("[CLIENT] ======================")
    
    # 获取服务器 IP
    while True:
        host_input = input("[CLIENT] Enter server IP (default: localhost): ").strip()
        if not host_input:
            host = 'localhost'
            break
        else:
            host = host_input
            break
    
    # 端口使用默认值 8888
    port = 8888
    print(f"[CLIENT] Using default port: {port}")
    
    return host, port

def get_client_mode():
    """获取客户端模式"""
    print("\n[CLIENT] Select mode:")
    print("[CLIENT] 1. Interactive mode (type messages manually)")
    print("[CLIENT] 2. File monitoring mode (monitor file changes)")
    
    while True:
        choice = input("[CLIENT] Enter choice (1 or 2, default: 1): ").strip()
        if not choice or choice == '1':
            return 'interactive'
        elif choice == '2':
            return 'file_monitor'
        else:
            print("[CLIENT] Please enter 1 or 2")

def get_file_path():
    """获取要监控的文件路径"""
    while True:
        file_path = input("[CLIENT] Enter file path to monitor: ").strip()
        if file_path:
            if os.path.exists(file_path):
                return file_path
            else:
                print(f"[CLIENT] File {file_path} does not exist")
        else:
            print("[CLIENT] Please enter a valid file path")

def main():
    # 获取客户端模式
    mode = get_client_mode()
    
    # 根据模式获取相应参数
    if mode == 'file_monitor':
        # 先获取文件路径
        file_path = get_file_path()
        # 再获取服务器信息
        host, port = get_server_info()
        # 创建客户端实例
        client = TCPClient(host, port)
        client.running = True
        client.mode = mode
        
        # 连接到服务器
        if not client.connect():
            print("[CLIENT] Failed to connect to server")
            return
            
        # 启动文件监控模式
        client.file_monitor_mode(file_path)
    else:  # interactive mode
        # 直接获取服务器信息
        host, port = get_server_info()
        # 创建客户端实例
        client = TCPClient(host, port)
        client.running = True
        client.mode = mode
        
        # 连接到服务器
        if not client.connect():
            print("[CLIENT] Failed to connect to server")
            return
            
        # 启动交互模式
        client.interactive_mode()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[CLIENT] Program interrupted by user")
    except Exception as e:
        print(f"[CLIENT] Unexpected error: {e}")
