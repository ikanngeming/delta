--[=[
    GOLO UI LIBRARY
    Custom Roblox UI library, built from scratch.

    Usage:
    local Library = loadstring(game:HttpGet("YOUR_RAW_URL/golo_library.lua"))()
    local Window = Library.CreateLib("IkannHU", "DarkTheme", {
        BackgroundImage = "rbxassetid://5252447904",
        BackgroundTransparency = 0.45,
        Subtitle = "custom.roblox",
        StatusText = "Keyless",
        AvatarText = "G",
    })
    local Tab = Window:NewTab("Main")
    local Section = Tab:NewSection("Features")
    local Selection = Section:NewSelection("Areas to Steal", {"Snow", "Forest", "Desert"}, function(value) print(value) end)
    Section:NewButton("Start", "Start selected feature", function() print("Start:", Selection:GetValue()) end)
    Section:NewButton("Example", "Run example", function() print("clicked") end)
    Section:NewToggle("Enabled", false, function(value) print(value) end)
]=]

local Library = {}
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local themes = {
    DarkTheme = {
        Accent = Color3.fromRGB(190, 68, 255), Accent2 = Color3.fromRGB(255, 87, 218),
        Text = Color3.fromRGB(246, 241, 255), Muted = Color3.fromRGB(201, 193, 215),
        Panel = Color3.fromRGB(34, 22, 57), PanelDark = Color3.fromRGB(24, 17, 43),
        Line = Color3.fromRGB(151, 117, 185),
    },
    PurpleTheme = {
        Accent = Color3.fromRGB(125, 83, 255), Accent2 = Color3.fromRGB(220, 100, 255),
        Text = Color3.fromRGB(255, 255, 255), Muted = Color3.fromRGB(190, 180, 210),
        Panel = Color3.fromRGB(38, 27, 65), PanelDark = Color3.fromRGB(25, 18, 45),
        Line = Color3.fromRGB(115, 90, 165),
    },
}

local function make(className, props, parent)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do object[key] = value end
    object.Parent = parent
    return object
end

local function round(parent, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 7)}, parent)
end

