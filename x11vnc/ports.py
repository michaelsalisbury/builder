import socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind(("127.0.0.1", 0))
s.listen(1)
ipaddr, port = s.getsockname()
print port
