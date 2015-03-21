#!/usr/bin/env python 

import socket
from time import sleep
import threading


def handle_connection(client, address):
    print "Client: {} with ip: {} CONNECTED".format(client, address)
    while 1:
        try:
            client.send("ping..")
            sleep(30)
            print "pong.."
        except socket.error:
            print "Client: {} with ip: {} DISCONNECTED".format(client, address)
            return


host = ''
port = 50008
backlog = 5
size = 64
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((host, port))
s.listen(backlog)
print "Star Echo Server...."
print "Host: {} Port: {}".format("0.0.0.0", port)
threads = []
try:
    while 1:
        client, address = s.accept()
        thread = threading.Thread(target=handle_connection, args=(client, address))
        thread.start()
        threads.append(thread)
except KeyboardInterrupt:
    [thread.stop() for thread in threads]
    print "Bye.."
    exit(-1)

