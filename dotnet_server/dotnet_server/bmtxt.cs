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
        return int.Parse(content.Split("\n")[0]);
    }
    public int GetWidth()
    {
        return int.Parse(content.Split("\n")[1]);
    }
    
    public void WriteCanvas(RGBLedCanvas canvas, int x, int y)
    {
        
        List<String> lines = content.Split("\n").ToList();

        int height = int.Parse(lines[0]);
        int width = int.Parse(lines[1]);
        
        int numPixels = height * width;

        List<String> components = lines[2].Split(",").ToList(); // r,g,b,r,g,b...
        
        for (int i = 0; i < numPixels; i++)
        {
            int r = int.Parse(components[i * 3]);
            int g = int.Parse(components[i * 3 + 1]);
            int b = int.Parse(components[i * 3 + 2]);
            
            int x1 = x + i % width;
            int y1 = y + i / width;
            
            canvas.SetPixel(x1, y1, new Color(r, g, b));
        }
        
    }
    
}