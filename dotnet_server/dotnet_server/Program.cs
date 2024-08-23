// See https://aka.ms/new-console-template for more information

using System.Net;
using HashtagChris.DotNetBlueZ;
using HashtagChris.DotNetBlueZ.Extensions;
using RPiRgbLEDMatrix;

var argsList = new List<string>(args);
if (!argsList.Contains("--led-no-hardware-pulse"))
{
    argsList.Add("--led-no-hardware-pulse");
}
// Convert the list back to an array
args = argsList.ToArray();

new Thread(async () =>
{
    Console.WriteLine("Starting Bluetooth");
    
    IAdapter1 adapter = (await BlueZManager.GetAdaptersAsync()).FirstOrDefault();
    
    await adapter.StartDiscoveryAsync();
    
    foreach (Device device in await adapter.GetDevicesAsync())
    {
        Console.WriteLine("Device: " + await device.GetNameAsync());
    }
    
    
}).Start();

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

String workingDir = System.IO.Directory.GetCurrentDirectory();
Console.WriteLine("Working dir: " + workingDir);

String resolvedPath = System.IO.Path.GetFullPath("assets/test.bdf");
Console.WriteLine("Resolved path: " + resolvedPath);

// Does font file exist?
if (!File.Exists(resolvedPath))
{
    Console.WriteLine("Font file not found");
    // return;
}
    
var font = new RGBLedFont("assets/test.bdf");
// var font = new RGBLedFont(resolvedPath);
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

Color fromHSB(double h, double s, double b)
{
    double r = 0, g = 0, bl = 0;
    if (s == 0)
    {
        r = g = bl = b;
    }
    else
    {
        double sectorPos = h / 60.0;
        int sectorNumber = (int)(Math.Floor(sectorPos));
        double fractionalSector = sectorPos - sectorNumber;

        double p = b * (1.0 - s);
        double q = b * (1.0 - (s * fractionalSector));
        double t = b * (1.0 - (s * (1 - fractionalSector)));

        switch (sectorNumber)
        {
            case 0:
                r = b;
                g = t;
                bl = p;
                break;
            case 1:
                r = q;
                g = b;
                bl = p;
                break;
            case 2:
                r = p;
                g = b;
                bl = t;
                break;
            case 3:
                r = p;
                g = q;
                bl = b;
                break;
            case 4:
                r = t;
                g = p;
                bl = b;
                break;
            case 5:
                r = b;
                g = p;
                bl = q;
                break;
        }
    }
    return new Color((byte)(r * 255), (byte)(g * 255), (byte)(bl * 255));
}

bool running = true;

new Thread(() =>
{
    Console.WriteLine("Starting matrix");
    while (running)
    {
        canvas.Clear();

        Color rainbowColor = fromHSB((DateTime.Now.Subtract(DateTime.MinValue.AddYears(1969)).TotalMilliseconds * 0.1) % 360, 1, 1);
        
        Color textColor = textColors[numRev % textColors.Count];
        textColor = rainbowColor;

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
