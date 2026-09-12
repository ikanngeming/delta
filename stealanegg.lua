local Window = Library.CreateLib("IkannHU", "DarkTheme", {
    BackgroundImage = "rbxassetid://5252447904",
    BackgroundTransparency = 0.45,
    OverlayColor = Color3.fromRGB(57, 28, 82),
    Subtitle = "custom.roblox",
    StatusText = "Keyless",
    AvatarText = "I",
})

local Main = Window:NewTab("Main")
local Section = Main:NewSection("Auto Steal Egg")

local SelectedArea = Section:NewSelection(
    "Areas to Steal",
    {"Snow", "Forest", "Desert"},
    function(value)
        print("Area dipilih:", value)
    end
)

Section:NewButton("Start", "Mulai fitur", function()
    local selectedArea = SelectedArea:GetValue()
    print("Memulai fitur di:", selectedArea)
end)

Section:NewToggle("Auto Steal Selected Eggs", false, function(enabled)
    print("Auto steal:", enabled)
end)

local Misc = Window:NewTab("Misc")
local MiscSection = Misc:NewSection("Miscellaneous")

local Settings = Window:NewTab("Settings")
local SettingsSection = Settings:NewSection("Interface")
