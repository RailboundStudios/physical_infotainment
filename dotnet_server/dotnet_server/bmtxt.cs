using RPiRgbLEDMatrix;

namespace dotnet_server;

public class bmtxt
{
    
    String content;
    
    public bmtxt(String content)
    {
        this.content = content;
    }

    public int GetHeight()
    {
        return Int32.Parse(content.Split("\n")[1]);
    }
    public int GetWidth()
    {
        return Int32.Parse(content.Split("\n")[0]);
    }
    
    public void WriteCanvas(RGBLedCanvas canvas, int x, int y)
    {
        Console.WriteLine("Writing bmtxt to canvas");
        
        String[] lines = content.Split("\n");

        int height = Int32.Parse(lines[1]);
        int width = Int32.Parse(lines[0]);
        
        int numPixels = height * width;

        String[] components = lines[2].Split(","); // r,g,b,r,g,b...
        
        Console.WriteLine("NumComponents: " + components.Length);
        
        for (int i = 0; i < numPixels; i++)
        {
            int r = Int32.Parse(components[i * 3]);
            int g = Int32.Parse(components[i * 3 + 1]);
            int b = Int32.Parse(components[i * 3 + 2]);
            
            int x1 = x + i % width;
            int y1 = y + i / width;
            
            canvas.SetPixel(x1, y1, new Color(r, g, b));
        }
        
        Console.WriteLine("Done writing bmtxt to canvas");
    }
    
}