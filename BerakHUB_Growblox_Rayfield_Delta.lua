--[[
    BerakHUB - Growblox  |  Rayfield Edition (Delta-friendly)
    Author UI asli: Ikann

    Urutan kerja:
      1. Jendela Rayfield dibuka dulu (kalau Rayfield gagal, muncul kotak error merah).
      2. Logika game dimuat dengan penangkap error.
      3. Tab "Debug" menampilkan executor, PlaceId, kemampuan executor, dan error.

    Menu key: RightControl (PC) / tombol bulat "B" yang bisa digeser (HP).
]]
local BerakUI = (function()
    -- ============================================================================
    --  BerakHUB UI - Rayfield Edition
    --  Adapter: API lama (Create / AddTab / AddLeftGroupbox / AddToggle / ...)
    --  diterjemahkan ke Rayfield, jadi script di bawahnya tidak perlu diubah.
    -- ============================================================================
    local Players = game:GetService("Players")
    local UIS = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer

    local BerakHUBUI = {
        Version = "Ikann-Rayfield-1.0",
        Logo = nil,
    }

    local active = { Library = nil, Window = nil, ToggleGui = nil }

    -- ---------- load Rayfield ----------
    local function loadRayfield()
        local ok, lib = pcall(function()
            return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
        end)
        if not ok or type(lib) ~= "table" then
            error("BerakHUB: gagal memuat Rayfield (" .. tostring(lib) .. ")")
        end
        return lib
    end

    local function fireAll(list, value)
        for _, fn in ipairs(list) do
            pcall(fn, value)
        end
    end

    local function clamp(v, lo, hi)
        if v < lo then return lo end
        if v > hi then return hi end
        return v
    end

    -- ---------- tombol melayang (untuk HP / tanpa keyboard) ----------
    local function destroyToggleGui()
        if active.ToggleGui then
            pcall(function() active.ToggleGui:Destroy() end)
            active.ToggleGui = nil
        end
    end

    local function createFloatingToggle(Library)
        destroyToggleGui()
        local gui = Instance.new("ScreenGui")
        gui.Name = "BerakHUB_RayfieldToggle"
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 999999
        gui.IgnoreGuiInset = true
        local parent = LocalPlayer:WaitForChild("PlayerGui")
        if type(gethui) == "function" then
            local okHui, hui = pcall(gethui)
            if okHui and hui then parent = hui end
        end
        gui.Parent = parent

        local button = Instance.new("TextButton")
        button.Name = "Toggle"
        button.Size = UDim2.fromOffset(42, 42)
        button.Position = UDim2.new(0, 12, 0.4, 0)
        button.BackgroundColor3 = Color3.fromRGB(17, 27, 35)
        button.TextColor3 = Color3.fromRGB(46, 205, 190)
        button.Font = Enum.Font.GothamBold
        button.TextSize = 18
        button.Text = "B"
        button.AutoButtonColor = true
        button.Parent = gui
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = button
        local s = Instance.new("UIStroke")
        s.Color = Color3.fromRGB(46, 205, 190)
        s.Thickness = 1.5
        s.Parent = button

        -- geser tombol; ketuk (tanpa geser) = buka/tutup menu
        local dragging, dragStart, startPos, moved = false, nil, nil, false
        button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging, moved = true, false
                dragStart = input.Position
                startPos = button.Position
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                local d = input.Position - dragStart
                if d.Magnitude > 6 then moved = true end
                if moved then
                    button.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + d.X,
                        startPos.Y.Scale, startPos.Y.Offset + d.Y)
                end
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if not dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
                if not moved then
                    pcall(function() Library:Toggle() end)
                end
            end
        end)

        active.ToggleGui = gui
        return gui
    end

    -- ---------- Library ----------
    local function buildLibrary(Rayfield)
        local L = {
            Toggles = {},
            Options = {},
            Toggled = true,
            Rayfield = Rayfield,
            _native = false,
        }

        function L:Notify(cfg)
            cfg = cfg or {}
            pcall(function()
                Rayfield:Notify({
                    Title = tostring(cfg.Title or "BerakHUB"),
                    Content = tostring(cfg.Description or cfg.Content or ""),
                    Duration = tonumber(cfg.Time or cfg.Duration) or 3,
                    Image = 4483362458,
                })
            end)
        end

        function L:Toggle(force)
            local want
            if force == nil then want = not self.Toggled else want = force == true end
            self.Toggled = want
            pcall(function() Rayfield:SetVisibility(want) end)
        end

        function L:Unload()
            destroyToggleGui()
            pcall(function() Rayfield:Destroy() end)
        end

        return L
    end

    -- ---------- Groupbox (Rayfield: Section di dalam Tab) ----------
    local function newGroupbox(Library, Tab, title)
        local G = {}
        pcall(function() Tab:CreateSection(tostring(title or "")) end)

        function G:AddLabel(text, wrap)
            text = tostring(text or "")
            local obj = { Type = "Label", Text = text }
            local rf
            if wrap then
                rf = Tab:CreateParagraph({ Title = "", Content = text })
                function obj:SetText(t)
                    self.Text = tostring(t or "")
                    pcall(function() rf:Set({ Title = "", Content = self.Text }) end)
                end
            else
                rf = Tab:CreateLabel(text)
                function obj:SetText(t)
                    self.Text = tostring(t or "")
                    pcall(function() rf:Set(self.Text) end)
                end
            end
            obj._rf = rf
            return obj
        end

        function G:AddButton(cfg)
            cfg = cfg or {}
            local func = cfg.Func or cfg.Callback or function() end
            local obj = { Type = "Button", Text = tostring(cfg.Text or "Button") }
            obj._rf = Tab:CreateButton({
                Name = obj.Text,
                Callback = function() pcall(func) end,
            })
            function obj:SetText(t)
                self.Text = tostring(t or "")
                pcall(function() self._rf:Set(self.Text) end)
            end
            return obj
        end

        function G:AddToggle(id, cfg)
            cfg = cfg or {}
            local opt = { Type = "Toggle", Value = cfg.Default == true, _cbs = {} }
            local silent = false
            opt._rf = Tab:CreateToggle({
                Name = tostring(cfg.Text or id),
                CurrentValue = opt.Value,
                Flag = tostring(id),
                Callback = function(v)
                    if silent then return end
                    v = v == true
                    opt.Value = v
                    fireAll(opt._cbs, v)
                end,
            })
            function opt:OnChanged(fn)
                self._cbs[#self._cbs + 1] = fn
                return self
            end
            function opt:SetValue(v)
                v = v == true
                if v == self.Value then return end
                self.Value = v
                silent = true
                pcall(function() self._rf:Set(v) end)
                silent = false
                fireAll(self._cbs, v)
            end
            opt._render = function(v)
                opt.Value = v == true
                silent = true
                pcall(function() opt._rf:Set(opt.Value) end)
                silent = false
            end
            Library.Toggles[id] = opt
            return opt
        end

        function G:AddInput(id, cfg)
            cfg = cfg or {}
            local opt = { Type = "Input", Value = tostring(cfg.Default or ""), _cbs = {} }
            local silent = false
            opt._rf = Tab:CreateInput({
                Name = tostring(cfg.Text or id),
                CurrentValue = opt.Value,
                PlaceholderText = tostring(cfg.Placeholder or ""),
                RemoveTextAfterFocusLost = false,
                Flag = tostring(id),
                Callback = function(text)
                    if silent then return end
                    text = tostring(text or "")
                    opt.Value = text
                    fireAll(opt._cbs, text)
                end,
            })
            function opt:OnChanged(fn)
                self._cbs[#self._cbs + 1] = fn
                return self
            end
            function opt:SetValue(v)
                v = tostring(v or "")
                if v == self.Value then return end
                self.Value = v
                silent = true
                pcall(function() self._rf:Set(v) end)
                silent = false
                fireAll(self._cbs, v)
            end
            opt._render = function(v)
                opt.Value = tostring(v or "")
                silent = true
                pcall(function() opt._rf:Set(opt.Value) end)
                silent = false
            end
            Library.Options[id] = opt
            return opt
        end

        function G:AddSlider(id, cfg)
            cfg = cfg or {}
            local min = tonumber(cfg.Min) or 0
            local max = tonumber(cfg.Max) or 100
            local rounding = tonumber(cfg.Rounding) or 0
            local step = 10 ^ (-rounding)
            local default = clamp(tonumber(cfg.Default) or min, min, max)
            local opt = { Type = "Slider", Value = default, Min = min, Max = max, _cbs = {} }
            local silent = false
            opt._rf = Tab:CreateSlider({
                Name = tostring(cfg.Text or id),
                Range = { min, max },
                Increment = step,
                Suffix = tostring(cfg.Suffix or ""),
                CurrentValue = default,
                Flag = tostring(id),
                Callback = function(v)
                    if silent then return end
                    v = tonumber(v) or default
                    opt.Value = v
                    fireAll(opt._cbs, v)
                end,
            })
            function opt:OnChanged(fn)
                self._cbs[#self._cbs + 1] = fn
                return self
            end
            function opt:SetValue(v)
                v = clamp(tonumber(v) or self.Value, self.Min, self.Max)
                if v == self.Value then return end
                self.Value = v
                silent = true
                pcall(function() self._rf:Set(v) end)
                silent = false
                fireAll(self._cbs, v)
            end
            opt._render = function(v)
                opt.Value = clamp(tonumber(v) or opt.Value, opt.Min, opt.Max)
                silent = true
                pcall(function() opt._rf:Set(opt.Value) end)
                silent = false
            end
            Library.Options[id] = opt
            return opt
        end

        function G:AddDropdown(id, cfg)
            cfg = cfg or {}
            local values = {}
            for i, v in ipairs(cfg.Values or {}) do values[i] = tostring(v) end

            local function contains(list, item)
                for _, v in ipairs(list) do
                    if v == item then return true end
                end
                return false
            end

            local default = cfg.Default
            if default ~= nil then default = tostring(default) end
            local current = nil
            if default ~= nil and contains(values, default) then current = default end

            local opt = { Type = "Dropdown", Value = current, Values = values, _cbs = {} }
            local silent = false
            opt._rf = Tab:CreateDropdown({
                Name = tostring(cfg.Text or id),
                Options = values,
                CurrentOption = current and { current } or {},
                MultipleOptions = false,
                Flag = tostring(id),
                Callback = function(selected)
                    if silent then return end
                    local v = type(selected) == "table" and selected[1] or selected
                    if v == nil then return end
                    v = tostring(v)
                    opt.Value = v
                    fireAll(opt._cbs, v)
                end,
            })
            function opt:OnChanged(fn)
                self._cbs[#self._cbs + 1] = fn
                return self
            end
            function opt:SetValue(v)
                if v == nil then return end
                v = tostring(v)
                if v == self.Value then return end
                self.Value = v
                silent = true
                pcall(function() self._rf:Set({ v }) end)
                silent = false
                fireAll(self._cbs, v)
            end
            opt._render = function(v)
                if v == nil then return end
                opt.Value = tostring(v)
                silent = true
                pcall(function() opt._rf:Set({ opt.Value }) end)
                silent = false
            end
            function opt:SetValues(list)
                local new = {}
                for i, v in ipairs(list or {}) do new[i] = tostring(v) end
                self.Values = new
                local keep = self.Value
                silent = true
                pcall(function() self._rf:Refresh(new) end)
                if keep ~= nil and contains(new, keep) then
                    pcall(function() self._rf:Set({ keep }) end)
                else
                    self.Value = nil
                end
                silent = false
            end
            Library.Options[id] = opt
            return opt
        end

        G.AddCheckbox = G.AddToggle
        return G
    end

    -- ---------- Window ----------
    local function buildWindow(Library, Rayfield, cfg)
        local RW = Rayfield:CreateWindow({
            Name = tostring(cfg.Title or "BerakHUB") .. "  |  " .. tostring(cfg.Subtitle or ""),
            LoadingTitle = tostring(cfg.Title or "BerakHUB"),
            LoadingSubtitle = tostring(cfg.Subtitle or "by Ikann"),
            Theme = "Ocean",
            ToggleUIKeybind = "RightControl",
            DisableRayfieldPrompts = true,
            DisableBuildWarnings = true,
            ConfigurationSaving = { Enabled = false },
            Discord = { Enabled = false },
            KeySystem = false,
        })

        local W = { _rf = RW }

        function W:AddTab(name, icon)
            local rfTab
            local ok = pcall(function()
                rfTab = RW:CreateTab(tostring(name), icon)
            end)
            if not ok or not rfTab then
                rfTab = RW:CreateTab(tostring(name), 4483362458)
            end
            local T = {}
            function T:AddLeftGroupbox(title)
                return newGroupbox(Library, rfTab, title)
            end
            function T:AddRightGroupbox(title)
                return newGroupbox(Library, rfTab, title)
            end
            T.AddGroupbox = T.AddLeftGroupbox
            return T
        end

        function W:SetVisible(v) Library:Toggle(v == true) end
        function W:Show() Library:Toggle(true) end
        function W:Hide() Library:Toggle(false) end

        return W
    end

    -- ---------- Public API ----------
    function BerakHUBUI:SetLogo(asset)
        if asset == nil or asset == "" then
            self.Logo = nil
        else
            self.Logo = tostring(asset)
        end
    end

    function BerakHUBUI:Create(gameName, options)
        options = options or {}
        gameName = tostring(gameName or options.GameName or "Game")

        self:Destroy()

        local Rayfield = loadRayfield()
        local Library = buildLibrary(Rayfield)
        local Window = buildWindow(Library, Rayfield, {
            Title = tostring(options.Title or "BerakHUB"),
            Subtitle = tostring(options.Subtitle or gameName),
        })

        active.Library = Library
        active.Window = Window

        if options.FloatingToggle ~= false then
            pcall(createFloatingToggle, Library)
        end

        return Library, Window
    end

    function BerakHUBUI:NewLibrary(options)
        options = options or {}
        local Library = buildLibrary(loadRayfield())
        active.Library = Library
        return Library
    end

    function BerakHUBUI:GetActive()
        return active.Library, active.Window
    end

    function BerakHUBUI:Destroy()
        destroyToggleGui()
        if active.Library and type(active.Library.Unload) == "function" then
            pcall(function() active.Library:Unload() end)
        end
        active.Library = nil
        active.Window = nil
    end

    return BerakHUBUI
end)()

local BERAKHUB_LOGIC = [=[
    -- ============================================================================
    --  BerakHUB - Growblox  (Place 112863874972771)
    --  2D tile-world sandbox. Native BerakHUB UI only.
    --  Every world action goes through the game's own functions, found by
    --  scanning the game client for them: the game's own punch function
    --  breaks tiles, the game's own place function puts blocks down, the
    --  game's own takeDrop collects drops, and movement drives the game's
    --  own input keys (walk / fall / jump) with A* pathfinding. Nothing
    --  here sends a punch or break packet by hand, and nothing writes a
    --  position: the server ignores hand-sent break claims and pushes
    --  back characters whose position was written.
    --  Kept from the previous script: Auto Spam Chat and manual Noclip
    --  (player Ghost attribute). Everything else is new.
    -- ============================================================================
    
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local HttpService = game:GetService("HttpService")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local VirtualUser = game:GetService("VirtualUser")
    local TextChatService = game:GetService("TextChatService")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    local C = {}
    if getgenv().BerakHUB_Growblox_Cleanup then pcall(getgenv().BerakHUB_Growblox_Cleanup) end
    C.loops = {}
    C.alive = true
    C.lastWorld = nil
    C.spamWarned = false
    C.logLines = {}
    C.stats = { placed = 0, broken = 0, collected = 0, collectFail = 0, harvested = 0, planted = 0, serverConfirmed = 0, claimed = 0, redeemed = 0 }
    C.dd = {}
    
    local function alive()
        return C.alive
    end
    
    -- ---------- config ----------
    local CONFIG_FILE = "BerakHUB/Growblox.json"
    local function cloneDefaults()
        return {
            GBX_AutoFarm = false,
            GBX_AutoDirtFarm = false,
            GBX_FarmMode = "Place + Break",
            GBX_FarmBlock = "",
            GBX_FarmOffsets = { ["1,0"] = true, ["2,0"] = true, ["1,-1"] = true, ["2,-1"] = true },
            GBX_MultiTarget = 1,
            GBX_PlaceMs = 250,
            GBX_BreakMs = 220,
            GBX_BypassPunchCooldown = false,
            GBX_AfterBreakMs = 300,
            GBX_HitsOverride = 0,
            GBX_AutoCollect = true,
            GBX_CollectRadius = 3.2,
            GBX_CollectAfterPlace = true,
            GBX_Farmer = false,
            GBX_FarmerSeed = "",
            GBX_FarmerHarvest = true,
            GBX_FarmerPlant = true,
            GBX_FarmerCollect = true,
            GBX_HarvestMs = 250,
            GBX_PlantMs = 250,
            GBX_ClearWorld = false,
            GBX_ClearIncludeBg = true,
            GBX_ClearSweep = "Kiri → Kanan",
            GBX_ClearUseBlock = false,
            GBX_ClearScaffold = "",
            GBX_ClearCollect = true,
            GBX_ScanAuto = false,
            GBX_ScanQuery = "",
            GBX_ScanLayer = "Semua",
            GBX_AutoQuest = false,
            GBX_AutoRedeem = false,
            GBX_Guard = false,
            GBX_GuardWho = "Staff (Mod/Dev)",
            GBX_GuardStopAll = true,
            GBX_GuardLeave = false,
            GBX_GuardAutoBack = true,
            GBX_GuardBackSec = 60,
            GBX_GuardCalmSec = 5,
            GBX_AutoSpam = false,
            GBX_SpamText = "",
            GBX_SpamInterval = 5,
            GBX_Speed = 100,
            GBX_InfJump = false,
            GBX_Noclip = false,
            GBX_LiteMode = false,
            GBX_MutePunch = true,
            GBX_AntiAfk = true,
            GBX_CalibX = 0,
            GBX_CalibY = 0,
            GBX_HideUsername = false,
        }
    end
    C.cfg = cloneDefaults()
    local function saveCfg()
        pcall(function()
            if writefile then writefile(CONFIG_FILE, HttpService:JSONEncode(C.cfg)) end
        end)
    end
    local function loadCfg()
        pcall(function()
            if isfile and isfile(CONFIG_FILE) then
                local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
                if type(data) == "table" then
                    for k, v in pairs(cloneDefaults()) do
                        if data[k] ~= nil then C.cfg[k] = data[k] end
                    end
                end
            end
        end)
    end
    loadCfg()
    if type(C.cfg.GBX_FarmOffsets) ~= "table" then C.cfg.GBX_FarmOffsets = cloneDefaults().GBX_FarmOffsets end
    
    local function logLine(text)
        table.insert(C.logLines, 1, text)
        while #C.logLines > 12 do table.remove(C.logLines) end
        if C.logLabel ~= nil then
            pcall(function() C.logLabel:SetText("Log:\n" .. table.concat(C.logLines, "\n")) end)
        end
    end
    
    -- ---------- game modules ----------
    local Shared = ReplicatedStorage:FindFirstChild("Shared")
    local WorldRemotes = ReplicatedStorage:FindFirstChild("WorldRemotes")
    local SetTileRemote = WorldRemotes and WorldRemotes:FindFirstChild("SetTile") or nil
    local TakeDropRemote = WorldRemotes and WorldRemotes:FindFirstChild("TakeDrop") or nil
    local ItemDB = nil
    pcall(function() ItemDB = require(Shared:FindFirstChild("ItemDB")) end)
    if type(ItemDB) ~= "table" then ItemDB = {} end
    local InventoryModule = nil
    pcall(function() InventoryModule = require(Shared:FindFirstChild("Inventory")) end)
    local NetOk, Net = pcall(require, Shared and Shared:FindFirstChild("Net"))
    if not NetOk or type(Net) ~= "table" then Net = nil end
    local RolesOk, RolesModule = pcall(require, Shared and Shared:FindFirstChild("Roles"))
    if not RolesOk or type(RolesModule) ~= "table" then RolesModule = nil end
    local GameGui = PlayerGui:FindFirstChild("GameGui")
    local ParticlesOk, ParticlesModule = false, nil
    if GameGui then
        ParticlesOk, ParticlesModule = pcall(require, GameGui:FindFirstChild("Particles"))
        if not ParticlesOk then ParticlesModule = nil end
    end
    local MenuModOk, MenuModule = false, nil
    if GameGui then
        MenuModOk, MenuModule = pcall(require, GameGui:FindFirstChild("WorldMenu"))
        if not MenuModOk or type(MenuModule) ~= "table" then MenuModule = nil end
    end
    local SfxOk, SfxModule = false, nil
    if Shared then
        SfxOk, SfxModule = pcall(require, Shared:FindFirstChild("Sfx"))
        if not SfxOk then SfxModule = nil end
    end
    
    -- ---------- find the game's own data and functions ----------
    -- Identification is by shape and constants, never by name. The punch
    -- function is the game's own hit closure; the place function is the
    -- game's own setTile wrapper. Both are called, never reimplemented.
    local Refs = {
        World = nil, Inv = nil, SetTile = nil, State = nil, Punch = nil,
        Particles = {}, Menu = nil, Gems = nil, Hud = nil, Trees = nil, Others = nil,
    }
    local getconsts = (debug and debug.getconstants) or getconstants
    
    -- Drop list from the game (declared early: refsText reads it).
    local Drops = { list = nil, update = nil }
    local DropFailUntil = {}
    
    local function isSetTileFn(fn)
        if not getconsts then return false end
        if islclosure and not islclosure(fn) then return false end
        local ok, consts = pcall(getconsts, fn)
        if not ok or type(consts) ~= "table" then return false end
        local hasSend, hasPlaced, hasFlips = false, false, false
        for _, c in pairs(consts) do
            if c == "tile" or c == "SetTile" then hasSend = true
            elseif c == "placedAt" then hasPlaced = true
            elseif c == "flips" then hasFlips = true end
        end
        return hasSend and hasPlaced and hasFlips
    end
    
    local function isPunchFn(fn)
        if not getconsts then return false end
        if islclosure and not islclosure(fn) then return false end
        local ok, consts = pcall(getconsts, fn)
        if not ok or type(consts) ~= "table" then return false end
        local hasVend, hasMark = false, false
        for _, c in pairs(consts) do
            if c == "Empty the Vending Machine first!" then hasVend = true
            elseif c == "newCrack" or c == "HarvestProvider" then hasMark = true end
        end
        return hasVend and hasMark
    end
    
    local function isStateHolder(v)
        local fn = rawget(v, "state")
        if type(fn) ~= "function" then return false end
        local ok, s = pcall(fn)
        return ok and type(s) == "table" and type(s.x) == "number" and type(s.y) == "number"
            and s.facing ~= nil and s.vx ~= nil
    end
    
    local function isGameFn(fn)
        if fn == isSetTileFn or fn == isPunchFn then return false end
        if isexecutorclosure then
            local ok, res = pcall(isexecutorclosure, fn)
            if ok and res then return false end
        end
        local ok, src = pcall(debug.info, fn, "s")
        if ok and type(src) == "string" and src ~= "" and not string.find(src, "GameGui", 1, true) then
            return false
        end
        return true
    end
    
    local function findRefs()
        Refs.World, Refs.Inv, Refs.SetTile, Refs.State, Refs.Punch, Refs.Menu = nil, nil, nil, nil, nil, nil
        Refs.Gems = nil
        Refs.Hud = nil
        Refs.Others = nil
        Refs.Particles = {}
        if not getgc then
            return false, "Executor has no getgc()"
        end
        for _, v in ipairs(getgc(true)) do
            local tv = type(v)
            if tv == "table" then
                if not Refs.World then
                    local ok, isWorld = pcall(function()
                        return type(rawget(v, "fg")) == "table" and type(rawget(v, "bg")) == "table"
                            and type(rawget(v, "w")) == "number" and type(rawget(v, "h")) == "number"
                            and rawget(v, "spawn") ~= nil
                    end)
                    if ok and isWorld then Refs.World = v end
                end
                if not Refs.Inv then
                    local ok, isInv = pcall(function()
                        return getmetatable(v) == InventoryModule and type(rawget(v, "slots")) == "table"
                            and rawget(v, "capacity") ~= nil
                    end)
                    if ok and isInv then Refs.Inv = v end
                end
                if not Refs.State then
                    local ok, isHolder = pcall(isStateHolder, v)
                    if ok and isHolder then Refs.State = rawget(v, "state") end
                end
                if not Refs.Menu then
                    local ok, isMenu = pcall(function()
                        return type(rawget(v, "openBackpack")) == "function" and type(rawget(v, "ui")) == "table"
                    end)
                    if ok and isMenu then Refs.Menu = v end
                end
                if not Refs.Gems then
                    local ok, isG = pcall(function() return type(rawget(v, "addGems")) == "function" end)
                    if ok and isG then Refs.Gems = v end
                end
                if not Refs.Hud then
                    local ok, isH = pcall(function()
                        return type(rawget(v, "punchRange")) == "function" and type(rawget(v, "handPower")) == "function"
                    end)
                    if ok and isH then Refs.Hud = v end
                end
                if not Refs.Others then
                    local ok, isO = pcall(function()
                        return type(rawget(v, "list")) == "function" and type(rawget(v, "where")) == "function"
                            and type(rawget(v, "playerAt")) == "function"
                    end)
                    if ok and isO then Refs.Others = v end
                end
                if ParticlesOk then
                    local ok, isP = pcall(function()
                        return getmetatable(v) == ParticlesModule and type(rawget(v, "live")) == "table"
                            and type(rawget(v, "free")) == "table"
                    end)
                    if ok and isP then table.insert(Refs.Particles, v) end
                end
            elseif tv == "function" and (not Refs.SetTile or not Refs.Punch) and isGameFn(v) then
                if not Refs.SetTile and isSetTileFn(v) then
                    Refs.SetTile = v
                elseif not Refs.Punch and isPunchFn(v) then
                    Refs.Punch = v
                end
            end
            if Refs.World and Refs.Inv and Refs.SetTile and Refs.State and Refs.Punch
                and Refs.Menu and Refs.Gems and Refs.Hud and Refs.Others then break end
        end
        return Refs.World ~= nil
    end
    
    -- Extra check: the punch closure should share the world table as an
    -- upvalue (same game world the character is in). Read-only; only the
    -- status line reports the result, nothing depends on it.
    local punchValidated = false
    local function validatePunch()
        punchValidated = false
        if not Refs.Punch or not Refs.World then return end
        pcall(function()
            if debug and debug.getupvalues then
                local ok, ups = pcall(debug.getupvalues, Refs.Punch)
                if ok and type(ups) == "table" then
                    for _, u in pairs(ups) do
                        if u == Refs.World then punchValidated = true end
                    end
                end
            end
        end)
    end
    
    local function refsText()
        return "World: " .. (Refs.World and "OK" or "NO")
            .. " | Inventory: " .. (Refs.Inv and "OK" or "NO")
            .. " | setTile: " .. (Refs.SetTile and "OK" or "fallback")
            .. " | Position: " .. (Refs.State and "OK" or "fallback")
            .. " | Punch: " .. (Refs.Punch and (punchValidated and "OK" or "OK?") or "NO — fallback, may not break")
            .. " | Drops: " .. (Drops.list and "OK" or "NO")
            .. " | Trees: " .. (Refs.Trees and "OK" or "NO")
            .. " | Players: " .. (Refs.Others and "OK" or "NO")
    end
    
    -- ---------- inventory (read from the game's own live table) ----------
    local function itemName(id)
        local it = ItemDB[id]
        return (it and it.name) or ("Item #" .. tostring(id))
    end
    
    local function invCount(id)
        if not Refs.Inv then return 0 end
        local ok, n = pcall(function() return Refs.Inv:count(id) end)
        return ok and n or 0
    end
    
    local function isPlaceable(id)
        local it = ItemDB[id]
        if not it then return false end
        if it.kind == "tool" or it.kind == "cloth" or it.kind == "clothes" or it.kind == "consumable" then
            return false
        end
        if it.lock or it.area then return false end
        return true
    end
    
    local function placeableIds()
        local ids = {}
        if Refs.Inv then
            for _, slot in ipairs(Refs.Inv.slots) do
                if slot.id and (slot.n or 0) > 0 and isPlaceable(slot.id) then
                    ids[#ids + 1] = slot.id
                end
            end
        end
        table.sort(ids)
        return ids
    end
    
    local function seedIds()
        local ids = {}
        if Refs.Inv then
            for _, slot in ipairs(Refs.Inv.slots) do
                local it = slot.id and ItemDB[slot.id]
                if it and it.kind == "seed" and (slot.n or 0) > 0 then
                    ids[#ids + 1] = slot.id
                end
            end
        end
        table.sort(ids)
        return ids
    end
    
    local function idFromLabel(label)
        if type(label) ~= "string" then return nil end
        return tonumber(string.match(label, "%[(%d+)%]$"))
    end
    
    local function inventoryLabels(ids)
        local out = {}
        for _, id in ipairs(ids) do
            out[#out + 1] = string.format("%s [%d]", itemName(id), id)
        end
        if #out == 0 then out = { "(inventory empty / not read yet)" } end
        return out
    end
    
    local lastInvSig, lastSeedSig, lastBlockSig = nil, nil, nil
    local invRefreshPending = false
    local function selectSaved(opt, labels, id)
        if not opt or not id then return end
        local want = "[" .. tostring(id) .. "]"
        for _, label in ipairs(labels) do
            if string.sub(label, -#want) == want then
                pcall(function() opt:SetValue(label) end)
                return
            end
        end
    end
    
    local function doInvRefresh(force)
        local ids = placeableIds()
        local sig = table.concat(ids, ",")
        if force or sig ~= lastInvSig then
            lastInvSig = sig
            local labels = inventoryLabels(ids)
            if C.dd.farmBlock then pcall(function() C.dd.farmBlock:SetValues(labels) end) end
            selectSaved(C.dd.farmBlock, labels, idFromLabel(C.cfg.GBX_FarmBlock))
        end
        local sids = seedIds()
        local ssig = table.concat(sids, ",")
        if force or ssig ~= lastSeedSig then
            lastSeedSig = ssig
            local labels = inventoryLabels(sids)
            if #labels == 1 and labels[1] == "(inventory empty / not read yet)" then labels = { "(no seeds in inventory)" } end
            if C.dd.farmerSeed then pcall(function() C.dd.farmerSeed:SetValues(labels) end) end
            selectSaved(C.dd.farmerSeed, labels, idFromLabel(C.cfg.GBX_FarmerSeed))
        end
        local bids = {}
        for _, id in ipairs(ids) do
            local it = ItemDB[id]
            if it and it.solid and it.kind ~= "seed" then bids[#bids + 1] = id end
        end
        local bsig = table.concat(bids, ",")
        if force or bsig ~= lastBlockSig then
            lastBlockSig = bsig
            local labels = inventoryLabels(bids)
            if #labels == 1 and labels[1] == "(inventory empty / not read yet)" then labels = { "(no solid blocks in inventory)" } end
            if C.dd.clearScaffold then pcall(function() C.dd.clearScaffold:SetValues(labels) end) end
            if C.dd.farmerScaffold then pcall(function() C.dd.farmerScaffold:SetValues(labels) end) end
            selectSaved(C.dd.clearScaffold, labels, idFromLabel(C.cfg.GBX_ClearScaffold))
            selectSaved(C.dd.farmerScaffold, labels, idFromLabel(C.cfg.GBX_ClearScaffold))
        end
    end
    
    local function refreshInvDropdown(force)
        if force then
            task.defer(function()
                if alive() then doInvRefresh(true) end
            end)
            return
        end
        if invRefreshPending then return end
        invRefreshPending = true
        task.delay(1, function()
            invRefreshPending = false
            if alive() then doInvRefresh(false) end
        end)
    end
    
    local invConn = nil
    local function watchInventory()
        if invConn then pcall(function() invConn:Disconnect() end) end
        invConn = nil
        if Refs.Inv and typeof(Refs.Inv.changed) == "Instance" then
            invConn = Refs.Inv.changed.Event:Connect(function()
                if alive() then refreshInvDropdown(false) end
            end)
        end
    end
    
    -- ---------- world: tiles and player position ----------
    local function tileAt(layer, x, y)
        local w = Refs.World
        if not w or x < 0 or y < 0 or x >= w.w or y >= w.h then return nil end
        local grid = w[layer]
        local row = grid and grid[y]
        return row and (row[x] or 0) or nil
    end
    
    local function getView()
        local gg = PlayerGui:FindFirstChild("GameGui")
        local cam = gg and gg:FindFirstChild("World") and gg.World:FindFirstChild("Camera")
        local tiles = cam and cam:FindFirstChild("Tiles")
        local pv = cam and cam:FindFirstChild("PlayerView")
        if not (tiles and pv) then return nil end
        local sample = tiles:FindFirstChildWhichIsA("ImageLabel")
        if not sample or sample.AbsoluteSize.X <= 0 then return nil end
        return { tiles = tiles, pv = pv, ts = sample.AbsoluteSize.X }
    end
    
    local function getPlayerTile()
        if Refs.State then
            local ok, s = pcall(Refs.State)
            if ok and type(s) == "table" and type(s.x) == "number" then
                if s.active == false then return nil end
                return math.floor(s.x) + (tonumber(C.cfg.GBX_CalibX) or 0), math.floor(s.y - 0.475) + (tonumber(C.cfg.GBX_CalibY) or 0)
            end
        end
        local v = getView()
        if not v then return nil end
        local center = v.pv.AbsolutePosition + v.pv.AbsoluteSize / 2
        local rel = center - v.tiles.AbsolutePosition
        return math.floor(rel.X / v.ts) + (tonumber(C.cfg.GBX_CalibX) or 0), math.floor(rel.Y / v.ts) + (tonumber(C.cfg.GBX_CalibY) or 0)
    end
    
    local function sortedOffsets()
        local list = {}
        for key in pairs(C.cfg.GBX_FarmOffsets) do
            local dx, dy = string.match(key, "^(-?%d+),(-?%d+)$")
            if dx then table.insert(list, { dx = tonumber(dx), dy = tonumber(dy) }) end
        end
        table.sort(list, function(a, b)
            if a.dy ~= b.dy then return a.dy < b.dy end
            return a.dx < b.dx
        end)
        return list
    end
    
    -- ---------- basic actions: place and punch ----------
    local HitCount = {}
    local PlacedAt = {}
    local FarmSkip = {}
    local FarmReject = {}
    
    local function sendSetTile(layer, x, y, id)
        if Refs.SetTile then
            local ok, err = pcall(Refs.SetTile, layer, x, y, id, false, false)
            if ok then return true end
            logLine("Place (game function) failed, using network fallback: " .. tostring(err))
        end
        if Net ~= nil and type(Net.tile) == "table" then
            local ok = pcall(Net.tile.send, {
                layer = (layer == "bg") and 2 or 1, x = x, y = y, id = id, flip = false,
            })
            if not ok then return false end
        elseif SetTileRemote then
            SetTileRemote:FireServer(layer, x, y, id, false)
        else
            return false
        end
        local grid = Refs.World and Refs.World[layer]
        if grid and grid[y] then grid[y][x] = id end
        return true
    end
    
    local function sendHitFx(x, y)
        if Net ~= nil and Net.act then
            pcall(Net.act.send, { x = x + 0.5, y = y + 0.5 })
        end
    end
    
    local function hitsNeeded(id)
        if (tonumber(C.cfg.GBX_HitsOverride) or 0) > 0 then return tonumber(C.cfg.GBX_HitsOverride) end
        local it = ItemDB[id]
        if not it then return 4 end
        local h = (it.kind == "seed") and 3 or it.hits
        return tonumber(h) or 4
    end
    
    local function canBreak(id)
        if id == 0 then return false end
        local it = ItemDB[id]
        if not it then return true end
        if it.lock or it.area or it.vend or it.display then return false end
        local h = (it.kind == "seed") and 3 or it.hits
        return h == nil or h > 0
    end
    
    -- The game ignores punches to a tile placed less than ~0.3 s ago.
    local PLACE_GUARD = 0.32
    
    local function farmBlockId()
        return idFromLabel(C.cfg.GBX_FarmBlock)
    end
    
    local function tryPlace(x, y)
        local id = farmBlockId()
        if not id then return nil end
        local fg = tileAt("fg", x, y)
        if fg == nil then return nil end
        local bg = tileAt("bg", x, y)
        local it = ItemDB[id]
        local layer = (it and it.background) and "bg" or "fg"
        local cur = (layer == "bg") and bg or fg
        if not (cur == 0 and (layer == "bg" or fg == 0)) then return nil end
        if invCount(id) <= 0 then return "out" end
        sendSetTile(layer, x, y, id)
        if Refs.Inv then pcall(function() Refs.Inv:remove(id, 1) end) end
        local key = x .. "," .. y
        HitCount[key] = nil
        PlacedAt[key] = os.clock()
        C.stats.placed += 1
        return "place"
    end
    
    local function breakableAt(x, y)
        local fg = tileAt("fg", x, y)
        if fg == nil then return false end
        if fg ~= 0 then return canBreak(fg) end
        local bg = tileAt("bg", x, y)
        return bg ~= nil and bg ~= 0 and canBreak(bg)
    end
    
    -- One punch. Returns "hit" / "broke" / nil.
    -- Native path: call the game's own punch function, then read the
    -- game's own tile grid to see whether the tile actually broke.
    -- Fallback (punch function not found): count hits locally, play the
    -- hit effect, and send the clear at the threshold. The fallback is
    -- the hand-sent path that does not persist on the server — the
    -- status line says so plainly when it is in use.
    local function tryBreak(x, y, includeBg)
        if includeBg == nil then includeBg = true end
        local key = x .. "," .. y
        local fg = tileAt("fg", x, y)
        if fg == nil then return nil end
        local bg = tileAt("bg", x, y)
        local layer, id
        if fg ~= 0 then
            layer, id = "fg", fg
        elseif includeBg and bg ~= 0 then
            layer, id = "bg", bg
        end
        if not layer or not canBreak(id) then return nil end
        local t = PlacedAt[key]
        if t then
            local age = os.clock() - t
            if age < PLACE_GUARD then task.wait(PLACE_GUARD - age) end
            PlacedAt[key] = nil
        end
        if Refs.Punch then
            -- The game itself gates punches: after each punch it sets
            -- world.punchReady = now + 0.22 and returns "wait" while
            -- now < punchReady, so the Break Speed slider alone cannot go
            -- faster than ~220 ms. Resetting punchReady to 0 first lets
            -- the slider control the rate. The SERVER may still enforce
            -- its own cadence -- if tiles start reverting, step back up.
            if C.cfg.GBX_BypassPunchCooldown == true and Refs.World then
                pcall(function() Refs.World.punchReady = 0 end)
            end
            local ok, err = pcall(Refs.Punch, x, y, (C.cfg.GBX_MutePunch == true) or nil, nil)
            if not ok then
                logLine("Punch error: " .. tostring(err))
                return nil
            end
            if tileAt(layer, x, y) ~= id then
                C.stats.broken += 1
                return "broke"
            end
            return "hit"
        end
        local hc = HitCount[key]
        if not hc or hc.id ~= id or hc.layer ~= layer then
            hc = { id = id, layer = layer, n = 0 }
            HitCount[key] = hc
        end
        hc.n += 1
        sendHitFx(x, y)
        local need = hitsNeeded(id)
        if hc.n >= need then
            sendSetTile(layer, x, y, 0)
            HitCount[key] = nil
            C.stats.broken += 1
            return "broke"
        end
        return "hit"
    end
    
    -- Server-driven break confirmation: the game's own tileChanged event.
    -- A tile the server reports as 0 really broke. Counted for the status
    -- line only; the local read above stays the fast path.
    -- One listen per Net object: reconnect() calls this every time, and
    -- without the guard each retry would stack another listener and the
    -- server-confirmed counter would count every break twice (or more).
    local tileListenNet = nil
    local function listenTileChanged()
        if Net == nil or Net.tileChanged == nil or type(Net.tileChanged.listen) ~= "function" then return end
        if tileListenNet == Net then return end
        tileListenNet = Net
        pcall(function()
            Net.tileChanged.listen(function(pkt)
                if type(pkt) == "table" and pkt.id == 0 and type(pkt.x) == "number" and type(pkt.y) == "number" then
                    C.stats.serverConfirmed += 1
                end
            end)
        end)
    end
    
    -- Forward declarations (defined in later sections, called by reconnect).
    local findDropRefs, findTreeRefs
    local stopClear, stopFarmer, setLite, hookJammer
    local Reach = nil
    
    local function reconnect(show)
        if C.clearRunning then stopClear("Stopped: reconnecting to the game") end
        if C.farmerRunning then stopFarmer("Stopped: reconnecting to the game") end
        Reach = nil
        findRefs()
        validatePunch()
        if findDropRefs then pcall(findDropRefs) end
        if findTreeRefs then pcall(findTreeRefs) end
        table.clear(DropFailUntil)
        watchInventory()
        refreshInvDropdown(true)
        if C.cfg.GBX_LiteMode == true then setLite(true) end
        if C.cfg.GBX_InfJump == true then hookJammer() end
        if Refs.World and type(rawget(Refs.World, "name")) == "string" then
            C.lastWorld = rawget(Refs.World, "name")
        end
        if C.refsLabel ~= nil then
            pcall(function() C.refsLabel:SetText(refsText()) end)
        end
        listenTileChanged()
        if show and C.notifyFn then C.notifyFn(refsText()) end
    end
    
    -- ---------- auto collect ----------
    -- The game's own way: World.takeDrop(uid, amount) -> the server
    -- replies with the amount taken -> it goes into the inventory.
    local function getUpvalues(fn)
        if debug and debug.getupvalues then
            local ok, ups = pcall(debug.getupvalues, fn)
            if ok and type(ups) == "table" then return ups end
        end
        local out = {}
        local gu = (debug and debug.getupvalue) or getupvalue
        if gu then
            for i = 1, 60 do
                local ok, v = pcall(gu, fn, i)
                if not ok then break end
                out[i] = v
            end
        end
        return out
    end
    
    local function isDropList(t)
        if type(t) ~= "table" or t == Refs.World then return false end
        local first = rawget(t, 1)
        if first == nil then return next(t) == nil end
        return type(first) == "table" and rawget(first, "uid") ~= nil and rawget(first, "frame") ~= nil
    end
    
    function findDropRefs()
        Drops.list, Drops.update = nil, nil
        local wd = Refs.World and rawget(Refs.World, "dropTaken")
        if type(wd) == "function" then
            for _, u in pairs(getUpvalues(wd)) do
                if not Drops.list and isDropList(u) then
                    Drops.list = u
                elseif not Drops.update and type(u) == "function" then
                    Drops.update = u
                end
            end
        end
        local ev = WorldRemotes and WorldRemotes:FindFirstChild("DropTaken")
        if not Drops.list and ev and getconnections then
            local ok, conns = pcall(getconnections, ev.OnClientEvent)
            if ok and type(conns) == "table" then
                for _, c in ipairs(conns) do
                    local okf, fn = pcall(function() return c.Function end)
                    if okf and type(fn) == "function" then
                        for _, u in pairs(getUpvalues(fn)) do
                            if not Drops.list and isDropList(u) then
                                Drops.list = u
                            elseif not Drops.update and type(u) == "function" then
                                Drops.update = u
                            end
                        end
                    end
                    if Drops.list then break end
                end
            end
        end
        if not Drops.list and getgc then
            for _, v in ipairs(getgc(true)) do
                if type(v) == "table" then
                    local e = rawget(v, 1)
                    if type(e) == "table" and rawget(e, "uid") ~= nil and rawget(e, "frame") ~= nil
                        and rawget(e, "born") ~= nil then
                        Drops.list = v
                        break
                    end
                end
            end
        end
        return Drops.list ~= nil
    end
    C.findDropRefs = findDropRefs
    
    local function takeDrop(d)
        local worldTake = Refs.World and rawget(Refs.World, "takeDrop")
        if type(worldTake) ~= "function" and not TakeDropRemote then return false end
        if d.taking or d.pending or d.display or (d.n or 0) <= 0 then return false end
        -- A drop you threw yourself cannot be picked up again yet (game
        -- rule), except gems.
        if d.armed == false and d.id ~= 112 then return false end
        local now = os.clock()
        if DropFailUntil[d.uid] and now < DropFailUntil[d.uid] then return false end
        local amount = d.n
        if d.id ~= 112 and Refs.Inv then -- 112 = gems, no slot used
            local okr, room = pcall(function() return Refs.Inv:room(d.id) end)
            if okr and type(room) == "number" then amount = math.min(amount, room) end
        end
        if amount <= 0 then -- inventory full: retry in 1 s
            DropFailUntil[d.uid] = now + 1
            return false
        end
        d.taking = true
        d.flown = true
        if typeof(d.frame) == "Instance" then pcall(function() d.frame.Visible = false end) end
        local ok, taken
        if type(worldTake) == "function" then
            ok, taken = pcall(worldTake, d.uid, amount)
        else
            ok, taken = pcall(TakeDropRemote.InvokeServer, TakeDropRemote, d.uid, amount)
        end
        d.taking = false
        if not (ok and type(taken) == "number" and taken > 0) then
            C.stats.collectFail += 1
            d.refused = os.clock()
            DropFailUntil[d.uid] = os.clock() + 1
            d.flown = nil
            if typeof(d.frame) == "Instance" then pcall(function() d.frame.Visible = not d.culled end) end
            return false
        end
        DropFailUntil[d.uid] = nil
        if d.id == 112 then
            if Refs.Gems then pcall(Refs.Gems.addGems, taken) end
        elseif Refs.Inv then
            pcall(function() Refs.Inv:add(d.id, taken) end)
        end
        if Drops.list and Drops.update and table.find(Drops.list, d) then
            pcall(Drops.update, d, d.n - taken)
        end
        C.stats.collected += taken
        return true
    end
    
    local function inTile(t, x, y)
        return x >= t.x - 0.15 and x < t.x + 1.15 and y >= t.y - 0.15 and y < t.y + 1.15
    end
    
    -- Fast collector: checks the drop list every frame. Drops in range
    -- are taken all at once (in parallel), not one server reply at a time.
    --   Auto Farm  : drops on the selected farm tiles
    --   Clear / Farmer : drops near the character
    local OffsetParse = {}
    local nextDropScan = 0
    
    local function canTry(d, now)
        if type(d) ~= "table" or d.taking or (d.n or 0) <= 0 or type(d.x) ~= "number" then return false end
        if d.armed == false and d.id ~= 112 then return false end
        local fail = DropFailUntil[d.uid]
        return not (fail and now < fail)
    end
    
    local function collectTick()
        local farmArea = (C.cfg.GBX_AutoCollect == true) and next(C.cfg.GBX_FarmOffsets) ~= nil and C.farmRunning
        local nearArea = (C.clearRunning and C.cfg.GBX_ClearCollect == true) or (C.farmerRunning and C.cfg.GBX_FarmerCollect == true) or (C.dirtRunning and C.cfg.GBX_AutoCollect == true)
        if not farmArea and not nearArea then return end
        local list = Drops.list
        if not list then
            local now = os.clock()
            if now >= nextDropScan then
                nextDropScan = now + 5
                findDropRefs()
            end
            return
        end
        if #list == 0 then return end
        local ok, s = false, nil
        if Refs.State then ok, s = pcall(Refs.State) end
        if not (ok and type(s) == "table" and type(s.x) == "number") then return end
        local cx, cy = s.x, s.y - 0.475
        local ptx, pty = getPlayerTile()
        local now = os.clock()
        for i = #list, 1, -1 do
            local d = list[i]
            if canTry(d, now) then
                local R = tonumber(C.cfg.GBX_CollectRadius) or 3.2
                local hit = nearArea and math.abs(d.x - cx) <= R and math.abs(d.y - cy) <= R
                if not hit and farmArea and ptx then
                    for key in pairs(C.cfg.GBX_FarmOffsets) do
                        local o = OffsetParse[key]
                        if not o then
                            local dx, dy = string.match(key, "^(-?%d+),(-?%d+)$")
                            o = { tonumber(dx), tonumber(dy) }
                            OffsetParse[key] = o
                        end
                        if inTile({ x = ptx + o[1], y = pty + o[2] }, d.x, d.y) then
                            hit = true
                            break
                        end
                    end
                end
                if hit then task.spawn(takeDrop, d) end
            end
        end
    end
    
    -- Wait a moment for drops on this tile to be collected (so a new
    -- block does not bury them).
    local function waitTileDrops(t, maxSec)
        local list = Drops.list
        if not list then return end
        local t0 = os.clock()
        while os.clock() - t0 < maxSec and alive() do
            local now, busy = os.clock(), false
            for _, d in ipairs(list) do
                if type(d) == "table" and type(d.x) == "number" and (d.n or 0) > 0 and inTile(t, d.x, d.y)
                    and (d.taking or canTry(d, now)) then
                    busy = true
                    break
                end
            end
            if not busy then return end
            task.wait()
        end
    end
    
    -- ---------- status ----------
    C.farmRunning = false
    C.clearRunning = false
    C.farmerRunning = false
    C.farmStatus = "-"
    C.clearStatus = "-"
    C.farmerStatus = "-"
    C.farmCycles = 0
    C.dirtRunning = false
    C.dirtStatus = "-"
    
    local function offsetsText()
        local list = {}
        for _, o in ipairs(sortedOffsets()) do
            table.insert(list, "(" .. o.dx .. "," .. o.dy .. ")")
        end
        return #list > 0 and table.concat(list, " ") or "-"
    end
    
    -- ---------- Lite mode (no particles / sound) ----------
    local DummyLabel = setmetatable({}, { __index = function() return 0 end, __newindex = function() end })
    local DummyParticle = setmetatable({ l = DummyLabel, k = {} }, { __index = function() return 0 end, __newindex = function() end })
    local NullSound
    NullSound = setmetatable({}, {
        __index = function() return NullSound end,
        __newindex = function() end,
        __call = function() return NullSound end,
    })
    local LiteSaved = {}
    
    local function liteOverride(tbl, key, repl)
        if type(tbl) == "table" and type(rawget(tbl, key)) == "function" then
            table.insert(LiteSaved, { tbl, key, rawget(tbl, key) })
            tbl[key] = repl
        end
    end
    
    function setLite(on)
        if on then
            if #LiteSaved == 0 then
                if ParticlesOk then liteOverride(ParticlesModule, "spawn", function() return DummyParticle end) end
                if SfxOk then
                    liteOverride(SfxModule, "play", function() return NullSound end)
                    liteOverride(SfxModule, "playAt", function() return NullSound end)
                end
            end
            for _, p in ipairs(Refs.Particles) do
                pcall(function()
                    for _, e in ipairs(p.live) do
                        if typeof(e.l) == "Instance" then e.l.Visible = false end
                    end
                end)
            end
        else
            for _, s in ipairs(LiteSaved) do
                pcall(function() s[1][s[2]] = s[3] end)
            end
            table.clear(LiteSaved)
        end
    end
    
    -- ---------- misc: walkspeed, infinite jump, virtual input ----------
    -- Movement keys the game reads. Clear / Farmer "press" these keys
    -- through the game's own input check below; nothing here writes a
    -- position or teleports.
    local AutoInput = { active = false, left = false, right = false, jump = false, down = false }
    local Misc = { Speed = 100, InfJump = false }
    
    local OrigJammerOn = nil
    local function infJumpWrapper(id, ...)
        -- Off while Clear / Farmer run (jumping must be normal there).
        if (C.cfg.GBX_InfJump == true) and id == 4992 and not AutoInput.active then
            return true
        end
        if OrigJammerOn then return OrigJammerOn(id, ...) end
        return false
    end
    
    function hookJammer()
        local w = Refs.World
        if not w then return end
        local cur = rawget(w, "jammerOn")
        if cur == infJumpWrapper or type(cur) ~= "function" then return end
        OrigJammerOn = cur
        w.jammerOn = infJumpWrapper
    end
    
    local function unhookJammer()
        local w = Refs.World
        if w and rawget(w, "jammerOn") == infJumpWrapper and OrigJammerOn then
            w.jammerOn = OrigJammerOn
        end
    end
    
    local function setSpeed(pct)
        Misc.Speed = math.clamp(math.floor(tonumber(pct) or 100), 50, 500)
        if Misc.Speed == 100 and Refs.World then Refs.World.speedScale = 1 end
    end
    
    -- The game's movement keys are read from WorldMenu.isDown. Wrapped so
    -- Clear / Farmer can "press" keys themselves, exactly as a player
    -- would. The original function is always called for anything else.
    local OrigIsDown = nil
    local function isDownWrapper(saved, key, ...)
        if AutoInput.active then
            if key == "keyLeft" then return AutoInput.left end
            if key == "keyRight" then return AutoInput.right end
            if key == "keyJump" then return AutoInput.jump end
            if key == "keyDown" then return AutoInput.down end
        end
        return OrigIsDown(saved, key, ...)
    end
    
    if MenuModOk and MenuModule ~= nil and type(rawget(MenuModule, "isDown")) == "function" then
        OrigIsDown = rawget(MenuModule, "isDown")
        MenuModule.isDown = isDownWrapper
    end
    
    -- Re-apply walkspeed every frame (the game can overwrite it).
    RunService.Heartbeat:Connect(function()
        local w = Refs.World
        if not w or not alive() then return end
        if Misc.Speed ~= 100 then w.speedScale = Misc.Speed / 100 end
    end)
    RunService.Heartbeat:Connect(function()
        if alive() then collectTick() end
    end)
    
    -- ---------- automatic movement, Clear World, Farmer ----------
    -- One function chunk (keeps the local count down). Movement drives
    -- the game's own input keys; A* finds a path using the game's own
    -- physics (walk / fall / jump 1-3 / gap / pillar with a scaffold
    -- block). No position is ever written.
    do (function()
    local floor, abs = math.floor, math.abs
    local Move = { Placed = 0, Homing = false }
    local BadEdge = {}
    local ClearFail, FarmerFail = {}, {}
    local BreakTimes = {}
    local ClearSkip, FarmerSkip = {}, {}
    local Clear = { TopRow = -1, DirRow = nil, Dir = nil, Broken = 0, Remaining = -1 }
    local Farmer = { Harvested = 0, Planted = 0 }
    
    local function autoOn()
        return (C.clearRunning or C.farmerRunning or C.dirtRunning or Move.Homing) and alive()
    end
    
    local function setMoveStatus(text)
        if C.clearRunning then C.clearStatus = text elseif C.farmerRunning then C.farmerStatus = text elseif C.dirtRunning then C.dirtStatus = text end
    end
    
    local function skipTile(tbl, idx, sec)
        tbl[idx] = os.clock() + (sec or 30)
    end
    
    local function skipped(tbl, idx, now)
        local t = tbl[idx]
        if not t then return false end
        if (now or os.clock()) >= t then
            tbl[idx] = nil
            return false
        end
        return true
    end
    
    local function skippedCount(tbl)
        local n, now = 0, os.clock()
        for _, t in pairs(tbl) do
            if t > now then n += 1 end
        end
        return n
    end
    
    local function hudRange(name, def)
        local f = Refs.Hud and Refs.Hud[name]
        if type(f) == "function" then
            local ok, r = pcall(f)
            if ok and type(r) == "number" and r > 0 then return r end
        end
        return def
    end
    
    local function punchReach() return hudRange("punchRange", 2.5) end
    local function buildReach() return hudRange("buildRange", 2.5) end
    
    local function playerState()
        if not Refs.State then return nil end
        local ok, s = pcall(Refs.State)
        if ok and type(s) == "table" and type(s.x) == "number" and type(s.y) == "number" and s.active ~= false then
            return s
        end
        return nil
    end
    
    local function fgIdAt(x, y)
        local w = Refs.World
        local row = w and w.fg[y]
        return (row and row[x]) or 0
    end
    
    local function fgItemAt(x, y)
        local id = fgIdAt(x, y)
        if id ~= 0 then return ItemDB[id] end
        return nil
    end
    
    local function solidAt(x, y)
        local w = Refs.World
        if not w then return true end
        if x < 0 or x >= w.w or y >= w.h then return true end
        if y < 0 then return false end
        local it = fgItemAt(x, y)
        if not it then return false end
        if it.combiner then
            local ok, shut = pcall(w.combinerShut, x, y)
            return (not ok) or (shut and true or false)
        end
        if it.vip then
            local ok, may = pcall(w.vipMay, x, y)
            return not (ok and may)
        end
        if it.entrance then
            local sw = w.switches and w.switches[y * w.w + x]
            if it.gate then
                return not (sw and sw.off == true)
            end
            if sw and sw.public then return false end
            local ok, may = pcall(function() return w.areas.mayBuild(w.lock, x, y) end)
            return not (ok and may)
        end
        return it.solid and true or false
    end
    
    local function hazardAt(x, y)
        local it = fgItemAt(x, y)
        return it ~= nil and (it.deadly or it.hurts or it.laser) and true or false
    end
    
    local function platformAt(x, y)
        local it = fgItemAt(x, y)
        return it ~= nil and it.platform and true or false
    end
    
    local function openAt(x, y)
        return not solidAt(x, y) and not hazardAt(x, y)
    end
    
    local function realSupport(x, y)
        return not hazardAt(x, y + 1) and (solidAt(x, y + 1) or platformAt(x, y + 1))
    end
    
    local function stateReaches(s, tx, ty, R)
        return abs(tx + 0.5 - s.x) <= R and abs(ty + 0.5 - (s.y - 0.475)) <= R
    end
    
    local function canWorkAt(x, y)
        local w = Refs.World
        local ok, res = pcall(function()
            if w.areas and type(w.areas.mayBuild) == "function" and not w.areas.mayBuild(w.lock, x, y) then
                return false
            end
            if type(w.builderOk) == "function" and not w.builderOk(x, y, false) then
                return false
            end
            return true
        end)
        return (not ok) or res
    end
    
    local function scaffoldId()
        if C.cfg.GBX_ClearUseBlock ~= true then return nil end
        local id = idFromLabel(C.cfg.GBX_ClearScaffold)
        if id and invCount(id) > 0 then return id end
        return nil
    end
    
    local function placeOk(x, y)
        local w = Refs.World
        if not w or x < 0 or y < 0 or x >= w.w or y >= w.h then return false end
        if fgIdAt(x, y) ~= 0 then return false end
        local ok, res = pcall(function()
            if w.areas and type(w.areas.canEdit) == "function" and not w.areas.canEdit(x, y) then return false end
            if type(w.builderOk) == "function" and not w.builderOk(x, y, true) then return false end
            return true
        end)
        return (not ok) or res
    end
    
    local function placeScaffold(x, y)
        local id = scaffoldId()
        if not id or not placeOk(x, y) then return false end
        local s = playerState()
        if not s or not stateReaches(s, x, y, buildReach() - 0.05) then return false end
        sendSetTile("fg", x, y, id)
        if Refs.Inv then pcall(function() Refs.Inv:remove(id, 1) end) end
        Move.Placed += 1
        return true
    end
    
    local function worldVersion()
        return Clear.Broken + Farmer.Harvested + Farmer.Planted + Move.Placed
    end
    
    local function startNode(s)
        local ny = floor(s.y - 0.475)
        local nx = floor(s.x)
        if realSupport(nx, ny) then return nx, ny end
        local a, b = floor(s.x - 0.3), floor(s.x + 0.3 - 0.0001)
        for _, c in ipairs({ a, b }) do
            if c ~= nx and realSupport(c, ny) then return c, ny end
        end
        return nx, ny
    end
    
    local function heapPush(hf, hi, n, f, i)
        n += 1
        local k = n
        while k > 1 do
            local p = k // 2
            if hf[p] <= f then break end
            hf[k], hi[k] = hf[p], hi[p]
            k = p
        end
        hf[k], hi[k] = f, i
        return n
    end
    
    local function heapPop(hf, hi, n)
        local top = hi[1]
        local lf, li = hf[n], hi[n]
        hf[n], hi[n] = nil, nil
        n -= 1
        if n > 0 then
            local k = 1
            while true do
                local c = k * 2
                if c > n then break end
                if c < n and hf[c + 1] < hf[c] then c += 1 end
                if lf <= hf[c] then break end
                hf[k], hi[k] = hf[c], hi[c]
                k = c
            end
            hf[k], hi[k] = lf, li
        end
        return top, n
    end
    
    local MAX_EXPAND = 8000
    local BLOCK_COST = 2
    
    local function reachOffsets(R)
        return floor(R), math.ceil(-R + 0.025), floor(R + 0.025)
    end
    
    local function astar(sx, sy, goals, gx, gy, R, useBlock)
        local w = Refs.World
        if not w then return nil, false, {} end
        local W, H = w.w, w.h
        local WH = W * H
        local dxm, dyLo, dyHi = reachOffsets(R)
        local oC, sC, bC = {}, {}, {}
        local function open(x, y)
            if x < 0 or x >= W or y >= H then return false end
            if y < 0 then return true end
            local i = y * W + x
            local v = oC[i]
            if v == nil then
                v = openAt(x, y)
                oC[i] = v
            end
            return v
        end
        local function sup(x, y)
            if x < 0 or x >= W or y < 0 or y >= H then return false end
            local i = y * W + x
            local v = sC[i]
            if v == nil then
                v = realSupport(x, y)
                sC[i] = v
            end
            return v
        end
        local function buildable(x, y)
            if not useBlock or x < 0 or x >= W or y < 0 or y >= H then return false end
            local i = y * W + x
            local v = bC[i]
            if v == nil then
                v = placeOk(x, y)
                bC[i] = v
            end
            return v
        end
        local function h(x, y)
            local dx = abs(gx - x) - R
            local dyRaw = gy - y
            local dy = abs(dyRaw) - R
            local vw = (dyRaw < 0) and 1.5 or 0.5
            return (dx > 0 and dx or 0) + vw * (dy > 0 and dy or 0)
        end
        local function isGoal(nx, ny)
            for ty = ny + dyLo, ny + dyHi do
                if ty >= 0 and ty < H then
                    local base = ty * W
                    for tx = nx - dxm, nx + dxm do
                        if tx >= 0 and tx < W and goals[base + tx] and not (tx == nx and ty == ny + 1) then
                            return true
                        end
                    end
                end
            end
            return false
        end
        local ex, ey, ek, ec, eb = {}, {}, {}, {}, {}
        local n = 0
        local function add(x, y, kind, cost, build)
            n += 1
            ex[n], ey[n], ek[n], ec[n], eb[n] = x, y, kind, cost, build
        end
        local function expand(x, y)
            n = 0
            for s = -1, 1, 2 do
                local ax = x + s
                if open(ax, y) then
                    if sup(ax, y) then
                        add(ax, y, "walk", 1, false)
                    else
                        if buildable(ax, y + 1) then
                            add(ax, y, "walk", 1 + BLOCK_COST, true)
                        end
                        local fy = y + 1
                        while fy < H and fy - y <= 40 and open(ax, fy) and not sup(ax, fy) do
                            fy += 1
                        end
                        if fy < H and open(ax, fy) and sup(ax, fy) then
                            add(ax, fy, "fall", 1 + 0.5 * (fy - y), false)
                        end
                        if open(x, y - 1) and open(x, y - 2) then
                            for dist = 2, 3 do
                                local mx = x + (dist - 1) * s
                                if not (open(mx, y) and open(mx, y - 1) and open(mx, y - 2)) then break end
                                if dist == 3 and sup(mx, y) then break end
                                local bx = x + dist * s
                                if open(bx, y - 1) and open(bx, y - 2) then
                                    for k = 0, 2 do
                                        if not open(bx, y + k) then break end
                                        if sup(bx, y + k) then
                                            add(bx, y + k, "gap", dist + 0.5 + 0.5 * k, false)
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                for dy = 1, 3 do
                    if not open(x, y - dy) then break end
                    if open(x, y - dy - 1) and open(ax, y - dy) and sup(ax, y - dy) and open(ax, y - dy - 1) then
                        add(ax, y - dy, "jump", 1 + 1.5 * dy, false)
                    end
                end
            end
            if useBlock and open(x, y - 1) and open(x, y - 2) and open(x, y - 3) and buildable(x, y) then
                add(x, y - 1, "pillar", 2 + BLOCK_COST, true)
            end
            return n
        end
        local startI = sy * W + sx
        local g, came, kind, buildOf, closed = { [startI] = 0 }, {}, {}, {}, {}
        local hf, hi, hn = {}, {}, 0
        hn = heapPush(hf, hi, hn, h(sx, sy), startI)
        local expanded = 0
        local now = os.clock()
        while hn > 0 do
            local cur
            cur, hn = heapPop(hf, hi, hn)
            if not closed[cur] then
                closed[cur] = true
                local cx, cy = cur % W, cur // W
                if isGoal(cx, cy) then
                    local path = {}
                    local i = cur
                    while i ~= startI do
                        local p = came[i]
                        table.insert(path, 1, {
                            fx = p % W, fy = p // W, x = i % W, y = i // W,
                            kind = kind[i], build = buildOf[i], key = p * WH + i,
                        })
                        i = p
                    end
                    return path, false, closed
                end
                expanded += 1
                if expanded > MAX_EXPAND then return nil, false, closed end
                if expanded % 400 == 0 then
                    task.wait()
                    if not autoOn() then return nil, false, closed end
                end
                local gc = g[cur]
                local cnt = expand(cx, cy)
                for k = 1, cnt do
                    local ni = ey[k] * W + ex[k]
                    if not closed[ni] then
                        local bad = BadEdge[cur * WH + ni]
                        if not (bad and bad > now) then
                            local ng = gc + ec[k]
                            local old = g[ni]
                            if old == nil or ng < old then
                                g[ni], came[ni], kind[ni], buildOf[ni] = ng, cur, ek[k], eb[k]
                                hn = heapPush(hf, hi, hn, ng + h(ex[k], ey[k]), ni)
                            end
                        end
                    end
                end
            end
        end
        return nil, true, closed
    end
    
    local function reachableTileSet(closed, W, R)
        local set = {}
        local dxm, dyLo, dyHi = reachOffsets(R)
        local n = 0
        for i in pairs(closed) do
            local x, y = i % W, i // W
            for dy = dyLo, dyHi do
                local ty = y + dy
                if ty >= 0 then
                    local base = ty * W
                    for dx = -dxm, dxm do
                        local tx = x + dx
                        if tx >= 0 and tx < W then set[base + tx] = true end
                    end
                end
            end
            n += 1
            if n % 500 == 0 then task.wait() end
        end
        return set
    end
    
    local function reachFilter(startI, R, useBlock)
        local c = Reach
        if c and c.world == Refs.World and c.start == startI and c.R == R and c.block == useBlock
            and c.ver == worldVersion() and os.clock() - c.at < 30 then
            return c.set
        end
        return nil
    end
    
    local function storeReach(startI, R, useBlock, closed)
        Reach = {
            world = Refs.World, start = startI, R = R, block = useBlock, ver = worldVersion(), at = os.clock(),
            set = reachableTileSet(closed, Refs.World.w, R),
        }
    end
    
    local function releaseInput()
        AutoInput.left, AutoInput.right, AutoInput.jump, AutoInput.down = false, false, false, false
    end
    
    local function frame()
        task.wait()
        return autoOn()
    end
    
    local function waitAuto(ms)
        task.wait(math.max(ms or 0, 30) / 1000)
        return autoOn()
    end
    
    local function steerX(s, targetX, tol)
        local dx = targetX - s.x
        local vx = s.vx or 0
        local decel = s.grounded and 48 or 17
        local dir = 0
        if abs(dx) > tol then
            dir = dx > 0 and 1 or -1
            if vx * dir > 0 and (vx * vx) / (2 * decel) >= abs(dx) - tol * 0.5 then
                dir = 0
            end
        end
        AutoInput.left = dir < 0
        AutoInput.right = dir > 0
    end
    
    local function execWalk(tx, ty)
        local cx = tx + 0.5
        local s0 = playerState()
        if not s0 then return false end
        local limit = 1.5 + abs(cx - s0.x) * 0.35
        local t0 = os.clock()
        while frame() do
            local s = playerState()
            if not s or s.dead then return false end
            local nx, ny = floor(s.x), floor(s.y - 0.475)
            if s.grounded and ny ~= ty then return false end
            steerX(s, cx, 0.1)
            if nx == tx and abs(s.x - cx) <= 0.2 and s.grounded and abs(s.vx or 0) < 2 then
                AutoInput.left, AutoInput.right = false, false
                return true
            end
            if os.clock() - t0 > limit then return false end
        end
        return false
    end
    
    local function execFall(e)
        local cx = e.x + 0.5
        local limit = 1.5 + 0.3 * (e.y - e.fy)
        local t0 = os.clock()
        while frame() do
            local s = playerState()
            if not s or s.dead then return false end
            steerX(s, cx, 0.1)
            if s.grounded then
                local nx, ny = floor(s.x), floor(s.y - 0.475)
                if ny == e.y then
                    if nx == e.x and abs(s.x - cx) <= 0.25 then return true end
                elseif ny ~= e.fy then
                    return false
                end
            end
            if os.clock() - t0 > limit then return false end
        end
        return false
    end
    
    local function execJump(e)
        if not execWalk(e.fx, e.fy) then return false end
        local dy = e.fy - e.y
        local top = e.y + 1
        local releaseY = top - ((dy == 1) and 0 or 0.4)
        local cx = e.x + 0.5
        releaseInput()
        if not frame() then return false end
        AutoInput.jump = true
        local t0 = os.clock()
        local airborne = false
        while frame() do
            local s = playerState()
            if not s or s.dead then return false end
            if not s.grounded then airborne = true end
            if AutoInput.jump and (s.y <= releaseY or (airborne and (s.vy or 0) >= 0)) then
                AutoInput.jump = false
            end
            if s.y <= top + 0.25 then
                steerX(s, cx, 0.1)
            else
                steerX(s, e.fx + 0.5, 0.15)
            end
            if airborne and s.grounded then
                local nx, ny = floor(s.x), floor(s.y - 0.475)
                if ny == e.y then
                    if nx == e.x and abs(s.x - cx) <= 0.25 then
                        AutoInput.jump = false
                        return true
                    end
                else
                    return false
                end
            end
            if not airborne and os.clock() - t0 > 0.35 then return false end
            if os.clock() - t0 > 1.8 then return false end
        end
        return false
    end
    
    local function execGap(e)
        if not execWalk(e.fx, e.fy) then return false end
        local s0 = playerState()
        if not s0 then return false end
        local dir = (e.x > e.fx) and 1 or -1
        local takeoff = e.fx + 0.5 + dir * 0.6
        local startY = s0.y
        local cx = e.x + 0.5
        releaseInput()
        local t0 = os.clock()
        local jumped, airborne, jumpAt = false, false, 0
        while frame() do
            local s = playerState()
            if not s or s.dead then return false end
            if not jumped then
                AutoInput.left, AutoInput.right = dir < 0, dir > 0
                if (s.x - takeoff) * dir >= 0 or not s.grounded then
                    jumped, jumpAt = true, os.clock()
                    AutoInput.jump = s.grounded
                end
            else
                if not s.grounded then airborne = true end
                if AutoInput.jump and (s.y <= startY - 1 or (airborne and (s.vy or 0) >= 0)) then
                    AutoInput.jump = false
                end
                steerX(s, cx, 0.1)
                if airborne and s.grounded then
                    local nx, ny = floor(s.x), floor(s.y - 0.475)
                    if ny == e.y then
                        if nx == e.x and abs(s.x - cx) <= 0.25 then return true end
                    else
                        return false
                    end
                end
                if not airborne and os.clock() - jumpAt > 0.35 then return false end
            end
            if os.clock() - t0 > 2.2 then return false end
        end
        return false
    end
    
    local function execPillar(e)
        if not execWalk(e.fx, e.fy) then return false end
        if fgIdAt(e.fx, e.fy) ~= 0 then return false end
        releaseInput()
        if not frame() then return false end
        AutoInput.jump = true
        local t0 = os.clock()
        local placed, airborne = false, false
        while frame() do
            local s = playerState()
            if not s or s.dead then return false end
            if not s.grounded then airborne = true end
            steerX(s, e.fx + 0.5, 0.12)
            if AutoInput.jump and (s.y < e.fy - 0.9 or (airborne and (s.vy or 0) >= 0)) then
                AutoInput.jump = false
            end
            -- Place the block late, once the server-side position has
            -- already risen with the jump.
            if not placed and airborne and s.y < e.fy - 0.25 and ((s.vy or 0) > -6 or s.y < e.fy - 0.8) then
                placed = placeScaffold(e.fx, e.fy)
                if not placed then return false end
            end
            if s.grounded and airborne then
                local nx, ny = floor(s.x), floor(s.y - 0.475)
                return placed and nx == e.x and ny == e.y
            end
            if not airborne and os.clock() - t0 > 0.35 then return false end
            if os.clock() - t0 > 1.8 then return false end
        end
        return false
    end
    
    local function followPath(path)
        local i = 1
        while i <= #path do
            if not autoOn() then return false end
            local e = path[i]
            local last, ok = i, false
            if e.kind == "walk" then
                local dir = e.x - e.fx
                while path[last + 1] and path[last + 1].kind == "walk" and (path[last + 1].x - path[last + 1].fx) == dir do
                    last += 1
                end
                local anyBuild = false
                for j = i, last do
                    if path[j].build then
                        anyBuild = true
                        break
                    end
                end
                if anyBuild then
                    ok = true
                    for j = i, last do
                        local st = path[j]
                        if st.build and not realSupport(st.x, st.y) then
                            setMoveStatus(("Placing a footing block (%d,%d)"):format(st.x, st.y + 1))
                            if not placeScaffold(st.x, st.y + 1) or not waitAuto(120) then
                                ok = false
                                break
                            end
                        end
                        if not execWalk(st.x, st.y) then
                            ok = false
                            break
                        end
                    end
                else
                    setMoveStatus(("Walking to (%d,%d)"):format(path[last].x, path[last].y))
                    ok = execWalk(path[last].x, path[last].y)
                end
            elseif e.kind == "pillar" then
                setMoveStatus(("Climbing with a block to (%d,%d)"):format(e.x, e.y))
                ok = execPillar(e)
            elseif e.kind == "fall" then
                setMoveStatus(("Dropping to (%d,%d)"):format(e.x, e.y))
                ok = execFall(e)
            elseif e.kind == "jump" then
                setMoveStatus(("Jumping to (%d,%d)"):format(e.x, e.y))
                ok = execJump(e)
            elseif e.kind == "gap" then
                setMoveStatus(("Jumping the gap to (%d,%d)"):format(e.x, e.y))
                ok = execGap(e)
            end
            releaseInput()
            if not ok then
                BadEdge[e.key] = os.clock() + 20
                return false
            end
            i = last + 1
        end
        return true
    end
    
    local function travelGroup(sx, sy, group, R, useBlock, skipTbl, failTbl)
        local w = Refs.World
        local goals = {}
        for _, t in ipairs(group) do goals[t.idx] = true end
        local first = group[1]
        setMoveStatus(("Finding a path to (%d,%d)"):format(first.x, first.y))
        local path, exhausted, closed = astar(sx, sy, goals, first.x, first.y, R, useBlock)
        if path then
            if #path == 0 then
                for _, t in ipairs(group) do skipTile(skipTbl, t.idx, 20) end
            elseif not followPath(path) then
                failTbl[first.idx] = (failTbl[first.idx] or 0) + 1
                if failTbl[first.idx] >= 3 then
                    for _, t in ipairs(group) do skipTile(skipTbl, t.idx, 40) end
                end
            end
            releaseInput()
            return true
        end
        for _, t in ipairs(group) do skipTile(skipTbl, t.idx, exhausted and 60 or 30) end
        if exhausted and w then storeReach(sy * w.w + sx, R, useBlock, closed) end
        releaseInput()
        return false
    end
    
    local function autoBegin()
        AutoInput.active = true
        releaseInput()
        Reach = nil
        -- Walking automation and noclip do not mix: the server pushes the
        -- character back when the position disagrees, so noclip is turned
        -- off while Clear / Farmer walk.
        if C.cfg.GBX_Noclip == true then
            C.cfg.GBX_Noclip = false
            saveCfg()
            if C.noclipOpt then pcall(function() C.noclipOpt:SetValue(false) end) end
        end
    end
    
    local function autoEnd()
        if C.clearRunning or C.farmerRunning or C.dirtRunning or Move.Homing then return end
        AutoInput.active = false
        releaseInput()
    end
    
    local function blockText()
        if C.cfg.GBX_ClearUseBlock ~= true then return "off" end
        local id = idFromLabel(C.cfg.GBX_ClearScaffold)
        if not id then return "not picked" end
        local n = invCount(id)
        return itemName(id) .. " x" .. n .. (n <= 0 and " (out)" or "")
    end
    
    -- ---------- Clear World: sweep from the top row down, 2 rows per band ----------
    local function clearCanBreak(id)
        if not id or id == 0 then return false end
        local it = ItemDB[id]
        if not it then return false end
        if it.lock or it.area or it.guildLock or it.vend or it.display then return false end
        local h = (it.kind == "seed") and 3 or it.hits
        if type(h) == "number" and h > 0 then return true end
        local w = Refs.World
        return (it.staffHits and w and w.areas and w.areas.staff) and true or false
    end
    
    local function clearLayerAt(x, y)
        local w = Refs.World
        local sp = w and w.spawn
        if sp ~= nil and (typeof(sp) == "Vector2" or type(sp) == "table") and x == sp.X and y == sp.Y then
            return nil
        end
        local fg = tileAt("fg", x, y)
        if fg == nil then return nil end
        if fg ~= 0 then
            if clearCanBreak(fg) then return "fg", fg end
            return nil
        end
        if C.cfg.GBX_ClearIncludeBg ~= false then
            local bg = tileAt("bg", x, y)
            if bg and bg ~= 0 and clearCanBreak(bg) then return "bg", bg end
        end
        return nil
    end
    
    local function scanTopRow()
        local w = Refs.World
        local W, H = w.w, w.h
        local now = os.clock()
        for y = 0, H - 1 do
            local frow, brow = w.fg[y], w.bg[y]
            for x = 0, W - 1 do
                local fid = frow and frow[x] or 0
                local bid = brow and brow[x] or 0
                if (fid ~= 0 or ((C.cfg.GBX_ClearIncludeBg ~= false) and bid ~= 0)) and clearLayerAt(x, y)
                    and not skipped(ClearSkip, y * W + x, now) then
                    return y
                end
            end
        end
        return nil
    end
    
    local function countRemaining()
        local w = Refs.World
        if not w then return -1 end
        local W, H = w.w, w.h
        local n, scanned = 0, 0
        for y = 0, H - 1 do
            local frow, brow = w.fg[y], w.bg[y]
            for x = 0, W - 1 do
                local fid = frow and frow[x] or 0
                local bid = brow and brow[x] or 0
                if (fid ~= 0 or ((C.cfg.GBX_ClearIncludeBg ~= false) and bid ~= 0)) and clearLayerAt(x, y) then n += 1 end
            end
            scanned += W
            if scanned >= 8000 then
                scanned = 0
                task.wait()
            end
        end
        return n
    end
    
    local function bandDir(topRow, s)
        if C.cfg.GBX_ClearSweep ~= "Zig-zag" then return 1 end
        if Clear.DirRow == topRow and Clear.Dir then return Clear.Dir end
        local w = Refs.World
        local now = os.clock()
        local minX, maxX
        for y = topRow, math.min(topRow + 1, w.h - 1) do
            for x = 0, w.w - 1 do
                if clearLayerAt(x, y) and not skipped(ClearSkip, y * w.w + x, now) then
                    if not minX or x < minX then minX = x end
                    if not maxX or x > maxX then maxX = x end
                end
            end
        end
        local dir = 1
        if minX and maxX and abs(s.x - maxX) < abs(s.x - minX) then dir = -1 end
        Clear.DirRow, Clear.Dir = topRow, dir
        return dir
    end
    
    local function bandTargets(top, bottom, dir, filter)
        local w = Refs.World
        local W = w.w
        local list = {}
        local now = os.clock()
        for y = top, math.min(bottom, w.h - 1) do
            for x = 0, W - 1 do
                local idx = y * W + x
                if clearLayerAt(x, y) and not skipped(ClearSkip, idx, now) then
                    if filter and not filter[idx] then
                        skipTile(ClearSkip, idx, 60)
                    elseif canWorkAt(x, y) then
                        list[#list + 1] = { x = x, y = y, idx = idx }
                    else
                        skipTile(ClearSkip, idx, 300)
                    end
                end
            end
        end
        table.sort(list, function(a, b)
            if a.x ~= b.x then return a.x * dir < b.x * dir end
            return a.y < b.y
        end)
        return list
    end
    
    local function clearInReach(s, bottom, dir)
        local w = Refs.World
        local W = w.w
        local R = punchReach() - 0.08
        local cx, cy = s.x, s.y - 0.475
        local footRow = floor(s.y + 0.01)
        local colA, colB = floor(s.x - 0.3), floor(s.x + 0.3 - 0.0001)
        local now = os.clock()
        local list = {}
        for ty = math.max(0, floor(cy - R - 0.5)), math.min(floor(cy + R + 0.5), bottom, w.h - 1) do
            for tx = math.max(0, floor(cx - R - 0.5)), math.min(floor(cx + R + 0.5), W - 1) do
                if stateReaches(s, tx, ty, R) then
                    local idx = ty * W + tx
                    if not skipped(ClearSkip, idx, now) and clearLayerAt(tx, ty) then
                        if canWorkAt(tx, ty) then
                            list[#list + 1] = {
                                x = tx, y = ty, idx = idx,
                                support = (ty == footRow and tx >= colA and tx <= colB),
                            }
                        else
                            skipTile(ClearSkip, idx, 300)
                        end
                    end
                end
            end
        end
        table.sort(list, function(a, b)
            if a.support ~= b.support then return not a.support end
            if a.x ~= b.x then return a.x * dir < b.x * dir end
            return a.y < b.y
        end)
        return list
    end
    
    local function fallAfterBreak(s, x, footRow)
        local colA, colB = floor(s.x - 0.3), floor(s.x + 0.3 - 0.0001)
        for c = colA, colB do
            if c ~= x and (solidAt(c, footRow) or platformAt(c, footRow)) then return 0 end
        end
        local w = Refs.World
        for y = footRow + 1, math.min(w.h - 1, footRow + 60) do
            if hazardAt(x, y) then return nil end
            if solidAt(x, y) or platformAt(x, y) then return y - footRow end
        end
        return 60
    end
    
    local function clearBreakTile(t)
        local x, y, idx = t.x, t.y, t.idx
        local layer, id = clearLayerAt(x, y)
        if not layer then return end
        local hits, maxHits = 0, hitsNeeded(id) * 3 + 6
        while C.clearRunning and alive() do
            layer, id = clearLayerAt(x, y)
            if not layer then return end
            local r = tryBreak(x, y, C.cfg.GBX_ClearIncludeBg ~= false)
            if r == nil then
                skipTile(ClearSkip, idx, 60)
                return
            end
            if r == "broke" then
                Clear.Broken += 1
                C.clearStatus = "Broke " .. itemName(id) .. " (" .. x .. "," .. y .. ")"
                BreakTimes[idx] = (BreakTimes[idx] or 0) + 1
                if BreakTimes[idx] > 6 then -- the server keeps putting this tile back
                    skipTile(ClearSkip, idx, 120)
                    return
                end
                hits = 0
                local _, nid = clearLayerAt(x, y)
                if nid then maxHits = hitsNeeded(nid) * 3 + 6 end
            else
                hits += 1
                C.clearStatus = "Hitting " .. itemName(id) .. " (" .. x .. "," .. y .. ")"
                if hits > maxHits then
                    skipTile(ClearSkip, idx, 45)
                    return
                end
            end
            if not waitAuto(tonumber(C.cfg.GBX_BreakMs) or 220) then return end
            if r == "broke" then
                local s = playerState()
                if not s or not s.grounded then return end
            end
        end
    end
    
    local function clearBreakList(list, s0)
        local footY = floor(s0.y - 0.475)
        local R = punchReach() - 0.08
        local done = 0
        for _, t in ipairs(list) do
            if not C.clearRunning or not alive() then break end
            local s = playerState()
            if not s or s.dead or not stateReaches(s, t.x, t.y, R) then break end
            if not s.grounded or floor(s.y - 0.475) ~= footY then break end
            local skipIt = false
            if t.support then
                local d = fallAfterBreak(s, t.x, floor(s.y + 0.01))
                if d == nil then
                    skipIt = true
                    C.clearStatus = ("Skipping (%d,%d): dangerous below"):format(t.x, t.y)
                elseif d > 3 then
                    skipIt = true
                    C.clearStatus = ("Skipping footing (%d,%d): drop below"):format(t.x, t.y)
                end
            end
            if skipIt then
                skipTile(ClearSkip, t.idx, 20)
            else
                clearBreakTile(t)
                done += 1
            end
        end
        return done
    end
    
    local lastClearText = nil
    local function updateClearStatus()
        if not C.clearLabel then return end
        local txt = "Status   : " .. (C.clearRunning and "RUNNING" or "STOPPED")
            .. "\nRow      : " .. (Clear.TopRow >= 0 and (Clear.TopRow .. "-" .. (Clear.TopRow + 1)) or "-")
            .. "  | direction: " .. ((Clear.Dir == -1 and C.cfg.GBX_ClearSweep == "Zig-zag") and "right→left" or "left→right")
            .. "\nBroken   : " .. Clear.Broken .. "  | collected: " .. C.stats.collected
            .. "\nLeft     : " .. (Clear.Remaining >= 0 and tostring(Clear.Remaining) or "-")
            .. "  | skipped: " .. skippedCount(ClearSkip)
            .. "\nScaffold : " .. blockText() .. "  | placed: " .. Move.Placed
            .. "\nAction   : " .. C.clearStatus
        if txt == lastClearText then return end
        lastClearText = txt
        task.defer(function()
            pcall(function() C.clearLabel:SetText(txt) end)
        end)
    end
    
    local function clearLoop()
        local idle, lastUi, lastCount = 0, 0, -10
        while C.clearRunning and alive() do
            task.wait()
            local now = os.clock()
            if now - lastCount > 3 then
                lastCount = now
                Clear.Remaining = countRemaining()
                if not C.clearRunning or not alive() then break end
            end
            if now - lastUi > 0.5 then
                lastUi = now
                updateClearStatus()
            end
            local w = Refs.World
            local s = playerState()
            if not w or not s or s.dead then
                releaseInput()
                C.clearStatus = "Waiting for character / world..."
                task.wait(0.5)
                continue
            end
            if not s.grounded then
                releaseInput()
                continue
            end
            releaseInput()
            local topRow = scanTopRow()
            if not topRow then
                local remaining = countRemaining()
                Clear.Remaining = remaining
                if remaining == 0 then
                    stopClear("World is clean!")
                    return
                end
                idle += 1
                if idle >= 3 then
                    stopClear(("Done. %d tiles left that cannot be reached / broken"):format(remaining))
                    return
                end
                C.clearStatus = ("%d skipped tiles left, retrying (%d/3)..."):format(remaining, idle)
                updateClearStatus()
                table.clear(ClearSkip)
                table.clear(ClearFail)
                table.clear(BadEdge)
                Reach = nil
                if not waitAuto(2000) then break end
                continue
            end
            Clear.TopRow = topRow
            local bottom = topRow + 1
            local dir = bandDir(topRow, s)
            local list = clearInReach(s, bottom, dir)
            if #list > 0 then
                if clearBreakList(list, s) > 0 then idle = 0 end
                continue
            end
            local R = punchReach() - 0.35
            local useBlock = scaffoldId() ~= nil
            local sx, sy = startNode(s)
            local band = bandTargets(topRow, bottom, dir, reachFilter(sy * w.w + sx, R, useBlock))
            if #band > 0 then
                local group = {}
                for _, t in ipairs(band) do
                    if (t.x - band[1].x) * dir <= 4 then group[#group + 1] = t end
                end
                travelGroup(sx, sy, group, R, useBlock, ClearSkip, ClearFail)
            end
        end
        releaseInput()
    end
    
    stopClear = function(reason)
        C.clearRunning = false
        autoEnd()
        C.clearStatus = reason or "Stopped"
        if reason and C.notifyFn then C.notifyFn("Auto Clear: " .. reason) end
        updateClearStatus()
    end
    
    local function checkAutoStart()
        if not Refs.World then return "Game data not found. Press 'Connect to game'" end
        if not Refs.Punch then return "Game punch function not found. Press 'Connect to game'" end
        if not OrigIsDown then return "Game movement keys (WorldMenu.isDown) not found" end
        if not playerState() then return "You are not in a world yet" end
        return nil
    end
    
    local function startClear()
        if C.clearRunning then return end
        local err = checkAutoStart()
        if err then
            if C.notifyFn then C.notifyFn("Auto Clear: " .. err) end
            return
        end
        if C.cfg.GBX_ClearUseBlock == true and (not idFromLabel(C.cfg.GBX_ClearScaffold) or invCount(idFromLabel(C.cfg.GBX_ClearScaffold)) <= 0) then
            if C.notifyFn then C.notifyFn("Auto Clear: scaffold block not picked / out — walking without scaffold blocks") end
        end
        if C.farmRunning and C.stopFarm then C.stopFarm("Stopped: Auto Clear started") end
        if C.farmerRunning then stopFarmer("Stopped: Auto Clear started") end
        if C.dirtRunning then stopDirtFarm("Stopped: Auto Clear started") end
        table.clear(ClearSkip)
        table.clear(ClearFail)
        table.clear(BadEdge)
        table.clear(BreakTimes)
        Clear.Broken = 0
        Clear.Remaining = -1
        Clear.TopRow = -1
        Clear.DirRow, Clear.Dir = nil, nil
        C.clearStatus = "Starting..."
        C.clearRunning = true
        autoBegin()
        updateClearStatus()
        task.spawn(function()
            local ok, e = pcall(clearLoop)
            if not ok then
                warn("[BerakHUB] Auto Clear error: " .. tostring(e))
                if C.clearRunning then stopClear("Error: " .. tostring(e)) end
            end
        end)
    end
    C.startClear = startClear
    C.stopClear = stopClear
    C.stopFarmer = stopFarmer
    C.resetClearSkip = function() table.clear(ClearSkip) end
    
    -- ---------- Farmer: harvest ripe trees + plant seeds ----------
    -- A tree is ripe when: server time >= plant time + grow time
    -- (same check the game uses). Seeds are planted on empty tiles with
    -- a solid non-seed block below.
    function findTreeRefs()
        Refs.Trees = nil
        local ev = WorldRemotes and WorldRemotes:FindFirstChild("TreeChanged")
        if not (ev and getconnections) then return false end
        local ok, conns = pcall(getconnections, ev.OnClientEvent)
        if not ok or type(conns) ~= "table" then return false end
        for _, c in ipairs(conns) do
            local okf, fn = pcall(function() return c.Function end)
            if okf and type(fn) == "function" then
                local ups = getUpvalues(fn)
                local cands = {}
                for i = 1, 12 do
                    local u = ups[i]
                    if type(u) == "table" and u ~= Refs.World and rawget(u, "fg") == nil then
                        cands[#cands + 1] = u
                    end
                end
                for _, t in ipairs(cands) do
                    local _, v = next(t)
                    if type(v) == "table" and type(rawget(v, "p")) == "number" then
                        Refs.Trees = t
                        break
                    end
                end
                if not Refs.Trees then
                    for _, t in ipairs(cands) do
                        if next(t) == nil then
                            Refs.Trees = t
                            break
                        end
                    end
                end
            end
            if Refs.Trees then break end
        end
        return Refs.Trees ~= nil
    end
    
    local function farmReach()
        return math.min(punchReach(), buildReach())
    end
    
    local function seedCount()
        local id = idFromLabel(C.cfg.GBX_FarmerSeed)
        return id and invCount(id) or 0
    end
    
    local function treeReadyAt(x, y, id)
        local trees, w = Refs.Trees, Refs.World
        if not trees or not w then return nil end
        local it = ItemDB[id]
        if not (it and it.kind == "seed") then return nil end
        local t = trees[y * w.w + x]
        if type(t) ~= "table" or type(t.p) ~= "number" then return nil end
        return t.p + (it.grow or 0)
    end
    
    local function plantSpotOk(x, y)
        local w = Refs.World
        if not w or x < 0 or y < 0 or x >= w.w or y + 1 >= w.h then return false end
        if fgIdAt(x, y) ~= 0 then return false end
        local below = fgIdAt(x, y + 1)
        if below == 0 then return false end
        local it = ItemDB[below]
        if not it or it.kind == "seed" then return false end
        if not (solidAt(x, y + 1) or it.platform) then return false end
        local ok, res = pcall(function()
            if w.areas and type(w.areas.canEdit) == "function" and not w.areas.canEdit(x, y) then return false end
            if type(w.builderOk) == "function" and not w.builderOk(x, y, true) then return false end
            local seed = idFromLabel(C.cfg.GBX_FarmerSeed) and ItemDB[idFromLabel(C.cfg.GBX_FarmerSeed)]
            if seed and type(w.needsWay) == "function" and w.needsWay(seed)
                and type(w.wayBlocked) == "function" and w.wayBlocked(x, y) then
                return false
            end
            return true
        end)
        return (not ok) or res
    end
    
    local function plantSeed(x, y)
        local id = idFromLabel(C.cfg.GBX_FarmerSeed)
        if not id or invCount(id) <= 0 then return false end
        sendSetTile("fg", x, y, id)
        if Refs.Inv then pcall(function() Refs.Inv:remove(id, 1) end) end
        Farmer.Planted += 1
        C.farmerStatus = "Planted " .. itemName(id) .. " (" .. x .. "," .. y .. ")"
        return true
    end
    
    local function farmerWorkInReach(s)
        local w = Refs.World
        local W = w.w
        local R = farmReach() - 0.08
        local cx, cy = s.x, s.y - 0.475
        local now = os.clock()
        local st = Workspace:GetServerTimeNow()
        local doPlant = C.cfg.GBX_FarmerPlant == true and seedCount() > 0
        local harvest, plant = {}, {}
        for ty = math.max(0, floor(cy - R - 0.5)), math.min(floor(cy + R + 0.5), w.h - 1) do
            for tx = math.max(0, floor(cx - R - 0.5)), math.min(floor(cx + R + 0.5), W - 1) do
                if stateReaches(s, tx, ty, R) then
                    local idx = ty * W + tx
                    if not skipped(FarmerSkip, idx, now) then
                        local id = fgIdAt(tx, ty)
                        if C.cfg.GBX_FarmerHarvest == true and id ~= 0 then
                            local ra = treeReadyAt(tx, ty, id)
                            if ra and st >= ra then
                                if canWorkAt(tx, ty) then
                                    harvest[#harvest + 1] = { x = tx, y = ty, idx = idx }
                                else
                                    skipTile(FarmerSkip, idx, 120)
                                end
                            end
                        elseif doPlant and id == 0 and plantSpotOk(tx, ty) then
                            plant[#plant + 1] = { x = tx, y = ty, idx = idx }
                        end
                    end
                end
            end
        end
        local function byX(a, b)
            if a.x ~= b.x then return a.x < b.x end
            return a.y < b.y
        end
        table.sort(harvest, byX)
        table.sort(plant, byX)
        local done = 0
        for _, t in ipairs(harvest) do
            if not C.farmerRunning or not alive() then return done end
            local cur = playerState()
            if not cur or not stateReaches(cur, t.x, t.y, R) then return done end
            local id = fgIdAt(t.x, t.y)
            local r = tryBreak(t.x, t.y, false) -- a ripe tree: one punch = one harvest
            if r == "broke" then
                Farmer.Harvested += 1
                C.stats.harvested += 1
                C.farmerStatus = "Harvested " .. itemName(id) .. " (" .. t.x .. "," .. t.y .. ")"
            else
                skipTile(FarmerSkip, t.idx, 30)
            end
            done += 1
            if not waitAuto(tonumber(C.cfg.GBX_HarvestMs) or 250) then return done end
        end
        for _, t in ipairs(plant) do
            if not C.farmerRunning or not alive() then return done end
            if seedCount() <= 0 then break end
            local cur = playerState()
            if not cur or not stateReaches(cur, t.x, t.y, R) then return done end
            if fgIdAt(t.x, t.y) == 0 then
                if not plantSeed(t.x, t.y) then break end
                C.stats.planted += 1
                done += 1
                if not waitAuto(tonumber(C.cfg.GBX_PlantMs) or 250) then return done end
            end
        end
        return done
    end
    
    local function farmerScan(px, py, maxN, filter)
        local w = Refs.World
        local W, H = w.w, w.h
        local best = {}
        local now = os.clock()
        local st = Workspace:GetServerTimeNow()
        local doPlant = C.cfg.GBX_FarmerPlant == true and seedCount() > 0
        local scanned = 0
        for y = 0, H - 1 do
            local frow, below = w.fg[y], w.fg[y + 1]
            for x = 0, W - 1 do
                local id = frow and frow[x] or 0
                local kind = nil
                if id ~= 0 then
                    if C.cfg.GBX_FarmerHarvest == true then
                        local ra = treeReadyAt(x, y, id)
                        if ra then
                            if st >= ra then
                                kind = "harvest"
                            end
                        end
                    end
                elseif doPlant then
                    local b = below and below[x] or 0
                    if b ~= 0 then kind = "plant" end
                end
                if kind then
                    local idx = y * W + x
                    if not skipped(FarmerSkip, idx, now) then
                        if filter and not filter[idx] then
                            skipTile(FarmerSkip, idx, 60)
                        else
                            local dx, dy = x - px, (y - py) * 1.3
                            local d = dx * dx + dy * dy - ((kind == "harvest") and 4 or 0)
                            if #best < maxN or d < best[#best].d then
                                local ok
                                if kind == "harvest" then ok = canWorkAt(x, y) else ok = plantSpotOk(x, y) end
                                if ok then
                                    local pos = #best + 1
                                    while pos > 1 and best[pos - 1].d > d do pos -= 1 end
                                    table.insert(best, pos, { x = x, y = y, idx = idx, d = d, kind = kind })
                                    if #best > maxN then best[#best] = nil end
                                else
                                    skipTile(FarmerSkip, idx, 120)
                                end
                            end
                        end
                    end
                end
            end
            scanned += W
            if scanned >= 6000 then
                scanned = 0
                task.wait()
                if not C.farmerRunning or not alive() then break end
            end
        end
        -- Seconds until the next tree ripens (status line only).
        local nextReady = nil
        if C.cfg.GBX_FarmerHarvest == true and Refs.Trees then
            for y = 0, H - 1 do
                local frow = w.fg[y]
                for x = 0, W - 1 do
                    local id = frow and frow[x] or 0
                    if id ~= 0 then
                        local ra = treeReadyAt(x, y, id)
                        if ra and ra > st and (not nextReady or ra - st < nextReady) then
                            nextReady = ra - st
                        end
                    end
                end
            end
        end
        return best, nextReady
    end
    
    local lastFarmerText = nil
    local function updateFarmerStatus()
        if not C.farmerLabel then return end
        local seed = idFromLabel(C.cfg.GBX_FarmerSeed)
        local txt = "Status  : " .. (C.farmerRunning and "RUNNING" or "STOPPED")
            .. "\nHarvest : " .. Farmer.Harvested .. "  | planted: " .. Farmer.Planted .. "  | collected: " .. C.stats.collected
            .. "\nSeed    : " .. (seed and (itemName(seed) .. " x" .. invCount(seed)) or "-")
            .. "\nTrees   : " .. (Refs.Trees and "read" or "NOT read (harvest off)")
            .. "\nScaffold: " .. blockText()
            .. "\nAction  : " .. C.farmerStatus
        if txt == lastFarmerText then return end
        lastFarmerText = txt
        task.defer(function()
            pcall(function() C.farmerLabel:SetText(txt) end)
        end)
    end
    
    local function farmerLoop()
        local lastUi = 0
        while C.farmerRunning and alive() do
            task.wait()
            if os.clock() - lastUi > 0.5 then
                lastUi = os.clock()
                updateFarmerStatus()
            end
            local w = Refs.World
            local s = playerState()
            if not w or not s or s.dead then
                releaseInput()
                C.farmerStatus = "Waiting for character / world..."
                task.wait(0.5)
                continue
            end
            if not s.grounded then
                releaseInput()
                continue
            end
            releaseInput()
            if farmerWorkInReach(s) > 0 then continue end
            local R = farmReach() - 0.35
            local useBlock = scaffoldId() ~= nil
            local sx, sy = startNode(s)
            local px, py = floor(s.x), floor(s.y - 0.475)
            local targets, nextReady = farmerScan(px, py, 8, reachFilter(sy * w.w + sx, R, useBlock))
            if not C.farmerRunning or not alive() then break end
            if #targets == 0 then
                local parts = {}
                if C.cfg.GBX_FarmerHarvest == true then
                    parts[#parts + 1] = nextReady and ("next tree ready in ±" .. math.ceil(nextReady) .. "s") or "no trees"
                end
                if C.cfg.GBX_FarmerPlant == true then
                    parts[#parts + 1] = (seedCount() <= 0) and "seeds out / not picked" or "no place to plant"
                end
                C.farmerStatus = "Waiting: " .. table.concat(parts, ", ")
                if not waitAuto(1000) then break end
                continue
            end
            travelGroup(sx, sy, targets, R, useBlock, FarmerSkip, FarmerFail)
        end
        releaseInput()
    end
    
    stopFarmer = function(reason)
        C.farmerRunning = false
        autoEnd()
        C.farmerStatus = reason or "Stopped"
        if reason and C.notifyFn then C.notifyFn("Farmer: " .. reason) end
        updateFarmerStatus()
    end
    
    local function startFarmer()
        if C.farmerRunning then return end
        local err = checkAutoStart()
        if not err and C.cfg.GBX_FarmerHarvest ~= true and C.cfg.GBX_FarmerPlant ~= true then
            err = "Turn on Auto Harvest or Auto Plant"
        end
        if not err and C.cfg.GBX_FarmerPlant == true and not idFromLabel(C.cfg.GBX_FarmerSeed) then
            err = "Pick a seed first for Auto Plant"
        end
        if err then
            if C.notifyFn then C.notifyFn("Farmer: " .. err) end
            return
        end
        if C.cfg.GBX_FarmerHarvest == true and not Refs.Trees and not findTreeRefs() then
            if C.notifyFn then C.notifyFn("Farmer: tree data not found — Auto Harvest cannot check ripeness") end
        end
        if C.farmRunning and C.stopFarm then C.stopFarm("Stopped: Farmer started") end
        if C.clearRunning then stopClear("Stopped: Farmer started") end
        if C.dirtRunning then stopDirtFarm("Stopped: Farmer started") end
        table.clear(FarmerSkip)
        table.clear(FarmerFail)
        table.clear(BadEdge)
        C.farmerStatus = "Starting..."
        C.farmerRunning = true
        autoBegin()
        updateFarmerStatus()
        task.spawn(function()
            local ok, e = pcall(farmerLoop)
            if not ok then
                warn("[BerakHUB] Farmer error: " .. tostring(e))
                if C.farmerRunning then stopFarmer("Error: " .. tostring(e)) end
            end
        end)
    end
    
    -- Walk to one tile (used by Guard to walk back to the farm spot).
    -- Same A*, no scaffold blocks.
    local function walkTo(tx, ty, maxSec)
        local w = Refs.World
        if not w or not OrigIsDown then return false end
        if tx < 0 or ty < 0 or tx >= w.w or ty >= w.h then return false end
        Move.Homing = true
        autoBegin()
        local goal = { [ty * w.w + tx] = true }
        local t0, ok = os.clock(), false
        while alive() and Move.Homing and os.clock() - t0 < (maxSec or 30) do
            local s = playerState()
            if not s or s.dead then
                task.wait(0.3)
            else
                local sx, sy = startNode(s)
                if sx == tx and sy == ty and s.grounded then
                    ok = true
                    break
                end
                local path = astar(sx, sy, goal, tx, ty, 0.5, false)
                if not path then break end
                if #path > 0 then followPath(path) end
                releaseInput()
                task.wait(0.15)
            end
        end
        Move.Homing = false
        autoEnd()
        return ok
    end
    
    C.startFarmer = startFarmer
    C.walkTo = walkTo
    C.stopWalk = function() Move.Homing = false end
    C.here = function()
        local s = playerState()
        if s then return startNode(s) end
        return nil
    end
    C.updateClearStatus = updateClearStatus
    C.updateFarmerStatus = updateFarmerStatus
    C.findTreeRefs = findTreeRefs
    C.releaseInput = releaseInput
    C.resetReach = function() Reach = nil end
    C.resetFarmerSkip = function() table.clear(FarmerSkip) end
    
    -- ---------- Auto Dirt Farm: Clear World, but dirt only ----------
    -- Breaks the natural dirt already in the world, row by row from the
    -- top down, and collects the Dirt Seeds and Dirt Blocks that drop.
    -- Nothing is placed and nothing is taken from the inventory: the
    -- dirt comes from the world, not from you. The character walks on
    -- the ground only, using Clear World's walker -- no position is ever
    -- written. Dirt is block id 2.
    local DIRT_ID = 2
    local Dirt = { TopRow = -1, Broken = 0, Remaining = -1 }
    local DirtSkip, DirtFail, DirtBreakTimes = {}, {}, {}
    local dirtOldCollect = nil
    
    local function updateDirtStatus()
        if not C.dirtLabel then return end
        local txt = "Status   : " .. (C.dirtRunning and "RUNNING" or "STOPPED")
            .. "\nRow      : " .. (Dirt.TopRow >= 0 and (Dirt.TopRow .. "-" .. (Dirt.TopRow + 1)) or "-")
            .. "\nBroke    : " .. Dirt.Broken .. "  | collected: " .. C.stats.collected
            .. "\nLeft     : " .. (Dirt.Remaining >= 0 and tostring(Dirt.Remaining) or "-")
            .. "  | skipped: " .. skippedCount(DirtSkip)
            .. "\nAction   : " .. C.dirtStatus
        task.defer(function()
            pcall(function() C.dirtLabel:SetText(txt) end)
        end)
    end
    
    stopDirtFarm = function(reason)
        C.dirtRunning = false
        if C.stopWalk then C.stopWalk() end
        if C.releaseInput then C.releaseInput() end
        autoEnd()
        if dirtOldCollect ~= nil then
            C.cfg.GBX_AutoCollect = dirtOldCollect
            dirtOldCollect = nil
            if C.autoCollectOpt then pcall(function() C.autoCollectOpt:SetValue(C.cfg.GBX_AutoCollect == true) end) end
        end
        C.cfg.GBX_AutoDirtFarm = false
        saveCfg()
        if C.dirtToggle then pcall(function() C.dirtToggle:SetValue(false) end) end
        if reason then
            C.dirtStatus = reason
            if C.notifyFn then C.notifyFn("Auto Dirt Farm stopped: " .. reason) end
        end
        updateDirtStatus()
    end
    C.stopDirtFarm = stopDirtFarm
    
    local function validateDirt()
        if not Refs.World then return "Game data not found. Press 'Connect to game'" end
        if not Refs.Punch then return "Game punch function not found. Press 'Connect to game'" end
        if not OrigIsDown then return "Game movement keys (WorldMenu.isDown) not found" end
        if not getPlayerTile() then return "You are not in a world yet" end
        return nil
    end
    
    -- Dirt-only target test: foreground dirt (id 2) that can be broken.
    -- Anything else -- other blocks, empty cells, the spawn tile -- is
    -- left untouched. Mirrors clearLayerAt.
    local function dirtLayerAt(x, y)
        local w = Refs.World
        local sp = w and w.spawn
        if sp ~= nil and (typeof(sp) == "Vector2" or type(sp) == "table") and x == sp.X and y == sp.Y then
            return nil
        end
        local fg = tileAt("fg", x, y)
        if fg == nil then return nil end
        if fg == DIRT_ID and clearCanBreak(fg) then return "fg", fg end
        return nil
    end
    
    local function scanDirtTopRow()
        local w = Refs.World
        local W, H = w.w, w.h
        local now = os.clock()
        for y = 0, H - 1 do
            local frow = w.fg[y]
            for x = 0, W - 1 do
                local fid = frow and frow[x] or 0
                if fid == DIRT_ID and dirtLayerAt(x, y) and not skipped(DirtSkip, y * W + x, now) then
                    return y
                end
            end
        end
        return nil
    end
    
    local function countDirtRemaining()
        local w = Refs.World
        if not w then return -1 end
        local W, H = w.w, w.h
        local n, scanned = 0, 0
        for y = 0, H - 1 do
            local frow = w.fg[y]
            for x = 0, W - 1 do
                local fid = frow and frow[x] or 0
                if fid == DIRT_ID and dirtLayerAt(x, y) then n += 1 end
            end
            scanned += W
            if scanned >= 8000 then
                scanned = 0
                task.wait()
            end
        end
        return n
    end
    
    local function dirtBandTargets(top, bottom, dir, filter)
        local w = Refs.World
        local W = w.w
        local list = {}
        local now = os.clock()
        for y = top, math.min(bottom, w.h - 1) do
            for x = 0, W - 1 do
                local idx = y * W + x
                if dirtLayerAt(x, y) and not skipped(DirtSkip, idx, now) then
                    if filter and not filter[idx] then
                        skipTile(DirtSkip, idx, 60)
                    elseif canWorkAt(x, y) then
                        list[#list + 1] = { x = x, y = y, idx = idx }
                    else
                        skipTile(DirtSkip, idx, 300)
                    end
                end
            end
        end
        table.sort(list, function(a, b)
            if a.x ~= b.x then return a.x * dir < b.x * dir end
            return a.y < b.y
        end)
        return list
    end
    
    local function dirtInReach(s, bottom, dir)
        local w = Refs.World
        local W = w.w
        local R = punchReach() - 0.08
        local cx, cy = s.x, s.y - 0.475
        local footRow = floor(s.y + 0.01)
        local colA, colB = floor(s.x - 0.3), floor(s.x + 0.3 - 0.0001)
        local now = os.clock()
        local list = {}
        for ty = math.max(0, floor(cy - R - 0.5)), math.min(floor(cy + R + 0.5), bottom, w.h - 1) do
            for tx = math.max(0, floor(cx - R - 0.5)), math.min(floor(cx + R + 0.5), W - 1) do
                if stateReaches(s, tx, ty, R) then
                    local idx = ty * W + tx
                    if not skipped(DirtSkip, idx, now) and dirtLayerAt(tx, ty) then
                        if canWorkAt(tx, ty) then
                            list[#list + 1] = {
                                x = tx, y = ty, idx = idx,
                                support = (ty == footRow and tx >= colA and tx <= colB),
                            }
                        else
                            skipTile(DirtSkip, idx, 300)
                        end
                    end
                end
            end
        end
        table.sort(list, function(a, b)
            if a.support ~= b.support then return not a.support end
            if a.x ~= b.x then return a.x * dir < b.x * dir end
            return a.y < b.y
        end)
        return list
    end
    
    local function dirtBreakTile(t)
        local x, y, idx = t.x, t.y, t.idx
        local layer, id = dirtLayerAt(x, y)
        if not layer then return end
        local hits, maxHits = 0, hitsNeeded(id) * 3 + 6
        while C.dirtRunning and alive() do
            layer, id = dirtLayerAt(x, y)
            if not layer then return end
            local r = tryBreak(x, y, false)
            if r == nil then
                skipTile(DirtSkip, idx, 60)
                return
            end
            if r == "broke" then
                Dirt.Broken += 1
                C.dirtStatus = "Broke Dirt (" .. x .. "," .. y .. ")"
                DirtBreakTimes[idx] = (DirtBreakTimes[idx] or 0) + 1
                if DirtBreakTimes[idx] > 6 then -- the server keeps putting this tile back
                    skipTile(DirtSkip, idx, 120)
                    return
                end
                hits = 0
                local _, nid = dirtLayerAt(x, y)
                if nid then maxHits = hitsNeeded(nid) * 3 + 6 end
            else
                hits += 1
                C.dirtStatus = "Hitting Dirt (" .. x .. "," .. y .. ")"
                if hits > maxHits then
                    skipTile(DirtSkip, idx, 45)
                    return
                end
            end
            if not waitAuto(tonumber(C.cfg.GBX_BreakMs) or 220) then return end
            if r == "broke" then
                local s = playerState()
                if not s or not s.grounded then return end
            end
        end
    end
    
    local function dirtBreakList(list, s0)
        local footY = floor(s0.y - 0.475)
        local R = punchReach() - 0.08
        local done = 0
        for _, t in ipairs(list) do
            if not C.dirtRunning or not alive() then break end
            local s = playerState()
            if not s or s.dead or not stateReaches(s, t.x, t.y, R) then break end
            if not s.grounded or floor(s.y - 0.475) ~= footY then break end
            local skipIt = false
            if t.support then
                local d = fallAfterBreak(s, t.x, floor(s.y + 0.01))
                if d == nil then
                    skipIt = true
                    C.dirtStatus = ("Skipping (%d,%d): dangerous below"):format(t.x, t.y)
                elseif d > 3 then
                    skipIt = true
                    C.dirtStatus = ("Skipping footing (%d,%d): drop below"):format(t.x, t.y)
                end
            end
            if skipIt then
                skipTile(DirtSkip, t.idx, 20)
            else
                dirtBreakTile(t)
                done += 1
            end
        end
        return done
    end
    
    local function dirtLoop()
        local idle, lastUi, lastCount = 0, 0, -10
        while C.dirtRunning and alive() do
            task.wait()
            local now = os.clock()
            if now - lastCount > 3 then
                lastCount = now
                Dirt.Remaining = countDirtRemaining()
                if not C.dirtRunning or not alive() then break end
            end
            if now - lastUi > 0.5 then
                lastUi = now
                updateDirtStatus()
            end
            local w = Refs.World
            local s = playerState()
            if not w or not s or s.dead then
                releaseInput()
                C.dirtStatus = "Waiting for character / world..."
                task.wait(0.5)
                continue
            end
            if not s.grounded then
                releaseInput()
                continue
            end
            releaseInput()
            local topRow = scanDirtTopRow()
            if not topRow then
                local remaining = countDirtRemaining()
                Dirt.Remaining = remaining
                if remaining == 0 then
                    stopDirtFarm("No more dirt in this world")
                    return
                end
                idle += 1
                if idle >= 3 then
                    stopDirtFarm(("Done. %d dirt tiles left that cannot be reached / broken"):format(remaining))
                    return
                end
                C.dirtStatus = ("%d skipped dirt tiles left, retrying (%d/3)..."):format(remaining, idle)
                updateDirtStatus()
                table.clear(DirtSkip)
                table.clear(DirtFail)
                table.clear(BadEdge)
                Reach = nil
                if not waitAuto(2000) then break end
                continue
            end
            Dirt.TopRow = topRow
            local bottom = topRow + 1
            local dir = 1
            local list = dirtInReach(s, bottom, dir)
            if #list > 0 then
                if dirtBreakList(list, s) > 0 then idle = 0 end
                continue
            end
            local R = punchReach() - 0.35
            local useBlock = scaffoldId() ~= nil
            local sx, sy = startNode(s)
            local band = dirtBandTargets(topRow, bottom, dir, reachFilter(sy * w.w + sx, R, useBlock))
            if #band > 0 then
                local group = {}
                for _, t in ipairs(band) do
                    if (t.x - band[1].x) * dir <= 4 then group[#group + 1] = t end
                end
                travelGroup(sx, sy, group, R, useBlock, DirtSkip, DirtFail)
            end
        end
        releaseInput()
    end
    
    startDirtFarm = function()
        if C.dirtRunning then return end
        local err = validateDirt()
        if err then
            stopDirtFarm(err)
            return
        end
        if C.farmRunning and C.stopFarm then C.stopFarm("Stopped: Auto Dirt Farm started") end
        if C.clearRunning then stopClear("Stopped: Auto Dirt Farm started") end
        if C.farmerRunning then stopFarmer("Stopped: Auto Dirt Farm started") end
        -- Auto Collect is forced on while dirt farming so the Dirt Seeds
        -- and Dirt Blocks from every broken tile are picked up; restored
        -- on stop.
        dirtOldCollect = C.cfg.GBX_AutoCollect
        C.cfg.GBX_AutoCollect = true
        if C.autoCollectOpt then pcall(function() C.autoCollectOpt:SetValue(true) end) end
        table.clear(DirtSkip)
        table.clear(DirtFail)
        table.clear(DirtBreakTimes)
        table.clear(BadEdge)
        Dirt.Broken = 0
        Dirt.Remaining = -1
        Dirt.TopRow = -1
        C.dirtStatus = "Starting..."
        C.dirtRunning = true
        autoBegin()
        updateDirtStatus()
        task.spawn(function()
            local ok, e = pcall(dirtLoop)
            if not ok then
                warn("[BerakHUB] Auto Dirt Farm error: " .. tostring(e))
                if C.dirtRunning then stopDirtFarm("Error: " .. tostring(e)) end
            end
        end)
    end
    C.startDirtFarm = startDirtFarm
    end)() end
    
    -- ---------- Auto Farm: place the selected tiles, then break them ----------
    local function waitMs(ms)
        task.wait(math.max(ms or 0, 10) / 1000)
        return C.farmRunning and alive()
    end
    
    local function validateFarm()
        local doPlace = C.cfg.GBX_FarmMode ~= "Break only"
        if not Refs.World then return "Game data not found. Press 'Connect to game'" end
        if next(C.cfg.GBX_FarmOffsets) == nil then return "Pick tiles first in the Farm Grid" end
        if not getPlayerTile() then return "You are not in a world yet" end
        if doPlace and not farmBlockId() then return "Pick a block from your inventory" end
        return nil
    end
    
    local function raymanOn()
        local w = Refs.World
        local f = w and rawget(w, "raymanOn")
        if type(f) ~= "function" then return false end
        local ok, on = pcall(f)
        return ok and on == true
    end
    
    local RAY_DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }
    local function raymanLine(px, py, active)
        local byKey = {}
        for _, a in ipairs(active) do byKey[a.x .. "," .. a.y] = a end
        local best, bestDir = nil, nil
        for _, d in ipairs(RAY_DIRS) do
            local line = {}
            for i = 1, 3 do
                local a = byKey[(px + d[1] * i) .. "," .. (py + d[2] * i)]
                if a then line[#line + 1] = a end
            end
            if #line >= 2 and #line > (best and #best or 0) then best, bestDir = line, d end
        end
        return best, bestDir
    end
    
    local function raymanAct(dir)
        local ok, s = pcall(Refs.State)
        if not ok or type(s) ~= "table" or not s.x then return end
        if Net ~= nil and Net.act then
            pcall(Net.act.send, { kind = 4, x = s.x + dir[1], y = s.y - 0.475 + dir[2] })
        end
    end
    
    local function updateFarmStatus()
        if not C.farmLabel then return end
        local sel = farmBlockId()
        local txt = "Status   : " .. (C.farmRunning and "RUNNING" or "STOPPED")
            .. "\nBlock    : " .. (sel and (itemName(sel) .. " x" .. invCount(sel)) or "-")
            .. "\nTiles    : " .. offsetsText()
            .. "\nPlace/Break/Collect : " .. C.stats.placed .. " / " .. C.stats.broken .. " / " .. C.stats.collected
            .. (C.stats.collectFail > 0 and (" (refused " .. C.stats.collectFail .. ")") or "")
            .. "\nCycles   : " .. C.farmCycles
            .. "\nAction   : " .. C.farmStatus
        task.defer(function()
            pcall(function() C.farmLabel:SetText(txt) end)
        end)
    end
    
    local stopFarm
    local function farmLoop(runId)
        local lastStatus = 0
        while C.farmRunning and alive() and C.farmRunId == runId do
            local doPlace = C.cfg.GBX_FarmMode ~= "Break only"
            local doBreak = C.cfg.GBX_FarmMode ~= "Place only"
            local px, py = getPlayerTile()
            if not px then
                stopFarm("Character not found (left the world?)")
                return
            end
            local now = os.clock()
            local tiles = {}
            for _, o in ipairs(sortedOffsets()) do
                local key = (px + o.dx) .. "," .. (py + o.dy)
                local skipUntil = FarmSkip[key]
                if not (skipUntil and now < skipUntil) then
                    tiles[#tiles + 1] = { x = px + o.dx, y = py + o.dy, key = key }
                end
            end
            local acted, outOfBlock = false, false
            if doPlace then
                for _, t in ipairs(tiles) do
                    if not C.farmRunning then break end
                    if C.cfg.GBX_CollectAfterPlace == true then waitTileDrops(t, 0.5) end
                    local r = tryPlace(t.x, t.y)
                    if r == "out" then
                        outOfBlock = true
                        break
                    elseif r == "place" then
                        acted = true
                        C.farmStatus = "Placed " .. itemName(farmBlockId()) .. " (" .. t.x .. "," .. t.y .. ")"
                        if not waitMs(tonumber(C.cfg.GBX_PlaceMs) or 250) then break end
                    end
                end
            end
            if doBreak then
                local K = math.clamp(math.floor(tonumber(C.cfg.GBX_MultiTarget) or 1), 1, 5)
                local nextI, active = 1, {}
                while C.farmRunning and alive() do
                    while #active < K and nextI <= #tiles do
                        local t = tiles[nextI]
                        nextI += 1
                        active[#active + 1] = { x = t.x, y = t.y, key = t.key, n = 0 }
                    end
                    if #active == 0 then break end
                    local hits, rayDir = nil, nil
                    if K > 1 and raymanOn() then
                        hits, rayDir = raymanLine(px, py, active)
                    end
                    if not rayDir then hits = { active[1] } end
                    local t0 = os.clock()
                    if rayDir then raymanAct(rayDir) end
                    local hit, broke = false, false
                    for i, a in ipairs(hits) do
                        if not C.farmRunning then break end
                        if i > 1 then task.wait(0.05) end
                        local r = tryBreak(a.x, a.y)
                        a.n += 1
                        if r then hit, acted = true, true end
                        if r == "broke" then
                            broke = true
                            FarmReject[a.key] = nil
                            C.farmStatus = "Broke tile (" .. a.x .. "," .. a.y .. ")"
                        end
                        if r == nil or a.n > 80 or (r == "broke" and not breakableAt(a.x, a.y)) then
                            if r ~= nil and a.n > 80 then
                                -- Full 80-hit pass without a break: the
                                -- server is not accepting hits here.
                                FarmReject[a.key] = (FarmReject[a.key] or 0) + 1
                                if FarmReject[a.key] > 1 then
                                    FarmSkip[a.key] = os.clock() + 120
                                end
                            end
                            a.done = true
                        end
                        a.used = true
                    end
                    local nextActive = {}
                    for _, a in ipairs(active) do
                        if not a.done and not a.used then nextActive[#nextActive + 1] = a end
                    end
                    for _, a in ipairs(hits) do
                        a.used = nil
                        if not a.done then nextActive[#nextActive + 1] = a end
                    end
                    active = nextActive
                    if hit then
                        local gap = (tonumber(C.cfg.GBX_BreakMs) or 220) / 1000
                        if rayDir then gap = math.max(gap, 0.35) end
                        local rest = gap - (os.clock() - t0)
                        if rest > 0.005 then task.wait(rest) end
                        if not (C.farmRunning and alive()) then break end
                    end
                    if broke and (tonumber(C.cfg.GBX_AfterBreakMs) or 300) > 0 then
                        task.wait((tonumber(C.cfg.GBX_AfterBreakMs) or 300) / 1000)
                    end
                end
            end
            if not C.farmRunning or not alive() then break end
            if not acted then
                if outOfBlock or (doPlace and farmBlockId() and invCount(farmBlockId()) <= 0) then
                    stopFarm("Block " .. itemName(farmBlockId()) .. " ran out in inventory")
                    return
                end
                if not waitMs(tonumber(C.cfg.GBX_BreakMs) or 220) then break end
            end
            C.farmCycles += 1
            if os.clock() - lastStatus > 1 then
                lastStatus = os.clock()
                updateFarmStatus()
            end
        end
        updateFarmStatus()
    end
    
    stopFarm = function(reason)
        C.farmRunning = false
        if C.farmToggle then pcall(function() C.farmToggle:SetValue(false) end) end
        if C.gridStart then
            pcall(function()
                C.gridStart.Text = "START"
                C.gridStart.BackgroundColor3 = Color3.fromRGB(46, 160, 90)
            end)
        end
        if reason then
            C.farmStatus = reason
            if C.notifyFn then C.notifyFn("Auto Farm stopped: " .. reason) end
        end
        updateFarmStatus()
    end
    C.stopFarm = stopFarm
    
    local function startFarm()
        if C.farmRunning then return end
        local err = validateFarm()
        if err then
            stopFarm(err)
            return
        end
        if C.clearRunning then stopClear("Stopped: Auto Farm started") end
        if C.farmerRunning then stopFarmer("Stopped: Auto Farm started") end
        if C.dirtRunning then stopDirtFarm("Stopped: Auto Farm started") end
        table.clear(HitCount)
        table.clear(PlacedAt)
        C.farmRunning = true
        C.farmRunId = (C.farmRunId or 0) + 1
        if C.farmToggle then pcall(function() C.farmToggle:SetValue(true) end) end
        if C.gridStart then
            pcall(function()
                C.gridStart.Text = "STOP"
                C.gridStart.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
            end)
        end
        C.farmStatus = "Starting..."
        updateFarmStatus()
        task.spawn(farmLoop, C.farmRunId)
    end
    C.startFarm = startFarm
    
    -- ---------- Farm Grid: 5x5 tile picker (centre = your character) ----------
    local gridGui = nil
    local function paintGridCell(key, btn)
        if btn then
            btn.BackgroundColor3 = C.cfg.GBX_FarmOffsets[key] and Color3.fromRGB(46, 160, 90) or Color3.fromRGB(48, 48, 60)
        end
    end
    local function openGrid()
        if gridGui == nil then
            local parent = (gethui and gethui()) or game:GetService("CoreGui")
            local sg = Instance.new("ScreenGui")
            sg.Name = "BerakHUBGrowbloxGrid"
            sg.ResetOnSpawn = false
            sg.IgnoreGuiInset = true
            sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            sg.DisplayOrder = 999
            sg.Enabled = false
            sg.Parent = parent
            gridGui = sg
            local side, cell, gap = 5, 38, 4
            local gridSize = side * cell + (side - 1) * gap
            local panel = Instance.new("Frame")
            panel.Size = UDim2.fromOffset(gridSize + 20, gridSize + 96)
            panel.Position = UDim2.fromOffset(20, 80)
            panel.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
            panel.BorderSizePixel = 0
            panel.Parent = sg
            Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
            local stroke = Instance.new("UIStroke", panel)
            stroke.Color = Color3.fromRGB(70, 70, 90)
            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, -40, 0, 28)
            title.Position = UDim2.fromOffset(10, 4)
            title.BackgroundTransparency = 1
            title.Font = Enum.Font.GothamBold
            title.TextSize = 13
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.TextColor3 = Color3.fromRGB(235, 235, 245)
            title.Text = "Farm Tiles"
            title.Parent = panel
            local closeBtn = Instance.new("TextButton")
            closeBtn.Size = UDim2.fromOffset(24, 24)
            closeBtn.Position = UDim2.new(1, -30, 0, 6)
            closeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
            closeBtn.Text = "X"
            closeBtn.Font = Enum.Font.GothamBold
            closeBtn.TextSize = 12
            closeBtn.TextColor3 = Color3.new(1, 1, 1)
            closeBtn.Parent = panel
            Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
            closeBtn.MouseButton1Click:Connect(function() sg.Enabled = false end)
            local holder = Instance.new("Frame")
            holder.Size = UDim2.fromOffset(gridSize, gridSize)
            holder.Position = UDim2.fromOffset(10, 36)
            holder.BackgroundTransparency = 1
            holder.Parent = panel
            for row = 0, side - 1 do
                for col = 0, side - 1 do
                    local dx, dy = col - 2, row - 2
                    local key = dx .. "," .. dy
                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.fromOffset(cell, cell)
                    btn.Position = UDim2.fromOffset(col * (cell + gap), row * (cell + gap))
                    btn.Font = Enum.Font.GothamBold
                    btn.TextSize = 12
                    btn.TextColor3 = Color3.new(1, 1, 1)
                    btn.Parent = holder
                    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
                    if dx == 0 and dy == 0 then
                        btn.Text = "ME"
                        btn.BackgroundColor3 = Color3.fromRGB(60, 110, 220)
                        btn.AutoButtonColor = false
                    else
                        btn.Text = ""
                        paintGridCell(key, btn)
                        btn.MouseButton1Click:Connect(function()
                            if C.cfg.GBX_FarmOffsets[key] then
                                C.cfg.GBX_FarmOffsets[key] = nil
                            else
                                C.cfg.GBX_FarmOffsets[key] = true
                            end
                            saveCfg()
                            paintGridCell(key, btn)
                            updateFarmStatus()
                        end)
                    end
                end
            end
            local startBtn = Instance.new("TextButton")
            startBtn.Size = UDim2.new(1, -20, 0, 30)
            startBtn.Position = UDim2.new(0, 10, 1, -54)
            startBtn.BackgroundColor3 = Color3.fromRGB(46, 160, 90)
            startBtn.Font = Enum.Font.GothamBold
            startBtn.TextSize = 14
            startBtn.TextColor3 = Color3.new(1, 1, 1)
            startBtn.Text = "START"
            startBtn.Parent = panel
            Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 8)
            C.gridStart = startBtn
            startBtn.MouseButton1Click:Connect(function()
                if C.farmRunning then stopFarm() else startFarm() end
            end)
            local clearBtn = Instance.new("TextButton")
            clearBtn.Size = UDim2.new(1, -20, 0, 22)
            clearBtn.Position = UDim2.new(0, 10, 1, -22)
            clearBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
            clearBtn.Font = Enum.Font.GothamBold
            clearBtn.TextSize = 11
            clearBtn.TextColor3 = Color3.new(1, 1, 1)
            clearBtn.Text = "Clear selection"
            clearBtn.Parent = panel
            Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 6)
            clearBtn.MouseButton1Click:Connect(function()
                table.clear(C.cfg.GBX_FarmOffsets)
                saveCfg()
                for _, child in ipairs(holder:GetChildren()) do
                    if child:IsA("TextButton") and child.Text ~= "ME" then
                        pcall(function() child.BackgroundColor3 = Color3.fromRGB(48, 48, 60) end)
                    end
                end
                updateFarmStatus()
            end)
        end
        gridGui.Enabled = true
    end
    C.openGrid = openGrid
    
    -- ---------- Bonus: auto claim quests and auto redeem codes ----------
    -- Uses the same calls the game's own Quest and Redeem menus use.
    -- The code list always comes from the server (ActiveCodes); codes
    -- are never invented locally. Note: the redeem channel is named
    -- "ModCommand" by the game itself — it only redeems public codes
    -- the server lists. Verify live before relying on it.
    do (function()
    local Bonus = {
        QuestEvery = 30, CodeEvery = 300,
        NextQuest = 0, NextCode = 0,
        Claimed = 0, Redeemed = 0,
        Tried = {}, QuestFail = {},
        QuestText = "-", CodeText = "-",
        ResetAt = nil,
    }
    local function strip(s) return (tostring(s or ""):gsub("`.", "")) end
    local function netCall(...)
        if Net ~= nil and type(Net.call) == "function" then
            return pcall(Net.call, ...)
        end
        return false, "Net.call missing"
    end
    local function timeText(sec)
        sec = math.max(0, math.floor(sec or 0))
        if sec >= 3600 then return ("%dh %dm"):format(sec // 3600, sec % 3600 // 60) end
        return ("%dm %ds"):format(sec // 60, sec % 60)
    end
    local function setGems(n)
        local g = Refs.Gems
        if type(n) == "number" and g and type(rawget(g, "setGems")) == "function" then
            pcall(g.setGems, n)
        end
    end
    local function checkQuests()
        if Bonus.BusyQ then return end
        Bonus.BusyQ = true
        local ok, good, data = netCall("Quests", "list")
        if not ok then
            Bonus.QuestText = "Could not load quests: " .. strip(good)
        elseif not good or type(data) ~= "table" or type(data.quests) ~= "table" then
            Bonus.QuestText = "Quests not available yet" .. (type(data) == "string" and (": " .. strip(data)) or "")
        else
            local total, done, wait = 0, 0, 0
            local now = os.clock()
            for _, q in ipairs(data.quests) do
                total += 1
                local have, need = tonumber(q.have) or 0, tonumber(q.need) or math.huge
                if q.claimed then
                    done += 1
                elseif have >= need and not ((Bonus.QuestFail[q.id] or 0) > now) then
                    local okc, success, msg, _, gems = netCall("Quests", "claim", q.id)
                    if okc and success then
                        done += 1
                        Bonus.Claimed += 1
                        C.stats.claimed += 1
                        local reward = q.xp and (tostring(q.reward) .. " XP") or (tostring(q.reward) .. " gems")
                        if C.notifyFn then C.notifyFn("Quest claimed: " .. strip(q.text or q.id) .. "  +" .. reward) end
                        setGems(gems)
                    else
                        wait += 1
                        Bonus.QuestFail[q.id] = now + 120
                        if okc and msg then Bonus.LastQuestMsg = strip(msg) end
                    end
                    task.wait(0.6)
                elseif have >= need then
                    wait += 1
                end
            end
            Bonus.ResetAt = os.clock() + (tonumber(data.resetIn) or 0)
            Bonus.QuestText = ("Done %d/%d | claimed by script: %d"):format(done, total, Bonus.Claimed)
                .. ((wait > 0) and (" | refused: " .. wait) or "")
        end
        Bonus.BusyQ = false
    end
    local function redeem(code)
        local ok, res = netCall("ModCommand", "redeemcode", code)
        if not ok then return nil, "could not reach server" end
        local lines = type(res) == "table" and type(res.lines) == "table" and res.lines or nil
        if not lines then return false, "empty reply" end
        local first = tostring(lines[1] or "")
        local parts = {}
        for _, l in ipairs(lines) do parts[#parts + 1] = strip(l) end
        return string.sub(first, 1, 2) == "`2", table.concat(parts, " ")
    end
    local function checkCodes()
        if Bonus.BusyR then return end
        Bonus.BusyR = true
        local ok, list = netCall("ActiveCodes")
        if not ok or type(list) ~= "table" then
            Bonus.CodeText = "Could not load the code list"
        elseif list.note ~= nil then
            Bonus.CodeText = "Redeem is closed: " .. strip(list.note)
        else
            local total, have, newOk = 0, 0, 0
            for _, c in ipairs(list) do
                total += 1
                local code = c.code and tostring(c.code)
                if c.done then
                    have += 1
                elseif code and not Bonus.Tried[code] and not (type(c.uses) == "number" and c.uses == 0) then
                    local success, msg = redeem(code)
                    if success ~= nil then Bonus.Tried[code] = true end
                    if success then
                        have += 1
                        newOk += 1
                        Bonus.Redeemed += 1
                        C.stats.redeemed += 1
                        if C.notifyFn then C.notifyFn("Code redeemed: " .. code .. ": " .. tostring(msg)) end
                    elseif success == false then
                        Bonus.LastCodeMsg = code .. ": " .. tostring(msg)
                    end
                    task.wait(1)
                end
            end
            Bonus.CodeText = ("Active codes: %d | already used: %d | redeemed by script: %d"):format(total, have, Bonus.Redeemed)
        end
        Bonus.BusyR = false
    end
    local function updateBonusStatus()
        local now = os.clock()
        local q = Bonus.QuestText
        if Bonus.ResetAt then q = q .. "\nNew quests in " .. timeText(Bonus.ResetAt - now) end
        if Bonus.LastQuestMsg then q = q .. "\nLast message: " .. Bonus.LastQuestMsg end
        q = q .. "\n" .. ((C.cfg.GBX_AutoQuest == true) and ("Checking again in " .. math.max(0, math.ceil(Bonus.NextQuest - now)) .. "s") or "Auto claim off")
        local c = Bonus.CodeText
        if Bonus.LastCodeMsg then c = c .. "\nLast message: " .. Bonus.LastCodeMsg end
        c = c .. "\n" .. ((C.cfg.GBX_AutoRedeem == true) and ("Checking again in " .. timeText(Bonus.NextCode - now)) or "Auto redeem off")
        if C.questLabel then pcall(function() C.questLabel:SetText(q) end) end
        if C.codeLabel then pcall(function() C.codeLabel:SetText(c) end) end
    end
    C.bonusCheckQuests = function()
        Bonus.NextQuest = 0
        task.spawn(checkQuests)
    end
    C.bonusCheckCodes = function()
        table.clear(Bonus.Tried)
        Bonus.NextCode = 0
        task.spawn(checkCodes)
    end
    C.bonusRedeemManual = function(code)
        code = tostring(code or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if code == "" then return end
        task.spawn(function()
            local success, msg = redeem(code)
            if success then Bonus.Redeemed += 1 end
            if C.notifyFn then C.notifyFn((success and "Code redeemed: " or "Redeem failed: ") .. code .. ": " .. tostring(msg)) end
        end)
    end
    task.spawn(function()
        while alive() do
            local now = os.clock()
            if C.cfg.GBX_AutoQuest == true and now >= Bonus.NextQuest then
                Bonus.NextQuest = now + Bonus.QuestEvery
                pcall(checkQuests)
            end
            if C.cfg.GBX_AutoRedeem == true and now >= Bonus.NextCode then
                Bonus.NextCode = now + Bonus.CodeEvery
                pcall(checkCodes)
            end
            updateBonusStatus()
            task.wait(1)
        end
    end)
    end)() end
    
    -- ---------- Growscan: floating items and world blocks (read-only) ----------
    do (function()
    local Scan = { Every = 2, Limit = 60, Last = nil }
    local function fmtNum(n)
        local str = tostring(math.floor(n))
        local out = str:reverse():gsub("(%d%d%d)", "%1."):reverse()
        return (out:gsub("^%.", ""))
    end
    local function blockName(id)
        local it = ItemDB[id]
        local nm = itemName(id)
        if it and it.kind == "seed" then nm = nm .. " (tree)" end
        return nm
    end
    local function listText(counts, nameFn)
        local list = {}
        for id, n in pairs(counts) do list[#list + 1] = { id = id, n = n } end
        table.sort(list, function(a, b)
            if a.n ~= b.n then return a.n > b.n end
            return a.id < b.id
        end)
        local filter = string.lower(C.cfg.GBX_ScanQuery or "")
        local lines, total = {}, 0
        for _, e in ipairs(list) do
            local name = nameFn(e.id)
            if filter == "" or string.find(string.lower(name), filter, 1, true) then
                total += 1
                if total <= Scan.Limit then
                    lines[#lines + 1] = name .. "  x" .. fmtNum(e.n)
                end
            end
        end
        if total > Scan.Limit then lines[#lines + 1] = ("... +%d more (use Search)"):format(total - Scan.Limit) end
        if #lines == 0 then lines[1] = (filter ~= "") and "No match" or "Empty" end
        return table.concat(lines, "\n"), total
    end
    local function scanFloating()
        local counts, total, piles = {}, 0, 0
        local list = Drops.list
        if type(list) ~= "table" then return nil end
        for _, d in pairs(list) do
            if type(d) == "table" and type(d.id) == "number" then
                local n = tonumber(d.n) or 1
                if n > 0 then
                    counts[d.id] = (counts[d.id] or 0) + n
                    total += n
                    piles += 1
                end
            end
        end
        return counts, total, piles
    end
    local function scanBlocks()
        local w = Refs.World
        if not w or type(w.fg) ~= "table" or type(w.w) ~= "number" then return nil end
        local fgC, bgC, nf, nb = {}, {}, 0, 0
        for y = 0, w.h - 1 do
            local rf = w.fg[y]
            local rb = w.bg and w.bg[y]
            for x = 0, w.w - 1 do
                local a = rf and rf[x] or 0
                if a ~= 0 then
                    fgC[a] = (fgC[a] or 0) + 1
                    nf += 1
                end
                local b = rb and rb[x] or 0
                if b ~= 0 then
                    bgC[b] = (bgC[b] or 0) + 1
                    nb += 1
                end
            end
            if y % 64 == 63 then task.wait() end
        end
        return fgC, bgC, nf, nb
    end
    local function setDesc(label, txt, key)
        if Scan[key] == txt then return end
        Scan[key] = txt
        if label then pcall(function() label:SetText(txt) end) end
    end
    local function runScan()
        if Scan.Busy then return end
        Scan.Busy = true
        local w = Refs.World
        local fl, flTotal, piles = scanFloating()
        local fgC, bgC, nf, nb = scanBlocks()
        local floatText = fl and select(1, listText(fl, itemName)) or "Drop data not found. Press 'Connect to game'"
        local blockText = "World data not found. Press 'Connect to game'"
        if fgC then
            local pick
            if C.cfg.GBX_ScanLayer == "Front" then
                pick = fgC
            elseif C.cfg.GBX_ScanLayer == "Background" then
                pick = bgC
            else
                pick = {}
                for id, n in pairs(fgC) do pick[id] = (pick[id] or 0) + n end
                for id, n in pairs(bgC) do pick[id] = (pick[id] or 0) + n end
            end
            blockText = select(1, listText(pick, blockName))
        end
        local name = w and rawget(w, "name")
        local info = table.concat({
            "World: " .. ((type(name) == "string" and name ~= "") and name or "-")
                .. (w and type(w.w) == "number" and (" (" .. w.w .. "x" .. w.h .. ")") or ""),
            "Front blocks: " .. (nf and fmtNum(nf) or "-") .. " | Background: " .. (nb and fmtNum(nb) or "-"),
            "Floating: " .. (flTotal and (fmtNum(flTotal) .. " items (" .. piles .. " piles)") or "-"),
            "Last scan: " .. os.date("%H:%M:%S"),
        }, "\n")
        setDesc(C.scanInfoLabel, info, "_info")
        setDesc(C.scanFloatLabel, floatText, "_float")
        setDesc(C.scanBlocksLabel, blockText, "_blocks")
        Scan.Busy = false
    end
    C.runScan = runScan
    task.spawn(function()
        local last = 0
        while alive() do
            if C.cfg.GBX_ScanAuto == true and os.clock() - last >= Scan.Every then
                last = os.clock()
                pcall(runScan)
            end
            task.wait(0.5)
        end
    end)
    end)() end
    
    -- ---------- Guard: watch for Mods / Devs / players entering the world ----------
    -- Polls the game's own player list every 0.5 s. Roles come from the
    -- game's own Roles module (including undercover). On detection it
    -- stops everything, then either waits for calm or leaves the world
    -- and comes back later, walking back to the farm spot first.
    do (function()
    local updateGuardStatus
    local Guard = {
        On = false, Token = 0, Mode = "idle",
        Allow = {}, Alerted = {}, Saved = nil,
        BackAt = 0, CalmAt = nil, LeftFg = nil, BackText = nil,
        Status = "Off", Detected = 0, LastTxt = nil,
    }
    local function strip(s) return (tostring(s or ""):gsub("`.", "")) end
    local function roleOf(uid)
        if not (RolesModule) then return nil end
        local okD, dev = pcall(RolesModule.isDeveloper, uid)
        if okD and dev then return "Developer" end
        local okM, mod = pcall(RolesModule.isModerator, uid)
        if okM and mod then return "Moderator" end
        return nil
    end
    local function worldName()
        local n = Refs.World and rawget(Refs.World, "name")
        return type(n) == "string" and n or ""
    end
    local function playersHere()
        local out = {}
        local o = Refs.Others
        if not o or type(rawget(o, "list")) ~= "function" then return out end
        local ok, list = pcall(o.list)
        if not ok or type(list) ~= "table" then return out end
        for _, e in ipairs(list) do
            local uid = type(e) == "table" and tonumber(e[1] or e.userId)
            if uid and uid ~= LocalPlayer.UserId then
                out[#out + 1] = { id = uid, name = strip(e[2] or e.name or uid), role = roleOf(uid) }
            end
        end
        return out
    end
    local function threatsOf(list)
        local out = {}
        for _, p in ipairs(list) do
            if p.role or (C.cfg.GBX_GuardWho == "All players" and not Guard.Allow[p.id]) then
                out[#out + 1] = p
            end
        end
        return out
    end
    local function label(p)
        local under = false
        if p.role and RolesModule and type(RolesModule.isUndercover) == "function" then
            local ok, u = pcall(RolesModule.isUndercover, p.id)
            under = ok and u == true
        end
        return p.name .. " (" .. (p.role or "Player") .. (under and ", undercover" or "") .. ")"
    end
    local function names(list, max)
        local t = {}
        for i, p in ipairs(list) do
            if i > (max or 4) then
                t[#t + 1] = "+" .. (#list - i + 1) .. " more"
                break
            end
            t[#t + 1] = label(p)
        end
        return table.concat(t, ", ")
    end
    local function anyRunning()
        return C.farmRunning or C.clearRunning or C.farmerRunning or (C.cfg.GBX_AutoSpam == true)
    end
    local function snapshot()
        local tx, ty = C.here()
        return {
            farm = C.farmRunning, clear = C.clearRunning, farmer = C.farmerRunning, spam = (C.cfg.GBX_AutoSpam == true),
            world = worldName(), tx = tx, ty = ty,
        }
    end
    local function stopAll()
        if C.stopWalk then C.stopWalk() end
        if C.farmRunning and C.stopFarm then C.stopFarm() end
        if C.clearRunning then
            if C.stopClear then C.stopClear() end
            C.clearStatus = "Paused by Guard"
        end
        if C.farmerRunning then
            if C.stopFarmer then C.stopFarmer() end
            C.farmerStatus = "Paused by Guard"
        end
        if C.dirtRunning then
            if C.stopDirtFarm then C.stopDirtFarm() end
            C.dirtStatus = "Paused by Guard"
        end
        if C.cfg.GBX_AutoSpam == true then
            C.cfg.GBX_AutoSpam = false
            saveCfg()
            if C.spamToggle then pcall(function() C.spamToggle:SetValue(false) end) end
        end
        if C.releaseInput then C.releaseInput() end
    end
    local function leaveWorld()
        local m = Refs.Menu
        if m and type(rawget(m, "openPicker")) == "function" and pcall(m.openPicker) then
            return true
        end
        local w = Refs.World
        if w and type(rawget(w, "call")) == "function" then
            return (pcall(w.call, "LeaveWorld"))
        end
        return false
    end
    local function enterWorld(name)
        local w = Refs.World
        if not w or name == "" then return false, "world name unknown" end
        local oldFg = rawget(w, "fg")
        local m = Refs.Menu
        if m and type(rawget(m, "enter")) == "function" then
            pcall(m.enter, name)
        elseif type(rawget(w, "enter")) == "function" then
            local ok, res, msg = pcall(w.enter, name)
            if ok and not res then return false, strip(msg) end
        else
            return false, "enter function not found"
        end
        local t0 = os.clock()
        while alive() and os.clock() - t0 < 8 do
            if rawget(w, "fg") ~= oldFg then return true end
            task.wait(0.25)
        end
        return false, "world full / locked / failed"
    end
    local function stillBack(token)
        return alive() and Guard.On and Guard.Token == token and Guard.Mode == "back"
    end
    local function resumeAll(saved, token)
        if not saved then return end
        if saved.world ~= "" and worldName() ~= saved.world then
            if C.notifyFn then C.notifyFn("Guard: world changed, activity not resumed") end
            return
        end
        if saved.spam and C.cfg.GBX_AutoSpam ~= true and stillBack(token) then
            if C.spamToggle then pcall(function() C.spamToggle:SetValue(true) end) end
            C.cfg.GBX_AutoSpam = true
            saveCfg()
        end
        if saved.farm then
            local hx, hy = C.here()
            if saved.tx and (hx ~= saved.tx or hy ~= saved.ty) then
                Guard.BackText = ("Walking back to the farm spot (%d,%d)"):format(saved.tx, saved.ty)
                local ok = C.walkTo(saved.tx, saved.ty, 45)
                if not ok and stillBack(token) then ok = C.walkTo(saved.tx, saved.ty, 30) end
                if not ok then
                    if stillBack(token) and C.notifyFn then
                        C.notifyFn("Guard: could not walk back to the farm spot. Auto Farm not resumed")
                    end
                    return
                end
            end
            if stillBack(token) and C.startFarm then C.startFarm() end
        elseif saved.clear then
            if stillBack(token) and C.startClear then C.startClear() end
        elseif saved.farmer then
            if stillBack(token) and C.startFarmer then C.startFarmer() end
        end
    end
    local function beginResume()
        local saved = Guard.Saved
        Guard.Token += 1
        local token = Guard.Token
        Guard.Mode = "back"
        Guard.BackText = nil
        task.spawn(function()
            local ok, err = pcall(resumeAll, saved, token)
            if not ok then warn("[BerakHUB] Guard resume error: " .. tostring(err)) end
            if Guard.Token == token and Guard.Mode == "back" then
                Guard.Mode, Guard.Saved, Guard.BackText = "idle", nil, nil
            end
        end)
    end
    local function goAway()
        if not leaveWorld() then
            if C.notifyFn then C.notifyFn("Guard: could not leave the world, activity only paused") end
            Guard.Mode = "pause"
            return
        end
        task.wait(0.3)
        Guard.LeftFg = Refs.World and rawget(Refs.World, "fg")
        Guard.BackAt = os.clock() + (tonumber(C.cfg.GBX_GuardBackSec) or 60)
        Guard.Mode = (C.cfg.GBX_GuardAutoBack == true) and "away" or "out"
        Guard.Status = "Left the world"
    end
    local function trigger(fresh)
        Guard.Detected += #fresh
        if C.notifyFn then C.notifyFn("Guard: entered the world: " .. names(fresh)) end
        if C.cfg.GBX_GuardStopAll ~= true and C.cfg.GBX_GuardLeave ~= true then return end
        if Guard.Mode ~= "back" and (anyRunning() or not Guard.Saved) then
            Guard.Saved = snapshot()
        end
        Guard.Token += 1
        stopAll()
        Guard.CalmAt = nil
        if C.cfg.GBX_GuardLeave == true then
            goAway()
            if Guard.Mode == "away" and C.notifyFn then
                C.notifyFn("Guard: left the world. Rejoining in " .. tostring(C.cfg.GBX_GuardBackSec) .. "s")
            elseif Guard.Mode == "out" and C.notifyFn then
                C.notifyFn("Guard: left the world")
            end
        else
            Guard.Mode = "pause"
        end
    end
    local function checkAfterEnter()
        if C.resetReach then C.resetReach() end
        if C.findDropRefs then pcall(C.findDropRefs) end
        if C.findTreeRefs then pcall(C.findTreeRefs) end
        table.clear(DropFailUntil)
        task.wait(1.5)
        local th = threatsOf(playersHere())
        if #th > 0 then
            for _, p in ipairs(th) do Guard.Alerted[p.id] = true end
            if C.notifyFn then C.notifyFn("Guard: still here: " .. names(th) .. ". Leaving again") end
            goAway()
            return
        end
        if C.notifyFn then C.notifyFn("Guard: world is safe, resuming activity") end
        beginResume()
    end
    local lastScan, staffText = -10, "-"
    local function serverStaff()
        if os.clock() - lastScan < 3 then return staffText end
        lastScan = os.clock()
        local t = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local r = roleOf(plr.UserId)
                if r then t[#t + 1] = (plr.DisplayName or plr.Name) .. " (" .. r .. ")" end
            end
        end
        staffText = (#t > 0) and table.concat(t, ", ") or "none"
        return staffText
    end
    local function tick(here)
        if not Guard.On then
            Guard.Status = "Off"
            return
        end
        local now = os.clock()
        local mode = Guard.Mode
        if mode == "away" or mode == "out" then
            local fgNow = Refs.World and rawget(Refs.World, "fg")
            if Guard.LeftFg and fgNow ~= Guard.LeftFg then
                if mode == "away" and Guard.Saved and worldName() == Guard.Saved.world then
                    checkAfterEnter()
                else
                    Guard.Mode, Guard.Saved = "idle", nil
                end
                return
            end
            local name = Guard.Saved and Guard.Saved.world or ""
            if mode == "out" or name == "" then
                Guard.Status = "Out of the world (auto resume off)"
                return
            end
            local left = Guard.BackAt - now
            if left > 0 then
                Guard.Status = ("Out of the world. Rejoining %s in %d seconds"):format(name, math.ceil(left))
                return
            end
            Guard.Status = "Rejoining " .. name .. "..."
            updateGuardStatus({})
            local ok, err = enterWorld(name)
            if not ok then
                Guard.BackAt = os.clock() + math.max(15, tonumber(C.cfg.GBX_GuardBackSec) or 60)
                if C.notifyFn then C.notifyFn("Guard: could not rejoin " .. name .. ": " .. tostring(err) .. ". Retrying later") end
                return
            end
            checkAfterEnter()
            return
        end
        local present = {}
        for _, p in ipairs(here) do present[p.id] = true end
        for id in pairs(Guard.Alerted) do
            if not present[id] then Guard.Alerted[id] = nil end
        end
        local threats = threatsOf(here)
        local fresh = {}
        for _, p in ipairs(threats) do
            if not Guard.Alerted[p.id] then
                Guard.Alerted[p.id] = true
                fresh[#fresh + 1] = p
            end
        end
        if #fresh > 0 then
            trigger(fresh)
            if Guard.Mode == "away" or Guard.Mode == "out" then return end
        end
        if #threats > 0 then
            Guard.CalmAt = nil
            Guard.Status = (Guard.Mode == "pause" and "Paused. Here: " or "Watch out. Here: ") .. names(threats)
            return
        end
        if Guard.Mode == "pause" then
            Guard.CalmAt = Guard.CalmAt or now
            local wait = (tonumber(C.cfg.GBX_GuardCalmSec) or 5) - (now - Guard.CalmAt)
            if wait > 0 then
                Guard.Status = ("They left. Resuming in %d seconds"):format(math.ceil(wait))
                return
            end
            Guard.CalmAt = nil
            if C.cfg.GBX_GuardAutoBack == true and Guard.Saved then
                if C.notifyFn then C.notifyFn("Guard: safe now, resuming activity") end
                beginResume()
            else
                Guard.Mode, Guard.Saved = "idle", nil
            end
            return
        end
        if Guard.Mode == "back" then
            Guard.Status = Guard.BackText or "Resuming activity..."
            return
        end
        Guard.Status = "Safe"
    end
    updateGuardStatus = function(here)
        local txt = table.concat({
            "Status: " .. Guard.Status .. (Refs.Others and "" or " (player data not found: press 'Connect to game')"),
            "Players in world: " .. ((#here == 0) and "none" or names(here, 6)),
            "Staff online on this server: " .. serverStaff(),
            "Detected: " .. Guard.Detected .. " times",
        }, "\n")
        if txt ~= Guard.LastTxt then
            Guard.LastTxt = txt
            if C.guardLabel then pcall(function() C.guardLabel:SetText(txt) end) end
        end
    end
    local function setGuard(on)
        Guard.On = on
        Guard.Token += 1
        if C.stopWalk then C.stopWalk() end
        Guard.Mode, Guard.Saved, Guard.CalmAt, Guard.BackText = "idle", nil, nil, nil
        table.clear(Guard.Alerted)
        table.clear(Guard.Allow)
        if on then
            for _, p in ipairs(playersHere()) do
                if not p.role then Guard.Allow[p.id] = true end
            end
        end
    end
    C.guardSet = setGuard
    C.guardAllowNow = function()
        local n = 0
        for _, p in ipairs(playersHere()) do
            if not p.role then
                Guard.Allow[p.id] = true
                n += 1
            end
        end
        return n
    end
    C.guardCancel = function() setGuard(Guard.On) end
    task.spawn(function()
        while alive() do
            local here = (Guard.Mode ~= "away" and Guard.Mode ~= "out") and playersHere() or {}
            local ok, err = pcall(tick, here)
            if not ok then warn("[BerakHUB] Guard error: " .. tostring(err)) end
            updateGuardStatus(here)
            task.wait(0.5)
        end
    end)
    end)() end
    
    -- ---------- Anti-AFK ----------
    -- The game's own idle kick is defeated the same way the game client
    -- does it: a synthetic input event when the player goes idle.
    local afkConn = nil
    local function setAntiAfk(on)
        if on then
            if afkConn then return end
            local vu = game:GetService("VirtualUser")
            afkConn = LocalPlayer.Idled:Connect(function()
                pcall(function()
                    vu:Button2Down(Vector2.zero)
                    task.wait(0.1)
                    vu:Button2Up(Vector2.zero)
                end)
            end)
        else
            if afkConn then pcall(function() afkConn:Disconnect() end) end
            afkConn = nil
        end
    end
    C.setAntiAfk = setAntiAfk
    
    -- ---------- Auto Spam (kept from the old script, verbatim logic) ----------
    -- Chat spam uses the same path as the game's own chat box: the world
    -- channel under TextChatService, SendAsync inside a pcall.
    local function resolveSpamChannel()
        local ok, tcs = pcall(function() return game:GetService("TextChatService") end)
        if not ok or tcs == nil then return nil end
        local world = tcs:FindFirstChild("WorldChannels")
        if world ~= nil then
            -- The game sends to the channel named for the current world
            -- (set on entry); only fall back to the first channel when
            -- that exact channel is missing.
            if C.lastWorld ~= nil and C.lastWorld ~= "" then
                local named = world:FindFirstChild(tostring(C.lastWorld))
                if named ~= nil and named:IsA("TextChannel") then return named end
            end
            local ch = world:FindFirstChildOfClass("TextChannel")
            if ch ~= nil then return ch end
            local kids = world:GetChildren()
            if #kids > 0 then return kids[1] end
        end
        local ch = tcs:FindFirstChildOfClass("TextChannel")
        if ch ~= nil then return ch end
        local stock = tcs:FindFirstChild("TextChannels")
        if stock ~= nil then
            local general = stock:FindFirstChild("RBXGeneral")
            if general ~= nil then return general end
            local ch2 = stock:FindFirstChildOfClass("TextChannel")
            if ch2 ~= nil then return ch2 end
        end
        return nil
    end
    
    local function spamStep()
        local interval = tonumber(C.cfg.GBX_SpamInterval) or 5
        if interval < 1 then interval = 1 end
        if interval > 30 then interval = 30 end
        local text = tostring(C.cfg.GBX_SpamText or "")
        if text == "" or string.match(text, "%S") == nil then
            task.wait(interval)
            return
        end
        local channel = resolveSpamChannel()
        if channel == nil then
            if not C.spamWarned then
                C.spamWarned = true
                logLine("Chat channel not found; waiting for the next interval.")
            end
            task.wait(interval)
            return
        end
        local ok, err = pcall(channel.SendAsync, channel, text)
        if ok then
            C.spamWarned = false
        elseif not C.spamWarned then
            C.spamWarned = true
            logLine("Chat send failed: " .. tostring(err))
        end
        task.wait(interval)
    end
    
    local spamRunId = 0
    local function startSpam()
        spamRunId += 1
        local id = spamRunId
        task.spawn(function()
            while alive() and C.cfg.GBX_AutoSpam == true and spamRunId == id do
                local ok, err = pcall(spamStep)
                if not ok then logLine("Auto Spam error: " .. tostring(err)) end
            end
        end)
    end
    C.startSpam = startSpam
    
    -- ---------- Noclip (kept from the old script, verbatim logic) ----------
    -- The game itself owns a no-collision state: it watches the local
    -- player's Ghost attribute and, while it is true, runs a movement
    -- branch with no solidity check at all (input speed only, clamped to
    -- the world bounds). So this toggle asserts that attribute while it
    -- is on, and the game's own movement code then walks the character
    -- through solid tiles with no script steps and no fight: manual
    -- joystick/key input keeps working exactly as normal, only walls no
    -- longer block it. The attribute is local only and is never sent to
    -- the server; the server still receives the game's normal move
    -- packets and may still push the character back. The value from
    -- before the toggle was first turned on is recorded, so turning it
    -- off (or unloading) restores exactly that value instead of forcing
    -- the state off for a player who already had it. Server events
    -- (world entry, staff action) can clear the attribute, so the
    -- watcher re-asserts every 0.25s while the toggle is on.
    local ncRecorded = false
    local ncPrev = nil
    task.spawn(function()
        while alive() do
            local isOn = (C.cfg.GBX_Noclip == true)
            if isOn then
                if not ncRecorded then
                    ncRecorded = true
                    pcall(function() ncPrev = LocalPlayer:GetAttribute("Ghost") end)
                end
                pcall(function()
                    if LocalPlayer:GetAttribute("Ghost") ~= true then LocalPlayer:SetAttribute("Ghost", true) end
                end)
            elseif ncRecorded then
                ncRecorded = false
                local prev = ncPrev
                ncPrev = nil
                pcall(function() LocalPlayer:SetAttribute("Ghost", prev) end)
            end
            task.wait(0.25)
        end
        if ncRecorded then
            ncRecorded = false
            local prev = ncPrev
            ncPrev = nil
            pcall(function() LocalPlayer:SetAttribute("Ghost", prev) end)
        end
    end)
    
    -- ---------- Hide Username (streaming) ----------
    -- Shows "BerakHUB" instead of the player's OWN username on their own
    -- screen: the nametag above the character, the name panel at the top
    -- left, and the sender name of their own chat lines. Other players
    -- still see the real name. Purely cosmetic: no remotes, no game
    -- state, no other player's data.
    -- Nametag/panel use the proven watermark mechanism (hide the
    -- BitmapText letter frame, add a plain TextLabel, resize the holder,
    -- move the Wrench icon) WITHOUT any gradient animation or third-party
    -- branding. Chat lines are single BitmapText objects ("Name:
    -- message"); their text is rewritten through the object's own :set()
    -- (which stores and re-renders, so a later rewrap keeps the
    -- replacement). The game rebuilds the nametag on respawn / world
    -- entry and chat lines arrive constantly, so a 0.5 s watcher
    -- re-applies both. Everything this script changed is restored on
    -- toggle OFF and on unload. Fail-closed: if an element cannot be
    -- found, one log line.
    local TextService = game:GetService("TextService")
    local NAME_REPLACE = "BerakHUB"
    local NAME_FONT = Enum.Font.FredokaOne
    local nameTagEntry, namePanelEntry = nil, nil
    local chatLinesTable = nil
    local chatLinesNextTry = 0
    local chatRewritten = {}
    local hideNameWarned = false
    local chatLinesWarned = false
    local function nameHolders()
        local gg = PlayerGui:FindFirstChild("GameGui")
        local world = gg and gg:FindFirstChild("World")
        local cam = world and world:FindFirstChild("Camera")
        local chat = PlayerGui:FindFirstChild("ChatGui")
        local hud = chat and chat:FindFirstChild("HUD")
        local panel = hud and hud:FindFirstChild("PlayerPanel")
        return cam and cam:FindFirstChild("NameTag"), panel and panel:FindFirstChild("Name")
    end
    local function nameTextWidth(text, size)
        local ok, v = pcall(TextService.GetTextSize, TextService, text, size, NAME_FONT, Vector2.new(2000, 200))
        return (ok and v.X or #text * size * 0.55) + 6
    end
    local function makeNameLabel(holder, size, isTag)
        local lb = Instance.new("TextLabel")
        lb.Name = "BerakHUBName"
        lb.BackgroundTransparency = 1
        lb.Font = NAME_FONT
        lb.TextSize = size
        lb.TextColor3 = Color3.new(1, 1, 1)
        lb.Text = NAME_REPLACE
        lb.ZIndex = isTag and 1017 or 10
        if isTag then
            lb.AnchorPoint = Vector2.new(0.5, 0.5)
            lb.Position = UDim2.fromScale(0.5, 0.5)
        else
            lb.AnchorPoint = Vector2.new(0, 0.5)
            lb.Position = UDim2.new(0, 3, 0.5, 0)
            lb.TextXAlignment = Enum.TextXAlignment.Left
        end
        local st = Instance.new("UIStroke")
        st.Thickness = 2
        st.Color = Color3.fromRGB(25, 12, 40)
        st.Transparency = 0.1
        st.Parent = lb
        lb.Parent = holder
        return lb
    end
    local function dropNameEntry(e)
        if not e then return end
        pcall(function() if e.label then e.label:Destroy() end end)
        if e.bitmap then
            pcall(function() if e.bitmap.Parent then e.bitmap.Visible = true end end)
        end
        if e.isTag and e.bitmap then
            pcall(function()
                local bw = e.bitmap.Size.X.Offset
                e.holder.Size = UDim2.fromOffset(bw, e.holder.Size.Y.Offset)
                local wr = e.holder:FindFirstChild("Wrench")
                if wr then wr.Position = UDim2.fromOffset(bw + 4, wr.Position.Y.Offset) end
            end)
        end
    end
    local function nameKeep(e, holder, size, isTag)
        if not holder then
            dropNameEntry(e)
            return nil
        end
        if not e or e.holder ~= holder or not e.label or not e.label.Parent then
            dropNameEntry(e)
            e = { holder = holder, bitmap = holder:FindFirstChild("BitmapText"), label = makeNameLabel(holder, size, isTag), w = 0, isTag = isTag }
        end
        if e.bitmap and e.bitmap.Visible then e.bitmap.Visible = false end
        if isTag then
            local w = nameTextWidth(NAME_REPLACE, size)
            local h = math.max(holder.Size.Y.Offset, size + 6)
            if e.label.Size.X.Offset ~= w or e.label.Size.Y.Offset ~= h then
                e.label.Size = UDim2.fromOffset(w, h)
            end
            if holder.Size.X.Offset ~= w then
                holder.Size = UDim2.fromOffset(w, holder.Size.Y.Offset)
            end
            local wr = holder:FindFirstChild("Wrench")
            if wr and wr.Position.X.Offset ~= w + 4 then
                wr.Position = UDim2.fromOffset(w + 4, wr.Position.Y.Offset)
            end
            e.w = w
        else
            e.label.Size = UDim2.new(1, -6, 1, 0)
        end
        return e
    end
    local function discoverChatLines()
        if chatLinesTable then return chatLinesTable end
        if os.clock() < chatLinesNextTry then return nil end
        chatLinesNextTry = os.clock() + 5
        if type(getgc) ~= "function" or type(debug) ~= "table" or type(debug.getupvalues) ~= "function" then return nil end
        local chatSrc = "Players." .. LocalPlayer.Name .. ".PlayerGui.GameGui.ChatUI"
        for _, f in ipairs(getgc(true)) do
            if type(f) == "function" then
                local okS, src = pcall(debug.info, f, "s")
                local okN, nm = pcall(debug.info, f, "n")
                if okS and okN and src == chatSrc and nm == "addLine" then
                    local okU, ups = pcall(debug.getupvalues, f)
                    if okU and type(ups) == "table" then
                        for _, v in pairs(ups) do
                            if type(v) == "table" then
                                for _, el in pairs(v) do
                                    if type(el) == "table" and type(el.set) == "function"
                                        and type(el.text) == "string" and typeof(el.frame) == "Instance" then
                                        chatLinesTable = v
                                        return v
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return nil
    end
    local function rewriteChatNames()
        local lines = discoverChatLines()
        if not lines then
            if not chatLinesWarned then
                chatLinesWarned = true
                logLine("Hide Username: chat lines not found (chat module not loaded?)")
            end
            return
        end
        local prefix = LocalPlayer.Name .. ":"
        for _, el in pairs(lines) do
            if type(el) == "table" and type(el.set) == "function" and type(el.text) == "string" then
                local t = el.text
                if t:sub(1, #prefix) == prefix then
                    chatRewritten[el] = t
                    pcall(el.set, el, NAME_REPLACE .. ":" .. t:sub(#prefix + 1))
                end
            end
        end
    end
    local function restoreChatNames()
        for el, orig in pairs(chatRewritten) do
            pcall(function()
                if el.frame and el.frame.Parent then el:set(orig) end
            end)
        end
        table.clear(chatRewritten)
    end
    local function cleanupHideUsername()
        dropNameEntry(nameTagEntry)
        dropNameEntry(namePanelEntry)
        nameTagEntry, namePanelEntry = nil, nil
        restoreChatNames()
    end
    local function applyHideUsername()
        if C.cfg.GBX_HideUsername == true then
            local tag, panelName = nameHolders()
            nameTagEntry = nameKeep(nameTagEntry, tag, 22, true)
            namePanelEntry = nameKeep(namePanelEntry, panelName, 21, false)
            if not tag and not panelName and not hideNameWarned then
                hideNameWarned = true
                logLine("Hide Username: name elements not found (not in a world yet?)")
            end
            rewriteChatNames()
        else
            cleanupHideUsername()
        end
    end
    task.spawn(function()
        while alive() do
            pcall(applyHideUsername)
            task.wait(0.5)
        end
        cleanupHideUsername()
    end)
    
    -- ---------- status line ----------
    local function statusText()
        local parts = { refsText() }
        parts[#parts + 1] = "Placed " .. C.stats.placed .. " · Broken " .. C.stats.broken
            .. " · Collected " .. C.stats.collected .. " · Server-confirmed breaks " .. C.stats.serverConfirmed
        parts[#parts + 1] = "Quests claimed " .. C.stats.claimed .. " · Codes redeemed " .. C.stats.redeemed
        if C.cfg.GBX_HideUsername == true then
            parts[#parts + 1] = "Username shown as BerakHUB (streaming)"
        end
        return table.concat(parts, "\n")
    end
    
    -- ---------- UI (BerakHUB native; provided by the build wrapper as BerakUI) ----------
    local Library, Window = getgenv().BerakHUB_Library, getgenv().BerakHUB_Window
    if not Library or not Window then error("UI Rayfield belum siap") end
    C.Library = Library
    C.notifyFn = function(text)
        Library:Notify({ Title = "BerakHUB", Description = text, Time = 3 })
    end
    local function bindToggle(group, id, text, flagKey, fn)
        local opt = group:AddToggle(id, { Text = text, Default = C.cfg[flagKey] == true })
        opt:OnChanged(function(v)
            C.cfg[flagKey] = v
            saveCfg()
            if fn ~= nil then fn(v) end
        end)
        return opt
    end
    local function momentary(group, text, fn)
        return group:AddButton({ Text = text, Func = fn })
    end
    local function textInput(group, id, text, flagKey, placeholder)
        local opt = group:AddInput(id, { Text = text, Default = tostring(C.cfg[flagKey] or ""), Placeholder = placeholder or "" })
        opt:OnChanged(function(v)
            C.cfg[flagKey] = v
            saveCfg()
        end)
        return opt
    end
    local function singleDropdown(group, id, text, flagKey, values)
        local opt = group:AddDropdown(id, { Text = text, Values = values or {}, Default = tostring(C.cfg[flagKey] or "") })
        opt:OnChanged(function(v)
            C.cfg[flagKey] = v
            saveCfg()
        end)
        return opt
    end
    local function slider(group, id, text, flagKey, min, max, default, rounding, onChange)
        local opt = group:AddSlider(id, { Text = text, Min = min, Max = max, Default = tonumber(C.cfg[flagKey]) or default, Rounding = rounding or 0 })
        opt:OnChanged(function(v)
            C.cfg[flagKey] = v
            saveCfg()
            if onChange ~= nil then onChange(v) end
        end)
        return opt
    end
    -- Set a dropdown's displayed value without firing its OnChanged
    -- (used to keep the two scaffold dropdowns in sync).
    local function setDropdownSilent(opt, v)
        if not opt or opt.Value == v then return end
        opt.Value = v
        if opt._render then pcall(opt._render, v) end
    end
    
    local T = {}
    T.Farm = Window:AddTab("Farm", "home")
    do
        local g = T.Farm:AddLeftGroupbox("Connection")
        momentary(g, "Connect to game", function() reconnect(true) end)
        C.refsLabel = g:AddLabel("Press 'Connect to game' after entering a world.", true)
        C.statusLabel = g:AddLabel("", true)
        local g2 = T.Farm:AddLeftGroupbox("Auto Farm")
        do
            local opt = g2:AddToggle("GBX_AutoFarm", { Text = "Auto Farm", Default = C.cfg.GBX_AutoFarm == true })
            C.farmToggle = opt
            opt:OnChanged(function(v)
                C.cfg.GBX_AutoFarm = v
                saveCfg()
                if v and not C.farmRunning then startFarm()
                elseif not v and C.farmRunning then stopFarm() end
            end)
        end
        do
            local opt = g2:AddToggle("GBX_AutoDirtFarm", { Text = "Auto Dirt Farm", Default = C.cfg.GBX_AutoDirtFarm == true })
            C.dirtToggle = opt
            opt:OnChanged(function(v)
                C.cfg.GBX_AutoDirtFarm = v
                saveCfg()
                if v and not C.dirtRunning then startDirtFarm()
                elseif not v and C.dirtRunning then stopDirtFarm() end
            end)
        end
        C.dirtLabel = g2:AddLabel("Auto Dirt Farm is off.", true)
        singleDropdown(g2, "GBX_FarmMode", "Farm Mode", "GBX_FarmMode", { "Place + Break", "Break only", "Place only" })
        C.dd.farmBlock = singleDropdown(g2, "GBX_FarmBlock", "Farm Block", "GBX_FarmBlock",
            { (C.cfg.GBX_FarmBlock ~= "" and C.cfg.GBX_FarmBlock or "(inventory empty / not read yet)") })
        momentary(g2, "Open Farm Grid", function() C.openGrid() end)
        slider(g2, "GBX_BreakMs", "Break Speed (ms per hit)", "GBX_BreakMs", 50, 1000, 220, 0)
        slider(g2, "GBX_PlaceMs", "Place Speed (ms per tile)", "GBX_PlaceMs", 100, 1000, 250, 0)
        slider(g2, "GBX_AfterBreakMs", "Delay After Break (ms)", "GBX_AfterBreakMs", 0, 1000, 300, 0)
        slider(g2, "GBX_MultiTarget", "Multi Target (1-5)", "GBX_MultiTarget", 1, 5, 1, 0)
        slider(g2, "GBX_HitsOverride", "Hits Per Tile (0 = game default)", "GBX_HitsOverride", 0, 20, 0, 0)
        bindToggle(g2, "GBX_MutePunch", "Mute Punch Sound", "GBX_MutePunch")
        bindToggle(g2, "GBX_BypassPunchCooldown", "Bypass Punch Cooldown", "GBX_BypassPunchCooldown")
        C.farmLabel = g2:AddLabel("Auto Farm is off.", true)
        local g3 = T.Farm:AddRightGroupbox("Farmer")
        do
            local opt = g3:AddToggle("GBX_Farmer", { Text = "Auto Farmer", Default = C.cfg.GBX_Farmer == true })
            C.farmerToggle = opt
            opt:OnChanged(function(v)
                C.cfg.GBX_Farmer = v
                saveCfg()
                if v and not C.farmerRunning then C.startFarmer()
                elseif not v and C.farmerRunning then C.stopFarmer() end
            end)
        end
        bindToggle(g3, "GBX_FarmerHarvest", "Auto Harvest Ripe Trees", "GBX_FarmerHarvest")
        bindToggle(g3, "GBX_FarmerPlant", "Auto Plant Seeds", "GBX_FarmerPlant")
        C.dd.farmerSeed = singleDropdown(g3, "GBX_FarmerSeed", "Seed to Plant", "GBX_FarmerSeed",
            { (C.cfg.GBX_FarmerSeed ~= "" and C.cfg.GBX_FarmerSeed or "(no seeds in inventory)") })
        do
            local opt = g3:AddDropdown("GBX_FarmerScaffold", { Text = "Scaffold Block", Values = { "(no solid blocks in inventory)" }, Default = tostring(C.cfg.GBX_ClearScaffold or "") })
            C.dd.farmerScaffold = opt
            opt:OnChanged(function(v)
                C.cfg.GBX_ClearScaffold = v
                saveCfg()
                setDropdownSilent(C.dd.clearScaffold, v)
            end)
        end
        slider(g3, "GBX_HarvestMs", "Harvest Speed (ms)", "GBX_HarvestMs", 100, 1000, 250, 0)
        slider(g3, "GBX_PlantMs", "Plant Speed (ms)", "GBX_PlantMs", 100, 1000, 250, 0)
        bindToggle(g3, "GBX_FarmerCollect", "Collect Drops While Farming", "GBX_FarmerCollect")
        C.farmerLabel = g3:AddLabel("Farmer is off.", true)
        local g4 = T.Farm:AddRightGroupbox("Auto Collect")
        C.autoCollectOpt = bindToggle(g4, "GBX_AutoCollect", "Auto Collect Drops", "GBX_AutoCollect")
        slider(g4, "GBX_CollectRadius", "Collect Radius (studs)", "GBX_CollectRadius", 1, 5, 3.2, 1)
        bindToggle(g4, "GBX_CollectAfterPlace", "Collect After Placing", "GBX_CollectAfterPlace")
        g4:AddLabel("Drops are taken with the game's own take function, in parallel, every frame. Drops you threw yourself cannot be picked up again yet (game rule), except gems.", true)
    end
    T.Clear = Window:AddTab("Clear World", "trash")
    do
        local g = T.Clear:AddLeftGroupbox("Auto Clear")
        do
            local opt = g:AddToggle("GBX_ClearWorld", { Text = "Auto Clear", Default = C.cfg.GBX_ClearWorld == true })
            C.clearToggle = opt
            opt:OnChanged(function(v)
                C.cfg.GBX_ClearWorld = v
                saveCfg()
                if v and not C.clearRunning then C.startClear()
                elseif not v and C.clearRunning then C.stopClear() end
            end)
        end
        bindToggle(g, "GBX_ClearIncludeBg", "Clear Background Too", "GBX_ClearIncludeBg")
        do
            local opt = g:AddDropdown("GBX_ClearScaffold", { Text = "Scaffold Block", Values = { "(no solid blocks in inventory)" }, Default = tostring(C.cfg.GBX_ClearScaffold or "") })
            C.dd.clearScaffold = opt
            opt:OnChanged(function(v)
                C.cfg.GBX_ClearScaffold = v
                saveCfg()
                setDropdownSilent(C.dd.farmerScaffold, v)
            end)
        end
        bindToggle(g, "GBX_ClearUseBlock", "Place Scaffold Blocks", "GBX_ClearUseBlock")
        singleDropdown(g, "GBX_ClearSweep", "Sweep Direction", "GBX_ClearSweep", { "Kiri → Kanan", "Zig-zag" })
        bindToggle(g, "GBX_ClearCollect", "Collect Drops While Clearing", "GBX_ClearCollect")
        C.clearLabel = g:AddLabel("Auto Clear is off.", true)
        local g2 = T.Clear:AddRightGroupbox("How it works")
        g2:AddLabel("Clears the world top to bottom, two rows at a time. Walks on the ground only — when there is no footing it places a scaffold block from your inventory (if enabled), then picks it back up. A tile the server refuses more than 6 times is skipped for 2 minutes.", true)
    end
    T.World = Window:AddTab("World", "globe")
    do
        local g = T.World:AddLeftGroupbox("Growscan")
        bindToggle(g, "GBX_ScanAuto", "Auto Scan", "GBX_ScanAuto")
        singleDropdown(g, "GBX_ScanLayer", "Layer", "GBX_ScanLayer", { "Semua", "Front", "Background" })
        textInput(g, "GBX_ScanQuery", "Search", "GBX_ScanQuery", "Filter by name...")
        momentary(g, "Scan Now", function() if C.runScan then C.runScan() end end)
        C.scanInfoLabel = g:AddLabel("", true)
        C.scanFloatLabel = g:AddLabel("Floating items: not scanned yet.", true)
        C.scanBlocksLabel = g:AddLabel("World blocks: not scanned yet.", true)
        local g2 = T.World:AddRightGroupbox("Bonus")
        bindToggle(g2, "GBX_AutoQuest", "Auto Claim Quests", "GBX_AutoQuest")
        momentary(g2, "Check Quests Now", function() if C.bonusCheckQuests then C.bonusCheckQuests() end end)
        C.questLabel = g2:AddLabel("Quests: not checked yet.", true)
        bindToggle(g2, "GBX_AutoRedeem", "Auto Redeem Codes", "GBX_AutoRedeem")
        momentary(g2, "Check Codes Now", function() if C.bonusCheckCodes then C.bonusCheckCodes() end end)
        C.codeLabel = g2:AddLabel("Codes: not checked yet.", true)
        local codeBox = g2:AddInput("GBX_ManualCode", { Text = "Redeem One Code", Default = "", Placeholder = "Type a code from the game's Discord..." })
        momentary(g2, "Redeem Code", function()
            if C.bonusRedeemManual then C.bonusRedeemManual(codeBox.Value) end
        end)
        g2:AddLabel("Codes always come from the server's own list — never type a guessed code. The redeem call is the same one the game's Redeem menu uses.", true)
    end
    T.Guard = Window:AddTab("Guard", "shield")
    do
        local g = T.Guard:AddLeftGroupbox("Penjaga")
        do
            local opt = g:AddToggle("GBX_Guard", { Text = "Guard (watch for staff)", Default = C.cfg.GBX_Guard == true })
            C.guardToggle = opt
            opt:OnChanged(function(v)
                C.cfg.GBX_Guard = v
                saveCfg()
                if C.guardSet then C.guardSet(v) end
            end)
        end
        singleDropdown(g, "GBX_GuardWho", "Watch For", "GBX_GuardWho", { "Staff (Mod/Dev)", "All players" })
        bindToggle(g, "GBX_GuardStopAll", "Stop Everything on Detection", "GBX_GuardStopAll")
        bindToggle(g, "GBX_GuardLeave", "Leave World on Detection", "GBX_GuardLeave")
        bindToggle(g, "GBX_GuardAutoBack", "Auto Rejoin After Leaving", "GBX_GuardAutoBack")
        slider(g, "GBX_GuardBackSec", "Rejoin After (seconds)", "GBX_GuardBackSec", 15, 300, 60, 0)
        slider(g, "GBX_GuardCalmSec", "Calm Before Resume (seconds)", "GBX_GuardCalmSec", 1, 30, 5, 0)
        momentary(g, "Allow Players Here Now", function()
            if C.guardAllowNow then
                local n = C.guardAllowNow()
                C.notifyFn("Guard: " .. n .. " player(s) allowed.")
            end
        end)
        momentary(g, "Reset Allow List", function()
            if C.guardCancel then C.guardCancel() end
            C.notifyFn("Guard: allow list reset.")
        end)
        C.guardLabel = g:AddLabel("Guard is off.", true)
        local g2 = T.Guard:AddRightGroupbox("How it works")
        g2:AddLabel("Watches the game's own player list every half second. Roles come from the game's own Roles module (including undercover staff). On detection it stops everything, then either waits for calm or leaves the world and comes back later, walking back to the farm spot first. Players already here when you turn Guard on are allowed automatically.", true)
    end
    T.Chat = Window:AddTab("Chat", "message-circle")
    do
        local g = T.Chat:AddLeftGroupbox("Auto Spam")
        textInput(g, "GBX_SpamText", "Spam Text", "GBX_SpamText", "Message to spam")
        slider(g, "GBX_SpamInterval", "Spam Interval (seconds)", "GBX_SpamInterval", 1, 30, 5, 0)
        do
            local opt = g:AddToggle("GBX_AutoSpam", { Text = "Auto Spam", Default = C.cfg.GBX_AutoSpam == true })
            C.spamToggle = opt
            opt:OnChanged(function(v)
                C.cfg.GBX_AutoSpam = v
                saveCfg()
                if v then startSpam() end
            end)
        end
        g:AddLabel("Sends through the game's own world chat channel, the same path as the chat box.", true)
    end
    T.Settings = Window:AddTab("Settings", "settings")
    do
        local g = T.Settings:AddLeftGroupbox("Movement")
        do
            local opt = g:AddToggle("GBX_Noclip", { Text = "Noclip", Default = C.cfg.GBX_Noclip == true })
            C.noclipOpt = opt
            opt:OnChanged(function(v)
                C.cfg.GBX_Noclip = v
                saveCfg()
            end)
        end
        g:AddLabel("Noclip sets the game's own Ghost state so manual walking passes through solid blocks. The server may still push you back.", true)
        slider(g, "GBX_Speed", "Walk Speed (%)", "GBX_Speed", 50, 500, 100, 0, function(v) setSpeed(v) end)
        bindToggle(g, "GBX_InfJump", "Infinite Jump", "GBX_InfJump", function(v)
            if v then hookJammer() else unhookJammer() end
        end)
        bindToggle(g, "GBX_LiteMode", "Lite Mode (no particles / sounds)", "GBX_LiteMode", function(v) setLite(v) end)
        local g2 = T.Settings:AddLeftGroupbox("Streaming")
        bindToggle(g2, "GBX_HideUsername", "Hide Username", "GBX_HideUsername")
        g2:AddLabel("Hides your own username on screen (nametag above your character + name panel, top left) so it does not show while streaming. Chat sender names cannot be hidden — each chat line is one text block with the name baked in, so hiding it would hide the message too.", true)
        local g3 = T.Settings:AddRightGroupbox("General")
        bindToggle(g3, "GBX_AntiAfk", "Anti-AFK", "GBX_AntiAfk", function(v) setAntiAfk(v) end)
        textInput(g3, "GBX_CalibX", "Position Calibration X", "GBX_CalibX", "0")
        textInput(g3, "GBX_CalibY", "Position Calibration Y", "GBX_CalibY", "0")
        local g4 = T.Settings:AddRightGroupbox("About")
        g4:AddLabel("BerakHUB · Growblox\nMenu key: RightControl\nConfig saved per account.", true)
        momentary(g4, "Stop All and Unload", function()
            if getgenv().BerakHUB_Growblox_Cleanup then getgenv().BerakHUB_Growblox_Cleanup() end
        end)
    end
    
    -- ---------- startup ----------
    reconnect(false)
    if C.cfg.GBX_Speed ~= nil then setSpeed(tonumber(C.cfg.GBX_Speed) or 100) end
    if C.cfg.GBX_AntiAfk == true then setAntiAfk(true) end
    if C.cfg.GBX_Guard == true and C.guardSet then C.guardSet(true) end
    if C.cfg.GBX_AutoFarm == true then startFarm() end
    if C.cfg.GBX_ClearWorld == true and C.startClear then C.startClear() end
    if C.cfg.GBX_Farmer == true and C.startFarmer then C.startFarmer() end
    if C.cfg.GBX_AutoDirtFarm == true and C.startDirtFarm then C.startDirtFarm() end
    if C.cfg.GBX_AutoSpam == true then startSpam() end
    -- Auto-connect retry: the load-time reconnect above runs once. If the
    -- game was not ready yet (script executed before entering a world),
    -- the refs stay empty and the saved-ON toggles above fail to start.
    -- Keep trying quietly every 5 s until the refs are found, then start
    -- the saved-ON toggles once. The button stays for manual reconnects
    -- (e.g. after hopping worlds).
    task.spawn(function()
        while alive() do
            if Refs.World and Refs.Punch then break end
            task.wait(5)
            if not alive() then break end
            if Refs.World and Refs.Punch then break end
            reconnect(false)
            if Refs.World and Refs.Punch then
                if C.cfg.GBX_AutoFarm == true then startFarm() end
                if C.cfg.GBX_ClearWorld == true and C.startClear then C.startClear() end
                if C.cfg.GBX_Farmer == true and C.startFarmer then C.startFarmer() end
                if C.cfg.GBX_AutoDirtFarm == true and C.startDirtFarm then C.startDirtFarm() end
                if C.cfg.GBX_AutoSpam == true then startSpam() end
                break
            end
        end
    end)
    pcall(function()
        if C.statusLabel ~= nil then C.statusLabel:SetText(statusText()) end
    end)
    task.spawn(function()
        while alive() do
            task.wait(15)
            pcall(function()
                if C.statusLabel ~= nil then C.statusLabel:SetText(statusText()) end
            end)
        end
    end)
    getgenv().BerakHUB_Growblox_Cleanup = function()
        C.alive = false
        saveCfg()
        if C.farmRunning then stopFarm() end
        if C.clearRunning and C.stopClear then C.stopClear() end
        if C.farmerRunning and C.stopFarmer then C.stopFarmer() end
        if C.dirtRunning and C.stopDirtFarm then C.stopDirtFarm() end
        if C.stopWalk then C.stopWalk() end
        pcall(function()
            if MenuModule ~= nil and OrigIsDown ~= nil and rawget(MenuModule, "isDown") == isDownWrapper then
                MenuModule.isDown = OrigIsDown
            end
        end)
        pcall(unhookJammer)
        pcall(function() setLite(false) end)
        pcall(function() setSpeed(100) end)
        pcall(function() if cleanupHideUsername then cleanupHideUsername() end end)
        pcall(function() if gridGui ~= nil then gridGui:Destroy() end end)
        pcall(function() Library:Unload() end)
    end
    Library:Notify({ Title = "BerakHUB", Description = "Growblox ready", Time = 2.5 })
    
    return C
]=]

-- ============================================================================
--  BOOTSTRAP
--  1) Jendela Rayfield dibuat DULU, jadi kalau ada yang gagal kamu tetap lihat UI.
--  2) Logika game (di bawah) dikompilasi dan dijalankan dengan penangkap error.
--  3) Tab "Debug" menampilkan kemampuan executor, PlaceId, dan semua error.
-- ============================================================================
local EXPECTED_PLACE = 112863874972771
local errorLog = {}

local function report(stage, err)
    local msg = "[" .. stage .. "] " .. tostring(err)
    errorLog[#errorLog + 1] = msg
    pcall(warn, "BerakHUB: " .. msg)
end

-- Pesan darurat di layar (dipakai kalau Rayfield sendiri gagal dimuat)
local function fatalOnScreen(text)
    pcall(warn, "BerakHUB FATAL: " .. tostring(text))
    pcall(function()
        local parent
        if type(gethui) == "function" then
            local ok, h = pcall(gethui)
            if ok then parent = h end
        end
        parent = parent or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local gui = Instance.new("ScreenGui")
        gui.Name = "BerakHUB_Fatal"
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 999999
        gui.Parent = parent
        local box = Instance.new("TextButton")
        box.Size = UDim2.new(0.9, 0, 0, 160)
        box.Position = UDim2.new(0.05, 0, 0.05, 0)
        box.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
        box.TextColor3 = Color3.new(1, 1, 1)
        box.TextWrapped = true
        box.TextSize = 14
        box.Font = Enum.Font.Gotham
        box.Text = "BerakHUB gagal dimuat:\n" .. tostring(text) .. "\n\n(ketuk untuk menutup)"
        box.Parent = gui
        box.MouseButton1Click:Connect(function() gui:Destroy() end)
    end)
end

local okUI, Library, Window = pcall(function()
    return BerakUI:Create("Growblox", { Title = "BerakHUB", Subtitle = "Growblox" })
end)
if not okUI or not Library or not Window then
    fatalOnScreen("Rayfield tidak bisa dibuka.\n" .. tostring(Library) ..
        "\nCek koneksi internet / apakah executor mengizinkan game:HttpGet.")
    return
end

getgenv().BerakHUB_Library = Library
getgenv().BerakHUB_Window = Window

if game.PlaceId ~= EXPECTED_PLACE then
    report("place", "PlaceId " .. tostring(game.PlaceId) .. " bukan Growblox (" .. EXPECTED_PLACE ..
        "). Fitur game tidak akan menemukan data yang dicari.")
end

Library:Notify({ Title = "BerakHUB", Description = "UI siap, memuat modul game...", Time = 3 })

-- Kompilasi logika game (error sintaks / batas Luau akan terbaca di sini)
local fn, compileErr = loadstring(BERAKHUB_LOGIC, "=BerakHUB_Growblox")
if not fn then
    report("compile", compileErr)
else
    local okRun, runErr = xpcall(fn, function(e)
        if debug and debug.traceback then
            return debug.traceback(tostring(e), 2)
        end
        return tostring(e)
    end)
    if not okRun then report("runtime", runErr) end
end

-- ---------- tab Debug ----------
pcall(function()
    local execName = "?"
    if type(identifyexecutor) == "function" then
        local ok, n, v = pcall(identifyexecutor)
        if ok then execName = tostring(n) .. (v and (" " .. tostring(v)) or "") end
    end
    local function has(label, cond)
        return (cond and "[OK]   " or "[TIDAK ADA]   ") .. label
    end
    local caps = {
        has("getgc", type(getgc) == "function"),
        has("debug.getupvalues", type(debug) == "table" and type(debug.getupvalues) == "function"),
        has("debug.info", type(debug) == "table" and type(debug.info) == "function"),
        has("getconnections", type(getconnections) == "function"),
        has("writefile / readfile / isfile",
            type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"),
        has("setclipboard", type(setclipboard) == "function"),
    }
    local needsGc = not (type(getgc) == "function" and type(debug) == "table"
        and type(debug.getupvalues) == "function")

    local dbg = Window:AddTab("Debug", "bug")
    local g = dbg:AddLeftGroupbox("Status")
    g:AddLabel("Executor: " .. execName ..
        "\nPlaceId: " .. tostring(game.PlaceId) ..
        (game.PlaceId == EXPECTED_PLACE and "  (Growblox)" or "  (BUKAN Growblox)"), true)
    g:AddLabel(table.concat(caps, "\n"), true)
    if needsGc then
        g:AddLabel("Executor ini tidak punya getgc / debug.getupvalues lengkap. " ..
            "Tombol 'Connect to game' dan fitur farm TIDAK akan menemukan fungsi game, " ..
            "walaupun UI muncul normal.", true)
    end

    local g2 = dbg:AddRightGroupbox("Error")
    if #errorLog == 0 then
        g2:AddLabel("Tidak ada error saat memuat.", true)
    else
        local text = table.concat(errorLog, "\n\n")
        g2:AddLabel(text, true)
        g2:AddButton({ Text = "Salin error", Func = function()
            if type(setclipboard) == "function" then
                pcall(setclipboard, text)
                Library:Notify({ Title = "BerakHUB", Description = "Error disalin", Time = 2 })
            end
        end })
    end
end)

if #errorLog > 0 then
    Library:Notify({
        Title = "BerakHUB: ada masalah",
        Description = "Buka tab Debug untuk detail error.",
        Time = 8,
    })
end
