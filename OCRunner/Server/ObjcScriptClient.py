#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Gen by Qwen3-Coder
import socket
import threading
import sys
import time
import struct
import os
import signal
import argparse
import glob
import hashlib

try:
    # 尝试导入 readline 支持方向键历史
    import readline
    READLINE_AVAILABLE = True
except ImportError:
    READLINE_AVAILABLE = False

from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# ANSI 颜色代码
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BRIGHT_GREEN = '\033[1;92m'
    BRIGHT_RED = '\033[1;91m'
    RESET = '\033[0m'

class FileMonitorHandler(FileSystemEventHandler):
    def __init__(self, client, monitoring_file):
        self.client = client
        self.monitoring_file = monitoring_file  # 直接传入监控文件路径
        self.last_sha256 = None
        
    def calculate_file_sha256(self, file_path):
        """计算文件的SHA256值"""
        try:
            hash_sha256 = hashlib.sha256()
            with open(file_path, "rb") as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    hash_sha256.update(chunk)
            return hash_sha256.hexdigest()
        except Exception as e:
            print(f"{Colors.RED}[CLIENT] Error calculating SHA256 for {file_path}: {e}{Colors.RESET}")
            return None
    
    def on_modified(self, event):
        if not event.is_directory:
            # 只有当修改的文件是我们监控的文件时才触发
            if os.path.abspath(event.src_path) == os.path.abspath(self.monitoring_file):
                # 计算当前文件的SHA256
                current_sha256 = self.calculate_file_sha256(event.src_path)
                if current_sha256 is None:
                    return
                
                # 如果是第一次或者SHA256值不同，则触发发送
                if self.last_sha256 is None or self.last_sha256 != current_sha256:
                    self.last_sha256 = current_sha256
                    print(f"{Colors.CYAN}[CLIENT] File {event.src_path} content changed, sending content...{Colors.RESET}")
                    self.client.send_file_content()
                else:
                    print(f"{Colors.YELLOW}[CLIENT] File {event.src_path} modified but content unchanged{Colors.RESET}")

class FolderMonitorHandler(FileSystemEventHandler):
    def __init__(self, client, monitoring_folder):
        self.client = client
        self.monitoring_folder = monitoring_folder  # 直接传入监控文件夹路径
        self.file_sha256_cache = {}  # 缓存每个文件的SHA256值
        
    def calculate_file_sha256(self, file_path):
        """计算文件的SHA256值"""
        try:
            hash_sha256 = hashlib.sha256()
            with open(file_path, "rb") as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    hash_sha256.update(chunk)
            return hash_sha256.hexdigest()
        except Exception as e:
            print(f"{Colors.RED}[CLIENT] Error calculating SHA256 for {file_path}: {e}{Colors.RESET}")
            return None
    
    def on_modified(self, event):
        if not event.is_directory:
            file_path = event.src_path
            # 检查文件是否在监控文件夹内
            if os.path.commonpath([self.monitoring_folder, file_path]) == os.path.normpath(self.monitoring_folder):
                # 计算当前文件的SHA256
                current_sha256 = self.calculate_file_sha256(file_path)
                if current_sha256 is None:
                    return
                
                # 获取之前的SHA256值
                previous_sha256 = self.file_sha256_cache.get(file_path)
                
                # 如果是第一次或者SHA256值不同，则触发发送
                if previous_sha256 is None or previous_sha256 != current_sha256:
                    self.file_sha256_cache[file_path] = current_sha256
                    print(f"{Colors.CYAN}[CLIENT] File {os.path.basename(file_path)} content changed, sending content...{Colors.RESET}")
                    self.client.send_single_file_content(file_path)
                else:
                    print(f"{Colors.YELLOW}[CLIENT] File {os.path.basename(file_path)} modified but content unchanged{Colors.RESET}")

