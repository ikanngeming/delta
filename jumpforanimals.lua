local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Window = Rayfield:CreateWindow({
    Name = "BerakHUB",
    Subtitle = "By Ikann",
    ShowText = "BerakHUB",
    Theme = "Amethyst",
    ToggleUIKeybind = "K"
})

local Home = Window:CreateTab({
    Name = "🏠 Home"
})

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer

local SelectedStage
local SelectedEgg
local SelectedTarget

local StageTargets = {}
local StageOptions = {}
local EggTargets = {}
local EggOptions = {}
local EggDropdown

local function GetCharacter()
    return Player.Character or Player.CharacterAdded:Wait()
end

local function GetTargetCFrame(Target)
    if not Target or not Target.Parent then
        return nil
    end

    if Target:IsA("BasePart") then
        return Target.CFrame
    elseif Target:IsA("Model") then
        return Target:GetPivot()
    elseif Target:IsA("CFrameValue") then
        return Target.Value
    end

    return nil
end

local function TeleportTo(Target)
    local TargetCFrame = GetTargetCFrame(Target)
    if not TargetCFrame then
        return false, "Target teleport tidak valid atau sudah dihapus."
    end

    local Character = GetCharacter()
    if not Character or not Character.Parent then
        return false, "Character belum tersedia."
    end

    local Success, ErrorMessage = pcall(function()
        Character:PivotTo(TargetCFrame + Vector3.new(0, 4, 0))
    end)

    if not Success then
        warn("Teleport gagal:", ErrorMessage)
        return false, tostring(ErrorMessage)
    end

    return true
end

local function IsTeleportObject(Object)
    return Object:IsA("Folder")
        or Object:IsA("Model")
        or Object:IsA("BasePart")
        or Object:IsA("CFrameValue")
end

local function CollectStages()
    StageTargets = {}
    StageOptions = {}

    for _, Object in ipairs(Workspace:GetDescendants()) do
        if IsTeleportObject(Object) then
            local ObjectName = tostring(Object.Name)
            if string.find(string.lower(ObjectName), "stage", 1, true)
                and not StageTargets[ObjectName] then
                StageTargets[ObjectName] = Object
                table.insert(StageOptions, ObjectName)
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

    -- Sertakan Stage sendiri jika ternyata object-nya adalah egg.
    local Objects = {Stage}
    for _, Object in ipairs(Stage:GetDescendants()) do
        table.insert(Objects, Object)
    end

    for _, Object in ipairs(Objects) do
        if IsTeleportObject(Object) then
            local ObjectName = tostring(Object.Name)
            if string.find(string.lower(ObjectName), "egg", 1, true)
                and not EggTargets[ObjectName] then
                EggTargets[ObjectName] = Object
                table.insert(EggOptions, ObjectName)
            end
        end
    end

    table.sort(EggOptions)
end

local function Notify(Title, Content, Duration)
    Rayfield:Notify({
        Title = Title,
        Content = Content,
        Duration = Duration or 4
    })
end

CollectStages()

if #StageOptions == 0 then
    Notify("BerakHUB", "Stage tidak ditemukan di Workspace.", 5)
else
    Notify("BerakHUB", "Ditemukan " .. #StageOptions .. " Stage.", 3)
end

Home:CreateDropdown({
    Name = "Pilih Stage",
    Options = StageOptions,
    CurrentOption = {},
    MultipleOptions = false,
    Callback = function(Value)
        SelectedStage = type(Value) == "table" and Value[1] or Value
        SelectedEgg = nil
        SelectedTarget = nil
        EggTargets = {}
        EggOptions = {}

        if not SelectedStage then
            if EggDropdown then
                EggDropdown:Refresh({}, true)
            end
            return
        end

        local Stage = StageTargets[SelectedStage]
        if not Stage then
            Notify("Error", "Object Stage tidak ditemukan.")
            return
        end

        CollectEggs(Stage)

        if EggDropdown then
            EggDropdown:Refresh(EggOptions, true)
        end

        if #EggOptions == 0 then
            Notify("Egg", "Tidak ada Egg di " .. tostring(SelectedStage), 4)
        else
            Notify("Egg", "Ditemukan " .. #EggOptions .. " Egg.", 3)
        end
    end
})

EggDropdown = Home:CreateDropdown({
    Name = "Pilih Egg",
    Options = {},
    CurrentOption = {},
    MultipleOptions = false,
    Callback = function(Value)
        SelectedEgg = type(Value) == "table" and Value[1] or Value
        SelectedTarget = SelectedEgg and EggTargets[SelectedEgg] or nil
    end
})

-- Tombol teleport dibuat setelah dropdown agar selalu tampil di tab Home.
Home:CreateButton({
    Name = "Teleport ke Egg",
    Callback = function()
        if not SelectedStage then
            Notify("Teleport", "Pilih Stage terlebih dahulu.")
            return
        end

        if not SelectedEgg or not SelectedTarget then
            Notify("Teleport", "Pilih Egg terlebih dahulu.")
            return
        end

        local Success, ErrorMessage = TeleportTo(SelectedTarget)
        if Success then
            Notify("Teleport Berhasil", "Menuju " .. tostring(SelectedEgg), 3)
        else
            Notify("Teleport Gagal", ErrorMessage or "Target tidak valid.", 4)
        end
    end
})
