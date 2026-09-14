local Ui = local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()
local window = Ui:CreateWindow({
    name = "BerakHUB",
    subtitle = "By Ikann",
    sidebarLayout = true,
    theme = "amethyst",
})

local home = window:CreateTab({ name = "🏠 Home", nil })
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
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
			character:PivotTo(
				target.CFrame + Vector3.new(0, 4, 0)
			)

		elseif target:IsA("Model") then
			character:PivotTo(
				target:GetPivot() + Vector3.new(0, 4, 0)
			)

		elseif target:IsA("CFrameValue") then
			character:PivotTo(
				target.Value + Vector3.new(0, 4, 0)
			)
		end
	end)

	if not success then
		warn("Teleport gagal:", result)
	end
end


local selectedStageName = nil
local selectedEggName = nil
local selectedTarget = nil

local eggTargets = {}
local eggOptions = {}
local eggDropdown

local stageTargets, stageOptions = collectStages()

if #stageOptions > 0 then
	selectedStageName = stageOptions[1]

	eggTargets, eggOptions =
		collectEggs(stageTargets[selectedStageName])

	selectedEggName = eggOptions[1]
	selectedTarget = selectedEggName and eggTargets[selectedEggName]

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
			selectedTarget = selectedEggName and eggTargets[selectedEggName]

			if eggDropdown then
				eggDropdown:Refresh(eggOptions, true)
			end
		end,
	})

	eggDropdown = home:CreateDropdown({
		Name = "Pilih Egg",
		Options = eggOptions,
		CurrentOption = {selectedEggName},
		MultipleOptions = false,
		Flag = "SelectedEgg",

		Callback = function(selected)
			selectedEggName = selected[1] or selected
			selectedTarget = eggTargets[selectedEggName]
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

			teleportTo(selectedTarget)

			Rayfield:Notify({
				Title = "Teleport",
				Content = "Berhasil teleport ke " .. tostring(selectedEggName),
				Duration = 3,
			})
		end,
	})
else
	Rayfield:Notify({
		Title = "Teleport",
		Content = "Tidak ada Stage yang ditemukan.",
		Duration = 5,
	})
end
