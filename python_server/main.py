import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
import time

from sys import path
path.append('C:\\Development\\Repositories\\physical_infotainment\\python_server\\includes\\rpi-rgb-led-matrix\\bindings\\python\\rgbmatrix')

from rgbmatrix import RGBMatrix, RGBMatrixOptions, graphics

topText = "Hello"
bottomText = "World"

options = RGBMatrixOptions()
options.rows = 16
options.cols = 64
options.gpio_slowdown = 4

matrix = RGBMatrix(options = options)

matrix.Clear()

hostName = "0.0.0.0"
serverPort = 8080

class MyServer(BaseHTTPRequestHandler):
    def do_GET(self):

        print("GET request, Path:", self.path)

        if not (self.path.startswith("/top") or self.path.startswith("/bottom")):
            self.send_response(400)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(bytes("Invalid path", "utf-8"))
            return

        isTopText = self.path.startswith("/top")
        text = self.path[5:]

        if isTopText:
            global topText
            topText = text

            # Send response status code with html "successfully updated top text"
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(bytes("Successfully updated top text", "utf-8"))

        else:
            global bottomText
            bottomText = text

            # Send response status code with html "successfully updated bottom text"
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(bytes("Successfully updated bottom text", "utf-8"))


font = graphics.Font()
font.LoadFont("assets/4x6.bdf")

def updateDisplay():
    global font

    canvas = matrix.CreateFrameCanvas()
    textColor = graphics.Color(255, 255, 255)

    while True:
        canvas.Clear()

        graphics.DrawText(canvas, font, 0, 6, textColor, topText)
        graphics.DrawText(canvas, font, 0, 12, textColor, bottomText)

        canvas = matrix.SwapOnVSync(canvas)

        print("Updated display")
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