local function tween(object, props)
    TweenService:Create(object, TweenInfo.new(.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function label(parent, value, size, color, font)
    return make("TextLabel", {BackgroundTransparency = 1, Text = value, TextSize = size or 13,
        TextColor3 = color, Font = font or Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left}, parent)
end

function Library.CreateLib(title, themeName, settings)
    settings = settings or {}
    local t = themes[themeName] or themes.DarkTheme
    local old = player:WaitForChild("PlayerGui"):FindFirstChild("GoloUI")
    if old then old:Destroy() end

    local gui = make("ScreenGui", {Name = "GoloUI", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, player.PlayerGui)

    local window = make("Frame", {Name = "Window", AnchorPoint = Vector2.new(.5, .5),
        Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(550, 327),
        BackgroundColor3 = t.PanelDark, BackgroundTransparency = .25, BorderSizePixel = 0,
        ClipsDescendants = true}, gui)
    round(window, 9)
    make("UIStroke", {Color = t.Line, Transparency = .25}, window)

    -- Background sengaja menjadi child dari Window, bukan ScreenGui,
    -- sehingga hanya mengisi area panel dan ikut terpotong oleh rounded corner.
    local background = make("ImageLabel", {
        Name = "Background",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(45, 27, 65),
        Image = (settings.BackgroundImage and settings.BackgroundImage ~= "") and settings.BackgroundImage or "rbxassetid://5252447904",
        ImageTransparency = 0,
        ScaleType = Enum.ScaleType.Crop,
        BorderSizePixel = 0,
        ZIndex = 0,
    }, window)
    make("Frame", {
        Name = "BackgroundOverlay",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = settings.OverlayColor or Color3.fromRGB(57, 28, 82),
        BackgroundTransparency = settings.BackgroundTransparency or .45,
        BorderSizePixel = 0,
        ZIndex = 1,
    }, window)

    local header = make("Frame", {Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = t.PanelDark,
        BackgroundTransparency = .12, BorderSizePixel = 0}, window)
    local avatar = make("Frame", {Position = UDim2.fromOffset(12, 13), Size = UDim2.fromOffset(32, 32),
        BackgroundColor3 = t.Accent}, header)
    round(avatar, 7)
    local avatarText = label(avatar, settings.AvatarText or string.sub(title or "G", 1, 1), 18, Color3.new(1,1,1), Enum.Font.GothamBold)
    avatarText.Size = UDim2.fromScale(1,1); avatarText.TextXAlignment = Enum.TextXAlignment.Center

    local titleLabel = label(header, title or "GOLO HUB", 14, t.Text, Enum.Font.GothamBold)
    titleLabel.Position = UDim2.fromOffset(53, 9); titleLabel.Size = UDim2.new(1, -170, 0, 20)
    local sub = label(header, settings.Subtitle or "custom.roblox", 10, t.Muted)
    sub.Position = UDim2.fromOffset(53, 29); sub.Size = UDim2.new(1, -170, 0, 15)
    local badge = make("TextLabel", {Position = UDim2.new(1, -93, 0, 15), Size = UDim2.fromOffset(55,27),
        BackgroundColor3 = Color3.fromRGB(41,139,224), Text = settings.StatusText or "Keyless", TextColor3 = Color3.new(1,1,1),
        TextSize = 11, Font = Enum.Font.GothamBold}, header)
    round(badge, 7)
    local minimize = make("TextButton", {Position = UDim2.new(1,-43,0,15), Size = UDim2.fromOffset(24,27),
        BackgroundTransparency = 1, Text = "×", TextColor3 = t.Accent2, TextSize = 22,
        Font = Enum.Font.Gotham, AutoButtonColor = false}, header)

    local sidebar = make("Frame", {Position = UDim2.fromOffset(0,60), Size = UDim2.new(0,150,1,-60),
        BackgroundColor3 = t.PanelDark, BackgroundTransparency = .28, BorderSizePixel = 0}, window)
    -- Sidebar hanya menampilkan tab yang dibuat oleh pengguna.
    local tabHolder = make("Frame", {Position = UDim2.fromOffset(8,14), Size = UDim2.new(1,-16,1,-24), BackgroundTransparency = 1}, sidebar)
    make("UIListLayout", {Padding = UDim.new(0,5), SortOrder = Enum.SortOrder.LayoutOrder}, tabHolder)
    local content = make("Frame", {Position = UDim2.fromOffset(150,60), Size = UDim2.new(1,-150,1,-60), BackgroundTransparency = 1}, window)

    local pages, tabs, active = {}, {}, nil
    local function select(name)
        for n, b in pairs(tabs) do b.BackgroundColor3 = n == name and t.Accent or Color3.new(0,0,0); b.BackgroundTransparency = n == name and .55 or 1; b.TextColor3 = n == name and t.Text or t.Muted end
        for n, p in pairs(pages) do p.Visible = n == name end
        active = name
    end

    local Window = {}
    function Window:NewTab(name)
        local tabButton = make("TextButton", {Size = UDim2.new(1,0,0,34), BackgroundTransparency = 1,
            Text = "  " .. name, TextColor3 = t.Muted, TextSize = 12, Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false}, tabHolder)
        round(tabButton, 6)
        local page = make("ScrollingFrame", {Size = UDim2.new(1,-28,1,-22), Position = UDim2.fromOffset(14,11),
            BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = t.Accent,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false}, content)
        make("UIListLayout", {Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder}, page)
        make("UIPadding", {PaddingBottom = UDim.new(0,10)}, page)
        tabs[name], pages[name] = tabButton, page
        tabButton.MouseButton1Click:Connect(function() select(name) end)

        local Tab = {}
        function Tab:NewSection(sectionName)
            local heading = label(page, sectionName, 15, t.Text, Enum.Font.GothamBold)
            heading.Size = UDim2.new(1,0,0,28)
            local Section = {}
            function Section:NewLabel(value)
                local item = label(page, value, 11, t.Muted); item.Size = UDim2.new(1,-4,0,25); item.TextWrapped = true; return item
            end
            function Section:NewButton(value, info, callback)
                if type(info) == "function" then callback, info = info, "" end
                local item = make("TextButton", {Size = UDim2.new(1,-4,0,37), BackgroundColor3 = t.Panel,
                    BackgroundTransparency = .28, Text = value, TextColor3 = t.Text, TextSize = 12,
                    Font = Enum.Font.GothamSemibold, AutoButtonColor = false}, page)
                round(item, 6); make("UIStroke", {Color = t.Line, Transparency = .45}, item)
                item.MouseEnter:Connect(function() tween(item, {BackgroundColor3 = t.Accent}) end)
                item.MouseLeave:Connect(function() tween(item, {BackgroundColor3 = t.Panel}) end)
                item.MouseButton1Click:Connect(function() if callback then callback() end end); return item
            end
            function Section:NewDropdown(value, options, callback)
                options = options or {}
                local selected = options[1]
                local opened = false
                local holder = make("Frame", {Size = UDim2.new(1,-4,0,37), BackgroundTransparency = 1}, page)
                local selectButton = make("TextButton", {Size = UDim2.new(1,0,0,37), BackgroundColor3 = t.Panel,
                    BackgroundTransparency = .18, Text = "", AutoButtonColor = false}, holder)
                round(selectButton, 6); make("UIStroke", {Color = t.Line, Transparency = .45}, selectButton)
                local nameLabel = label(selectButton, value, 12, t.Text, Enum.Font.GothamSemibold)
                nameLabel.Position = UDim2.fromOffset(12,0); nameLabel.Size = UDim2.new(.52,0,1,0)
                local choiceLabel = label(selectButton, tostring(selected or "Select..."), 12, t.Muted)
                choiceLabel.Position = UDim2.new(.52,0,0,0); choiceLabel.Size = UDim2.new(.43,0,1,0); choiceLabel.TextXAlignment = Enum.TextXAlignment.Right
                local arrow = label(selectButton, "▾", 15, t.Accent2, Enum.Font.GothamBold)
                arrow.Position = UDim2.new(1,-25,0,0); arrow.Size = UDim2.fromOffset(18,37); arrow.TextXAlignment = Enum.TextXAlignment.Center
                local optionsFrame = make("Frame", {Position = UDim2.fromOffset(0,40), Size = UDim2.new(1,0,0,0),
                    BackgroundColor3 = t.PanelDark, BackgroundTransparency = .03, Visible = false, ZIndex = 20}, holder)
                round(optionsFrame, 6); make("UIListLayout", {Padding = UDim.new(0,2)}, optionsFrame)
                local function closeMenu() opened = false; optionsFrame.Visible = false; arrow.Text = "▾" end
                for _, option in ipairs(options) do
                    local optionButton = make("TextButton", {Size = UDim2.new(1,0,0,30), BackgroundTransparency = 1,
                        Text = tostring(option), TextColor3 = t.Text, TextSize = 11, Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, ZIndex = 21}, optionsFrame)
                    optionButton.MouseButton1Click:Connect(function()
                        selected = option; choiceLabel.Text = tostring(option); closeMenu()
                        if callback then callback(selected) end
                    end)
                end
                optionsFrame.Size = UDim2.new(1,0,0,math.min(#options * 32, 128))
                selectButton.MouseButton1Click:Connect(function()
                    opened = not opened; optionsFrame.Visible = opened; arrow.Text = opened and "▴" or "▾"
                end)
                local selection = {}
                function selection:GetValue() return selected end
                function selection:SetValue(option)
                    for _, item in ipairs(options) do if item == option then selected = option; choiceLabel.Text = tostring(option); break end end
                end
                return selection
            end
            Section.NewSelection = Section.NewDropdown
            function Section:NewToggle(value, default, callback)
                local enabled = default == true
                local row = make("TextButton", {Size = UDim2.new(1,-4,0,37), BackgroundTransparency = 1, Text = "", AutoButtonColor = false}, page)
                local rowText = label(row, value, 13, t.Text, Enum.Font.GothamSemibold); rowText.Position = UDim2.fromOffset(3,0); rowText.Size = UDim2.new(1,-60,1,0)
                local track = make("Frame", {Position = UDim2.new(1,-39,.5,-10), Size = UDim2.fromOffset(39,20), BackgroundColor3 = Color3.fromRGB(236,233,240)}, row); round(track,12)
                local knob = make("Frame", {Position = UDim2.fromOffset(3,3), Size = UDim2.fromOffset(14,14), BackgroundColor3 = Color3.fromRGB(160,157,168)}, track); round(knob,8)
                local function render() tween(track, {BackgroundColor3 = enabled and t.Accent or Color3.fromRGB(236,233,240)}); tween(knob, {Position = enabled and UDim2.fromOffset(22,3) or UDim2.fromOffset(3,3), BackgroundColor3 = enabled and Color3.new(1,1,1) or Color3.fromRGB(160,157,168)}) end
                row.MouseButton1Click:Connect(function() enabled = not enabled; render(); if callback then callback(enabled) end end); render(); return row
            end
            return Section
        end
        if not active then select(name) end
        return Tab
    end

    local dragging, dragStart, startPos = false, nil, nil
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, window.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            window.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
    local minimized, fullSize = false, window.Size
    minimize.MouseButton1Click:Connect(function()
        minimized = not minimized; tween(window, {Size = minimized and UDim2.fromOffset(550,60) or fullSize}); minimize.Text = minimized and "□" or "×"
    end)
    return Window
end

return Library
