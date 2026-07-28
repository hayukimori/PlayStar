using Godot;
using System;
using System.IO;
using System.Text;

public class GodotConsoleWriter : TextWriter
{
    public override Encoding Encoding => Encoding.UTF8;

    public override void WriteLine(string value)
    {
        GD.Print(value);
    }

    public override void Write(string value)
    {
        if (value != "\r\n" && value != "\n")
        {
            GD.Print(value);
        }
    }
}
