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
                Target.CFrame + Vector3.new(0, 4, 0)
            )

        elseif Target:IsA("Model") then
            Character:PivotTo(
                Target:GetPivot() + Vector3.new(0, 4, 0)
            )

        elseif Target:IsA("CFrameValue") then
            Character:PivotTo(
                Target.Value + Vector3.new(0, 4, 0)
            )
        end
    end)

    if not Success then
        warn("Teleport gagal:", Error)
        return false
    end

    return true
end

local function CollectStages()
    StageTargets = {}
    StageOptions = {}

    for _, Object in ipairs(Workspace:GetDescendants()) do
        if Object:IsA("Folder") or Object:IsA("Model") then
            local Name = Object.Name

            if string.find(string.lower(Name), "stage") then
                if not StageTargets[Name] then
                    StageTargets[Name] = Object
                    table.insert(StageOptions, Name)
                end
            end
        end
    end

    table.sort(StageOptions)
end

local function CollectEggs(Stage)
    EggTargets = {}
    EggOptions = {}

    if not Stage then
        return
    end

    for _, Object in ipairs(Stage:GetDescendants()) do
        if Object:IsA("BasePart")
            or Object:IsA("Model")
            or Object:IsA("CFrameValue") then

            local Name = Object.Name

            if string.find(string.lower(Name), "egg") then
                if not EggTargets[Name] then
                    EggTargets[Name] = Object
                    table.insert(EggOptions, Name)
                end
            end
        end
    end

    table.sort(EggOptions)
end

CollectStages()

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

        if not SelectedStage or SelectedStage == "" then
            return
        end

        local Stage = StageTargets[SelectedStage]

        if not Stage then
            Rayfield:Notify({
                Title = "Stage",
                Content = "Stage tidak ditemukan.",
                Duration = 4
            })
            return
        end

        CollectEggs(Stage)

        if #EggOptions == 0 then
            Rayfield:Notify({
                Title = "Egg",
                Content = "Tidak ada Egg di " .. tostring(SelectedStage),
                Duration = 4
            })

            if EggDropdown then
                EggDropdown:Refresh({}, true)
            end

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

                Callback = function(Value)
                    SelectedEgg = Value[1] or Value

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
            Content = tostring(SelectedStage) .. " memiliki " .. tostring(#EggOptions) .. " Egg.",
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
                Content = "Menuju " .. tostring(SelectedEgg),
                Duration = 3
            })
        end
    end
})
