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
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function teleportTo(target)
    if not target then
        return
    end

    local character = getCharacter()
    if not character then
        return
    end

    local success, result = pcall(function()
        if target:IsA("BasePart") then
            character:PivotTo(target.CFrame + Vector3.new(0, 4, 0))
        elseif target:IsA("Model") then
            character:PivotTo(target:GetPivot() + Vector3.new(0, 4, 0))
        elseif target:IsA("CFrameValue") then
            character:PivotTo(target.Value)
        end
    end)

    if not success then
        warn("Teleport gagal:", result)
    end
end

local function collectTeleportTargets(folder)
    local targets = {}
    local options = {}

    if not folder then
        return targets, options
    end

    for _, object in ipairs(folder:GetChildren()) do
        local targetName =
            object:GetAttribute("EggName")
            or object:GetAttribute("Name")
            or object.Name

        targets[targetName] = object
        table.insert(options, targetName)
    end

    table.sort(options)
    return targets, options
end

local teleportFolder = workspace:FindFirstChild("AreaEggSlotsClient")
local teleportTargets, teleportOptions =
    collectTeleportTargets(teleportFolder)

if #teleportOptions > 0 then
    home:CreateDropdown({
        Name = "Teleport To",
        Options = teleportOptions,
        CurrentOption = {teleportOptions[1]},
        MultipleOptions = false,
        Flag = "TeleportTarget",

        Callback = function(selected)
            local targetName = selected[1]
            teleportTo(teleportTargets[targetName])
        end,
    })
else
    Rayfield:Notify({
        Title = "Teleport",
        Content = "Tidak ada lokasi teleport yang ditemukan.",
        Duration = 5,
    })
end
