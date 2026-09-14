local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local window = Rayfield:CreateWindow({
    Name = "BerakHUB",
    Subtitle = "By Ikann",
    SidebarLayout = true,
    Theme = "Amethyst",
})

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local home = window:CreateTab({
    Name = "🏠 Home"
})

local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function teleportTo(target)
    if not target then
        return false
    end

    local character = getCharacter()

    if not character then
        return false
    end

    local success, result = pcall(function()
        if target:IsA("BasePart") then
            character:PivotTo(target.CFrame + Vector3.new(0, 4, 0))
        elseif target:IsA("Model") then
            character:PivotTo(target:GetPivot() + Vector3.new(0, 4, 0))
        elseif target:IsA("CFrameValue") then
            character:PivotTo(target.Value + Vector3.new(0, 4, 0))
        end
    end)

    if not success then
        warn("Teleport gagal:", result)
        return false
    end

    return true
end

local function collectStages()
    local stageTargets = {}
    local stageOptions = {}

    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("Folder") or object:IsA("Model") then
            local name = object.Name

            if string.find(string.lower(name), "stage") then
                if not stageTargets[name] then
                    stageTargets[name] = object
                    table.insert(stageOptions, name)
                end
            end
        end
    end

    table.sort(stageOptions)

    return stageTargets, stageOptions
end

local function collectEggs(stage)
    local eggTargets = {}
    local eggOptions = {}

    if not stage then
        return eggTargets, eggOptions
    end

    for _, object in ipairs(stage:GetDescendants()) do
        if object:IsA("BasePart")
            or object:IsA("Model")
            or object:IsA("CFrameValue") then

            local name = object.Name

            if string.find(string.lower(name), "egg") then
                if not eggTargets[name] then
                    eggTargets[name] = object
                    table.insert(eggOptions, name)
                end
            end
        end
    end

    table.sort(eggOptions)

    return eggTargets, eggOptions
end

local selectedStageName = nil
local selectedEggName = nil
local selectedTarget = nil

local eggTargets = {}
local eggOptions = {}
local eggDropdown = nil

local stageTargets, stageOptions = collectStages()

if #stageOptions > 0 then
    selectedStageName = stageOptions[1]

    eggTargets, eggOptions =
        collectEggs(stageTargets[selectedStageName])

    selectedEggName = eggOptions[1]

    if selectedEggName then
        selectedTarget = eggTargets[selectedEggName]
    end

    home:CreateDropdown({
        Name = "Pilih Stage",
        Options = stageOptions,
        CurrentOption = {selectedStageName},
        MultipleOptions = false,
        Flag = "SelectedStage",

        Callback = function(selected)
            selectedStageName = selected[1] or selected

            eggTargets, eggOptions =
                collectEggs(stageTargets[selectedStageName])

            selectedEggName = eggOptions[1]

            if selectedEggName then
                selectedTarget = eggTargets[selectedEggName]
            else
                selectedTarget = nil
            end

            if eggDropdown then
                eggDropdown:Refresh(eggOptions, true)
            end
        end,
    })

    eggDropdown = home:CreateDropdown({
        Name = "Pilih Egg",
        Options = eggOptions,
        CurrentOption = selectedEggName and {selectedEggName} or {},
        MultipleOptions = false,
        Flag = "SelectedEgg",

        Callback = function(selected)
            selectedEggName = selected[1] or selected

            if selectedEggName then
                selectedTarget = eggTargets[selectedEggName]
            else
                selectedTarget = nil
            end
        end,
    })

    home:CreateButton({
        Name = "Teleport ke Egg",

        Callback = function()
            if not selectedTarget then
                Rayfield:Notify({
                    Title = "Teleport",
                    Content = "Silakan pilih egg terlebih dahulu.",
                    Duration = 5,
                })
                return
            end

            local success = teleportTo(selectedTarget)

            if success then
                Rayfield:Notify({
                    Title = "Teleport",
                    Content = "Berhasil teleport ke " .. tostring(selectedEggName),
                    Duration = 3,
                })
            else
                Rayfield:Notify({
                    Title = "Teleport",
                    Content = "Gagal melakukan teleport.",
                    Duration = 5,
                })
            end
        end,
    })
else
    Rayfield:Notify({
        Title = "Teleport",
        Content = "Tidak ada Stage yang ditemukan.",
        Duration = 5,
    })
end
