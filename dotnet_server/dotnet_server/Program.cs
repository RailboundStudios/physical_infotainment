// See https://aka.ms/new-console-template for more information

using RPiRgbLEDMatrix;

var matrix = new RGBLedMatrix(
    new RGBLedMatrixOptions
    {
        Rows = 16,
        Cols = 32,
        ChainLength = 4,
    }    
);
var canvas = matrix.CreateOffscreenCanvas();
var font = new RGBLedFont("assets/4x6.bdf");

var color = new Color(255, 0, 0);

String text = "Hello World!";

int pos = canvas.Width;

bool running = true;

Console.CancelKeyPress += (s, e) =>
{
    running = false;
    e.Cancel = true; // don't terminate, we need to dispose
};


while (running)
{
    canvas.Clear();

    var length = canvas.DrawText(font, pos, 0, color, text);
    pos -= 1;
    
    if (pos + length < 0)
    {
        pos = canvas.Width;
    }
    
    Task.Delay(10).Wait();
    matrix.SwapOnVsync(canvas);
    
    Console.WriteLine("update");
}