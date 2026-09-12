local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ikanngeming/delta/refs/heads/main/library.lua"))()

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