class TCPClient:
    def __init__(self, host='localhost', port=8888, preload_folder=None):
        self.host = host
        self.port = port
        self.socket = None
        self.connected = False
        self.running = False
        self.max_message_size = 1024 * 1024  # 1MB
        self.monitoring_file = None
        self.monitoring_folder = None
        self.observer = None
        self.file_handler = None
        self.mode = 'interactive'  # 'interactive', 'file_monitor', or 'folder_monitor'
        self.reconnect_delay = 5  # 重连间隔秒数
        self.should_reconnect = True
        self.exit_requested = False
        self.preload_folder = preload_folder
        
        # 如果有 readline，启用历史记录
        if READLINE_AVAILABLE:
            readline.parse_and_bind("mode emacs")  # 启用 emacs 模式以支持方向键
            
    def connect(self):
        """连接到服务器"""
        while self.should_reconnect and self.running:
            try:
                print(f"{Colors.CYAN}[CLIENT] Attempting to connect to {self.host}:{self.port}...{Colors.RESET}")
                self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                # 设置连接超时
                self.socket.settimeout(10)
                # 设置 socket 选项
                self.socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
                self.socket.connect((self.host, self.port))
                self.connected = True
                
                print(f"{Colors.CYAN}[CLIENT] Connected to server {self.host}:{self.port}{Colors.RESET}")
                print(f"{Colors.CYAN}[CLIENT] Maximum message size: {self.max_message_size} bytes{Colors.RESET}")
                
                # 如果指定了 preload_folder，发送预加载内容
                if self.preload_folder:
                    self.send_preload_content()
                
                # 启动接收消息的线程
                receive_thread = threading.Thread(target=self.receive_messages)
                receive_thread.daemon = True
                receive_thread.start()
                
                # 如果是文件监控模式或文件夹监控模式，发送初始文件内容
                if self.mode in ['file_monitor', 'folder_monitor']:
                    if self.mode == 'file_monitor' and self.monitoring_file:
                        print(f"{Colors.CYAN}[CLIENT] Triggering initial file send on connection...{Colors.RESET}")
                        self.send_file_content()
                    elif self.mode == 'folder_monitor' and self.monitoring_folder:
                        print(f"{Colors.CYAN}[CLIENT] Triggering initial folder files send on connection...{Colors.RESET}")
                        self.send_all_folder_files()
                
                return True
                
            except Exception as e:
                print(f"{Colors.RED}[CLIENT] Connection failed: {e}{Colors.RESET}")
                if self.should_reconnect and self.running:
                    print(f"{Colors.YELLOW}[CLIENT] Retrying in {self.reconnect_delay} seconds...{Colors.RESET}")
                    time.sleep(self.reconnect_delay)
                else:
                    break
                    
        return False
    
    def send_preload_content(self):
        """发送预加载文件夹中的所有文件内容"""
        if not self.preload_folder or not os.path.exists(self.preload_folder):
            return
            
        try:
            print(f"{Colors.CYAN}[CLIENT] Loading content from preload folder: {self.preload_folder}{Colors.RESET}")
            
            # 获取文件夹下所有文件
            files = glob.glob(os.path.join(self.preload_folder, "*"))
            files = [f for f in files if os.path.isfile(f)]
            
            if not files:
                print(f"{Colors.YELLOW}[CLIENT] No files found in preload folder{Colors.RESET}")
                return
            
            # 读取所有文件内容并拼接
            all_content = []
            total_size = 0
            
            for file_path in sorted(files):  # 按文件名排序
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        if content:
                            file_info = f"// {os.path.basename(file_path)}\n{content}\n"
                            all_content.append(file_info)
                            total_size += len(file_info.encode('utf-8'))
                            print(f"{Colors.CYAN}[CLIENT] Loaded file: {os.path.basename(file_path)} ({len(content)} chars){Colors.RESET}")
                except Exception as e:
                    print(f"{Colors.RED}[CLIENT] Error reading file {file_path}: {e}{Colors.RESET}")
            
            if all_content:
                combined_content = "\n".join(all_content)
                message = f"// [PRELOAD]\n{combined_content}"
                
                if self.send_message(message):
                    print(f"{Colors.BLUE}[CLIENT] Preload content sent successfully ({total_size} bytes){Colors.RESET}")
                else:
                    print(f"{Colors.BRIGHT_RED}[CLIENT] Failed to send preload content{Colors.RESET}")
            else:
                print(f"{Colors.YELLOW}[CLIENT] No content to send from preload folder{Colors.RESET}")
                
        except Exception as e:
            print(f"{Colors.RED}[CLIENT] Error processing preload folder: {e}{Colors.RESET}")
    
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
                    # 打印服务器返回的完整内容
                    try:
                        message = message_bytes.decode('utf-8')
                        message_length = len(message_bytes)
                        
                        # 检查是否包含错误信息
                        if '-Error-' in message:
                            print(f"{Colors.RED}[SERVER RESPONSE] ({message_length} bytes) - ERROR DETECTED:{Colors.RESET}")
                            print(f"{Colors.RED}{message.strip()}{Colors.RESET}")
                        else:
                            print(f"{Colors.BLUE}[SERVER RESPONSE] ({message_length} bytes):{Colors.RESET}")
                            print(f"{Colors.WHITE}{message.strip()}{Colors.RESET}")
                    except UnicodeDecodeError:
                        message_length = len(message_bytes)
                        print(f"{Colors.BLUE}[SERVER RESPONSE] ({message_length} bytes - binary data):{Colors.RESET}")
                        print(f"{Colors.WHITE}{message_bytes}{Colors.RESET}")
                else:
                    # 服务器关闭连接
                    print(f"{Colors.RED}[CLIENT] Server disconnected{Colors.RESET}")
                    self.connected = False
                    break
            except ValueError as e:
                print(f"{Colors.RED}[CLIENT] Protocol error: {e}{Colors.RESET}")
                self.connected = False
                break
            except socket.timeout:
                continue  # 继续循环
            except Exception as e:
                if self.running:
                    print(f"{Colors.RED}[CLIENT] Error receiving message: {e}{Colors.RESET}")
                self.connected = False
                break
        
        # 如果应该重连，启动重连过程
        if self.should_reconnect and self.running and not self.connected:
            self.handle_disconnect()
    
    def send_message(self, message):
        """发送消息到服务器"""
        if not self.connected:
            print(f"{Colors.RED}[CLIENT] Not connected to server{Colors.RESET}")
            return False
            
        try:
            self.send_message_with_length(message)
            print(f"{Colors.BLUE}[CLIENT] Message sent successfully ({len(message)} chars){Colors.RESET}")
            return True
        except Exception as e:
            print(f"{Colors.BRIGHT_RED}[CLIENT] Error sending message: {e}{Colors.RESET}")
            self.connected = False
            return False
    
    def disconnect(self):
        """断开连接"""
        print(f"{Colors.CYAN}[CLIENT] Disconnecting...{Colors.RESET}")
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
        print(f"{Colors.CYAN}[CLIENT] Disconnected from server{Colors.RESET}")
    
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
            
        print(f"{Colors.YELLOW}[CLIENT] Connection lost. Attempting to reconnect...{Colors.RESET}")
        
        # 在新线程中重连，避免阻塞接收线程
        reconnect_thread = threading.Thread(target=self.reconnect_worker)
        reconnect_thread.daemon = True
        reconnect_thread.start()
    
    def reconnect_worker(self):
        """重连工作线程"""
        if self.connect() and self.mode in ['file_monitor', 'folder_monitor']:
            # 重连成功后重新发送文件内容（已经在connect中处理）
            pass
    
    def start_file_monitoring(self, file_path):
        """开始单文件监控模式"""
        if not os.path.exists(file_path):
            print(f"{Colors.RED}[CLIENT] File {file_path} does not exist{Colors.RESET}")
            return False
            
        self.monitoring_file = file_path
        self.mode = 'file_monitor'
        
        # 设置文件监控
        self.file_handler = FileMonitorHandler(self, file_path)  # 传入文件路径
        self.observer = Observer()
        self.observer.schedule(self.file_handler, os.path.dirname(os.path.abspath(file_path)), recursive=False)
        self.observer.start()
        
        print(f"{Colors.CYAN}[CLIENT] Started monitoring file: {file_path}{Colors.RESET}")
        print(f"{Colors.CYAN}[CLIENT] File changes will be automatically sent to server{Colors.RESET}")
        print(f"{Colors.CYAN}[CLIENT] Type 'stop' to stop monitoring and disconnect{Colors.RESET}")
        
        return True
    
    def start_folder_monitoring(self, folder_path):
        """开始文件夹监控模式"""
        if not os.path.exists(folder_path):
            print(f"{Colors.RED}[CLIENT] Folder {folder_path} does not exist{Colors.RESET}")
            return False
            
        self.monitoring_folder = folder_path
        self.mode = 'folder_monitor'
        
        # 设置文件夹监控
        self.file_handler = FolderMonitorHandler(self, folder_path)  # 传入文件夹路径
        self.observer = Observer()
        self.observer.schedule(self.file_handler, folder_path, recursive=True)
        self.observer.start()
        
        print(f"{Colors.CYAN}[CLIENT] Started monitoring folder: {folder_path}{Colors.RESET}")
        print(f"{Colors.CYAN}[CLIENT] File changes in folder will be automatically sent to server{Colors.RESET}")
        print(f"{Colors.CYAN}[CLIENT] Type 'stop' to stop monitoring and disconnect{Colors.RESET}")
        
        return True
    
    def send_file_content(self):
        """发送单文件内容到服务器（用于 file_monitor 模式）"""
        if not self.monitoring_file or not os.path.exists(self.monitoring_file) or not self.connected:
            return
            
        try:
            with open(self.monitoring_file, 'r', encoding='utf-8') as f:
                content = f.read()
                
            if content:
                message = f"[FILE] {os.path.basename(self.monitoring_file)}: {content}"
                if self.send_message(message):
                    print(f"{Colors.BLUE}[CLIENT] File content sent successfully ({len(content)} chars){Colors.RESET}")
                else:
                    print(f"{Colors.BRIGHT_RED}[CLIENT] Failed to send file content{Colors.RESET}")
        except Exception as e:
            print(f"{Colors.RED}[CLIENT] Error reading file: {e}{Colors.RESET}")
    
    def send_single_file_content(self, file_path):
        """发送单个文件内容到服务器（用于 folder_monitor 模式）"""
        if not os.path.exists(file_path) or not self.connected:
            return
            
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            if content:
                message = f"[FILE] {os.path.basename(file_path)}: {content}"
                if self.send_message(message):
                    print(f"{Colors.BLUE}[CLIENT] File {os.path.basename(file_path)} sent successfully ({len(content)} chars){Colors.RESET}")
                else:
                    print(f"{Colors.BRIGHT_RED}[CLIENT] Failed to send file {os.path.basename(file_path)}{Colors.RESET}")
        except Exception as e:
            print(f"{Colors.RED}[CLIENT] Error reading file {file_path}: {e}{Colors.RESET}")
    
    def send_all_folder_files(self):
        """发送文件夹中所有文件的内容（用于 folder_monitor 模式初始化）"""
        if not self.monitoring_folder or not os.path.exists(self.monitoring_folder) or not self.connected:
            return
            
        try:
            # 获取文件夹下所有文件
            files = glob.glob(os.path.join(self.monitoring_folder, "**/*"), recursive=True)
            files = [f for f in files if os.path.isfile(f)]
            
            if not files:
                print(f"{Colors.YELLOW}[CLIENT] No files found in folder{Colors.RESET}")
                return
            
            print(f"{Colors.CYAN}[CLIENT] Sending initial content of {len(files)} files...{Colors.RESET}")
            
            for file_path in sorted(files):  # 按文件名排序
                self.send_single_file_content(file_path)
                
        except Exception as e:
            print(f"{Colors.RED}[CLIENT] Error processing folder: {e}{Colors.RESET}")
    
    def interactive_mode(self):
        """交互模式 - 使用标准 input 支持 readline"""
        print(f"{Colors.CYAN}[CLIENT] Enter messages (type 'quit' or 'exit' to disconnect){Colors.RESET}")
        print(f"{Colors.CYAN}[CLIENT] Special commands:{Colors.RESET}")
        print(f"{Colors.CYAN}  - 'quit' or 'exit': Disconnect{Colors.RESET}")
        print(f"{Colors.CYAN}  - 'help': Show this help{Colors.RESET}")
        if READLINE_AVAILABLE:
            print(f"{Colors.CYAN}  - Use Up/Down arrow keys to navigate history{Colors.RESET}")
        print(f"{Colors.CYAN}[CLIENT] Use Ctrl+C to exit program{Colors.RESET}")
        
        try:
            while self.running and not self.exit_requested:
                if self.connected:
                    try:
                        # 使用标准 input，支持 readline 历史
                        message = input("")
                        
                        if not message.strip():
                            continue
                            
                        # 处理特殊命令
                        if message.lower() in ['quit', 'exit']:
                            self.should_reconnect = False
                            if self.send_message(message):
                                print(f"{Colors.BLUE}[CLIENT] Quit command sent successfully{Colors.RESET}")
                            time.sleep(0.1)  # 等待服务器响应
                            break
                        elif message.lower() == 'help':
                            print(f"{Colors.CYAN}Special commands:{Colors.RESET}")
                            print(f"{Colors.CYAN}  - 'quit' or 'exit': Disconnect{Colors.RESET}")
                            print(f"{Colors.CYAN}  - 'help': Show this help{Colors.RESET}")
                            if READLINE_AVAILABLE:
                                print(f"{Colors.CYAN}  - Use Up/Down arrow keys to navigate history{Colors.RESET}")
                            print(f"{Colors.CYAN}  - Use Ctrl+C to exit program{Colors.RESET}")
                        else:
                            self.send_message(message)
                    except EOFError:
                        # Ctrl+D
                        self.should_reconnect = False
                        break
                    except KeyboardInterrupt:
                        print(f"\n{Colors.CYAN}[CLIENT] Ctrl+C received, exiting...{Colors.RESET}")
                        self.exit_requested = True
                        self.should_reconnect = False
                        break
                    except Exception as e:
                        if self.running:
                            print(f"{Colors.RED}[CLIENT] Error in interactive mode: {e}{Colors.RESET}")
                else:
                    # 未连接时的命令处理
                    try:
                        command = input(f"{Colors.RED}[CLIENT] Disconnected. Commands: 'reconnect', 'quit': {Colors.RESET}")
                        if command.lower() in ['quit', 'exit']:
                            self.should_reconnect = False
                            break
                        elif command.lower() == 'reconnect':
                            if self.connect():
                                print(f"{Colors.BLUE}[CLIENT] Reconnected successfully{Colors.RESET}")
                    except (EOFError, KeyboardInterrupt):
                        self.should_reconnect = False
                        break
                        
        except KeyboardInterrupt:
            print(f"\n{Colors.CYAN}[CLIENT] Interrupted by user{Colors.RESET}")
            self.should_reconnect = False
        finally:
            self.disconnect()
    
    def file_monitor_mode(self, file_path):
        """单文件监控模式"""
        # 先设置监控文件
        self.monitoring_file = file_path
        self.mode = 'file_monitor'
        
        # 然后连接到服务器
        if not self.connect():
            print(f"{Colors.RED}[CLIENT] Failed to connect to server{Colors.RESET}")
            return
            
        # 启动文件监控
        if not self.start_file_monitoring(file_path):
            return
            
        try:
            while self.running:
                if self.connected:
                    try:
                        command = input()
                        if command.lower() == 'stop':
                            print(f"{Colors.CYAN}[CLIENT] Stopping file monitoring...{Colors.RESET}")
                            self.should_reconnect = False
                            break
                    except (EOFError, KeyboardInterrupt):
                        self.should_reconnect = False
                        break
                else:
                    # 未连接时等待重连
                    time.sleep(1)
                        
        except KeyboardInterrupt:
            print(f"\n{Colors.CYAN}[CLIENT] Interrupted by user{Colors.RESET}")
            self.should_reconnect = False
        finally:
            self.disconnect()
    
    def folder_monitor_mode(self, folder_path):
        """文件夹监控模式"""
        # 先设置监控文件夹
        self.monitoring_folder = folder_path
        self.mode = 'folder_monitor'
        
        # 然后连接到服务器
        if not self.connect():
            print(f"{Colors.RED}[CLIENT] Failed to connect to server{Colors.RESET}")
            return
            
        # 启动文件夹监控
        if not self.start_folder_monitoring(folder_path):
            return
            
        try:
            while self.running:
                if self.connected:
                    try:
                        command = input()
                        if command.lower() == 'stop':
                            print(f"{Colors.CYAN}[CLIENT] Stopping folder monitoring...{Colors.RESET}")
                            self.should_reconnect = False
                            break
                    except (EOFError, KeyboardInterrupt):
                        self.should_reconnect = False
                        break
                else:
                    # 未连接时等待重连
                    time.sleep(1)
                        
        except KeyboardInterrupt:
            print(f"\n{Colors.CYAN}[CLIENT] Interrupted by user{Colors.RESET}")
            self.should_reconnect = False
        finally:
            self.disconnect()

