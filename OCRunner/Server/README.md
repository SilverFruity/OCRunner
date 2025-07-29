## How to use ObjcScript

1. Run server in applications,

   ```objc
   #import <ObjcScript/TcpServer.h>
   ObjcScriptRunExeServer();
   ```

2. Get `en0` IPv4 address `30.211.98.210` in Xcode console log:

   ```
   [SERVER] Starting TCP server on port 8888...
   [SERVER] Maximum message size: 1048576 bytes (1.00 MB)
   [SERVER] Maximum clients: 1
   [SERVER] Local IPv4 Addresses:
   [SERVER]   en2: 169.254.54.129
   [SERVER]   en0: 30.211.98.210
   [SERVER] Server listening on port 8888
   [SERVER] Waiting for a single client connection...
   [SERVER] Commands: 'quit' or 'exit' to disconnect
   [SERVER] Use StopTcpServer() to stop server
   [SERVER] RunTcpServer completed, server running in backgroun
   ```

2. Then use script to connect server

   ```shell
   python3 ObjcScriptClient.py --host 30.211.98.210 --preload-folder xxx/Scripts.bundle
   ```

   