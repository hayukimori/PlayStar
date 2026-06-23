using Godot;

namespace PlayStar.Scripts.Models;
[GlobalClass]
public partial class UserDefaults : Resource
{
    [Export] public bool RandomMode { get; set; } = false;
    [Export] public int RepeatMode { get; set; } = 0;
}