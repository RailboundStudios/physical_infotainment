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
using var matrix = new RGBLedMatrix(new RGBLedMatrixOptions
{
    Cols = 96,
    Rows = 16
});
Console.WriteLine("Matrix created");
var canvas = matrix.CreateOffscreenCanvas();

canvas.DrawLine(0,0,canvas.Width,canvas.Height, new Color(255, 0, 0));
canvas.DrawLine(0,canvas.Height,canvas.Width,0, new Color(0, 255, 0));
matrix.SwapOnVsync(canvas);

// Hold for 5 seconds
Task.Delay(5000).Wait();

var font = new RGBLedFont("dotnet_server/assets/test.bdf");
canvas.Clear();
// canvas.DrawText(font, 1, 6, new Color(0, 255, 0), "Testing font");
canvas.DrawText(font, 10, 10, new Color(0, 255, 0), "Testing font");
font.DrawText(canvas._canvas, 1, 6, new Color(0, 255, 0), "Testing font");
matrix.SwapOnVsync(canvas);

// Hold for 5 seconds
Task.Delay(5000).Wait();

var textColor = new Color(255,140,0);

String topText = "Forest Road / Bell Corner";
int topPos = canvas.Width;

String bottomText = "Bus Stopping";
int bottomPos = canvas.Width;

while (true)
{
    canvas.Clear();
    
    int topWidth = font.DrawText(canvas._canvas, topPos, 7, textColor, topText);
    int bottomWidth = font.DrawText(canvas._canvas, bottomPos, 15, textColor, bottomText);

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
        }
    }
    
    matrix.SwapOnVsync(canvas);
    
    Task.Delay(10).Wait();
    
    DateTime now = DateTime.Now;
    // HH:mm AM/PM
    bottomText = now.ToString("hh:mmtt");
    bottomText = bottomText.ToUpper();
}
Console.WriteLine("Matrix complete");