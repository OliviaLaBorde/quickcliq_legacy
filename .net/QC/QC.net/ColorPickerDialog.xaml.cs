using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Shapes;

namespace QC.net;

public partial class ColorPickerDialog : Window
{
    private bool _updating = false;
    private bool _paletteMouseDown = false;
    private bool _hueMouseDown = false;
    
    private double _hue = 0; // 0-360
    private double _saturation = 1; // 0-1
    private double _brightness = 1; // 0-1
    
    public System.Windows.Media.Color SelectedColor { get; private set; }
    
    public ColorPickerDialog(System.Windows.Media.Color initialColor)
    {
        InitializeComponent();
        
        SelectedColor = initialColor;
        
        Loaded += (s, e) =>
        {
            CreateGradients();
            SetFromRgb(initialColor);
        };
    }
    
    private void CreateGradients()
    {
        // Create saturation/brightness gradient on palette
        var whiteBrush = new LinearGradientBrush
        {
            StartPoint = new System.Windows.Point(0, 0),
            EndPoint = new System.Windows.Point(1, 0)
        };
        whiteBrush.GradientStops.Add(new GradientStop(Colors.White, 0));
        whiteBrush.GradientStops.Add(new GradientStop(Colors.Transparent, 1));
        
        var whiteOverlay = new System.Windows.Shapes.Rectangle
        {
            Width = paletteCanvas.ActualWidth,
            Height = paletteCanvas.ActualHeight,
            Fill = whiteBrush
        };
        paletteCanvas.Children.Insert(0, whiteOverlay);
        
        var blackBrush = new LinearGradientBrush
        {
            StartPoint = new System.Windows.Point(0, 0),
            EndPoint = new System.Windows.Point(0, 1)
        };
        blackBrush.GradientStops.Add(new GradientStop(Colors.Transparent, 0));
        blackBrush.GradientStops.Add(new GradientStop(Colors.Black, 1));
        
        var blackOverlay = new System.Windows.Shapes.Rectangle
        {
            Width = paletteCanvas.ActualWidth,
            Height = paletteCanvas.ActualHeight,
            Fill = blackBrush
        };
        paletteCanvas.Children.Insert(1, blackOverlay);
        
        // Create rainbow hue gradient
        var hueBrush = new LinearGradientBrush
        {
            StartPoint = new System.Windows.Point(0, 0),
            EndPoint = new System.Windows.Point(0, 1)
        };
        hueBrush.GradientStops.Add(new GradientStop(System.Windows.Media.Color.FromRgb(255, 0, 0), 0.00)); // Red
        hueBrush.GradientStops.Add(new GradientStop(System.Windows.Media.Color.FromRgb(255, 255, 0), 0.17)); // Yellow
        hueBrush.GradientStops.Add(new GradientStop(System.Windows.Media.Color.FromRgb(0, 255, 0), 0.33)); // Green
        hueBrush.GradientStops.Add(new GradientStop(System.Windows.Media.Color.FromRgb(0, 255, 255), 0.50)); // Cyan
        hueBrush.GradientStops.Add(new GradientStop(System.Windows.Media.Color.FromRgb(0, 0, 255), 0.67)); // Blue
        hueBrush.GradientStops.Add(new GradientStop(System.Windows.Media.Color.FromRgb(255, 0, 255), 0.83)); // Magenta
        hueBrush.GradientStops.Add(new GradientStop(System.Windows.Media.Color.FromRgb(255, 0, 0), 1.00)); // Red
        
        var hueRect = new System.Windows.Shapes.Rectangle
        {
            Width = hueCanvas.ActualWidth,
            Height = hueCanvas.ActualHeight,
            Fill = hueBrush
        };
        hueCanvas.Children.Insert(0, hueRect);
    }
    
    private void SetFromRgb(System.Windows.Media.Color color)
    {
        _updating = true;
        
        // Convert RGB to HSB
        RgbToHsb(color.R, color.G, color.B, out _hue, out _saturation, out _brightness);
        
        UpdateUI();
        
        _updating = false;
    }
    
    private void UpdateUI()
    {
        // Update palette background to current hue
        var hueColor = HsbToRgb(_hue, 1, 1);
        paletteCanvas.Background = new SolidColorBrush(hueColor);
        
        // Update cursors
        if (paletteCanvas.ActualWidth > 0 && paletteCanvas.ActualHeight > 0)
        {
            Canvas.SetLeft(paletteCursor, _saturation * paletteCanvas.ActualWidth - 6);
            Canvas.SetTop(paletteCursor, (1 - _brightness) * paletteCanvas.ActualHeight - 6);
        }
        
        if (hueCanvas.ActualHeight > 0)
        {
            Canvas.SetTop(hueCursor, (_hue / 360.0) * hueCanvas.ActualHeight - 3);
        }
        
        // Update selected color
        SelectedColor = HsbToRgb(_hue, _saturation, _brightness);
        
        // Update displays
        colorPreview.Background = new SolidColorBrush(SelectedColor);
        txtHex.Text = $"#{SelectedColor.R:X2}{SelectedColor.G:X2}{SelectedColor.B:X2}";
        txtR.Text = SelectedColor.R.ToString();
        txtG.Text = SelectedColor.G.ToString();
        txtB.Text = SelectedColor.B.ToString();
    }
    
