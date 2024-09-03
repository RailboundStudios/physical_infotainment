// See https://aka.ms/new-console-template for more information

using RPiRgbLEDMatrix;
using System.Runtime.InteropServices;
using Color = RPiRgbLEDMatrix.Color;
using System.Drawing;
using dotnet_server;

// Initialise the matrix
Console.WriteLine("Creating matrix");
using var matrix = new RGBLedMatrix(new RGBLedMatrixOptions
{
    Cols = 128,
    Rows = 16
});
Console.WriteLine("Matrix created");

// Create a canvas
var canvas = matrix.CreateOffscreenCanvas();

// Initialise the boot sequence
bmtxt bootImage = new bmtxt(File.ReadAllText("./assets/logo.txt"));
Console.WriteLine("Boot image loaded");
int bootWidth = bootImage.GetWidth();
// Place in the middle of the screen
bootImage.WriteCanvas(canvas, (canvas.Width - bootWidth) / 2, 0);
Console.WriteLine("Boot image written");
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

// Config
Color textColor = new Color(231, 164, 57);
int FrameMs = 10;

Console.WriteLine("Getting text ready");

String topText = "";
int topPos = canvas.Width;

String bottomText = "";
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
        
        if (textColor is { R: 0, G: 0, B: 0 })
        {
            textColor = rainbowColor;
        }
        
        int topWidth = canvas.DrawText(font, topPos, 7, textColor, topText);
        int bottomWidth = 0;

        if (bottomText == "%time")
        {
            DateTime now = DateTime.Now;
            String bottomTextt = now.ToString("hh:mm tt").ToUpper();
            // bottomWidth = font.DrawText(canvas._canvas, bottomPos, 15, textColor, bottomTextt);
            bottomWidth = canvas.DrawText(font, bottomPos, 16, textColor, bottomTextt);
        }
        else
        {
            // bottomWidth = font.DrawText(canvas._canvas, bottomPos, 15, textColor, bottomText);
            bottomWidth = canvas.DrawText(font, bottomPos, 16, textColor, bottomText);
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

        Task.Delay(FrameMs).Wait();
        // Console.WriteLine("Matrix running");
    }
    Console.WriteLine("Matrix stopped");
}).Start();




while (running)
{
    Console.WriteLine("Type: ");
    Console.WriteLine("Top=... # to change the top text");
    Console.WriteLine("Bottom=... # to change the bottom text");
    Console.WriteLine("Color=... # to change the color (r, g, b)");
    Console.WriteLine("Speed=... # to change the speed");
    Console.WriteLine("exit # to quit");
    
    String? input = Console.ReadLine();

    if (input == null)
    {
        continue;
    }
    
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
    else if (input.StartsWith("Color="))
    {
        String[] colorParts = input.Split("=")[1].Split(",");
        if (colorParts.Length == 3)
        {
            textColor = new Color(byte.Parse(colorParts[0]), byte.Parse(colorParts[1]), byte.Parse(colorParts[2]));
        }
    }
    else if (input.StartsWith("Speed="))
    {
        FrameMs = int.Parse(input.Split("=")[1]);
    }
    else if (input.Equals("exit", StringComparison.OrdinalIgnoreCase))
    {
        running = false;
    }
    else
    {
        Console.WriteLine("Invalid command");
    }
}

Console.WriteLine("Matrix complete");
