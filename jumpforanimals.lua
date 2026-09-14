-- BerakHUB Teleport - versi diagnostik
-- Jalankan seluruh file ini, jangan termasuk tanda ``` jika menyalin dari chat.

local function Debug(Message)
    print("[BerakHUB] " .. tostring(Message))
end

local Source = game:HttpGet("https://sirius.menu/gen2")
local Loader = loadstring(Source)
if not Loader then
    warn("[BerakHUB] Rayfield gagal di-load: loadstring nil")
    return
end

local Ok, Rayfield = pcall(Loader)
if not Ok or not Rayfield then
    warn("[BerakHUB] Rayfield gagal di-load:", Rayfield)
    return
end

local OkWindow, Window = pcall(function()
    return Rayfield:CreateWindow({
        name = "BerakHUB",
        subtitle = "Teleport",
        showText = "BerakHUB",
        theme = "Default",
        toggleUIKeybind = "K"
    })
end)

if not OkWindow or not Window then
    warn("[BerakHUB] Window gagal dibuat:", Window)
    return
end

local OkTab, Home = pcall(function()
    return Window:CreateTab({
        name = "Home"
    })
end)

if not OkTab or not Home then
    warn("[BerakHUB] Tab gagal dibuat:", Home)
    return
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer

local Stages = {}
local StageNames = {}
local Eggs = {}
local EggNames = {}
local SelectedStage
local SelectedEgg
local StageDropdown
local EggDropdown

local function Notify(Title, Content)
    pcall(function()
        Rayfield:Notify({
            title = Title,
            content = Content,
            duration = 4
        })
    end)
end

local function IsTarget(Object)
    return Object:IsA("BasePart") or Object:IsA("Model") or Object:IsA("Folder") or Object:IsA("CFrameValue")
end

local function GetCFrame(Object)
    if not Object or not Object.Parent then
        return nil
    end
    if Object:IsA("BasePart") then
        return Object.CFrame
    elseif Object:IsA("Model") then
        return Object:GetPivot()
    elseif Object:IsA("CFrameValue") then
        return Object.Value
    end
    return nil
end

local function Teleport(Object)
    local TargetCFrame = GetCFrame(Object)
    local Character = Player.Character or Player.CharacterAdded:Wait()
    if not TargetCFrame or not Character then
        return false
    end
    local Ok = pcall(function()
        Character:PivotTo(TargetCFrame + Vector3.new(0, 5, 0))
    end)
    return Ok
end

local function ReadValue(Value)
    if type(Value) == "table" then
        return Value[1]
    end
    return Value
end

local function Scan()
    Stages = {}
    StageNames = {}
    Eggs = {}
    EggNames = {}

    for _, Object in ipairs(Workspace:GetDescendants()) do
        if IsTarget(Object) then
            local Name = tostring(Object.Name)
            local Lower = string.lower(Name)

            -- Stage/level/checkpoint dipisahkan agar nama game lebih fleksibel.
            if string.find(Lower, "stage", 1, true)
                or string.find(Lower, "level", 1, true)
                or string.find(Lower, "checkpoint", 1, true) then
                if not Stages[Name] then
                    Stages[Name] = Object
                    table.insert(StageNames, Name)
                end
            end

            if string.find(Lower, "egg", 1, true)
                or string.find(Lower, "telur", 1, true) then
                if not Eggs[Name] then
                    Eggs[Name] = Object
                    table.insert(EggNames, Name)
                end
            end
        end
    end

    table.sort(StageNames)
    table.sort(EggNames)
    Debug("Stage/Level ditemukan: " .. #StageNames)
    Debug("Egg ditemukan: " .. #EggNames)

    if StageDropdown then
        pcall(function() StageDropdown:Refresh(StageNames, true) end)
    end
    if EggDropdown then
        pcall(function() EggDropdown:Refresh(EggNames, true) end)
    end

    Notify("Scan selesai", "Stage: " .. #StageNames .. " | Egg: " .. #EggNames)
end

-- Elemen UI dibuat sebelum scan supaya tetap muncul walaupun object tidak ditemukan.
StageDropdown = Home:CreateDropdown({
    name = "Pilih Stage / Level",
    options = {},
    currentOption = {},
    multipleOptions = false,
    callback = function(Value)
        SelectedStage = ReadValue(Value)
    end
})

EggDropdown = Home:CreateDropdown({
    name = "Pilih Egg",
    options = {},
    currentOption = {},
    multipleOptions = false,
    callback = function(Value)
        SelectedEgg = ReadValue(Value)
    end
})

Home:CreateButton({
    name = "Refresh / Cari Target",
    callback = Scan
})

Home:CreateButton({
    name = "Teleport ke Stage",
    callback = function()
        if not SelectedStage or not Stages[SelectedStage] then
            Notify("Teleport", "Pilih Stage/Level terlebih dahulu.")
            return
        end
        if Teleport(Stages[SelectedStage]) then
            Notify("Berhasil", "Teleport ke " .. SelectedStage)
        else
            Notify("Gagal", "Stage tidak punya posisi teleport.")
        end
    end
})

Home:CreateButton({
    name = "Teleport ke Egg",
    callback = function()
        if not SelectedEgg or not Eggs[SelectedEgg] then
            Notify("Teleport", "Pilih Egg terlebih dahulu.")
            return
        end
        if Teleport(Eggs[SelectedEgg]) then
            Notify("Berhasil", "Teleport ke " .. SelectedEgg)
        else
            Notify("Gagal", "Egg tidak punya posisi teleport.")
        end
    end
})

Home:CreateParagraph({
    title = "Cara pakai",
    content = "Klik Refresh / Cari Target setelah map selesai loading. Jika UI tidak muncul, buka Developer Console (F9) dan cari baris [BerakHUB]."
})

Scan()
