import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
import time

from sys import path
path.append('C:\\Development\\Repositories\\physical_infotainment\\python_server\\includes\\rpi-rgb-led-matrix\\bindings\\python\\rgbmatrix')

from rgbmatrix import RGBMatrix, RGBMatrixOptions

topText = "Hello"
bottomText = "World"

options = RGBMatrixOptions()
options.rows = 16
options.cols = 96
options.chain_length = 1

matrix = RGBMatrix(options = options)

matrix.Clear()

hostName = "localhost"
serverPort = 8080

class MyServer(BaseHTTPRequestHandler):
    def do_GET(self):

        isTopText = self.path.startswith("/top")
        text = self.path[5:]

        if isTopText:
            global topText
            topText = text
        else:
            global bottomText
            bottomText = text

def updateDisplay():
    while True:
        matrix.Clear()
        matrix.Fill(255, 0, 0)
        matrix.brightness = 100
        matrix.DrawText(0, 0, 255, 255, 255, topText)
        matrix.DrawText(0, 8, 255, 255, 255, bottomText)
        time.sleep(1)

if __name__ == "__main__":
    webServer = HTTPServer((hostName, serverPort), MyServer)
    print("Server started http://%s:%s" % (hostName, serverPort))

    # Start a new thread to update the display
    displayThread = threading.Thread(target=updateDisplay)
    displayThread.start()

    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()
    print("Server stopped.")