    private void Palette_MouseDown(object sender, MouseButtonEventArgs e)
    {
        _paletteMouseDown = true;
        paletteCanvas.CaptureMouse();
        UpdateFromPalette(e.GetPosition(paletteCanvas));
    }
    
    private void Palette_MouseMove(object sender, System.Windows.Input.MouseEventArgs e)
    {
        if (_paletteMouseDown)
        {
            UpdateFromPalette(e.GetPosition(paletteCanvas));
        }
    }
    
    private void UpdateFromPalette(System.Windows.Point pos)
    {
        if (_updating || paletteCanvas.ActualWidth == 0 || paletteCanvas.ActualHeight == 0) return;
        
        _updating = true;
        
        _saturation = Math.Clamp(pos.X / paletteCanvas.ActualWidth, 0, 1);
        _brightness = Math.Clamp(1 - (pos.Y / paletteCanvas.ActualHeight), 0, 1);
        
        UpdateUI();
        
        _updating = false;
    }
    
    private void Hue_MouseDown(object sender, MouseButtonEventArgs e)
    {
        _hueMouseDown = true;
        hueCanvas.CaptureMouse();
        UpdateFromHue(e.GetPosition(hueCanvas));
    }
    
    private void Hue_MouseMove(object sender, System.Windows.Input.MouseEventArgs e)
    {
        if (_hueMouseDown)
        {
            UpdateFromHue(e.GetPosition(hueCanvas));
        }
    }
    
    private void UpdateFromHue(System.Windows.Point pos)
    {
        if (_updating || hueCanvas.ActualHeight == 0) return;
        
        _updating = true;
        
        _hue = Math.Clamp((pos.Y / hueCanvas.ActualHeight) * 360, 0, 360);
        
        UpdateUI();
        
        _updating = false;
    }
    
    protected override void OnMouseLeftButtonUp(MouseButtonEventArgs e)
    {
        base.OnMouseLeftButtonUp(e);
        
        if (_paletteMouseDown)
        {
            _paletteMouseDown = false;
            paletteCanvas.ReleaseMouseCapture();
        }
        
        if (_hueMouseDown)
        {
            _hueMouseDown = false;
            hueCanvas.ReleaseMouseCapture();
        }
    }
    
    private void HexInput_Changed(object sender, TextChangedEventArgs e)
    {
        if (_updating || txtHex == null) return;
        
        try
        {
            var hex = txtHex.Text.Trim().Replace("#", "").Replace("0x", "");
            
            if (hex.Length == 6)
            {
                byte r = Convert.ToByte(hex.Substring(0, 2), 16);
                byte g = Convert.ToByte(hex.Substring(2, 2), 16);
                byte b = Convert.ToByte(hex.Substring(4, 2), 16);
                
                SetFromRgb(System.Windows.Media.Color.FromRgb(r, g, b));
            }
        }
        catch { }
    }
    
    private void CommonColor_Click(object sender, RoutedEventArgs e)
    {
        if (sender is System.Windows.Controls.Button button && button.Tag is string colorHex)
        {
            try
            {
                var color = (System.Windows.Media.Color)System.Windows.Media.ColorConverter.ConvertFromString(colorHex);
                SetFromRgb(color);
            }
            catch { }
        }
    }
    
    private void OK_Click(object sender, RoutedEventArgs e)
    {
        DialogResult = true;
        Close();
    }
    
    private void Cancel_Click(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
        Close();
    }
    
    // HSB/RGB Conversion helpers
    private static void RgbToHsb(byte r, byte g, byte b, out double hue, out double saturation, out double brightness)
    {
        double rd = r / 255.0;
        double gd = g / 255.0;
        double bd = b / 255.0;
        
        double max = Math.Max(rd, Math.Max(gd, bd));
        double min = Math.Min(rd, Math.Min(gd, bd));
        double delta = max - min;
        
        brightness = max;
        
        if (max == 0)
        {
            saturation = 0;
            hue = 0;
            return;
        }
        
        saturation = delta / max;
        
        if (delta == 0)
        {
            hue = 0;
        }
        else if (max == rd)
        {
            hue = 60 * (((gd - bd) / delta) % 6);
        }
        else if (max == gd)
        {
            hue = 60 * (((bd - rd) / delta) + 2);
        }
        else
        {
            hue = 60 * (((rd - gd) / delta) + 4);
        }
        
        if (hue < 0) hue += 360;
    }
    
    private static System.Windows.Media.Color HsbToRgb(double hue, double saturation, double brightness)
    {
        double c = brightness * saturation;
        double x = c * (1 - Math.Abs((hue / 60.0) % 2 - 1));
        double m = brightness - c;
        
        double r = 0, g = 0, b = 0;
        
        if (hue < 60)
        {
            r = c; g = x; b = 0;
        }
        else if (hue < 120)
        {
            r = x; g = c; b = 0;
        }
        else if (hue < 180)
        {
            r = 0; g = c; b = x;
        }
        else if (hue < 240)
        {
            r = 0; g = x; b = c;
        }
        else if (hue < 300)
        {
            r = x; g = 0; b = c;
        }
        else
        {
            r = c; g = 0; b = x;
        }
        
        return System.Windows.Media.Color.FromRgb(
            (byte)Math.Round((r + m) * 255),
            (byte)Math.Round((g + m) * 255),
            (byte)Math.Round((b + m) * 255)
        );
    }
}
