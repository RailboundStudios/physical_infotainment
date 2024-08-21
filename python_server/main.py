import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
import time

from sys import path
path.append('/home/imbenji/physical_infotainment/python_server/includes/rpi-rgb-led-matrix/bindings/python/rgbmatrix')


from rgbmatrix import RGBMatrix, RGBMatrixOptions, graphics

topText = "Walthamstow Central"
bottomText = "World"
topPos = 0
bottomPos = 0

options = RGBMatrixOptions()
options.rows = 16
options.cols = 32
options.chain_length = 3
options.parallel = 1
options.gpio_slowdown = 4
options.show_refresh_rate = True
options.hardware_mapping = "adafruit-hat"

matrix = RGBMatrix(options = options)
matrix.brightness = 100
canvas = matrix.CreateFrameCanvas()

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
        text = self.path.split("=")[1]
        text = text.replace("%20", " ")

        if isTopText:
            global topText
            topText = text
            topPos = canvas.width

            # Send response status code with html "successfully updated top text"
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(bytes("Successfully updated top text", "utf-8"))

        else:
            global bottomText
            bottomText = text
            bottomPos = canvas.width

            # Send response status code with html "successfully updated bottom text"
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(bytes("Successfully updated bottom text", "utf-8"))

        # updateDisplay()


font = graphics.Font()
font.LoadFont("assets/test.bdf")

def updateDisplay():
    global font
    global canvas
    global topPos
    global bottomPos

    while True:
        canvas.Clear()

        textColor = graphics.Color(255,140,0)

        topLength = graphics.DrawText(canvas, font, topPos, 7, textColor, topText)
        bottomLength = graphics.DrawText(canvas, font, bottomPos, 15, textColor, bottomText)

        if topLength > canvas.width:
            topPos-=1
            if (topPos + topLength < 0):
                topPos = canvas.width

        if bottomLength > canvas.width:
            bottomPos-=1
            if (bottomPos + bottomLength < 0):
                bottomPos = canvas.width

        # Draw a cross
        lineAColor = graphics.Color(20, 0, 0)
        lineBColor = graphics.Color(0, 0, 20)
        # graphics.DrawLine(canvas, 0, 0, matrix.width, 15, lineAColor)
        # graphics.DrawLine(canvas, 0, matrix.height, matrix.width, 0, lineBColor)

        canvas = matrix.SwapOnVSync(canvas)

        time.sleep(0.02)

        # matrix.Clear()

        # time.sleep(0.01)

        print("=== Updated display ======================")
        print("Top text: ", topText)
        print("Bottom text: ", bottomText)
        print("==========================================")

# updateDisplay()



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