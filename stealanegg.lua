local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "BerakHUB",
   Icon = 0,
   LoadingTitle = "BerakHUB - LOADING",
   LoadingSubtitle = "Made ikann",
   ShowText = "BerakHUB",
   Theme = "AmberGlow",

   ToggleUIKeybind = "K", 
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "Berak Hub"
   },
})

Rayfield:Notify({
   Title = "Welcome to BerakHUB",
   Content = "Made Ikann from Indonesia",
   Duration = 6.5,
   Image = 4483362458,
})

local home = Window:CreateTab("🏠 Home", nil)
local afk = home:CreateSection("👾 Afk")
local folder = workspace:WaitForChild("AreaEggSlotsClient")
local eggs, options = {}, {}

for _, egg in ipairs(folder:GetChildren()) do
    if egg:IsA("Model") then
        local name = egg:GetAttribute("EggName") or egg:GetAttribute("Name") or egg.Name
        eggs[name] = egg
        table.insert(options, name)
    end
end

home:CreateDropdown({
    Name = "Teleport To",
    Options = options,
    CurrentOption = {options[1]},
    MultipleOptions = false,
    Flag = "TeleportEgg",
    Callback = function(Options)
        local egg = eggs[Options[1]]
        if egg and game.Players.LocalPlayer.Character then
            game.Players.LocalPlayer.Character:PivotTo(
                egg:GetPivot() + Vector3.new(0, 4, 0)
            )
        end
    end,
})
