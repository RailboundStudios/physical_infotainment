// See https://aka.ms/new-console-template for more information

using RPiRgbLEDMatrix;

var argsList = new List<string>(args);
if (!argsList.Contains("--led-no-hardware-pulse"))
{
    argsList.Add("--led-no-hardware-pulse");
}
// Convert the list back to an array
args = argsList.ToArray();

Console.WriteLine("Creating matrix");
var matrix = new RGBLedMatrix(
    16, 2, 1
);
Console.WriteLine("Matrix created");
var canvas = matrix.CreateOffscreenCanvas();
var font = new RGBLedFont("assets/4x6.bdf");

var color = new Color(255, 0, 0);

String text = "Hello World!";

int pos = canvas.Width;

bool running = true;

Console.WriteLine("Doign stufffffff");

Console.CancelKeyPress += (s, e) =>
{
    running = false;
    e.Cancel = true; // don't terminate, we need to dispose
};


while (running)
{
    canvas.Clear();

    var length = canvas.DrawText(font, pos, 6, color, text);
    matrix.SwapOnVsync(canvas);
    pos -= 1;
    
    if (pos + length < 0)
    {
        pos = canvas.Width;
    }
    
    Task.Delay(100).Wait();
    
    
    Console.WriteLine("pos = " + pos);
}
Console.WriteLine("Matrix complete");