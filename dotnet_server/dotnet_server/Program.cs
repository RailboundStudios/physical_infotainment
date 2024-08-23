// See https://aka.ms/new-console-template for more information

using System.Net;
using RPiRgbLEDMatrix;

var argsList = new List<string>(args);
if (!argsList.Contains("--led-no-hardware-pulse"))
{
    argsList.Add("--led-no-hardware-pulse");
}
// Convert the list back to an array
args = argsList.ToArray();

Console.WriteLine("Creating matrix");
using var matrix = new RGBLedMatrix(new RGBLedMatrixOptions
{
    Cols = 128,
    Rows = 16
});
Console.WriteLine("Matrix created");
var canvas = matrix.CreateOffscreenCanvas();

canvas.DrawLine(0,0,canvas.Width,canvas.Height, new Color(255, 0, 0));
canvas.DrawLine(0,canvas.Height,canvas.Width,0, new Color(0, 255, 0));
matrix.SwapOnVsync(canvas);

// Hold for 5 seconds
Task.Delay(5000).Wait();

String exePath = System.Reflection.Assembly.GetExecutingAssembly().Location;
String exeDir = System.IO.Path.GetDirectoryName(exePath);
Console.WriteLine("Exe dir: " + exeDir);

String fontPath = exeDir+"/../assets/test.bdf";
String resolvedPath = System.IO.Path.GetFullPath(fontPath);

Console.WriteLine("Font path: " + resolvedPath);

var font = new RGBLedFont("assets/test.bdf");
canvas.Clear();

List<Color> textColors = new List<Color>();
textColors.Add(new Color(255, 140, 0));
textColors.Add(new Color(255, 255, 255));
textColors.Add(new Color(0, 255, 0));
textColors.Add(new Color(0, 0, 255));
textColors.Add(new Color(255, 0, 0));
textColors.Add(new Color(255, 255, 0));
textColors.Add(new Color(0, 255, 255));
textColors.Add(new Color(255, 0, 255));

Console.WriteLine("Getting text ready");

String topText = "Crooked Billet / Walthamstow Avenue";
int topPos = canvas.Width;

String bottomText = "Bus Stopping";
int bottomPos = canvas.Width;

int numRev = 0;
/*
 *  Allow the user to type Top=... or Bottom=... to change the text in the console
 */

bool running = true;

new Thread(() =>
{
    Console.WriteLine("Starting matrix");
    while (running)
    {
        canvas.Clear();

        Color textColor = textColors[numRev % textColors.Count];

        int topWidth = font.DrawText(canvas._canvas, topPos, 7, textColor, topText);
        int bottomWidth = 0;

        if (bottomText == "%time")
        {
            DateTime now = DateTime.Now;
            String bottomTextt = now.ToString("hh:mm tt").ToUpper();
            bottomWidth = font.DrawText(canvas._canvas, bottomPos, 15, textColor, bottomTextt);
        }
        else
        {
            bottomWidth = font.DrawText(canvas._canvas, bottomPos, 15, textColor, bottomText);
        }

        if (topWidth <= canvas.Width)
        {
            topPos = (canvas.Width - topWidth) / 2;
        }
        else
        {
            topPos -= 1;
            if (topPos < -topWidth)
            {
                topPos = canvas.Width;
                numRev++;
            }
        }

        if (bottomWidth <= canvas.Width)
        {
            bottomPos = (canvas.Width - bottomWidth) / 2;
        }
        else
        {
            bottomPos -= 1;
            if (bottomPos < -bottomWidth)
            {
                bottomPos = canvas.Width;
                numRev++;
            }
        }

        matrix.SwapOnVsync(canvas);

        Task.Delay(10).Wait();
        // Console.WriteLine("Matrix running");
    }
    Console.WriteLine("Matrix stopped");
}).Start();

while (running)
{
    Console.WriteLine("Type 'Top=...' or 'Bottom=...' to change the text, or type 'exit' to quit");
    String input = Console.ReadLine();
    if (input.StartsWith("Top="))
    {
        topText = input.Split("=")[1];
        topPos = canvas.Width;
    }
    else if (input.StartsWith("Bottom="))
    {
        bottomText = input.Split("=")[1];
        bottomPos = canvas.Width;
    }
    else if (input.Equals("exit", StringComparison.OrdinalIgnoreCase))
    {
        running = false;
    }
    else
    {
        Console.WriteLine("Invalid input. Use 'Top=...' or 'Bottom=...' or type 'exit' to quit.");
    }
}

Console.WriteLine("Matrix complete");
