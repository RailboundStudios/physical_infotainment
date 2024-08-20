// See https://aka.ms/new-console-template for more information

using RPiRgbLEDMatrix;

var Matrix = new RGBLedMatrix(
    new RGBLedMatrixOptions
    {
        Rows = 16,
        Cols = 32,
        ChainLength = 4,
    }    
);