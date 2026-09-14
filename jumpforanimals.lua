local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Window = Rayfield:CreateWindow({
    Name = "BerakHUB",
    Subtitle = "By Ikann",
    SidebarLayout = true,
    Theme = "Amethyst",
})

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer

local Home = Window:CreateTab({
    Name = "🏠 Home"
})

local StagesFolder = Workspace:WaitForChild("Stages")

local SelectedStage = nil
local SelectedEgg = nil
local SelectedTarget = nil

local StageTargets = {}
local StageOptions = {}

local EggTargets = {}
local EggOptions = {}

local EggDropdown = nil

local function GetCharacter()
    return Player.Character or Player.CharacterAdded:Wait()
end

local function TeleportTo(Target)
    if not Target then
        return false
    end

    local Character = GetCharacter()

    if not Character then
        return false
    end

    local Success, Error = pcall(function()
        if Target:IsA("BasePart") then
            Character:PivotTo(
                Target.CFrame + Vector3.new(0, 5, 0)
            )
        elseif Target:IsA("Model") then
            Character:PivotTo(
                Target:GetPivot() + Vector3.new(0, 5, 0)
            )
        elseif Target:IsA("CFrameValue") then
            Character:PivotTo(
                Target.Value + Vector3.new(0, 5, 0)
            )
        end
    end)

    if not Success then
        warn("Teleport gagal:", Error)
        return false
    end

    return true
end

for _, Stage in ipairs(StagesFolder:GetChildren()) do
    if Stage:IsA("Folder") or Stage:IsA("Model") then
        StageTargets[Stage.Name] = Stage
        table.insert(StageOptions, Stage.Name)
    end
end

table.sort(StageOptions)

local StageDropdown = Home:CreateDropdown({
    Name = "Pilih Stage",
    Options = StageOptions,
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "SelectedStage",

    Callback = function(Value)
        SelectedStage = Value[1] or Value

        SelectedEgg = nil
        SelectedTarget = nil
        EggTargets = {}
        EggOptions = {}

        if not SelectedStage then
            return
        end

        local Stage = StageTargets[SelectedStage]

        if not Stage then
            return
        end

        local SpawnedEggs = Stage:FindFirstChild("SpawnedEggs")

        if not SpawnedEggs then
            Rayfield:Notify({
                Title = "Egg",
                Content = "SpawnedEggs tidak ditemukan di " .. SelectedStage,
                Duration = 4
            })
            return
        end

        for Index, Egg in ipairs(SpawnedEggs:GetChildren()) do
            if Egg:IsA("Model")
                or Egg:IsA("BasePart")
                or Egg:IsA("CFrameValue") then

                local DisplayName = Egg.Name .. " #" .. Index

                EggTargets[DisplayName] = Egg
                table.insert(EggOptions, DisplayName)
            end
        end

        table.sort(EggOptions)

        if #EggOptions == 0 then
            Rayfield:Notify({
                Title = "Egg",
                Content = "Tidak ada Egg di " .. SelectedStage,
                Duration = 4
            })
            return
        end

        if EggDropdown then
            EggDropdown:Refresh(EggOptions, true)
        else
            EggDropdown = Home:CreateDropdown({
                Name = "Pilih Egg",
                Options = EggOptions,
                CurrentOption = {},
                MultipleOptions = false,
                Flag = "SelectedEgg",

                Callback = function(EggValue)
                    SelectedEgg = EggValue[1] or EggValue

                    if SelectedEgg then
                        SelectedTarget = EggTargets[SelectedEgg]
                    else
                        SelectedTarget = nil
                    end
                end
            })
        end

        Rayfield:Notify({
            Title = "Stage Dipilih",
            Content = SelectedStage .. " memiliki " .. #EggOptions .. " Egg",
            Duration = 3
        })
    end
})

Home:CreateButton({
    Name = "Teleport ke Egg",

    Callback = function()
        if not SelectedStage then
            Rayfield:Notify({
                Title = "Teleport",
                Content = "Pilih Stage terlebih dahulu.",
                Duration = 4
            })
            return
        end

        if not SelectedEgg or not SelectedTarget then
            Rayfield:Notify({
                Title = "Teleport",
                Content = "Pilih Egg terlebih dahulu.",
                Duration = 4
            })
            return
        end

        local Success = TeleportTo(SelectedTarget)

        if Success then
            Rayfield:Notify({
                Title = "Teleport Berhasil",
                Content = "Menuju " .. SelectedEgg,
                Duration = 3
            })
        else
            Rayfield:Notify({
                Title = "Teleport",
                Content = "Teleport gagal.",
                Duration = 4
            })
        end
    end
})
