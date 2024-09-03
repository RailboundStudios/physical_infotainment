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
        
        // Lambda to convert 1d index to 2d index
        Func<int, int, int> index = (i, j) => i * width + j;

        List<String> components = lines[2].Split(",").ToList(); // r,g,b,r,g,b...
        
        for (int i = 0; i < height; i++)
        {
            for (int j = 0; j < width; j++)
            {
                int r = int.Parse(components[index(i, j)]);
                int g = int.Parse(components[index(i, j) + 1]);
                int b = int.Parse(components[index(i, j) + 2]);
                
                canvas.SetPixel(x + j, y + i, new Color(r, g, b));
            }
        }
    }
    
}