def parse_arguments():
    """解析命令行参数"""
    parser = argparse.ArgumentParser(description='TCP Client')
    parser.add_argument('--host', type=str, default='localhost', 
                       help='Server host address (default: localhost)')
    parser.add_argument('--port', type=int, default=8888, 
                       help='Server port (default: 8888)')
    parser.add_argument('--preload-folder', type=str, 
                       help='Folder path to preload content from (optional)')
    
    args = parser.parse_args()
    return args.host, args.port, args.preload_folder

def get_client_mode():
    """获取客户端模式"""
    print(f"\n{Colors.CYAN}[CLIENT] Select mode:{Colors.RESET}")
    print(f"{Colors.CYAN}[CLIENT] 1. Interactive mode (type messages manually){Colors.RESET}")
    print(f"{Colors.CYAN}[CLIENT] 2. Single file monitoring mode (monitor one file changes){Colors.RESET}")
    print(f"{Colors.CYAN}[CLIENT] 3. Folder monitoring mode (monitor all files in folder){Colors.RESET}")
    
    while True:
        choice = input(f"{Colors.CYAN}[CLIENT] Enter choice (1, 2 or 3, default: 1): {Colors.RESET}").strip()
        if not choice or choice == '1':
            return 'interactive'
        elif choice == '2':
            return 'file_monitor'
        elif choice == '3':
            return 'folder_monitor'
        else:
            print(f"{Colors.RED}[CLIENT] Please enter 1, 2 or 3{Colors.RESET}")

