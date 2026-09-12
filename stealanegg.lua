local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ikanngeming/delta/refs/heads/main/library.lua"))()

 local Window = Library.CreateLib("IkannHU", "DarkTheme", {
        BackgroundImage = "rbxassetid://1234567890",
        BackgroundTransparency = 0.45,
        Subtitle = "custom.roblox",
        StatusText = "Keyless",
        AvatarText = "G",
    })
    local Tab = Window:NewTab("Main")
    local Section = Tab:NewSection("Features")
    Section:NewButton("Example", "Run example", function() print("clicked") end)
    Section:NewToggle("Enabled", false, function(value) print(value) end)
