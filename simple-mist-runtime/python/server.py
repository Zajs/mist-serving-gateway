#!/usr/bin/env python

import signal
import os
from BaseHTTPServer import BaseHTTPRequestHandler,HTTPServer

class myHandler(BaseHTTPRequestHandler):
	#Handler for the GET requests
	def do_GET(self):
		self.send_response(200)
		self.send_header('Content-type','text/html')
		self.end_headers()
		# Send the html message

		self.wfile.write("Hello World !")
		self.wfile.write(" MODEL_VERSION=" + MODEL_VERSION)
		self.wfile.write(" MODEL_NAME=" + MODEL_NAME)
		self.wfile.write(" MODEL_TYPE=" + MODEL_TYPE)
		return

PORT_NUMBER = 8080
MODEL_VERSION=os.getenv('MODEL_VERSION', "version")
MODEL_NAME=os.getenv('MODEL_NAME', "name")
MODEL_TYPE=os.getenv('MODEL_TYPE', "type")

server = HTTPServer(('', PORT_NUMBER), myHandler)

def sigterm_handler(_signo, _stack_frame):
	server.socket.close()

signal.signal(signal.SIGTERM, sigterm_handler)

print 'Started httpserver on port ' , PORT_NUMBER

server.serve_forever()