def get_file_path():
    """获取要监控的文件路径"""
    while True:
        file_path = input(f"{Colors.CYAN}[CLIENT] Enter file path to monitor: {Colors.RESET}").strip()
        if file_path:
            if os.path.exists(file_path):
                return file_path
            else:
                print(f"{Colors.RED}[CLIENT] File {file_path} does not exist{Colors.RESET}")
        else:
            print(f"{Colors.RED}[CLIENT] Please enter a valid file path{Colors.RESET}")

def get_folder_path():
    """获取要监控的文件夹路径"""
    while True:
        folder_path = input(f"{Colors.CYAN}[CLIENT] Enter folder path to monitor: {Colors.RESET}").strip()
        if folder_path:
            if os.path.exists(folder_path):
                return folder_path
            else:
                print(f"{Colors.RED}[CLIENT] Folder {folder_path} does not exist{Colors.RESET}")
        else:
            print(f"{Colors.RED}[CLIENT] Please enter a valid folder path{Colors.RESET}")

def main():
    # 解析命令行参数
    host, port, preload_folder = parse_arguments()
    
    print(f"{Colors.CYAN}[CLIENT] Using server: {host}:{port}{Colors.RESET}")
    if preload_folder:
        print(f"{Colors.CYAN}[CLIENT] Preload folder: {preload_folder}{Colors.RESET}")
    
    # 获取客户端模式
    mode = get_client_mode()
    
    # 根据模式获取相应参数
    if mode == 'file_monitor':
        # 获取文件路径
        file_path = get_file_path()
        # 创建客户端实例
        client = TCPClient(host, port, preload_folder)
        client.running = True
        client.mode = mode
        
        # 启动文件监控模式（会先设置监控文件再连接）
        client.file_monitor_mode(file_path)
    elif mode == 'folder_monitor':
        # 获取文件夹路径
        folder_path = get_folder_path()
        # 创建客户端实例
        client = TCPClient(host, port, preload_folder)
        client.running = True
        client.mode = mode
        
        # 启动文件夹监控模式（会先设置监控文件夹再连接）
        client.folder_monitor_mode(folder_path)
    else:  # interactive mode
        # 创建客户端实例
        client = TCPClient(host, port, preload_folder)
        client.running = True
        client.mode = mode
        
        # 连接到服务器
        if not client.connect():
            print(f"{Colors.RED}[CLIENT] Failed to connect to server{Colors.RESET}")
            return
            
        # 启动交互模式
        client.interactive_mode()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{Colors.CYAN}[CLIENT] Program interrupted by user{Colors.RESET}")
    except Exception as e:
        print(f"{Colors.RED}[CLIENT] Unexpected error: {e}{Colors.RESET}")
    finally:
        # 确保清理资源
        if 'client' in locals():
            try:
                client.disconnect()
            except:
                pass