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

List<Color> textColors = new List<Color>();
textColors.Add(new Color(255, 140, 0));
textColors.Add(new Color(255, 255, 255));
textColors.Add(new Color(0, 255, 0));
textColors.Add(new Color(0, 0, 255));
textColors.Add(new Color(255, 0, 0));
textColors.Add(new Color(255, 255, 0));
textColors.Add(new Color(0, 255, 255));
textColors.Add(new Color(255, 0, 255));

// Scan a white line 5 pixels thick from right to left and back
// while (true)
// {
//     foreach (Color color in textColors)
//     {
//         for (int i = -5; i < canvas.Width; i++)
//         {
//             canvas.Clear();
//             canvas.DrawLine(i, 0, i, canvas.Height, color);
//             canvas.DrawLine(i + 1, 0, i + 1, canvas.Height, color);
//             canvas.DrawLine(i + 2, 0, i + 2, canvas.Height, color);
//             canvas.DrawLine(i + 3, 0, i + 3, canvas.Height, color);
//             canvas.DrawLine(i + 4, 0, i + 4, canvas.Height, color);
//             matrix.SwapOnVsync(canvas);
//             Task.Delay(100).Wait();
//         }
//     }
// }


matrix.SwapOnVsync(canvas);

// Hold for 5 seconds
Task.Delay(5000).Wait();

// var textColor = new Color(255,140,0);
// textColor = new Color(255,255,255);

Console.WriteLine("Getting text ready");

String topText = "Crooked Billet / Walthamstow Avenue";
int topPos = canvas.Width;

String bottomText = "Bus Stopping";
int bottomPos = canvas.Width;

// Spin up a web server in a separate thread
// new Thread(() =>
// {
//     Thread.CurrentThread.IsBackground = true;
//     
//     using var listener = new HttpListener();
//     listener.Prefixes.Add("http://localhost:8080/");
//     listener.Start();
//     Console.WriteLine("Listening on http://localhost:8080/");
//     while (true)
//     {
//         // Get request
//         var context = listener.GetContext();
//         
//         // get path
//         String path = context.Request.Url.AbsolutePath;
//         
//         if (!(path.StartsWith("/top") || path.StartsWith("/bottom")))
//         {
//             context.Response.StatusCode = 404;
//             context.Response.Close();
//             continue;
//         }
//         
//         bool isTopText = path.StartsWith("/top");
//         String text = path.Split("=")[1];
//         text = WebUtility.UrlDecode(text);
//         
//         if (isTopText)
//         {
//             topText = text;
//             topPos = canvas.Width;
//         }
//         else
//         {
//             bottomText = text;
//             bottomPos = canvas.Width;
//         }
//         
//         context.Response.StatusCode = 200;
//         // Send "Success" message
//         byte[] buffer = System.Text.Encoding.UTF8.GetBytes("Success");
//         context.Response.Close();
//     }
// }).Start();

int numRev = 0;

new Thread(() =>
{
    while (true)
    {
        canvas.Clear();

        Color textColor = textColors[numRev % textColors.Count];

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
    }
}).Start();

/*
 *  Allow the user to type Top=... or Bottom=... to change the text in the console
 */

while (true)
{
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
}

Console.WriteLine("Matrix complete");