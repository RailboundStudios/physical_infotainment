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

// Spin up a web server in a separate thread
Task.Run(() =>
{
    using var listener = new HttpListener();
    listener.Prefixes.Add("http://localhost:8080/");
    listener.Start();
    Console.WriteLine("Listening on http://localhost:8080/");
    while (true)
    {
        // Get request
        var context = listener.GetContext();
        
        // get path
        String path = context.Request.Url.AbsolutePath;
        
        if (!(path.StartsWith("/top") || path.StartsWith("/bottom")))
        {
            context.Response.StatusCode = 404;
            context.Response.Close();
            continue;
        }
        
        bool isTopText = path.StartsWith("/top");
        String text = path.Split("=")[1];
        text = WebUtility.UrlDecode(text);
        
        if (isTopText)
        {
            topText = text;
            topPos = canvas.Width;
        }
        else
        {
            bottomText = text;
            bottomPos = canvas.Width;
        }
        
        context.Response.StatusCode = 200;
        // Send "Success" message
        byte[] buffer = System.Text.Encoding.UTF8.GetBytes("Success");
        context.Response.Close();
    }
});

while (true)
{
    canvas.Clear();
    
    int topWidth = font.DrawText(canvas._canvas, topPos, 7, textColor, topText);
    int bottomWidth = 0;

    if (bottomText == "%time")
    {
        DateTime now = DateTime.Now;
        // HH:mm AM/PM
        String bottomTextt = now.ToString("hh:mm tt");
        bottomTextt = bottomTextt.ToUpper();
        
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
}
Console.WriteLine("Matrix complete");