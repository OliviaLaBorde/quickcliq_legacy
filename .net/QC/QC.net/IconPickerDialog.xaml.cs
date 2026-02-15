using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using MaterialDesignThemes.Wpf;
using QuickCliq.Core.Services;
using QuickCliq.Core.Models;

namespace QC.net;

public partial class IconPickerDialog : Window
{
    private readonly IconResolver _iconResolver = new();
    private string _selectedIcon = string.Empty;
    private List<PackIconKind> _allMaterialIcons = new();
    private bool _emojisLoaded = false;
    
    public string SelectedIcon => _selectedIcon;
    
    public IconPickerDialog(string? currentIcon = null)
    {
        InitializeComponent();
        
        // Parse current icon if provided
        if (!string.IsNullOrWhiteSpace(currentIcon))
        {
            _selectedIcon = currentIcon;
            txtSelectedIcon.Text = currentIcon;
            UpdatePreview();
            btnOK.IsEnabled = true;
        }
        
        // Load Material icons immediately
        LoadMaterialIcons();
        
        // Hook up tab changed event to load emojis lazily
        tabControl.SelectionChanged += TabControl_SelectionChanged;
    }
    
    private void TabControl_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        // Load emojis when emoji tab is first selected
        if (tabControl.SelectedIndex == 1 && !_emojisLoaded)
        {
            // Use Dispatcher to ensure controls are loaded
            Dispatcher.InvokeAsync(() =>
            {
                if (emojiPanel != null)
                {
                    LoadEmojis("smileys");
                    _emojisLoaded = true;
                }
            }, System.Windows.Threading.DispatcherPriority.Loaded);
        }
    }
    
    private void LoadMaterialIcons()
    {
        // Get all PackIconKind enum values
        _allMaterialIcons = Enum.GetValues(typeof(PackIconKind)).Cast<PackIconKind>().ToList();
        // Don't display anything initially - user must search
    }
    
    private void MaterialSearch_TextChanged(object sender, TextChangedEventArgs e)
    {
        if (materialIconsPanel == null) return;
        
        var searchText = txtMaterialSearch.Text.Trim().ToLower();
        
        // Clear previous results
        materialIconsPanel.Children.Clear();
        
        if (string.IsNullOrWhiteSpace(searchText))
        {
            txtMaterialResultCount.Text = "Type to search 1000+ Material Design icons";
            return;
        }
        
        // Filter icons - limit to 50 results for performance
        var filtered = _allMaterialIcons
            .Where(icon => icon.ToString().ToLower().Contains(searchText))
            .Take(50)
            .ToList();
        
        if (filtered.Count == 0)
        {
            txtMaterialResultCount.Text = "No icons found";
            return;
        }
        
        // Update result count
        var totalMatches = _allMaterialIcons.Count(icon => icon.ToString().ToLower().Contains(searchText));
        txtMaterialResultCount.Text = totalMatches > 50 
            ? $"Showing first 50 of {totalMatches} matches" 
            : $"{filtered.Count} icon{(filtered.Count == 1 ? "" : "s")} found";
        
        // Display only the filtered results
        DisplayMaterialIcons(filtered);
    }
    
    private void DisplayMaterialIcons(List<PackIconKind> icons)
    {
        foreach (var iconKind in icons)
        {
            var button = new System.Windows.Controls.Button
            {
                Style = (Style)FindResource("IconButtonStyle"),
                ToolTip = iconKind.ToString(),
                Margin = new Thickness(4)
            };
            
            var stackPanel = new System.Windows.Controls.StackPanel
            {
                Orientation = System.Windows.Controls.Orientation.Vertical,
                HorizontalAlignment = System.Windows.HorizontalAlignment.Center
            };
            
            var icon = new PackIcon
            {
                Kind = iconKind,
                Width = 32,
                Height = 32,
                HorizontalAlignment = System.Windows.HorizontalAlignment.Center
            };
            
            var text = new TextBlock
            {
                Text = iconKind.ToString(),
                FontSize = 9,
                TextAlignment = TextAlignment.Center,
                TextWrapping = TextWrapping.Wrap,
                MaxWidth = 56,
                Margin = new Thickness(0, 4, 0, 0)
            };
            
            stackPanel.Children.Add(icon);
            stackPanel.Children.Add(text);
            button.Content = stackPanel;
            
            var iconName = iconKind.ToString();
            button.Click += (s, e) => SelectMaterialIcon(iconName);
            
            materialIconsPanel.Children.Add(button);
        }
    }
    
    private void SelectMaterialIcon(string iconName)
    {
        _selectedIcon = _iconResolver.CreateIconString(IconType.Material, iconName);
        txtSelectedIcon.Text = _selectedIcon;
        UpdatePreview();
        btnOK.IsEnabled = true;
    }
    
    private void LoadEmojis(string category)
    {
        if (emojiPanel == null) return; // Safety check
        
        emojiPanel.Children.Clear();
        
        var emojis = category switch
        {
            "smileys" => new[]
            {
                // Faces - Positive
                "😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂",
                "🙂", "🙃", "😉", "😊", "😇", "🥰", "😍", "🤩",
                "😘", "😗", "☺️", "😚", "😙", "🥲", "😋", "😛",
                "😜", "🤪", "😝", "🤑", "🤗", "🤭", "🤫", "🤔",
                // Faces - Neutral
                "🤐", "🤨", "😐", "😑", "😶", "😶‍🌫️", "😏", "😒",
                "🙄", "😬", "🤥", "😌", "😔", "😪", "🤤", "😴",
                // Faces - Negative
                "😷", "🤒", "🤕", "🤢", "🤮", "🤧", "🥵", "🥶",
                "🥴", "😵", "😵‍💫", "🤯", "🤠", "🥳", "🥸", "😎",
                "🤓", "🧐", "😕", "😟", "🙁", "☹️", "😮", "😯",
                "😲", "😳", "🥺", "😦", "😧", "😨", "😰", "😥",
                "😢", "😭", "😱", "😖", "😣", "😞", "😓", "😩",
                "😫", "🥱", "😤", "😡", "😠", "🤬", "😈", "👿",
                // Other faces
                "💀", "☠️", "💩", "🤡", "👹", "👺", "👻", "👽",
                "👾", "🤖", "😺", "😸", "😹", "😻", "😼", "😽",
                "🙀", "😿", "😾"
            },
            "people" => new[]
            {
                // Hands & gestures
                "👋", "🤚", "🖐️", "✋", "🖖", "👌", "🤌", "🤏",
                "✌️", "🤞", "🤟", "🤘", "🤙", "👈", "👉", "👆",
                "🖕", "👇", "☝️", "👍", "👎", "✊", "👊", "🤛",
                "🤜", "👏", "🙌", "👐", "🤲", "🤝", "🙏", "✍️",
                "💅", "🤳", "💪", "🦾", "🦿", "🦵", "🦶", "👂",
                // People
                "👶", "👧", "🧒", "👦", "👩", "🧑", "👨", "👩‍🦱",
                "🧑‍🦱", "👨‍🦱", "👩‍🦰", "🧑‍🦰", "👨‍🦰", "👱‍♀️", "👱", "👱‍♂️",
                "👩‍🦳", "🧑‍🦳", "👨‍🦳", "👩‍🦲", "🧑‍🦲", "👨‍🦲", "🧔", "👵",
                "🧓", "👴", "👲", "👳‍♀️", "👳", "👳‍♂️", "🧕", "👮‍♀️",
                "👮", "👮‍♂️", "👷‍♀️", "👷", "👷‍♂️", "💂‍♀️", "💂", "💂‍♂️",
                "🕵️‍♀️", "🕵️", "🕵️‍♂️", "👩‍⚕️", "🧑‍⚕️", "👨‍⚕️", "👩‍🌾", "🧑‍🌾",
                "👨‍🌾", "👩‍🍳", "🧑‍🍳", "👨‍🍳", "👩‍🎓", "🧑‍🎓", "👨‍🎓", "👩‍🎤",
                "🧑‍🎤", "👨‍🎤", "👩‍💻", "🧑‍💻", "👨‍💻", "👩‍🔬", "🧑‍🔬", "👨‍🔬"
            },
            "animals" => new[]
            {
                // Mammals
                "🐶", "🐕", "🦮", "🐕‍🦺", "🐩", "🐺", "🦊", "🦝",
                "🐱", "🐈", "🐈‍⬛", "🦁", "🐯", "🐅", "🐆", "🐴",
                "🐎", "🦄", "🦓", "🦌", "🦬", "🐮", "🐂", "🐃",
                "🐄", "🐷", "🐖", "🐗", "🐽", "🐏", "🐑", "🐐",
                "🐪", "🐫", "🦙", "🦒", "🐘", "🦣", "🦏", "🦛",
                "🐭", "🐁", "🐀", "🐹", "🐰", "🐇", "🐿️", "🦫",
                "🦔", "🦇", "🐻", "🐻‍❄️", "🐨", "🐼", "🦥", "🦦",
                "🦨", "🦘", "🦡",
                // Birds
                "🐔", "🐓", "🐣", "🐤", "🐥", "🐦", "🐧", "🕊️",
                "🦅", "🦆", "🦢", "🦉", "🦤", "🪶", "🦩", "🦚",
                "🦜",
                // Reptiles & Amphibians
                "🐸", "🐊", "🐢", "🦎", "🐍", "🐲", "🐉", "🦕",
                "🦖",
                // Marine
                "🐳", "🐋", "🐬", "🦭", "🐟", "🐠", "🐡", "🦈",
                "🐙", "🐚", "🦀", "🦞", "🦐", "🦑", "🪸",
                // Bugs
                "🐌", "🦋", "🐛", "🐜", "🐝", "🪲", "🐞", "🦗",
                "🪳", "🕷️", "🕸️", "🦂", "🦟", "🪰", "🪱", "🦠",
                // Plants
                "💐", "🌸", "💮", "🏵️", "🌹", "🥀", "🌺", "🌻",
                "🌼", "🌷", "🌱", "🪴", "🌲", "🌳", "🌴", "🌵",
                "🌾", "🌿", "☘️", "🍀", "🍁", "🍂", "🍃"
            },
            "food" => new[]
            {
                // Fruits
                "🍇", "🍈", "🍉", "🍊", "🍋", "🍌", "🍍", "🥭",
                "🍎", "🍏", "🍐", "🍑", "🍒", "🍓", "🫐", "🥝",
                "🍅", "🫒", "🥥",
                // Vegetables
                "🥑", "🍆", "🥔", "🥕", "🌽", "🌶️", "🫑", "🥒",
                "🥬", "🥦", "🧄", "🧅", "🍄", "🥜", "🌰",
                // Prepared Food
                "🍞", "🥐", "🥖", "🫓", "🥨", "🥯", "🥞", "🧇",
                "🧀", "🍖", "🍗", "🥩", "🥓", "🍔", "🍟", "🍕",
                "🌭", "🥪", "🌮", "🌯", "🫔", "🥙", "🧆", "🥚",
                "🍳", "🥘", "🍲", "🫕", "🥣", "🥗", "🍿", "🧈",
                "🧂", "🥫",
                // Asian Food
                "🍱", "🍘", "🍙", "🍚", "🍛", "🍜", "🍝", "🍠",
                "🍢", "🍣", "🍤", "🍥", "🥮", "🍡", "🥟", "🥠",
                "🥡",
                // Sweets
                "🍦", "🍧", "🍨", "🍩", "🍪", "🎂", "🍰", "🧁",
                "🥧", "🍫", "🍬", "🍭", "🍮", "🍯",
                // Drinks
                "🍼", "🥛", "☕", "🫖", "🍵", "🍶", "🍾", "🍷",
                "🍸", "🍹", "🍺", "🍻", "🥂", "🥃", "🥤", "🧋",
                "🧃", "🧉", "🧊"
            },
            "activities" => new[]
            {
                // Sports
                "⚽", "🏀", "🏈", "⚾", "🥎", "🎾", "🏐", "🏉",
                "🥏", "🎱", "🪀", "🏓", "🏸", "🏒", "🏑", "🥍",
                "🏏", "🪃", "🥅", "⛳", "🪁", "🏹", "🎣", "🤿",
                "🥊", "🥋", "🎽", "🛹", "🛼", "🛷", "⛸️", "🥌",
                "🎿", "⛷️", "🏂", "🪂",
                // Sports People
                "🏋️", "🤼", "🤸", "⛹️", "🤺", "🤾", "🏌️", "🏇",
                "🧘", "🏄", "🏊", "🤽", "🚣", "🧗", "🚴", "🚵",
                // Games & Arts
                "🎯", "🪀", "🪁", "🎮", "🕹️", "🎰", "🎲", "🧩",
                "🎭", "🎨", "🧵", "🪡", "🧶", "🪢",
                // Music
                "🎼", "🎵", "🎶", "🎤", "🎧", "🎷", "🎸", "🎹",
                "🎺", "🎻", "🪕", "🥁", "🪘",
                // Performance
                "🎪", "🎬", "🎟️", "🎫"
            },
            "travel" => new[]
            {
                // Transport - Ground
                "🚗", "🚕", "🚙", "🚌", "🚎", "🏎️", "🚓", "🚑",
                "🚒", "🚐", "🛻", "🚚", "🚛", "🚜", "🦯", "🦽",
                "🦼", "🛴", "🚲", "🛵", "🏍️", "🛺", "🚨", "🚔",
                "🚍", "🚘", "🚖", "🚡", "🚠", "🚟", "🚃", "🚋",
                "🚞", "🚝", "🚄", "🚅", "🚈", "🚂", "🚆", "🚇",
                "🚊", "🚉", "✈️", "🛫", "🛬",
                // Transport - Air & Water
                "🛩️", "💺", "🛰️", "🚀", "🛸", "🚁", "🛶", "⛵",
                "🚤", "🛥️", "🛳️", "⛴️", "🚢", "⚓", "🪝", "⛽",
                "🚧", "🚦", "🚥", "🚏",
                // Buildings
                "🏠", "🏡", "🏘️", "🏚️", "🏗️", "🏭", "🏢", "🏬",
                "🏣", "🏤", "🏥", "🏦", "🏨", "🏪", "🏫", "🏩",
                "💒", "🏛️", "⛪", "🕌", "🕍", "🛕", "🕋", "⛩️",
                "🛤️", "🛣️", "🗺️", "🗿", "🗽", "🗼", "🏰", "🏯",
                // Nature Places
                "🌋", "⛰️", "🏔️", "🗻", "🏕️", "🏖️", "🏜️", "🏝️",
                "🏞️"
            },
            "objects" => new[]
            {
                // Office
                "📁", "📂", "🗂️", "📅", "📆", "🗒️", "🗓️", "📇",
                "📈", "📉", "📊", "📋", "📌", "📍", "📎", "🖇️",
                "📏", "📐", "✂️", "🗃️", "🗄️", "🗑️",
                // Security
                "🔒", "🔓", "🔐", "🔑", "🗝️",
                // Tools
                "🔨", "🪓", "⛏️", "⚒️", "🛠️", "🗡️", "⚔️", "🔧",
                "🪛", "🔩", "⚙️", "🗜️", "⚖️", "🦯", "🔗", "⛓️",
                "🪝", "🧰", "🧲", "🪜",
                // Tech
                "💻", "🖥️", "🖨️", "⌨️", "🖱️", "🖲️", "💽", "💾",
                "💿", "📀", "🧮", "📱", "📲", "☎️", "📞", "📟",
                "📠", "📺", "📻", "🎙️", "🎚️", "🎛️", "🧭", "⏱️",
                "⏲️", "⏰", "🕰️", "⌛", "⏳", "📡", "🔋", "🔌",
                "💡", "🔦", "🕯️", "🪔", "🧯",
                // Household
                "🛢️", "💸", "💵", "💴", "💶", "💷", "🪙", "💰",
                "💳", "💎", "⚖️", "🪜", "🧰", "🪛", "🔧", "🔨",
                // Medical
                "🩹", "🩺", "💊", "💉", "🩸", "🧬", "🦠", "🧫",
                "🧪", "🌡️", "🧹", "🧺", "🧻", "🪣", "🧼", "🪥",
                "🧽", "🧴", "🛁", "🛀", "🧖",
                // Camera & Video
                "📷", "📸", "📹", "📼", "🔍", "🔎", "🕯️", "💡",
                "🔦", "🏮", "🪔",
                // Books & Writing
                "📔", "📕", "📖", "📗", "📘", "📙", "📚", "📓",
                "📒", "📃", "📜", "📄", "📰", "🗞️", "📑", "🔖",
                "🏷️", "💰", "🪙", "💴", "💵", "💶", "💷", "💸",
                "💳", "🧾", "✉️", "📧", "📨", "📩", "📤", "📥",
                "📦", "📫", "📪", "📬", "📭", "📮", "🗳️"
            },
            "symbols" => new[]
            {
                // Hearts
                "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍",
                "🤎", "💔", "❤️‍🔥", "❤️‍🩹", "❣️", "💕", "💞", "💓",
                "💗", "💖", "💘", "💝",
                // Emotion symbols
                "💟", "☮️", "✝️", "☪️", "🕉️", "☸️", "✡️", "🔯",
                "🕎", "☯️", "☦️", "🛐", "⛎",
                // Zodiac
                "♈", "♉", "♊", "♋", "♌", "♍", "♎", "♏",
                "♐", "♑", "♒", "♓",
                // Checkmarks & X
                "✅", "✔️", "☑️", "✖️", "❌", "❎",
                // Math & Symbols
                "➕", "➖", "➗", "✖️", "🟰", "♾️", "‼️", "⁉️",
                "❓", "❔", "❕", "❗", "〰️",
                // Currency
                "💱", "💲", "💹",
                // Medical & Hazard
                "⚕️", "♻️", "⚜️", "🔱", "📛", "🔰", "⭕", "✔️",
                "☑️", "🔘", "⚪", "⚫", "🔴", "🔵", "🟠", "🟡",
                "🟢", "🟣", "🟤", "🟥", "🟧", "🟨", "🟩", "🟦",
                "🟪", "🟫", "⬛", "⬜", "◼️", "◻️", "◾", "◽",
                "▪️", "▫️", "🔶", "🔷", "🔸", "🔹", "🔺", "🔻",
                "💠", "🔘", "🔳", "🔲",
                // Arrows
                "🔼", "🔽", "⏫", "⏬", "⬆️", "↗️", "➡️", "↘️",
                "⬇️", "↙️", "⬅️", "↖️", "↕️", "↔️", "↩️", "↪️",
                "⤴️", "⤵️", "🔀", "🔁", "🔂", "🔄", "🔃",
                // Media Controls
                "⏩", "⏭️", "⏯️", "⏸️", "⏹️", "⏺️", "⏏️", "🎦",
                "🔅", "🔆", "📶", "📳", "📴",
                // Stars & Symbols
                "⭐", "🌟", "✨", "⚡", "💥", "💫", "🔥", "💧",
                "💦", "💨", "☁️", "⛅", "☀️", "🌤️", "⛈️", "🌩️",
                "💡", "🔦", "🪔", "💤", "💯", "💢", "🔔", "🔕",
                "📢", "📣", "🔇", "🔈", "🔉", "🔊", "🎵", "🎶",
                "⚠️", "🚸", "⛔", "🚫", "🚳", "🚭", "🚯", "🚱",
                "🚷", "📵", "🔞", "☢️", "☣️"
            },
            "flags" => new[]
            {
                // Common flags
                "🏁", "🚩", "🎌", "🏴", "🏳️", "🏳️‍🌈", "🏳️‍⚧️", "🏴‍☠️",
                // Country flags (selection of common ones)
                "🇺🇸", "🇬🇧", "🇨🇦", "🇦🇺", "🇯🇵", "🇰🇷", "🇨🇳", "🇮🇳",
                "🇧🇷", "🇲🇽", "🇪🇸", "🇫🇷", "🇩🇪", "🇮🇹", "🇷🇺", "🇿🇦",
                "🇸🇦", "🇦🇪", "🇮🇱", "🇹🇷", "🇬🇷", "🇵🇱", "🇸🇪", "🇳🇴",
                "🇩🇰", "🇫🇮", "🇮🇪", "🇵🇹", "🇳🇱", "🇧🇪", "🇨🇭", "🇦🇹",
                "🇨🇿", "🇸🇰", "🇭🇺", "🇷🇴", "🇧🇬", "🇭🇷", "🇸🇮", "🇱🇹",
                "🇱🇻", "🇪🇪", "🇺🇦", "🇦🇷", "🇨🇱", "🇨🇴", "🇵🇪", "🇻🇪",
                "🇨🇺", "🇯🇲", "🇵🇷", "🇩🇴", "🇪🇬", "🇳🇬", "🇰🇪", "🇪🇹",
                "🇬🇭", "🇹🇿", "🇿🇼", "🇲🇦", "🇹🇳", "🇩🇿", "🇱🇾", "🇸🇩",
                "🇵🇰", "🇧🇩", "🇱🇰", "🇲🇲", "🇹🇭", "🇻🇳", "🇵🇭", "🇮🇩",
                "🇲🇾", "🇸🇬", "🇳🇿", "🇵🇬", "🇫🇯"
            },
            _ => Array.Empty<string>()
        };
        
        foreach (var emoji in emojis)
        {
            var button = new System.Windows.Controls.Button
            {
                Style = (Style)FindResource("EmojiButtonStyle"),
                Content = emoji,
                ToolTip = emoji
            };
            
            button.Click += (s, e) => SelectEmoji(emoji);
            emojiPanel.Children.Add(button);
        }
    }
    
    private void SelectEmoji(string emoji)
    {
        _selectedIcon = _iconResolver.CreateIconString(IconType.Emoji, emoji);
        txtSelectedIcon.Text = _selectedIcon;
        UpdatePreview();
        btnOK.IsEnabled = true;
    }
    
    private void UpdatePreview()
    {
        previewContent.Content = null;
        
        var iconData = _iconResolver.Resolve(_selectedIcon);
        
        switch (iconData.Type)
        {
            case IconType.Material:
                if (Enum.TryParse<PackIconKind>(iconData.Value, out var iconKind))
                {
                    previewContent.Content = new PackIcon
                    {
                        Kind = iconKind,
                        Width = 32,
                        Height = 32
                    };
                }
                break;
                
            case IconType.Emoji:
                previewContent.Content = new TextBlock
                {
                    Text = iconData.Value,
                    FontSize = 32,
                    TextAlignment = TextAlignment.Center
                };
                break;
                
            case IconType.File:
                try
                {
                    var image = new System.Windows.Controls.Image
                    {
                        Width = 32,
                        Height = 32,
                        Source = new System.Windows.Media.Imaging.BitmapImage(
                            new Uri(iconData.Value, UriKind.Absolute))
                    };
                    previewContent.Content = image;
                }
                catch
                {
                    // If file can't be loaded, show icon placeholder
                    previewContent.Content = new PackIcon
                    {
                        Kind = PackIconKind.ImageBroken,
                        Width = 32,
                        Height = 32,
                        Opacity = 0.3
                    };
                }
                break;
        }
    }
    
    private void EmojiCategory_Changed(object sender, SelectionChangedEventArgs e)
    {
        if (cmbEmojiCategory.SelectedItem is ComboBoxItem item && item.Tag is string category)
        {
            LoadEmojis(category);
        }
    }
    
    private void BrowseFile_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Title = "Select Icon File",
            Filter = "Icon files (*.ico)|*.ico|Image files (*.png;*.jpg;*.bmp)|*.png;*.jpg;*.bmp|All files (*.*)|*.*",
            CheckFileExists = true
        };
        
        if (dialog.ShowDialog() == true)
        {
            _selectedIcon = _iconResolver.CreateIconString(IconType.File, dialog.FileName);
            txtSelectedIcon.Text = _selectedIcon;
            UpdatePreview();
            btnOK.IsEnabled = true;
        }
    }
    
    private void Clear_Click(object sender, RoutedEventArgs e)
    {
        _selectedIcon = string.Empty;
        txtSelectedIcon.Text = string.Empty;
        previewContent.Content = null;
        btnOK.IsEnabled = false;
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
}
