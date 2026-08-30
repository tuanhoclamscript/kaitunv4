--[[
    KAITUN DRACO MULTI-RACE PIPELINE - MASTER ENGINE (FULL PORT)
    ============================================================
    Orchestration FSM theo plan.md (tick 2.22s):
      Buoc 0: Check FG -> marker + ServerData + doi toc ke tiep
      Buoc 1: Beli < 2M -> Haunted Castle | Cyborg >= 5000 Frag -> Tyrant/Auto Raid
      Buoc 2: Lay toc hiem (Ghoul V1 / Cyborg V1 / Roll Tort)
      Buoc 3: V2 (Alchemist 3 hoa)
      Buoc 4: V3 (Arowe + WebSocket PvP cho Angel/Ghoul)
      Buoc 5: Mirage Night + Pull Lever
      Buoc 6: Trial V4 (WS sync full moon) + Gear + Master Training -> FG

    Port verbatim tu: v4.lua (tween/FastAttack/Tyrant/Raid/Trial/SmartTele/
    Coordinator), ghoulv1.lua, uknow.lua (chest + safety lock), v3.lua,
    ghoulv3.lua (PvP helper), data.lua (ServerData)
]]

local getgenv = (typeof(getgenv) == "function" and getgenv) or function() return _G end

-- =====================================================================
-- MODULE 0: CONFIG
-- =====================================================================
getgenv().Config = {
    RacesToUpgrade = { "Human", "Cyborg", "Ghoul", "Mink", "Fishman", "Skypiea" },
    Team = "Pirates",
    AutoRollRace = true,
    CentralHubWS = "ws://13.75.105.170:20425/?token=ditnhaukhong",
    GearPatterns = {
        Ghoul = "B-B-A", Cyborg = "A-B-B", Mink = "B-B-A",
        Skypiea = "B-B-A", Human = "B-A-A", Fishman = "B-A-A"
    },
    -- Nguong tai nguyen
    MinBeli = 2000000,
    CyborgMinFrags = 5000,
    GhoulEctoplasmTarget = 100,
    -- FSM
    TickInterval = 2.22,
    -- Farm Beli
    FarmHeight = 100,
    TweenSpeed = 200,
    -- PvP rendezvous (Diamond Hill) tu ghoulv3.lua
    PvpRendezvous = CFrame.new(-1871.12, 45.86, 1362.31),
    -- An toan tuyet doi
    SafetyLockItems = { "Fist of Darkness", "Core Brain", "Hellfire Torch" },

    -- ==== Cac key theo dung ten v4.lua de port verbatim khong sua ====
    ["Farm Fragments"] = { autoraid = true, autotyrant = true },
    ["Gear"] = "B-B-A",
    ["ChangeBestGear"] = false,
    ["Training Islands"] = { "Tiki Outpost", "Ice Cream Island", "Haunted Castle", "Great Tree", "Port Town", "Peanut Island" },
    ["Trial Orbit Height"] = 30,
    ["Fish Trial Stand Height"] = 350,
    ["Human Trial Hover Height"] = 10,
    ["Human Trial Kill Delay"] = 0.45,
    ["Human Trial Post Kill Delay"] = 0.25,
    ["Human Trial Wave Delay"] = 1.2,
    ["V3 Door Distance"] = 50,
    ["V3 Countdown"] = 6,
    ["V3 Ready Hold Time"] = 0.6,
    ["V3 WebSocket Sync"] = true,
    ["V3 Require Different Races"] = true,
    ["V3 Fire Count"] = 1,
    ["V3 Fire Interval"] = 0.05,
    ["Pair Temple Timeout"] = 35,
    ["Pair Requeue Delay"] = 15,
    ["Pair Force Temple Interval"] = 0.8,
    ["Reset Teleport After Trial"] = true,
    ["Reset Teleport Settle Time"] = 0.45,
    ["Trial Barrier Timeout"] = 240,
    ["Full Moon API URL"] = "https://vortexz-hub.xyz/fullmoon",
    ["Full Moon Poll Interval"] = 15,
    ["Full Moon Cycle Seconds"] = 600,
    ["Full Moon Minimum Remaining"] = 120,
    ["Full Moon Max Players"] = 8,
    ["Central Hub WebSocket"] = "ws://13.75.105.170:20425/?token=ditnhaukhong",
    ["Central Hub Heartbeat Interval"] = 3,
}

-- TyrantConfig verbatim tu v4.lua:301-314
getgenv().TyrantConfig = {
    Weapon = "Dragon Talon",
    TweenSpeed = 200,
    FarmHeight = 25,
    BossHeight = 30,
    AttackDistance = 105,
    AttackDelay = 0.03,
    AutoBuyDragonTalon = true,
    AutoBuso = true,
    BringMobs = false,
    VaseSweepInterval = 120,
    VaseSweepDuration = 60,
}

TweenSpeed = getgenv().Config.TweenSpeed or getgenv().TyrantConfig.TweenSpeed or 200

-- Alias named <-> bracket keys (bridge port v4.lua <-> pipeline)
getgenv().Config.CentralHubWS = getgenv().Config.CentralHubWS
    or getgenv().Config["Central Hub WebSocket"]
getgenv().Config.Gear = getgenv().Config["Gear"]
getgenv().Config.TrainingIslands = getgenv().Config["Training Islands"]
getgenv().Config.PairTempleTimeout = tonumber(getgenv().Config["Pair Temple Timeout"])
getgenv().Config.V3DoorDistance = tonumber(getgenv().Config["V3 Door Distance"])
getgenv().Config.V3Countdown = tonumber(getgenv().Config["V3 Countdown"])
getgenv().Config.V3ReadyHoldTime = tonumber(getgenv().Config["V3 Ready Hold Time"])
getgenv().Config.V3WebSocketSync = getgenv().Config["V3 WebSocket Sync"]
getgenv().Config.V3FireCount = tonumber(getgenv().Config["V3 Fire Count"])
getgenv().Config.V3FireInterval = tonumber(getgenv().Config["V3 Fire Interval"])
getgenv().Config.ResetTeleportAfterTrial = getgenv().Config["Reset Teleport After Trial"]
getgenv().Config.ResetTeleportSettleTime = tonumber(getgenv().Config["Reset Teleport Settle Time"])
getgenv().Config.TrialBarrierTimeout = tonumber(getgenv().Config["Trial Barrier Timeout"])
getgenv().Config.FullMoonApiUrl = getgenv().Config["Full Moon API URL"]
getgenv().Config.FullMoonPollInterval = tonumber(getgenv().Config["Full Moon Poll Interval"])
getgenv().Config.FullMoonMinRemaining = tonumber(getgenv().Config["Full Moon Minimum Remaining"])
getgenv().Config.FullMoonMaxPlayers = tonumber(getgenv().Config["Full Moon Max Players"])
getgenv().Config.VaseSweepInterval = tonumber(getgenv().Config["Vase Sweep Interval"] or 120)
getgenv().Config.FishTrialStandHeight = tonumber(getgenv().Config["Fish Trial Stand Height"])
getgenv().Config.HumanTrialHoverHeight = tonumber(getgenv().Config["Human Trial Hover Height"])
getgenv().Config.HumanTrialKillDelay = tonumber(getgenv().Config["Human Trial Kill Delay"])
getgenv().Config.HumanTrialPostKillDelay = tonumber(getgenv().Config["Human Trial Post Kill Delay"])
getgenv().Config.HumanTrialWaveDelay = tonumber(getgenv().Config["Human Trial Wave Delay"])
getgenv().Config.AttackDelay = tonumber(getgenv().Config.AttackDelay or 0.03)
getgenv().Config.AttackDistance = tonumber(getgenv().Config.AttackDistance or 105)

TweenSpeed = getgenv().Config.TweenSpeed or getgenv().TyrantConfig.TweenSpeed or 200

local AttackConfig = {
    AutoClickEnabled = true,
    AttackDistance = 65,
    AttackCooldown = 0.05,
    ComboResetTime = 1.5,
    MaxCombo = 4,
    AttackMobs = true,
    AttackPlayers = false,
}

-- =====================================================================
-- SERVICES & REMOTES
-- =====================================================================
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

if not game:IsLoaded() then
    pcall(function() game.Loaded:Wait() end)
end

local Player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local plr = Player
local LocalPlayer = Player
local USERNAME = Player.Name

-- =====================================================================
-- PERFORMANCE OPTIMIZATION (Luau best practices)
--  - 1 pcall/phase, khong pcall tung object (pcall la function call + stack)
--  - Lookup table theo ClassName thay cho chuoi IsA (IsA walk class hierarchy)
--  - Cache Enum.ET ra local (global Enum la table lookup moi lan)
--  - Quet chunked + task.wait() de khong khoa frame
--  - CastShadow=false + tat ParticleEmitter/Trail/Beam (ke giu FPS chinh)
--  - Texture/Decal -> Transparency=1 (an hoan toan, khong Destroy gay event)
--  - Chay 1 lan, DescendantAdded xu ly instance moi stream ve sau
-- =====================================================================
do
    local SOLID_CLASSES = {
        Part = true, MeshPart = true, UnionOperation = true,
        IntersectOperation = true, WedgePart = true, CornerWedgePart = true,
        TrussPart = true, SpawnLocation = true,
    }
    local EFFECT_CLASSES = {
        ParticleEmitter = true, Trail = true, Beam = true,
        Smoke = true, Fire = true, Sparkles = true,
    }
    local KILL_CLASSES = {
        ColorCorrectionEffect = true, SunRaysEffect = true, BlurEffect = true,
        BloomEffect = true, DepthOfFieldEffect = true, Atmosphere = true,
        Explosion = true,
    }
    local SMOOTH_PLASTIC = Enum.Material.SmoothPlastic

    local function stripInstance(object)
        local className = object.ClassName
        if SOLID_CLASSES[className] then
            object.CastShadow = false
            object.Material = SMOOTH_PLASTIC
            if className == "MeshPart" then
                -- TextureID rong = khong phai sample texture GPU
                object.TextureID = ""
            end
        elseif className == "Texture" or className == "Decal" then
            object.Transparency = 1
        elseif EFFECT_CLASSES[className] then
            object.Enabled = false
        elseif KILL_CLASSES[className] then
            object:Destroy()
        end
    end

    local function optimizeWorld()
        if getgenv().__KAITUN_FPS_OPTIMIZED then
            return
        end
        getgenv().__KAITUN_FPS_OPTIMIZED = true

        task.spawn(function()
            -- Cho game load (co timeout, khong tre han script)
            local startedAt = tick()
            while not game:IsLoaded() do
                if tick() - startedAt > 15 then break end
                task.wait(0.25)
            end
            task.wait(1)

            pcall(function()
                settings().Rendering.QualityLevel = 1
                UserSettings():GetService("UserGameSettings").MasterVolume = 0
                local StarterGui = game:GetService("StarterGui")
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
            end)

            pcall(function()
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 9e9
                Lighting.EnvironmentDiffuseScale = 0
                Lighting.EnvironmentSpecularScale = 0
                local terrain = Workspace:FindFirstChildOfClass("Terrain")
                if terrain then
                    terrain.WaterWaveSize = 0
                    terrain.WaterWaveSpeed = 0
                    terrain.WaterReflectance = 0
                    terrain.WaterTransparency = 1
                    local clouds = terrain:FindFirstChildOfClass("Clouds")
                    if clouds then clouds:Destroy() end
                end
            end)

            -- Quet map theo lo 4000 instance, yield giua cac lo
            pcall(function()
                local count = 0
                for _, object in ipairs(Workspace:GetDescendants()) do
                    stripInstance(object)
                    count = count + 1
                    if count % 4000 == 0 then
                        task.wait()
                    end
                end
            end)

            -- Instance sinh sau nay (skill effect, stream) cung bi strip
            Workspace.DescendantAdded:Connect(function(object)
                stripInstance(object)
            end)
        end)
    end

    optimizeWorld()
end

-- Temple of Time tu MapStash (v4.lua)
pcall(function()
    local mapStash = ReplicatedStorage:WaitForChild("MapStash", 5)
    local temple = mapStash and mapStash:WaitForChild("Temple of Time", 5)
    local map = Workspace:WaitForChild("Map", 5)
    if temple and map then
        temple.Parent = map
    end
end)

local Modules = ReplicatedStorage:WaitForChild("Modules", 10)
local Net = Modules and Modules:WaitForChild("Net", 10)
local CommF_ = ReplicatedStorage:WaitForChild("Remotes", 10)
    and ReplicatedStorage.Remotes:WaitForChild("CommF_", 10)
local CommE = nil
pcall(function()
    CommE = ReplicatedStorage:FindFirstChild("Remotes")
        and ReplicatedStorage.Remotes:FindFirstChild("CommE_")
end)

local RegisterAttack = nil
local RegisterHit = nil
pcall(function()
    if Net then
        local NetRequired = require(Net)
        if type(NetRequired) == "table" and type(NetRequired.RemoteEvent) == "function" then
            RegisterAttack = NetRequired:RemoteEvent("RegisterAttack", true)
            RegisterHit = NetRequired:RemoteEvent("RegisterHit", true)
        end
    end
end)
if not RegisterAttack and Net then
    RegisterAttack = Net:FindFirstChild("RE/RegisterAttack") or Net:WaitForChild("RE/RegisterAttack", 5)
end
if not RegisterHit and Net then
    RegisterHit = Net:FindFirstChild("RE/RegisterHit") or Net:WaitForChild("RE/RegisterHit", 5)
end

local GunValidator = nil
local ShootGunEvent = nil
pcall(function()
    if Net then
        GunValidator = Net:FindFirstChild("RE/GunValidate") or Net:FindFirstChild("GunValidator")
        ShootGunEvent = Net:FindFirstChild("RE/ShootGun") or Net:FindFirstChild("ShootGun")
    end
end)

local SEA1 = game.PlaceId == 2753915549 or game.PlaceId == 85211729168715
local SEA2 = game.PlaceId == 4442272183 or game.PlaceId == 79091703265657
local SEA3 = game.PlaceId == 7449423635 or game.PlaceId == 100117331123089

-- Mapping PlaceId -> Sea (changefg.lua) — dung runtime lookup thay vi local
-- bi freeze sau teleport (SEA1/SEA2/SEA3 khong cap nhat khi hop server)
local PLACE_TO_SEA = {
    [2753915549] = 1, [85211729168715] = 1,
    [4442272183] = 2, [79091703265657] = 2,
    [7449423635] = 3, [100117331123089] = 3,
}

function GetCurrentSea()
    return tonumber(PLACE_TO_SEA[tostring(game.PlaceId)]) or PLACE_TO_SEA[game.PlaceId] or 0
end

function IsInSea(seaNumber)
    return GetCurrentSea() == tonumber(seaNumber)
end

-- =====================================================================
-- STATUS LOG (thay UI cua v4.lua)
-- =====================================================================
currentTaskStatus = "starting"
currentSubTask = "starting"

function status(text)
    currentTaskStatus = tostring(text)
    print("[Kaitun] " .. tostring(text))
end

function substatus(text)
    currentSubTask = tostring(text)
end

function formatNumber(value)
    local n = tonumber(value) or 0
    local formatted = tostring(math.floor(n))
    while true do
        local k
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

-- Vai tro account: master engine chay tren acc chinh (Main). Acc phu (helper)
-- chay rieng theo phan Hub assignment phia duoi.
HelpWhitelist = {}
isallies = {}
isAlly = false
isUper = true
mainAccountName = ""

-- Forward declaration (gan body phia phan Trial)
local equipTrialCombatTool

-- =====================================================================
-- CORE: TWEEN / NOCLIP / AIM  (ke thua v4.lua:553-810)
-- =====================================================================
tweenNoclipConnection = nil
tweenCollisionStates = {}
extractOrbitAngle = 30
extractOrbitLastChange = tick()

local function setTweenNoclip(enabled)
    if enabled then
        if tweenNoclipConnection then
            return
        end
        -- Cache danh sach BasePart thay vi GetDescendants() moi frame
        -- (tạo bang moi lan go + walk cay = rac GC + frame spike)
        local cachedCharacter = nil
        local cachedParts = nil
        tweenNoclipConnection = RunService.Stepped:Connect(function()
            local character = Player.Character
            if not character then
                cachedCharacter = nil
                cachedParts = nil
                return
            end
            if character ~= cachedCharacter or cachedParts == nil then
                cachedCharacter = character
                cachedParts = {}
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        cachedParts[#cachedParts + 1] = part
                        if tweenCollisionStates[part] == nil then
                            tweenCollisionStates[part] = part.CanCollide
                        end
                    end
                end
            end
            for i = 1, #cachedParts do
                cachedParts[i].CanCollide = false
            end
        end)
        return
    end
    if tweenNoclipConnection then
        tweenNoclipConnection:Disconnect()
        tweenNoclipConnection = nil
    end
    for part, originalCanCollide in pairs(tweenCollisionStates) do
        if part.Parent then
            part.CanCollide = originalCanCollide
        end
    end
    table.clear(tweenCollisionStates)
end

-- CFrame.lookAt NaN khi direction song song up vector (Sea Beast trial
-- bay dung tren dau target). safeLookAt chon up=(0,0,-1) trong truong do.
function safeLookAt(position, target)
    local direction = target - position
    if direction.Magnitude < 0.05 then
        return CFrame.new(position)
    end
    local up = Vector3.new(0, 1, 0)
    if math.abs(direction.Unit.Y) > 0.999 then
        up = Vector3.new(0, 0, -1)
    end
    return CFrame.lookAt(position, target, up)
end

-- Aim target dung chung: _G.TRIAL_SKILL_TARGET chi song khi
-- _G.SHOULDSPAMSKILLS = true (trial Sea Beast); _G.SKILL_AIM_TARGET dung
-- cho moi truong hop khac (binh, Tyrant, mob): khong lock camera, chi
-- quay than nhan vat dung luc ban skill.
_G.SKILL_AIM_TARGET = nil
_G.TRIAL_SKILL_TARGET = nil
_G.SHOULDSPAMSKILLS = false
_G.TYRANT_FARMING = false

function getActiveAimPart()
    local trialTarget = _G.SHOULDSPAMSKILLS and _G.TRIAL_SKILL_TARGET
    if typeof(trialTarget) == "Instance" and trialTarget:IsA("BasePart") and trialTarget.Parent then
        return trialTarget, true
    end
    local aimTarget = _G.SKILL_AIM_TARGET
    if typeof(aimTarget) == "Instance" and aimTarget:IsA("BasePart") and aimTarget.Parent then
        return aimTarget, false
    end
    return nil, false
end

-- Tween ghi root CFrame moi Heartbeat (sau aim RenderStep) nen
-- CFrame.new(position) thuan se xoa rotation ma skill bay theo.
function trialAimLookCFrame(position)
    local target = getActiveAimPart()
    if target then
        return safeLookAt(position, target.Position)
    end
    return CFrame.new(position)
end

function normalizeTweenTarget(target)
    if typeof(target) == "CFrame" then
        return target
    end
    if typeof(target) == "Vector3" then
        return CFrame.new(target)
    end
    if typeof(target) == "Instance" then
        if target:IsA("BasePart") then
            return target.CFrame
        end
        if target:IsA("Model") then
            return target:GetPivot()
        end
    end
    return nil
end

-- Farm di chuyen quanh target thay vi bay 1 diem co dinh: goc orbit
-- tang 80 do moi 0.4 giay, ban kinh 40 studs, position lam tron 10.
function getExtractOrbitTarget(target, height)
    local targetCFrame = normalizeTweenTarget(target)
    if not targetCFrame then
        return nil
    end
    local now = tick()
    if now - extractOrbitLastChange > 0.4 then
        extractOrbitAngle = extractOrbitAngle + 80
        extractOrbitLastChange = now
        if extractOrbitAngle > 50000 then
            extractOrbitAngle = 60
        end
    end
    local radians = math.rad(extractOrbitAngle)
    local orbitPosition = targetCFrame.Position
        + Vector3.new(math.cos(radians) * 40, 0, math.sin(radians) * 40)
    local position = Vector3.new(
        math.floor(orbitPosition.X / 10) * 10,
        math.floor(orbitPosition.Y / 10) * 10 + (tonumber(height) or 35),
        math.floor(orbitPosition.Z / 10) * 10
    )
    return CFrame.new(position, targetCFrame.Position)
end

-- =====================================================================
-- MODULE M: tween/eq/haki/getdis (v4.lua "module")
-- =====================================================================
local M = {}
smoothTweenId = 0
smoothTweenRunning = false
smoothTweenTarget = nil
smoothTweenSpeed = 200
lastHakiRequestAt = 0

function M:eq()
    -- Equip melee (fallback khi khong tim duu ToolTip cu the)
    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if char:FindFirstChildOfClass("Tool") then return end
    local bp = Player:FindFirstChild("Backpack")
    if not bp then return end
    for _, tool in ipairs(bp:GetChildren()) do
        if tool:IsA("Tool") and (tool.ToolTip == "Melee" or tool.ToolTip == "Sword") then
            pcall(function() hum:EquipTool(tool) end)
            return
        end
    end
end

function M:haki()
    local character = Player.Character
    if character and not character:FindFirstChild("HasBuso") and tick() - lastHakiRequestAt >= 2 then
        lastHakiRequestAt = tick()
        CommF_:InvokeServer("Buso")
    end
end

function M:getdis(x, y)
    local xp
    if typeof(x) == "CFrame" then
        xp = x.Position
    elseif typeof(x) == "Vector3" then
        xp = x
    elseif typeof(x) == "Instance" then
        if x:IsA("BasePart") then
            xp = x.Position
        elseif x:IsA("Model") then
            xp = x:GetPivot().Position
        end
    end
    if not xp then return math.huge end
    local ref
    if y then
        if typeof(y) == "CFrame" then
            ref = y.Position
        elseif typeof(y) == "Vector3" then
            ref = y
        elseif typeof(y) == "Instance" then
            if y:IsA("BasePart") then
                ref = y.Position
            elseif y:IsA("Model") then
                ref = y:GetPivot().Position
            end
        end
    else
        local char = Player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        ref = hrp and hrp.Position or nil
    end
    if not ref then return math.huge end
    return (xp - ref).Magnitude
end

function M:stopTween()
    smoothTweenId = smoothTweenId + 1
    smoothTweenRunning = false
    smoothTweenTarget = nil
    setTweenNoclip(false)
end

function M:topos(target, speed, heightOffset, useNoclip, keepNoclip)
    local targetCFrame = normalizeTweenTarget(target)
    if not targetCFrame then
        return false
    end
    speed = tonumber(speed) or smoothTweenSpeed
    heightOffset = tonumber(heightOffset) or 0
    useNoclip = useNoclip == nil and true or useNoclip
    keepNoclip = keepNoclip == true
    if speed <= 0 then
        return false
    end

    local character = Player.Character or Player.CharacterAdded:Wait()
    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root then
        return false
    end
    if humanoid then
        humanoid.Sit = false
    end

    local destination = targetCFrame.Position + Vector3.new(0, heightOffset, 0)
    if smoothTweenRunning and smoothTweenTarget
        and (smoothTweenTarget.Position - destination).Magnitude < 1
    then
        return true
    end
    if smoothTweenRunning then
        self:stopTween()
    end

    local startPosition = root.Position
    local distance = (destination - startPosition).Magnitude
    if distance <= 0.05 then
        root.CFrame = trialAimLookCFrame(destination)
        if not keepNoclip then
            self:stopTween()
        else
            smoothTweenRunning = false
            smoothTweenTarget = nil
        end
        return true
    end

    smoothTweenId = smoothTweenId + 1
    local currentTweenId = smoothTweenId
    smoothTweenTarget = CFrame.new(destination)
    smoothTweenRunning = true
    setTweenNoclip(useNoclip)

    local duration = distance / speed
    local startedAt = tick()
    while currentTweenId == smoothTweenId do
        character = Player.Character
        local current = character and character:FindFirstChild("HumanoidRootPart")
        if current ~= root then break end
        local progress = math.min((tick() - startedAt) / duration, 1)
        root.CFrame = CFrame.new(startPosition:Lerp(destination, progress))
        if progress >= 1 then break end
        RunService.Heartbeat:Wait()
    end
    if currentTweenId == smoothTweenId then
        smoothTweenRunning = false
        smoothTweenTarget = nil
        if not keepNoclip then
            setTweenNoclip(false)
        end
    end
    return true
end

function topos(target, speed, heightOffset, useNoclip, keepNoclip)
    return M:topos(target, speed, heightOffset, useNoclip, keepNoclip)
end

function StopTween()
    return M:stopTween()
end

function getdis(...)
    return M:getdis(...)
end

-- getPortal toi uu (v3.lua)
function getPortal(check2)
    local check3 = check2.Position
    local gQ = {}
    if game.PlaceId == 2753915549 then
        gQ = { Vector3.new(-7894.6, 5545.5, -380.2), Vector3.new(-4607.8, 872.5, -1667.5),
            Vector3.new(61163.8, 11.7, 1819.7), Vector3.new(3876.2, 35.1, -1939.3) }
    elseif game.PlaceId == 4442272183 then
        gQ = { Vector3.new(-288.4, 306.1, 597.9), Vector3.new(2284.9, 15.1, 905.4),
            Vector3.new(923.2, 126.9, 32852.8), Vector3.new(-6508.5, 89.0, -132.8) }
    elseif game.PlaceId == 7449423635 then
        gQ = { Vector3.new(-5058.7, 314.5, -3155.8), Vector3.new(5756.8, 610.4, -253.9),
            Vector3.new(-12463.8, 374.9, -7523.7), Vector3.new(28282.5, 14896.8, 105.1),
            Vector3.new(-11993.5, 334.7, -8844.1), Vector3.new(5314.5, 25.4, -125.9) }
    end
    local aM, aN = Vector3.new(0, 0, 0), math.huge
    for _, aL in pairs(gQ) do
        if (aL - check3).Magnitude < aN then
            aM, aN = aL, (aL - check3).Magnitude
        end
    end
    return aM
end

-- =====================================================================
-- CORE: FAST ATTACK CLASS (v4.lua:1504-1746)
-- =====================================================================
local FastAttack = {}
FastAttack.__index = FastAttack

function FastAttack.new()
    local self = setmetatable({
        Debounce = 0,
        ComboDebounce = 0,
        ShootDebounce = 0,
        M1Combo = 0,
        EnemyRootPart = nil,
        Connections = {},
        Overheat = {
            Dragonstorm = {
                MaxOverheat = 3,
                Cooldown = 0,
                TotalOverheat = 0,
                Distance = 350,
                Shooting = false
            }
        },
        ShootsPerTarget = {
            ["Dual Flintlock"] = 2
        },
        SpecialShoots = {
            ["Skull Guitar"] = "TAP",
            ["Bazooka"] = "Position",
            ["Cannon"] = "Position",
            ["Dragonstorm"] = "Overheat"
        }
    }, FastAttack)
    pcall(function()
        self.CombatFlags = require(Modules.Flags).COMBAT_REMOTE_THREAD
        self.ShootFunction = getupvalue(require(ReplicatedStorage.Controllers.CombatController).Attack, 9)
        local LocalScript = Player:WaitForChild("PlayerScripts"):FindFirstChildOfClass("LocalScript")
        if LocalScript and getsenv then
            self.HitFunction = getsenv(LocalScript)._G.SendHitsToServer
        end
    end)
    return self
end

function FastAttack:IsEntityAlive(entity)
    if not entity or not entity.Parent then return false end
    local humanoid = entity:FindFirstChildOfClass("Humanoid") or entity:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

function FastAttack:CheckStun(Character, Humanoid, ToolTip)
    if not Character or not Humanoid then return false end
    if Humanoid.Sit then
        pcall(function() Humanoid.Sit = false end)
    end
    local Stun = Character:FindFirstChild("Stun")
    if Stun and Stun.Value > 0 then
        pcall(function() Stun.Value = 0 end)
    end
    local Busy = Character:FindFirstChild("Busy")
    if Busy and Busy.Value then
        pcall(function() Busy.Value = false end)
    end
    return true
end

function FastAttack:GetBladeHits(Character, Distance)
    local Position = Character:GetPivot().Position
    local targets = {}
    Distance = Distance or AttackConfig.AttackDistance or 65
    local function ProcessTargets(Folder)
        if not Folder then return end
        for _, Enemy in ipairs(Folder:GetChildren()) do
            pcall(function()
                if Enemy ~= Character and self:IsEntityAlive(Enemy) then
                    local BasePart = Enemy:FindFirstChild("HumanoidRootPart")
                        or Enemy:FindFirstChild("Head")
                        or Enemy:FindFirstChild("UpperTorso")
                        or Enemy:FindFirstChild("Torso")
                        or Enemy.PrimaryPart
                    if BasePart and (Position - BasePart.Position).Magnitude <= Distance then
                        table.insert(targets, Enemy)
                    end
                end
            end)
        end
    end
    if AttackConfig.AttackMobs then
        pcall(ProcessTargets, Workspace:FindFirstChild("Enemies"))
        local origin = Workspace:FindFirstChild("_WorldOrigin")
        if origin and origin:FindFirstChild("Enemies") then
            pcall(ProcessTargets, origin.Enemies)
        end
        local mobsFolder = Workspace:FindFirstChild("Mobs")
        if mobsFolder then
            pcall(ProcessTargets, mobsFolder)
        end
        local npcsFolder = Workspace:FindFirstChild("NPCs")
        if npcsFolder then
            pcall(ProcessTargets, npcsFolder)
        end
    end
    if AttackConfig.AttackPlayers then
        pcall(ProcessTargets, Workspace:FindFirstChild("Characters"))
    end
    return targets
end

function FastAttack:GetClosestEnemy(Character, Distance)
    local targets = self:GetBladeHits(Character, Distance)
    local Closest, MinDistance = nil, math.huge
    for _, Enemy in ipairs(targets) do
        local part = Enemy:FindFirstChild("HumanoidRootPart") or Enemy:FindFirstChild("Head") or Enemy.PrimaryPart
        if part then
            local Magnitude = (Character:GetPivot().Position - part.Position).Magnitude
            if Magnitude < MinDistance then
                MinDistance = Magnitude
                Closest = part
            end
        end
    end
    return Closest
end

function FastAttack:GetCombo()
    local Combo = (tick() - self.ComboDebounce) <= AttackConfig.ComboResetTime and self.M1Combo or 0
    Combo = Combo >= AttackConfig.MaxCombo and 1 or Combo + 1
    self.ComboDebounce = tick()
    self.M1Combo = Combo
    return Combo
end

function FastAttack:ShootInTarget(TargetPosition)
    local Character = Player.Character
    if not self:IsEntityAlive(Character) then
        return
    end
    local Equipped = Character:FindFirstChildOfClass("Tool")
    if not Equipped or Equipped.ToolTip ~= "Gun" then
        return
    end
    local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or 0.3
    if (tick() - self.ShootDebounce) < Cooldown then
        return
    end
    local ShootType = self.SpecialShoots[Equipped.Name] or "Normal"
    if ShootType == "Position" or (ShootType == "TAP" and Equipped:FindFirstChild("RemoteEvent")) then
        Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
        if GunValidator and self.ShootFunction then
            pcall(function() GunValidator:FireServer(self:GetValidator2()) end)
        end
        if ShootType == "TAP" then
            Equipped.RemoteEvent:FireServer("TAP", TargetPosition)
        elseif ShootGunEvent then
            ShootGunEvent:FireServer(TargetPosition)
        end
        self.ShootDebounce = tick()
    else
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        self.ShootDebounce = tick()
    end
end

function FastAttack:GetValidator2()
    local v1 = getupvalue(self.ShootFunction, 15)
    local v2 = getupvalue(self.ShootFunction, 13)
    local v3 = getupvalue(self.ShootFunction, 16)
    local v4 = getupvalue(self.ShootFunction, 17)
    local v5 = getupvalue(self.ShootFunction, 14)
    local v6 = getupvalue(self.ShootFunction, 12)
    local v7 = getupvalue(self.ShootFunction, 18)
    local v8 = v6 * v2
    local v9 = (v5 * v2 + v6 * v1) % v3
    v9 = (v9 * v3 + v8) % v4
    v5 = math.floor(v9 / v3)
    v6 = v9 - v5 * v3
    v7 = v7 + 1
    setupvalue(self.ShootFunction, 15, v1)
    setupvalue(self.ShootFunction, 13, v2)
    setupvalue(self.ShootFunction, 16, v3)
    setupvalue(self.ShootFunction, 17, v4)
    setupvalue(self.ShootFunction, 14, v5)
    setupvalue(self.ShootFunction, 12, v6)
    setupvalue(self.ShootFunction, 18, v7)
    return math.floor(v9 / v4 * 16777215), v7
end

function FastAttack:UseNormalClick(Character, Humanoid, Cooldown, Combo)
    local targets = self:GetBladeHits(Character)
    if #targets > 0 then
        FireDamageToTargets(targets)
        pcall(function()
            local tool = Character:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
        end)
        pcall(function()
            local VirtualUser = game:GetService("VirtualUser")
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(851, 158))
        end)
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end)
    end
end

function FastAttack:UseFruitM1(Character, Equipped, Combo)
    local targets = self:GetBladeHits(Character)
    if not targets[1] then
        return
    end
    local part = targets[1]:FindFirstChild("HumanoidRootPart") or targets[1]:FindFirstChild("Head") or targets[1].PrimaryPart
    if not part then return end
    local Direction = (part.Position - Character:GetPivot().Position).Unit
    Equipped.LeftClickRemote:FireServer(Direction, Combo)
end

function FastAttack:Attack()
    if not AttackConfig.AutoClickEnabled or (tick() - self.Debounce) < AttackConfig.AttackCooldown then
        return
    end
    local Character = Player.Character
    if not Character or not self:IsEntityAlive(Character) then
        return
    end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid") or Character:FindFirstChild("Humanoid")
    local Equipped = Character:FindFirstChildOfClass("Tool")
    if not Equipped then
        if equipTrialCombatTool then equipTrialCombatTool() end
        Equipped = Character:FindFirstChildOfClass("Tool")
    end
    local ToolTip = Equipped and Equipped.ToolTip or "Melee"
    local Cooldown = AttackConfig.AttackCooldown or 0.05
    self.Debounce = tick()
    if ToolTip == "Blox Fruit" and Equipped and Equipped:FindFirstChild("LeftClickRemote") then
        self:UseFruitM1(Character, Equipped, 1)
    elseif ToolTip == "Gun" and Equipped then
        local Target = self:GetClosestEnemy(Character, 120)
        if Target then
            self:ShootInTarget(Target.Position)
        end
    else
        self:UseNormalClick(Character, Humanoid, Cooldown, 1)
    end
end

-- Combat controller chay tren moi physics step.
-- _G.TYRANT_FARMING: khi farm Tyrant, TyrFastAttack la nguon duy nhat
-- ban RegisterAttack/RegisterHit — hai luong cung ban se bi server
-- rate-validate va drop het ("attack loi").
local previousAttackConnection = getgenv().__KAITUN_ATTACK_CONNECTION
if previousAttackConnection then
    pcall(function()
        previousAttackConnection:Disconnect()
    end)
end
local AttackInstance = FastAttack.new()
local attackConnection = RunService.Stepped:Connect(function()
    if AttackConfig.AutoClickEnabled and not _G.TYRANT_FARMING then
        pcall(function()
            M:haki()
            AttackInstance:Attack()
        end)
    end
end)
table.insert(AttackInstance.Connections, attackConnection)
getgenv().__KAITUN_ATTACK_CONNECTION = attackConnection

-- =====================================================================
-- CORE: XOR ENCRYPTED HIT BYPASS (v4.lua:143-249)
-- =====================================================================
local _seed = nil
local _remoteAttack = nil
local _remoteId = nil

local function GetBloxRemoteAttack()
    if _remoteAttack and _remoteAttack.Parent and _remoteId then
        return true
    end
    _remoteAttack, _remoteId = nil, nil
    for _, folderName in ipairs({ "Util", "Common", "Remotes", "Assets", "FX" }) do
        local folder = ReplicatedStorage:FindFirstChild(folderName)
        if folder then
            for _, obj in ipairs(folder:GetChildren()) do
                if obj:IsA("RemoteEvent") and obj:GetAttribute("Id") then
                    _remoteAttack, _remoteId = obj, obj:GetAttribute("Id")
                    return true
                end
            end
        end
    end
    return false
end

local function FireEncryptedHit(hitData)
    if not _seed and Net then
        pcall(function()
            local seedRemote = Net:FindFirstChild("seed") or Net:WaitForChild("seed", 2)
            if seedRemote then _seed = seedRemote:InvokeServer() end
        end)
    end
    if not GetBloxRemoteAttack() or not _seed then return end
    pcall(function()
        local encodedName = string.gsub("RE/RegisterHit", ".", function(c)
            return string.char(bit32.bxor(string.byte(c),
                math.floor(Workspace:GetServerTimeNow() / 10 % 10) + 1))
        end)
        _remoteAttack:FireServer(encodedName,
            bit32.bxor(_remoteId + 909090, _seed * 2),
            unpack(hitData))
    end)
end

function FireDamageToTargets(targets)
    if not targets or #targets == 0 then return false end
    local hitData = { [1] = nil, [2] = {}, [4] = "078da5141" }
    for _, enemy in ipairs(targets) do
        if enemy and enemy.Parent then
            local hitPart = enemy:FindFirstChild("Head")
                or enemy:FindFirstChild("HumanoidRootPart")
                or enemy:FindFirstChild("UpperTorso")
                or enemy.PrimaryPart
            local hrp = enemy:FindFirstChild("HumanoidRootPart")
                or enemy:FindFirstChild("UpperTorso")
                or hitPart
            if hitPart and hrp then
                if not hitData[1] then hitData[1] = hitPart end
                table.insert(hitData[2], { [1] = enemy, [2] = hrp })
            end
        end
    end
    if not hitData[1] or #hitData[2] == 0 then return false end
    -- 0 Cooldown RegisterAttack + RegisterHit + XOR pipeline
    pcall(function()
        if RegisterAttack then RegisterAttack:FireServer(0) end
        local rawA = Net and Net:FindFirstChild("RE/RegisterAttack")
        if rawA and rawA ~= RegisterAttack then rawA:FireServer(0) end
    end)
    pcall(function()
        if RegisterHit then RegisterHit:FireServer(unpack(hitData)) end
        local rawH = Net and Net:FindFirstChild("RE/RegisterHit")
        if rawH and rawH ~= RegisterHit then rawH:FireServer(unpack(hitData)) end
    end)
    pcall(FireEncryptedHit, hitData)
    return true
end

-- extractAttack (v4.lua:1772-1853): hit list theo cap {entity, part} roi
-- mot bang rong dem sau moi cap — day thang entity lech cap phia sau lam
-- huy ca goi hit (server bug bypass).
local lastExtractAttackAt = -math.huge
local function getExtractAttackTargets()
    local character = Player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return {}
    end
    local targets = {}
    local function collect(folder)
        if not folder then
            return
        end
        for _, entity in ipairs(folder:GetChildren()) do
            if entity ~= character then
                local humanoid = entity:FindFirstChild("Humanoid")
                local entityRoot = entity:FindFirstChild("HumanoidRootPart")
                if humanoid and entityRoot and humanoid.Health > 0
                    and (entityRoot.Position - root.Position).Magnitude <= AttackConfig.AttackDistance
                then
                    targets[#targets + 1] = entity
                end
            end
        end
    end
    if AttackConfig.AttackMobs then
        collect(Workspace:FindFirstChild("Enemies"))
        local origin = Workspace:FindFirstChild("_WorldOrigin")
        if origin and origin:FindFirstChild("Enemies") then
            collect(origin.Enemies)
        end
        collect(Workspace:FindFirstChild("Mobs"))
        collect(Workspace:FindFirstChild("NPCs"))
    end
    if AttackConfig.AttackPlayers then
        collect(Workspace:FindFirstChild("Characters"))
    end
    return targets
end

function extractAttack()
    if not AttackConfig.AutoClickEnabled then
        return false
    end
    if tick() - lastExtractAttackAt < AttackConfig.AttackCooldown then
        return false
    end
    local targets = getExtractAttackTargets()
    if #targets == 0 then
        return false
    end
    local firstHit = nil
    local hitList = {}
    for _, entity in ipairs(targets) do
        local hitPart = entity:FindFirstChild("Head") or entity:FindFirstChild("HumanoidRootPart")
        local entityRoot = entity:FindFirstChild("HumanoidRootPart")
        if hitPart and entityRoot then
            firstHit = firstHit or hitPart
            hitList[#hitList + 1] = { entity, entityRoot }
            hitList[#hitList + 1] = {}
        end
    end
    if not firstHit then
        return false
    end
    local extractCombo = AttackInstance and AttackInstance:GetCombo() or 1
    local extractCooldown = extractCombo >= (AttackConfig.MaxCombo or 4) and 0.9 or 0.4
    pcall(function()
        RegisterAttack:FireServer(extractCooldown, extractCombo)
    end)
    pcall(function()
        RegisterHit:FireServer(firstHit, hitList, nil, "078da5141")
    end)
    lastExtractAttackAt = tick()
    return true
end

-- =====================================================================
-- CORE: TIEN ICH
-- =====================================================================
function CheckAlive(x)
    return x and x.Parent
        and x:FindFirstChild("Humanoid")
        and x:FindFirstChild("HumanoidRootPart")
        and x.Humanoid.Health > 0
end

function DetectMob(c)
    if not Workspace:FindFirstChild("Enemies") then return nil end
    local dist, name = math.huge, nil
    for _, v in pairs(Workspace.Enemies:GetChildren()) do
        local stripped = v.Name:gsub(" %pLv. %d+%p", "")
        if (typeof(c) == "table" and (table.find(c, v.Name) or table.find(c, stripped)))
            or v.Name == c or c == stripped then
            if v:IsA("Model") and CheckAlive(v) then
                local m = (v.HumanoidRootPart.Position
                    - Player.Character.HumanoidRootPart.Position).Magnitude
                if m < dist then dist, name = m, v end
            end
        end
    end
    return name
end

function CheckStore(x)
    local ok, inv = pcall(function()
        return CommF_:InvokeServer("getInventory")
    end)
    if not ok or type(inv) ~= "table" then return 0 end
    for _, v in pairs(inv) do
        if v.Name == x then return v.Count or 1 end
    end
    return 0
end

function CheckTool(v)
    return plr.Backpack:FindFirstChild(v)
        or (plr.Character and plr.Character:FindFirstChild(v))
end

function checkbackpack(v)
    local backpack = Player:FindFirstChildOfClass("Backpack")
    local character = Player.Character
    return (backpack and backpack:FindFirstChild(v)) or (character and character:FindFirstChild(v))
end

function EquipWeapon(toolName)
    if plr.Backpack:FindFirstChild(toolName) then
        pcall(function()
            plr.Character.Humanoid:EquipTool(plr.Backpack[toolName])
        end)
    end
end

function NameWeapon(x)
    local a
    for _, v in pairs(plr.Backpack:GetChildren()) do
        if v:IsA("Tool") and v.ToolTip == x then a = v.Name end
    end
    if plr.Character then
        for _, v in pairs(plr.Character:GetChildren()) do
            if v:IsA("Tool") and v.ToolTip == x then a = v.Name end
        end
    end
    return a
end

function AutoBusoAndMelee()
    local char = plr.Character
    if char and not char:FindFirstChild("HasBuso") then
        pcall(function() CommF_:InvokeServer("Buso") end)
    end
    local melee = NameWeapon("Melee")
    if melee then EquipWeapon(melee) end
end

function getBeli()
    local ok, v = pcall(function() return plr.Data.Beli.Value end)
    return ok and (tonumber(v) or 0) or 0
end

function getFrags()
    local ok, v = pcall(function() return plr.Data.Fragments.Value end)
    return ok and (tonumber(v) or 0) or 0
end

function getRace()
    local ok, v = pcall(function() return tostring(plr.Data.Race.Value) end)
    return ok and v or "Unknown"
end

function getLocalRaceName()
    local ok, v = pcall(function() return tostring(LocalPlayer.Data.Race.Value) end)
    return ok and v or ""
end

function canonicalRaceName(race)
    race = tostring(race or "")
    return race_name_aliases[race] or race
end

race_abilities = {
    ["Human"] = "Last Resort",
    ["Mink"] = "Agility",
    ["Fishman"] = "Water Body",
    ["Skypiea"] = "Heavenly Blood",
    ["Ghoul"] = "Heightened Senses",
    ["Cyborg"] = "Energy Core"
}

race_name_aliases = {
    Rabbit = "Mink",
    Shark = "Fishman",
    Angel = "Skypiea"
}

function isnight()
    local c = Lighting.ClockTime
    return c >= 18 or c < 5
end

function isfullmoon()
    return Lighting:GetAttribute("MoonPhase") == 5
end

-- getFullMoonTimeRemaining (v4.lua:1088-1150)
function getFullMoonTimeRemaining()
    local moonPhase = tonumber(Lighting:GetAttribute("MoonPhase"))
    local clockTime = tonumber(Lighting.ClockTime) or 12
    clockTime = clockTime % 24
    local isNight = (clockTime >= 18 or clockTime < 5)

    local isFM = (moonPhase == 5) and isNight

    if not isFM and isNight and moonPhase == nil then
        local sky = Lighting:FindFirstChildOfClass("Sky")
        local moonTexture = sky and tostring(sky.MoonTextureId) or ""
        isFM = (moonTexture:find("970914431", 1, true) ~= nil)
    end

    if not isFM then
        return {
            isFullMoon = false,
            isActive = false,
            moonPhase = moonPhase or 0,
            secondsRemaining = 0,
            secondsToStart = 0,
            formatted = "NO FULL MOON",
            shortFormatted = "NO FM"
        }
    end

    if isNight then
        local hoursRemaining = (clockTime >= 18) and ((24 - clockTime) + 5) or (5 - clockTime)
        local secondsRemaining = math.max(0, math.floor(hoursRemaining * 25))
        local m = math.floor(secondsRemaining / 60)
        local s = secondsRemaining % 60
        local timeStr = string.format("%02d:%02d", m, s)
        return {
            isFullMoon = true,
            isActive = true,
            moonPhase = moonPhase or 5,
            secondsRemaining = secondsRemaining,
            secondsToStart = 0,
            formatted = string.format("FULL MOON (Ends %s)", timeStr),
            shortFormatted = string.format("FM (%s)", timeStr)
        }
    else
        local hoursToStart = math.max(0, 18 - clockTime)
        local secondsToStart = math.max(0, math.floor(hoursToStart * 25))
        local totalHoursRemaining = hoursToStart + 11
        local secondsRemaining = math.max(0, math.floor(totalHoursRemaining * 25))
        local m = math.floor(secondsToStart / 60)
        local s = secondsToStart % 60
        local timeStr = string.format("%02d:%02d", m, s)
        return {
            isFullMoon = true,
            isActive = false,
            moonPhase = moonPhase or 5,
            secondsRemaining = secondsRemaining,
            secondsToStart = secondsToStart,
            formatted = string.format("FULL MOON IN %s", timeStr),
            shortFormatted = string.format("FM in %s", timeStr)
        }
    end
end

-- getdoor (v4.lua:877-896): cua trial cua race trong Temple of Time
function getdoor(vv)
    if not vv then
        vv = getLocalRaceName()
    end
    local corridorRaceAliases = { Rabbit = "Mink", Shark = "Fishman", Angel = "Skypiea" }
    vv = corridorRaceAliases[tostring(vv)] or tostring(vv)
    local temple = Workspace.Map:FindFirstChild("Temple of Time")
    if not temple then
        return nil
    end
    local corridor = temple:FindFirstChild(vv .. "Corridor")
    if not corridor then
        return nil
    end
    local door = corridor:FindFirstChild("Door")
    if not door then
        return nil
    end
    return door:FindFirstChild("Entrance")
end

pos_plr_trial = {
    CFrame.new(28692.3477, 14887.5605, -53.7669983),
    CFrame.new(28782.7246, 14898.9902, -59.6069946),
    CFrame.new(28700.875, 14888.2598, -154.110992),
    CFrame.new(28795.7715, 14888.2598, -112.917999),
    CFrame.new(28658.4551, 14888.2598, -121.372009),
    CFrame.new(28742.4688, 14887.5596, -18.2120056)
}

function isplrshouldkill(p)
    if p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
        for _, v in pairs(pos_plr_trial) do
            if getdis(p.Character.HumanoidRootPart.CFrame, v) < 5 then
                return true
            end
        end
    end
    return false
end

function updateplayers()
    if not _G.playersinserver then
        _G.playersinserver = {}
    end
    local players = {}
    for _, v in pairs(Players:GetChildren()) do
        pcall(function()
            local data = v:FindFirstChild("Data")
            local raceObj = data and data:FindFirstChild("Race")
            local raceVal = raceObj and raceObj.Value
            if raceVal then
                local doorEntrance = nil
                pcall(function()
                    local map = Workspace:FindFirstChild("Map")
                    local temple = map and map:FindFirstChild("Temple of Time")
                    local corridor = temple and temple:FindFirstChild(raceVal .. "Corridor")
                    local door = corridor and corridor:FindFirstChild("Door")
                    doorEntrance = door and door:FindFirstChild("Entrance")
                end)
                players[v] = {
                    ["Race"] = raceVal,
                    ["Door"] = doorEntrance
                }
            end
        end)
    end
    _G.playersinserver = players
end

function isshouldturnonability()
    local count = 0
    for _, v in pairs(Workspace.Characters:GetChildren()) do
        if v.Name ~= Player.Name and v:FindFirstChild("HumanoidRootPart") then
            local theirrace = Players:FindFirstChild(v.Name).Data.Race.Value
            local corridor = Workspace.Map["Temple of Time"]:FindFirstChild(theirrace .. "Corridor")
            local race_door = corridor and corridor:FindFirstChild("Door")
            race_door = race_door and race_door:FindFirstChild("Entrance")
            local abilityName = race_abilities[canonicalRaceName(theirrace)]
            if race_door and abilityName and getdis(race_door.CFrame, v.HumanoidRootPart.CFrame) < 10 then
                if v.HumanoidRootPart:FindFirstChild(abilityName) then
                    count = count + 1
                end
            end
        end
    end
    return count >= 2
end

function getCurrentJobId()
    return game.JobId
end

function readJobId(value, fallback)
    if type(value) == "string" and value ~= "" then
        return value
    end
    if type(value) == "table" then
        return tostring(value.id or value.jobId or value.JobId or fallback or "")
    end
    return fallback or ""
end

function readPlaceId(value, fallback)
    local pid = tonumber(value)
    if pid then return pid end
    if type(value) == "table" then
        pid = tonumber(value.placeId or value.PlaceId or value.placeid)
        if pid then return pid end
    end
    return fallback
end
-- =====================================================================
-- PHAN 2: V4 STATUS / GEAR / TEMPLE / V3 SYNC / TRAINING / SMART TP / TRIAL
-- (port verbatim v4.lua 931-4300)
-- =====================================================================

trial_location_names = {
	Human = "Trial of Strength",
	Mink = "Trial of Speed",
	Fishman = "Trial of Water",
	Skypiea = "Trial of the King",
	Ghoul = "Trial of Carnage",
	Cyborg = "Trial of the Machine"
}

races_trial_place = setmetatable({}, {
	__index = function(_, key)
		local race = canonicalRaceName(key)
		local locName = trial_location_names[race]
		if not locName then return nil end
		local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
		local locations = worldOrigin and worldOrigin:FindFirstChild("Locations")
		return locations and locations:FindFirstChild(locName)
	end
})

function getOwnTrialLocation()
	local race = canonicalRaceName(getLocalRaceName())
	return race, races_trial_place[race]
end

function getmob1(pos)
	local allmobs = {}
	for i, v in pairs(workspace.Enemies:GetChildren()) do
		if v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid")
			and v.Humanoid.Health > 0 and getdis(v.HumanoidRootPart.CFrame, pos) < 1000 then
			table.insert(allmobs, v)
		end
	end
	return allmobs
end

function checkmob_(v)
	return v and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0
end

function noideaforname(v)
	if isallies[v.Name] then
		return false
	end
	return true
end

function getplayers(all)
	local plrs = {}
	for i, v in pairs(game.Players:GetPlayers()) do
		if v ~= plr and v.Character then
			if all then
				if v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("HumanoidRootPart") and v.Character.Humanoid.Health > 0 then
					for _, pos in pairs(pos_plr_trial) do
						if getdis(v.Character.HumanoidRootPart.CFrame, pos) < 10 then
							plrs[v.Character] = true
						end
					end
				end
			else
				if v ~= game.Players:FindFirstChild(mainAccountName) and noideaforname(v) then
					if v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("HumanoidRootPart") and v.Character.Humanoid.Health > 0 then
						for _, pos in pairs(pos_plr_trial) do
							if getdis(v.Character.HumanoidRootPart.CFrame, pos) < 10 then
								plrs[v.Character] = true
							end
						end
					end
				end
			end
		end
	end
	return plrs
end

function getCurrentPos()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		return root.CFrame
	end
	return CFrame.new()
end

-- ============ V4 STATUS (v4.lua 1208-1480) ============
V4StatusCache = { at = 0, data = nil }
local V4_STATUS_CACHE_TIME = 5

function invokeUpgradeRace(action)
	return CommF_:InvokeServer("UpgradeRace", action, 1)
end

function invalidateV4Status()
	V4StatusCache.at = 0
	V4StatusCache.data = nil
end

function readRaceV4Progress()
	local ok, progress = pcall(function()
		return CommF_:InvokeServer("RaceV4Progress", "Check")
	end)
	if ok then
		return tonumber(progress)
	end
	return nil
end

local v4Started = false
function talktoonggianaodo()
	if v4Started then
		return
	end
	v4Started = true
	local ok, thua = pcall(function()
		return CommF_:InvokeServer("RaceV4Progress", "Check")
	end)
	if not ok then
		v4Started = false
		return
	end
	if thua == 1 then
		pcall(function()
			CommF_:InvokeServer("RaceV4Progress", "Check")
		end)
		pcall(function()
			CommF_:InvokeServer("RaceV4Progress", "Begin")
		end)
	elseif thua == 2 then
		local startAt = tick()
		repeat
			task.wait(0.5)
			pcall(function()
				CommF_:InvokeServer("RaceV4Progress", "Teleport")
			end)
			pcall(function()
				topos(CFrame.new(3028, 2281, -7325))
			end)
		until M:getdis(CFrame.new(28286.35546875, 14896.5078125, 102.62469482422)) <= 15 or tick() - startAt > 30
	else
		pcall(function()
			CommF_:InvokeServer("RaceV4Progress", "Check")
		end)
		task.wait(1)
		pcall(function()
			CommF_:InvokeServer("RaceV4Progress", "Continue")
		end)
	end
	v4Started = false
end

function getBlueGear()
	if not workspace.Map:FindFirstChild("MysticIsland") then
		return nil
	end
	for o, c in pairs(workspace.Map.MysticIsland:GetChildren()) do
		if c:IsA("MeshPart") and c.MeshId == "rbxassetid://10153114969" then
			return c
		end
	end
end

function getV4Status(forceRefresh)
	if not forceRefresh and V4StatusCache.data and tick() - V4StatusCache.at < V4_STATUS_CACHE_TIME then
		return V4StatusCache.data
	end
	local state = {
		key = "unknown",
		label = "UNKNOWN",
		detail = "Unable to read Race V4 status",
		code = nil,
		progress = nil,
		cost = 0,
		canTrial = false,
		needsTraining = false,
		needsPurchase = false,
		needsGearClaim = false,
		complete = false,
		remainingTraining = nil,
		completedTraining = nil,
		gear = nil,
		race = getLocalRaceName(),
		energy = 0,
		transformed = false
	}
	local character = Players.LocalPlayer.Character
	if not character then
		state.key = "waiting_character"
		state.label = "WAITING CHARACTER"
		state.detail = "Waiting for character to load"
		V4StatusCache.at = tick()
		V4StatusCache.data = state
		return state
	end
	local raceEnergy = character:FindFirstChild("RaceEnergy")
	local raceTransformed = character:FindFirstChild("RaceTransformed")
	if raceEnergy then
		state.energy = tonumber(raceEnergy.Value) or 0
	end
	if raceTransformed then
		state.transformed = raceTransformed.Value == true
	end
	if not raceTransformed then
		local progress = readRaceV4Progress()
		local abilityName = race_abilities[canonicalRaceName(state.race)]
		local hasV3Ability = abilityName and checkbackpack(abilityName) ~= nil
		state.progress = progress
		if progress == nil then
			state.key = "check_failed"
			state.label = "V4 CHECK FAILED"
			state.detail = "RaceV4Progress Check returned no valid status"
		elseif hasV3Ability and progress >= 4 then
			state.key = "first_trial_ready"
			state.label = "FIRST TRIAL READY"
			state.detail = "V3 is ready; waiting for Full Moon trial"
			state.canTrial = true
		elseif progress == 0 then
			state.key = "v4_quest_not_started"
			state.label = "V4 QUEST NOT STARTED"
			state.detail = "Defeat rip_indra and begin the Race V4 quest"
		elseif progress == 1 then
			state.key = "v4_quest_begin"
			state.label = "BEGIN V4 QUEST"
			state.detail = "Talk to Sealed King to begin the Great Tree step"
		elseif progress == 2 then
			state.key = "go_great_tree"
			state.label = "GO TO GREAT TREE"
			state.detail = "Use the Great Tree entrance to reach Temple of Time"
		elseif progress == 3 then
			state.key = "continue_v4_quest"
			state.label = "CONTINUE V4 QUEST"
			state.detail = "Return to Sealed King and continue the quest"
		elseif progress == 4 or progress == 5 then
			state.key = "first_trial_preparation"
			state.label = "FIRST TRIAL PREPARATION"
			state.detail = hasV3Ability and "V3 detected; preparing first trial" or "V3 ability was not detected"
			state.canTrial = hasV3Ability
		else
			state.key = "starting_v4"
			state.label = "STARTING V4 PROCESS"
			state.detail = "Completing the Race V4 prerequisite steps"
		end
		if isAlly then
			state.complete = false
			state.canTrial = true
			state.needsPurchase = false
			state.needsTraining = false
			state.key = "trial_ready"
			state.label = "READY FOR TRIAL"
			state.detail = "Helper is ready to support"
		end
		V4StatusCache.at = tick()
		V4StatusCache.data = state
		return state
	end
	local ok, code, progress, cost = pcall(function()
		return invokeUpgradeRace("Check")
	end)
	if not ok then
		state.key = "check_failed"
		state.label = "V4 CHECK FAILED"
		state.detail = "UpgradeRace Check remote failed"
		V4StatusCache.at = tick()
		V4StatusCache.data = state
		return state
	end
	code = tonumber(code)
	progress = tonumber(progress)
	cost = tonumber(cost) or 0
	if cost <= 0 and code then
		local fallbackCosts = {
			[2] = 1000,
			[4] = 2000,
			[7] = 3250,
			[9] = 4000,
		}
		cost = fallbackCosts[code] or 0
	end
	state.code = code
	state.progress = progress
	state.cost = cost
	if code == 0 then
		state.key = "trial_ready"
		state.label = "READY FOR TRIAL"
		state.detail = "Training requirement completed"
		state.canTrial = true
		state.gear = progress
	elseif code == 1 then
		state.key = "training_stage_1"
		state.label = "TRAINING REQUIRED"
		state.detail = "Train Race V4 energy before the next upgrade"
		state.needsTraining = true
	elseif code == 2 then
		state.key = "buy_gear_1"
		state.label = "BUY NEXT GEAR"
		state.detail = "First Race V4 gear upgrade is available"
		state.needsPurchase = true
	elseif code == 3 then
		state.key = "training_stage_2"
		state.label = "TRAINING REQUIRED"
		state.detail = "Train again to improve transformation duration"
		state.needsTraining = true
	elseif code == 4 then
		state.key = "buy_duration_upgrade"
		state.label = "BUY DURATION UPGRADE"
		state.detail = "Transformation limit upgrade is available"
		state.needsPurchase = true
	elseif code == 5 then
		state.key = "completed"
		state.label = "RACE V4 COMPLETED"
		state.detail = "All Race V4 upgrades are complete"
		state.complete = true
	elseif code == 6 then
		local completed = math.clamp((progress or 2) - 2, 0, 3)
		local remaining = math.max(0, 3 - completed)
		state.key = "three_session_training"
		state.label = remaining > 0 and "TRAINING REQUIRED" or "TRAINING CHECKING"
		state.completedTraining = completed
		state.remainingTraining = remaining
		state.detail = "Additional sessions: " .. tostring(completed) .. "/3 completed"
		state.needsTraining = remaining > 0
	elseif code == 7 then
		state.key = "buy_next_upgrade"
		state.label = "BUY NEXT UPGRADE"
		state.detail = "The next Race V4 upgrade is available"
		state.needsPurchase = true
	elseif code == 8 then
		local remaining = math.max(0, 10 - (progress or 0))
		state.key = "mastery_training"
		state.label = remaining > 0 and "MASTERY TRAINING" or "MASTERY COMPLETE"
		state.remainingTraining = remaining
		state.completedTraining = math.clamp(progress or 0, 0, 10)
		state.detail = remaining > 0
			and (tostring(remaining) .. " mastery training sessions remaining")
			or "All optional mastery sessions are complete"
		state.needsTraining = remaining > 0
		state.complete = remaining <= 0
	elseif code == 9 then
		state.key = "special_race_path"
		state.label = "SPECIAL RACE PATH"
		state.detail = "This race uses a different V4 upgrade path"
	else
		state.key = "not_ready"
		state.label = "NOT TRIAL READY"
		state.detail = "Unknown UpgradeRace state: " .. tostring(code)
	end
	if isAlly then
		state.complete = false
		state.canTrial = true
		state.needsPurchase = false
		state.needsTraining = false
		state.key = "trial_ready"
		state.label = "READY FOR TRIAL"
		state.detail = "Helper is ready to support"
	end
	V4StatusCache.at = tick()
	V4StatusCache.data = state
	return state
end

function getdialogoftemple()
	return getV4Status(true).detail
end

function trialable(forceRefresh)
	local state = getV4Status(forceRefresh == true)
	if isAlly then
		return true, state.gear or 5
	end
	if state.canTrial then
		return true, state.gear
	end
	if state.complete then
		return false, "completed"
	end
	if state.needsPurchase then
		local fragments = 0
		pcall(function()
			fragments = tonumber(Players.LocalPlayer.Data.Fragments.Value) or 0
		end)
		if state.cost > 0 and fragments >= state.cost then
			local ok, bought = pcall(function()
				return invokeUpgradeRace("Buy")
			end)
			invalidateV4Status()
			if ok and bought then
				return false, "upgrade_bought"
			end
			return false, "buy_failed"
		end
		return false, "raiding"
	end
	if state.needsTraining then
		return false, state.remainingTraining or "training"
	end
	return false, state.key
end

-- ============ MATCH STATE + GROUP (v4.lua 1868-2142) ============
local configuredCentralHubUrl = tostring((getgenv().Config or {}).CentralHubWS or "")
local centralHubConfigured = configuredCentralHubUrl ~= ""
	and not configuredCentralHubUrl:find("HOANGLAM_ISGAY", 1, true)
local localGroupId = "local_" .. mainAccountName
matchState = {
	assigned = not centralHubConfigured and (mainAccountName ~= ""),
	group_id = localGroupId,
	main_username = mainAccountName,
	main_job_id = game.JobId,
	helpers = {},
	all_in_job = true,
}
local isCurrentlyTraining = false
task.spawn(function()
	while task.wait(2) do
		if getgenv().UpdateRoles then
			getgenv().UpdateRoles()
		end
		if matchState then
			local v4s = nil
			pcall(function() v4s = getV4Status(false) end)
			local needsIndependentWork = v4s and (v4s.needsTraining or v4s.needsPurchase)
			local hubAssignment = getgenv().__KAITUN_HUB_ASSIGNMENT
			local hubAssignmentActive = type(hubAssignment) == "table"
				and tick() - (tonumber(hubAssignment.receivedAt) or 0) < 900
			if needsIndependentWork then
				if hubAssignmentActive then
					pcall(releaseCurrentGroup, 'main_needs_training')
				else
					matchState.assigned = false
				end
			elseif hubAssignmentActive then
				matchState.assigned = true
			elseif centralHubConfigured then
				matchState.assigned = false
				matchState.group_id = ""
				matchState.main_username = ""
				matchState.main_job_id = game.JobId
				matchState.helpers = {}
				matchState.all_in_job = false
			else
				matchState.assigned = (mainAccountName ~= "")
				matchState.group_id = "local_" .. mainAccountName
				matchState.main_username = mainAccountName
				local list = {}
				for name, _ in pairs(isallies) do
					table.insert(list, name)
				end
				matchState.helpers = list
			end
		end
	end
end)

mainJobId = game.JobId
matchTeleportAt = 0
scheduledRoundId = ""
handledRoundId = ""
lastReadyWrite = 0
pairAssignedAt = tick()
pairAllInJobAt = tick()
pairTempleReadyAt = 0
lastTempleReadyCount = 0
lastPairGroupId = localGroupId
localRequeueBlockUntil = 0
releasingGroup = false
gearClaimInProgress = false
lastTempleForceAt = 0
lastTempleProgressAt = 0
lastTempleDistance = math.huge
pairTrialCycleStarted = false
pairV3ActivatedAt = 0
failedRoundId = ""
helperSacrificeDone = false
postTrialTransitionInProgress = false
lastPostTrialTransitionAt = 0
lastTrialActionAt = 0
trialCharacterReplacedAt = 0
readySent = false
abilityCooldown = 0

local PAIR_TEMPLE_TIMEOUT = math.max(15, tonumber(getgenv().Config.PairTempleTimeout) or 35)
local PAIR_RELEASE_AFTER_TRIAL = getgenv().Config.PairReleaseAfterTrial ~= false
local PAIR_STICKY_UNTIL_TRIAL_COMPLETE = getgenv().Config.PairStickyUntilTrialComplete ~= false
local V3_DOOR_DISTANCE = math.max(10, tonumber(getgenv().Config.V3DoorDistance) or 50)
local V3_COUNTDOWN = math.max(1, tonumber(getgenv().Config.V3Countdown) or 6)
local V3_READY_HOLD = math.max(0.2, tonumber(getgenv().Config.V3ReadyHoldTime) or 0.6)
local V3_WS_SYNC = getgenv().Config.V3WebSocketSync ~= false
local V3_FIRE_COUNT = math.max(1, math.floor(tonumber(getgenv().Config.V3FireCount) or 1))
local V3_FIRE_INTERVAL = math.max(0.03, tonumber(getgenv().Config.V3FireInterval) or 0.05)
local TRIAL_BARRIER_TIMEOUT = math.max(60, tonumber(getgenv().Config.TrialBarrierTimeout) or 240)

function req()
	return http_request or http and http.request or request or syn and syn.request
end

function jsonEncode(t)
	return HttpService:JSONEncode(t)
end

function jsonDecode(s)
	return HttpService:JSONDecode(s)
end

function getRole()
	if isUper then
		return "upgear"
	end
	if isAlly then
		return "allies"
	end
	return "none"
end

function apiPost(path, body)
	return nil
end

function apiGet(path)
	return nil
end

trialCycleDone = false
trialCycleDoneAt = 0
trialTimerSeen = false
trialTimerLostAt = 0
trialBarrierSacrificeAt = 0
lastBarrierGearCheckAt = 0
barrierProgressAt = 0

function resetTrialBarrierState()
	trialCycleDone = false
	trialCycleDoneAt = 0
	trialTimerSeen = false
	trialTimerLostAt = 0
	trialBarrierSacrificeAt = 0
	lastBarrierGearCheckAt = 0
	barrierProgressAt = 0
	trialCharacterReplacedAt = 0
end
resetTrialBarrierState()

function resetLocalPairState()
	mainJobId = game.JobId
	readySent = false
	scheduledRoundId = ""
	handledRoundId = ""
	lastPairGroupId = localGroupId
	pairAssignedAt = tick()
	pairAllInJobAt = tick()
	pairTempleReadyAt = 0
	lastTempleReadyCount = 0
	lastTempleForceAt = 0
	lastTempleProgressAt = 0
	lastTempleDistance = math.huge
	pairTrialCycleStarted = false
	pairV3ActivatedAt = 0
	failedRoundId = ""
	helperSacrificeDone = false
	resetTrialBarrierState()
end

function releaseCurrentGroup(reason)
	reason = tostring(reason or "completed")
	local assignment = getgenv().__KAITUN_HUB_ASSIGNMENT
	local groupId = type(assignment) == "table" and tostring(assignment.groupId or "") or ""
	local coordinator = getgenv().__KAITUN_V4_COORDINATOR
	local socket = coordinator and coordinator.socket
	if groupId ~= "" and socket then
		pcall(function()
			local send = socket.Send or socket.send
			assert(type(send) == "function", "WebSocket send method is unavailable")
			send(socket, HttpService:JSONEncode({
				type = "CANCEL_ASSIGNMENT_REQUEST",
				sender = USERNAME,
				groupId = groupId,
				reason = reason
			}))
		end)
	end
	getgenv().__KAITUN_HUB_ASSIGNMENT = nil
	if centralHubConfigured then
		matchState.assigned = false
		matchState.group_id = ""
		matchState.main_username = ""
		matchState.main_job_id = game.JobId
		matchState.helpers = {}
		matchState.all_in_job = false
	end
	status("Trial cycle reset: " .. reason)
	resetLocalPairState()
	return true
end

function computeQueueReady()
	if not (isnight() and isfullmoon()) then
		return false, "waiting_full_moon"
	end
	local ok, canTrial = pcall(function()
		local ready = trialable()
		return ready == true
	end)
	if ok and canTrial then
		return true, "ready_for_pair"
	end
	return false, "not_trial_ready"
end

function getCurrentUpgearTurn()
	if mainAccountName ~= "" then
		return mainAccountName
	end
	if isUper then
		return USERNAME
	end
	return nil
end

function isMyUpgearTurn()
	return isUper
end

function isOtherUpgearTraining()
	if not isAlly then
		return false
	end
	return mainAccountName ~= ""
end

function refreshMatch()
	return matchState
end

function sendMainJob()
	return refreshMatch()
end

function getMainJob()
	if matchState and matchState.main_job_id then
		return matchState.main_job_id
	end
	return mainJobId
end

task.spawn(function()
	while task.wait(2) do
		pcall(refreshMatch)
	end
end)

-- ============ GEAR (v4.lua 2144-2425) ============
function autoEquipGear()
	local gearConfig = getgenv().Config.Gear
	if not gearConfig or #gearConfig ~= 5 then
		return
	end
	local slot1Type = string.sub(gearConfig, 1, 1)
	local accessoryMap = {
		["A"] = {
			"Pale Scarf", "Pink Coat", "Valentine's Necklace", "Black Cape", "Swan Glasses",
			"Tomoe Ring", "Dark Coat", "Musketeer Hat", "Kitsune Mask", "Kitsune Ribbon",
			"Lei", "Pretty Helmet"
		},
		["B"] = {
			"Ghoul Mask", "Winter Sky", "Black Spikey Coat", "Koko's Glasses", "Berserker Mask",
			"Warrior Helmet", "Water Key Necklace", "Pilot Helmet"
		},
		["C"] = {
			"Marine Cap", "Swordsman Hat", "Usoap's Hat", "Choppa's Hat", "Robin's Glasses",
			"Namis Glasses", "Brook's Glasses", "Bobby's Glasses", "Jaw's Glasses",
			"Bear Ears", "Cool Shades", "Skeleton Mask"
		}
	}
	local function getPriority(accessoryName)
		for tier, names in pairs(accessoryMap) do
			for _, name in ipairs(names) do
				if accessoryName:find(name) then
					return tier == "A" and 3 or tier == "B" and 2 or 1
				end
			end
		end
		return 0
	end
	local function findBestAccessoryInBackpack()
		local best, bestPriority = nil, -1
		for _, tool in ipairs(Players.LocalPlayer.Backpack:GetChildren()) do
			if tool:IsA("Accessory") then
				local priority = getPriority(tool.Name)
				if priority > bestPriority then
					bestPriority = priority
					best = tool
				end
			end
		end
		return best
	end
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end
	local function equipToSlot(slotIndex, desiredType)
		local currentAccessory = character:FindFirstChildOfClass("Accessory")
		if currentAccessory and currentAccessory.Name:find("Accessory") then
			local currentPriority = getPriority(currentAccessory.Name)
			local desiredPriority = desiredType == "-" and 99 or (accessoryMap[desiredType] and (desiredType == "A" and 3 or desiredType == "B" and 2 or 1) or 0)
			if currentPriority >= desiredPriority then
				return
			end
		end
		local bestBackpack = findBestAccessoryInBackpack()
		if bestBackpack then
			local backpackPriority = getPriority(bestBackpack.Name)
			local desiredPriority = desiredType == "-" and 0 or (accessoryMap[desiredType] and (desiredType == "A" and 3 or desiredType == "B" and 2 or 1) or 0)
			if backpackPriority >= desiredPriority then
				Players.LocalPlayer.Character.Humanoid:EquipTool(bestBackpack)
			end
		end
	end
	if Players.LocalPlayer.Backpack:FindFirstChildOfClass("Accessory") then
		equipToSlot(1, slot1Type)
	end
end

function checkgear()
	if gearClaimInProgress or not CommF_ then
		return false
	end
	gearClaimInProgress = true
	local function finish(result)
		gearClaimInProgress = false
		return result
	end
	local function snapshot(clockData)
		local details = clockData and clockData.RaceDetails
		if type(details) ~= "table" then
			return nil
		end
		local gears = type(details.Gears) == "table" and details.Gears or {}
		local gearParts = {}
		for index = 1, 3 do
			gearParts[index] = tostring(gears[index] or "")
		end
		return {
			hadPoint = clockData.HadPoint == true,
			raceLevel = tonumber(clockData.RaceLevel) or 0,
			a = tonumber(details.A) or 0,
			b = tonumber(details.B) or 0,
			c = tonumber(details.C) or 0,
			completed = tonumber(details.Completed) or tonumber(clockData.Completed) or 0,
			gears = table.concat(gearParts, "|"),
			rawGears = { gearParts[1], gearParts[2], gearParts[3] }
		}
	end
	local ok, beforeData = pcall(function()
		return CommF_:InvokeServer("TempleClock", "Check")
	end)
	local before = ok and snapshot(beforeData) or nil
	if not before then
		return finish(false)
	end

	local race = canonicalRaceName(getLocalRaceName())
	local pattern = (getgenv().Config.GearPatterns and getgenv().Config.GearPatterns[race]) or getgenv().Config.Gear or "B-B-A"
	local g1, g2, g3 = tostring(pattern):match("^([AB])%-([AB])%-([AB])$")
	if not g1 or not g2 or not g3 then
		g1, g2, g3 = "B", "B", "A"
	end
	local convert = { A = "Alpha", B = "Omega" }
	local targetGears = { convert[g1], convert[g2], convert[g3] }
	local installedCount = before.a + before.b

	if installedCount >= 3 then
		local changedAny = false
		for i = 1, 3 do
			if before.rawGears[i] ~= "" and before.rawGears[i] ~= targetGears[i] then
				local slotNameToChange = "Gear" .. tostring(i + 1)
				pcall(function()
					CommF_:InvokeServer("TempleClock", "ChangeGear", slotNameToChange, targetGears[i])
				end)
				changedAny = true
				task.wait(0.5)
			end
		end
		if changedAny then
			invalidateV4Status()
			finish(true)
			return true
		end
		finish(false)
		return false
	end

	if beforeData.HadPoint ~= true then
		return finish(false)
	end
	local slotName = nil
	local choose = nil
	local isFirstGear = before.raceLevel < 2
	if isFirstGear then
		slotName = "Gear1"
	else
		if installedCount < 0 or installedCount > 2 then
			return finish(false)
		end
		local slotIndex = installedCount + 2
		local slotPattern = { g1, g2, g3 }
		slotName = "Gear" .. tostring(slotIndex)
		choose = convert[slotPattern[installedCount + 1]]
		if before.a >= 2 then
			choose = "Omega"
		elseif before.b >= 2 then
			choose = "Alpha"
		elseif choose ~= "Alpha" and choose ~= "Omega" then
			choose = "Omega"
		end
	end
	local spentOk, spentResult = pcall(function()
		if isFirstGear then
			return CommF_:InvokeServer("TempleClock", "SpendPoint")
		end
		return CommF_:InvokeServer("TempleClock", "SpendPoint", slotName, choose)
	end)
	if not spentOk or spentResult == false then
		return finish(false)
	end
	local claimed = false
	for _ = 1, 12 do
		task.wait(0.35)
		local verifyOk, verifyData = pcall(function()
			return CommF_:InvokeServer("TempleClock", "Check")
		end)
		local after = verifyOk and snapshot(verifyData) or nil
		if after and verifyData.HadPoint == false then
			local progressionChanged
			if isFirstGear then
				progressionChanged = after.raceLevel > before.raceLevel or after.completed ~= before.completed or after.gears ~= before.gears
			else
				progressionChanged = after.a ~= before.a
					or after.b ~= before.b
					or after.gears ~= before.gears
					or after.completed ~= before.completed
			end
			if progressionChanged then
				claimed = true
				break
			end
		end
	end
	if claimed then
		invalidateV4Status()
		finish(true)
		if isUper and isMyUpgearTurn() then
			task.spawn(function()
				beginPostTrialFarmTransition("gear_claimed")
			end)
		end
		return true
	end
	return finish(false)
end

task.spawn(function()
	while task.wait(5) do
		if Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
			pcall(autoEquipGear)
		end
	end
end)

task.spawn(function()
	while task.wait(1) do
		if isUper and isMyUpgearTurn() then
			local v4st = getV4Status(false)
			if (matchState and matchState.assigned) or (v4st and v4st.needsGearClaim) then
				pcall(checkgear)
			end
		end
	end
end)

-- ============ TEMPLE / V3 SYNC (v4.lua 2427-2825) ============
local isCurrentGroupInThisServer
local templeMoveGeneration = 0

function localDoorState()
	local door = getdoor()
	local char = Players.LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local distance = math.huge
	if door and hrp then
		distance = (door.Position - hrp.Position).Magnitude
	end
	local timerVisible = false
	pcall(function()
		timerVisible = Players.LocalPlayer.PlayerGui.Main.Timer.Visible == true
	end)
	local alive = hum ~= nil and hum.Health > 0
	local nearDoor = alive and door ~= nil and distance <= V3_DOOR_DISTANCE
	return {
		door = door,
		distance = distance,
		nearDoor = nearDoor,
		timerVisible = timerVisible,
		alive = alive
	}
end

TEMPLE_ENTRY_POSITION = Vector3.new(28310.0234, 14895.1123, 109.456741)

function isInsideOwnTrial()
	local _, trialLocation = getOwnTrialLocation()
	if trialLocation then
		local ok, distance = pcall(function()
			return getdis(trialLocation.CFrame)
		end)
		if ok and distance < 1500 then
			return true
		end
	end
	local timerVisible = false
	pcall(function()
		timerVisible = Players.LocalPlayer.PlayerGui.Main.Timer.Visible == true
	end)
	return timerVisible
end

function forceMatchedAccountToTemple(isRetry)
	if not isCurrentGroupInThisServer() or not (isnight() and isfullmoon()) then
		return false
	end
	if not isRetry and isInsideOwnTrial() then
		return true
	end
	if trialCycleDone and not isRetry then
		return true
	end
	local v4st = getV4Status(false)
	if not isRetry and v4st and v4st.needsGearClaim then
		return true
	end
	if tick() - lastTempleForceAt < 0.8 then
		return false
	end
	lastTempleForceAt = tick()
	if not workspace.Map:FindFirstChild("Temple of Time") then
		local templeRef = ReplicatedStorage.MapStash:FindFirstChild("Temple of Time")
		if templeRef then
			templeRef.Parent = workspace.Map
		end
	end
	local door = getdoor()
	local char = Players.LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		status("Paired - waiting character before Temple")
		return false
	end
	local templeDistance = (root.Position - TEMPLE_ENTRY_POSITION).Magnitude
	if not door or templeDistance > 3000 then
		status(isRetry and "Trial retry - entering Temple of Time" or "Paired - entering Temple of Time")
		pcall(function()
			CommF_:InvokeServer("requestEntrance", TEMPLE_ENTRY_POSITION)
		end)
		return false
	end
	local distance = (door.Position - root.Position).Magnitude
	if distance + 20 < lastTempleDistance then
		lastTempleDistance = distance
		lastTempleProgressAt = tick()
	elseif lastTempleProgressAt <= 0 then
		lastTempleProgressAt = tick()
	end
	if distance > V3_DOOR_DISTANCE then
		status(string.format("Paired - flying to race door (%.0f)", distance))
		pcall(function()
			topos(door.CFrame)
		end)
		if tick() - lastTempleProgressAt > 8 then
			lastTempleProgressAt = tick()
			pcall(function()
				CommF_:InvokeServer("requestEntrance", TEMPLE_ENTRY_POSITION)
			end)
			task.wait(0.25)
			pcall(function()
				topos(door.CFrame)
			end)
		end
		return false
	end
	pcall(function()
		topos(door.CFrame)
	end)
	status("Paired - at race door")
	return true
end

function scheduleMatchedTempleMove(groupId)
	templeMoveGeneration = templeMoveGeneration + 1
	local generation = templeMoveGeneration
	task.spawn(function()
		local deadline = tick() + 45
		while generation == templeMoveGeneration and tick() < deadline do
			if currentGroupId() ~= tostring(groupId or "") or not isCurrentGroupInThisServer() then
				return
			end
			if isInsideOwnTrial() or forceMatchedAccountToTemple() then
				return
			end
			task.wait(0.5)
		end
	end)
end

function v3ServerNow()
	local ok, value = pcall(function()
		return Workspace:GetServerTimeNow()
	end)
	if ok and tonumber(value) then
		return tonumber(value)
	end
	return tick()
end

local v3ReadySince = 0

function currentGroupId()
	if matchState and matchState.assigned and matchState.group_id then
		return tostring(matchState.group_id)
	end
	return ""
end

function currentGroupMembers()
	local members = {}
	local seen = {}
	local function add(name)
		name = tostring(name or "")
		if name ~= "" and not seen[name] then
			seen[name] = true
			table.insert(members, name)
		end
	end
	if matchState and matchState.assigned then
		add(matchState.main_username)
		for _, name in ipairs(matchState.helpers or {}) do
			add(name)
		end
		for _, name in ipairs(matchState.members or {}) do
			add(name)
		end
		if Player and Player.Name then
			add(Player.Name)
		end
		return members
	end
	if mainAccountName and mainAccountName ~= "" then
		add(mainAccountName)
	end
	for name, _ in pairs(HelpWhitelist) do
		if Players:FindFirstChild(name) then
			add(name)
		end
	end
	for name, _ in pairs(isallies) do
		if Players:FindFirstChild(name) then
			add(name)
		end
	end
	if Player and Player.Name then
		add(Player.Name)
	end
	return members
end

isCurrentGroupInThisServer = function()
	return matchState ~= nil
		and matchState.assigned == true
		and tostring(matchState.main_job_id or "") == tostring(game.JobId)
		and currentGroupId() ~= ""
end

function computeV3ReadyState()
	if not isCurrentGroupInThisServer() then
		v3ReadySince = 0
		return false, "no_group", nil
	end
	local doorState = localDoorState()
	local race = ""
	pcall(function()
		race = canonicalRaceName(Players.LocalPlayer.Data.Race.Value)
	end)
	local abilityName = race_abilities[canonicalRaceName(race)]
	local abilityAvailable = abilityName ~= nil and checkbackpack(abilityName) ~= nil
	local rawReady = tick() >= abilityCooldown
		and doorState.alive
		and doorState.nearDoor
		and not doorState.timerVisible
		and abilityAvailable
	if rawReady then
		if v3ReadySince == 0 then
			v3ReadySince = tick()
		end
	else
		v3ReadySince = 0
	end
	local debounced = rawReady and tick() - v3ReadySince >= V3_READY_HOLD
	readySent = debounced
	return debounced, debounced and "ready" or "waiting_door", { race = race, doorDistance = doorState.distance, timerVisible = doorState.timerVisible }
end

function getV3HeartbeatFields()
	if not V3_WS_SYNC then
		return { v3Ready = false, v3Race = getLocalRaceName(), v3DoorDistance = -1, v3GroupId = "", v3AbilityReady = false }
	end
	local ready, _, info = computeV3ReadyState()
	return {
		v3Ready = ready == true,
		v3Race = info and tostring(info.race or "") or getLocalRaceName(),
		v3DoorDistance = info and (info.doorDistance == math.huge and -1 or math.floor(info.doorDistance * 100) / 100) or -1,
		v3GroupId = currentGroupId(),
		v3AbilityReady = ready == true,
	}
end

function commandHasCurrentUser(command)
	local members = command.members or command.Members
	if type(members) ~= "table" then return false end
	for _, name in ipairs(members) do
		local n = type(name) == "table" and (name.name or name.Name) or name
		if tostring(n) == USERNAME then return true end
	end
	return false
end

function normalizeV3Command(raw)
	if type(raw) ~= "table" then return nil end
	local groupId = tostring(raw.groupId or raw.group_id or "")
	local jobId = tostring(raw.jobId or raw.job_id or "")
	local roundId = tostring(raw.roundId or raw.round_id or "")
	local fireAt = tonumber(raw.fireAt or raw.fire_at)
	local members = raw.members or raw.Members
	if groupId == "" or roundId == "" or not fireAt or fireAt <= 0 then return nil end
	return {
		group_id = groupId,
		job_id = jobId,
		round_id = roundId,
		fire_at = fireAt,
		members = members,
		groupId = groupId,
		jobId = jobId,
		roundId = roundId,
		fireAt = fireAt,
	}
end

function waitForSharedFireTime(fireAt)
	local fireAtTick = tick() + math.max(0, (tonumber(fireAt) or 0) - v3ServerNow())
	while true do
		local remaining = fireAtTick - tick()
		if remaining <= 0 then return end
		status(string.format("V3 countdown %.2fs", remaining))
		if remaining > 0.25 then
			task.wait(math.min(0.10, math.max(0.03, remaining - 0.15)))
		else
			RunService.Heartbeat:Wait()
		end
	end
end

function isOwnV3AbilityActive()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local abilityName = race_abilities[canonicalRaceName(getLocalRaceName())]
	return root ~= nil and abilityName ~= nil and root:FindFirstChild(abilityName) ~= nil
end

function activateOwnV3Ability()
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local abilityName = race_abilities[canonicalRaceName(getLocalRaceName())]
	if not character or not humanoid or humanoid.Health <= 0 or not abilityName then
		return false
	end
	if not checkbackpack(abilityName) then
		status("V3 ability tool is missing: " .. tostring(abilityName))
		return false
	end
	if isOwnV3AbilityActive() then
		return true
	end
	for index = 1, V3_FIRE_COUNT do
		pcall(function()
			(ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommE")):FireServer("ActivateAbility")
		end)
		local verifyUntil = tick() + math.max(0.8, V3_FIRE_INTERVAL)
		repeat
			task.wait(0.03)
		until isOwnV3AbilityActive() or tick() >= verifyUntil
		if isOwnV3AbilityActive() then
			return true
		end
	end
	return false
end

function scheduleV3SocketRound(command)
	command = normalizeV3Command(command)
	if not command then return false end
	local roundId = tostring(command.round_id or "")
	local fireAt = tonumber(command.fire_at) or 0
	if roundId == "" or fireAt <= 0 then return false end
	if roundId == handledRoundId or roundId == scheduledRoundId or roundId == failedRoundId then
		return false
	end
	if not commandHasCurrentUser(command) then return false end
	scheduledRoundId = roundId
	task.spawn(function()
		waitForSharedFireTime(fireAt)
		local validGroup = isCurrentGroupInThisServer()
			and tostring(command.group_id or "") == currentGroupId()
			and tostring(command.job_id or "") == tostring(game.JobId)
		local doorState = localDoorState()
		local fired = false
		if validGroup and doorState.nearDoor and not doorState.timerVisible then
			status("Activating Race V3 from shared time")
			fired = activateOwnV3Ability()
			if fired then
				handledRoundId = roundId
				failedRoundId = ""
				abilityCooldown = tick() + 30
				readySent = false
				helperSacrificeDone = false
				pairTrialCycleStarted = true
				pairV3ActivatedAt = tick()
				status("Race V3 activation confirmed")
			else
				failedRoundId = roundId
				abilityCooldown = tick() + 1
				readySent = false
				status("V3 activation was rejected - waiting next sync round")
			end
		else
			status("V3 countdown ended but account left its race door")
		end
		scheduledRoundId = ""
		return fired
	end)
	return true
end

function handleV3CommandMessage(raw)
	local command = normalizeV3Command(raw.payload or raw)
	if not command then
		command = normalizeV3Command(raw)
	end
	if not command then return false end
	return scheduleV3SocketRound(command)
end

function tryActivateAbility()
	if not V3_WS_SYNC or not isCurrentGroupInThisServer() then
		return false
	end
	local ready = computeV3ReadyState()
	if ready then
		status("At race door - waiting Hub V3 countdown")
	end
	return ready == true
end

-- ============ TRAINING ISLANDS + SMART TELEPORT (v4.lua 2826-3351) ============
TyrState = {
	AttackLoaded = false,
	Farming = true,
	CurrentMode = "STARTING",
	CurrentTarget = nil,
	LastStatus = "",
	TrackedBreakables = setmetatable({}, { __mode = "k" }),
	CachedBreakables = {},
	LastBreakableScan = 0
}

local TIKI_CENTER = CFrame.new(-16682.7, 215, 524.2)
local TYRANT_ENTRANCE = CFrame.new(-16342.5, 174, 1397)
local ARENA_CENTER = Vector3.new(-16335, 174, 1397)
local DRAGON_TALON_BUY_POS = CFrame.new(5661.616211, 1211.299438, 865.999451)

TikiMobs = {
	["Isle Outlaw"] = true,
	["Island Boy"] = true,
	["Sun-kissed Warrior"] = true,
	["Isle Champion"] = true,
	["Serpent Hunter"] = true,
	["Skull Slayer"] = true
}

TrainingIslandData = {
	["Haunted Castle"] = {
		Position = CFrame.new(-9530.61035, 200.860657, 5763.13477),
		Mobs = {
			["Reborn Skeleton"] = true,
			["Living Zombie"] = true,
			["Demonic Soul"] = true,
			["Possessed Mummy"] = true
		}
	},
	["Tiki Outpost"] = {
		Position = CFrame.new(-16490.9727, 98.1144867, 1245.58984, -0.034969449, 0, 0.999388516, 0, 1, 0, -0.999388516, 0, -0.034969449),
		Mobs = {
			["Isle Outlaw"] = true,
			["Island Boy"] = true,
			["Sun-kissed Warrior"] = true,
			["Isle Champion"] = true
		}
	},
	["Great Tree"] = {
		Positions = {
			CFrame.new(2527.22119, 88.0126953, -7554.48096, -0.999390602, -0.0349089168, -1.05798244e-06, 1.05798244e-06, -6.05583191e-05, 1, -0.0349089168, 0.999390483, 6.05583191e-05),
			CFrame.new(2923.90332, 91.6738281, -7734.71631, 0.997561574, -0, -0.0697919354, 0, 1, -0, 0.0697919354, 0, 0.997561574),
			CFrame.new(3778.4248, 116.34375, -6938.81641, -0.667134643, -0.731317759, 0.141794443, -0.207926333, 2.65836716e-05, -0.978144467, 0.71533066, -0.682036817, -0.152077913)
		},
		Mobs = {
			["Marine Commodore"] = true,
			["Marine Rear Admiral"] = true
		}
	},
	["Ice Cream Island"] = {
		Position = CFrame.new(-851.74633789062, 65.819496154785, -10932.150390625),
		Mobs = {
			["Peanut Scout"] = true,
			["Peanut President"] = true,
			["Ice Cream Chef"] = true,
			["Ice Cream Commander"] = true
		}
	},
	["Port Town"] = {
		Positions = {
			CFrame.new(-172.031281, 52.8853912, 5851.12793, 0.965929627, -0, -0.258804798, 0, 1, -0, 0.258804798, 0, 0.965929627),
			CFrame.new(-638.581543, 50.9266357, 5627.74951, 0.258864343, 0, 0.965913713, 0, 1, 0, -0.965913713, 0, 0.258864343),
			CFrame.new(-61.3757935, 48.8545227, 6151.30762, 0.965929627, -0, -0.258804798, 0, 1, -0, 0.258804798, 0, 0.965929627),
			CFrame.new(-662.967041, 65.9991913, 5804.41699, 0.965938151, 0.050586991, -0.253780305, -4.01213765e-06, 0.980709016, 0.195473209, 0.258773029, -0.188813999, 0.947304487)
		},
		Mobs = {
			["Pirate Millionaire"] = true,
			["Pistol Billionaire"] = true
		}
	},
	["Peanut Island"] = {
		Position = CFrame.new(-2087.0561523438, 11.722011566162, -10002.080078125),
		Mobs = {
			["Peanut Scout"] = true,
			["Peanut President"] = true
		}
	}
}

local TrainingIslandOrder = getgenv().Config.TrainingIslands or {
	"Tiki Outpost",
	"Ice Cream Island",
	"Haunted Castle",
	"Great Tree",
	"Port Town",
	"Peanut Island"
}

local MAX_ACCS_PER_ISLAND = 2
local myAssignedIsland = nil

function assignTrainingIsland()
	local bestIsland = nil
	local bestCount = math.huge
	for _, islandName in ipairs(TrainingIslandOrder) do
		local count = TrainingIslandData[islandName] and countAccountsAtIsland(islandName) or math.huge
		if count < MAX_ACCS_PER_ISLAND and count < bestCount then
			bestCount = count
			bestIsland = islandName
		end
	end
	if not bestIsland then
		for _, islandName in ipairs(TrainingIslandOrder) do
			local count = TrainingIslandData[islandName] and countAccountsAtIsland(islandName) or math.huge
			if count < bestCount then
				bestCount = count
				bestIsland = islandName
			end
		end
	end
	bestIsland = bestIsland or TrainingIslandOrder[1]
	myAssignedIsland = bestIsland
	return bestIsland
end

function countAccountsAtIsland(islandName)
	local data = TrainingIslandData[islandName]
	if not data then
		return 0
	end
	local islandPos
	if data.Positions then
		islandPos = data.Positions[1].Position
	else
		islandPos = data.Position.Position
	end
	local count = 0
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= Players.LocalPlayer and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp and (hrp.Position - islandPos).Magnitude < 1000 then
				count = count + 1
			end
		end
	end
	return count
end

function CheckMonster(...)
	local args = { ... }
	local containers = { workspace.Enemies, ReplicatedStorage }
	for i = 1, #args do
		local m = workspace.Enemies:FindFirstChild(args[i]) or ReplicatedStorage:FindFirstChild(args[i])
		if m and m:IsA("Model") and m.Name ~= "Blank Buddy" then
			local h = m:FindFirstChildWhichIsA("Humanoid")
			local r = m:FindFirstChild("HumanoidRootPart")
			if h and r and h.Health > 0 then
				return m
			end
		end
	end
	for _, container in ipairs(containers) do
		for _, m in ipairs(container:GetChildren()) do
			local h = m:FindFirstChild("Humanoid")
			local r = m:FindFirstChild("HumanoidRootPart")
			if m:IsA("Model") and h and r and h.Health > 0 and m.Name ~= "Blank Buddy" then
				for i = 1, #args do
					if m.Name == args[i] or m.Name:lower():find(args[i]:lower()) then
						return m
					end
				end
			end
		end
	end
	return false
end

function forceReassignIsland()
	myAssignedIsland = nil
end

function getTrainingIslandTarget(islandName)
	local data = islandName and TrainingIslandData[islandName]
	if not data then
		return nil
	end
	if data.Positions and data.Positions[1] then
		return data.Positions[1]
	end
	return data.Position
end

function getLastSpawnPointValue()
	local data = Players.LocalPlayer:FindFirstChild("Data")
	local node = data and data:FindFirstChild("LastSpawnPoint")
	return node and tostring(node.Value) or nil
end

function findSpawnNameNear(position, maxDistance)
	local origin = Workspace:FindFirstChild("_WorldOrigin")
	local spawns = origin and origin:FindFirstChild("PlayerSpawns")
	if not spawns then return nil end
	local bestName, bestDist = nil, maxDistance or 1200
	for _, team in ipairs(spawns:GetChildren()) do
		for _, spawn in ipairs(team:GetChildren()) do
			local part = spawn:IsA("BasePart") and spawn
				or (spawn:IsA("Model") and (spawn.PrimaryPart or spawn:FindFirstChildWhichIsA("BasePart")))
			if part then
				local dist = (part.Position - position).Magnitude
				if dist < bestDist then
					bestDist = dist
					bestName = spawn.Name
				end
			end
		end
	end
	return bestName
end

function setTrainingSpawnPoint(target)
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not target then return false end
	local wasTweening = smoothTweenRunning
	if wasTweening then M:stopTween() end
	root.CFrame = target + Vector3.new(0, 6, 0)
	task.wait(0.2)
	local ok = pcall(function()
		CommF_:InvokeServer("SetSpawnPoint")
	end)
	local spawnName = findSpawnNameNear(target.Position, 1500)
	if spawnName then
		local current = getLastSpawnPointValue()
		if current ~= spawnName then
			pcall(function()
				CommF_:InvokeServer("SetLastSpawnPoint", spawnName)
			end)
			local deadline = tick() + 2.5
			repeat
				task.wait(0.15)
				current = getLastSpawnPointValue()
			until current == spawnName or tick() >= deadline
		end
		ok = (current == spawnName)
	end
	if wasTweening then task.wait(0.1) end
	return ok
end

function getAllSpawnWaypoints()
	local waypoints = {}
	local origin = Workspace:FindFirstChild("_WorldOrigin")
	local spawns = origin and origin:FindFirstChild("PlayerSpawns")
	if not spawns then return waypoints end
	local seen = {}
	for _, team in ipairs(spawns:GetChildren()) do
		for _, spawn in ipairs(team:GetChildren()) do
			if not seen[spawn.Name] then
				local part = spawn:IsA("BasePart") and spawn
					or (spawn:IsA("Model") and (spawn.PrimaryPart or spawn:FindFirstChildWhichIsA("BasePart")))
				if part then
					seen[spawn.Name] = true
					table.insert(waypoints, { Name = spawn.Name, Position = part.Position })
				end
			end
		end
	end
	return waypoints
end

local SMART_TELE_MAX_HOP = 5000
function findSmartTelePath(startPos, goalPos, maxHop)
	maxHop = maxHop or SMART_TELE_MAX_HOP
	if (startPos - goalPos).Magnitude <= maxHop then
		return {}
	end
	local waypoints = getAllSpawnWaypoints()
	for islandName, data in pairs(TrainingIslandData) do
		local pos
		if data.Positions then
			pos = data.Positions[1]
			if typeof(pos) == "CFrame" then pos = pos.Position end
		elseif data.Position then
			pos = data.Position
			if typeof(pos) == "CFrame" then pos = pos.Position end
		end
		if pos then
			local isDup = false
			for _, wp in ipairs(waypoints) do
				if (wp.Position - pos).Magnitude < 200 then isDup = true break end
			end
			if not isDup then
				table.insert(waypoints, { Name = islandName, Position = pos })
			end
		end
	end

	local nodes = {}
	nodes[1] = { Position = startPos, Name = "START" }
	nodes[2] = { Position = goalPos, Name = "GOAL" }
	for i, wp in ipairs(waypoints) do
		nodes[i + 2] = wp
	end

	local queue = { { idx = 1, path = {} } }
	local visited = { [1] = true }
	local head = 0
	while head < #queue do
		head = head + 1
		local current = queue[head]
		local curPos = nodes[current.idx].Position
		if (curPos - goalPos).Magnitude <= maxHop then
			return current.path
		end
		for i, node in ipairs(nodes) do
			if not visited[i] and i ~= 1 then
				if (curPos - node.Position).Magnitude <= maxHop then
					visited[i] = true
					local newPath = {}
					for _, p in ipairs(current.path) do
						newPath[#newPath + 1] = p
					end
					newPath[#newPath + 1] = node
					if i == 2 then
						return newPath
					end
					queue[#queue + 1] = { idx = i, path = newPath }
				end
			end
		end
	end
	return nil
end

function doSingleResetHop(targetCFrame, hopLabel)
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return false end
	M:stopTween()
	if hopLabel then substatus("Reset hop -> " .. tostring(hopLabel)) end
	local spawnOk = setTrainingSpawnPoint(targetCFrame)
	if not spawnOk then
		root.CFrame = targetCFrame + Vector3.new(0, 6, 0)
		task.wait(0.3)
		pcall(function() CommF_:InvokeServer("SetSpawnPoint") end)
		task.wait(0.2)
	end
	local oldCharacter = character
	pcall(function() humanoid.Health = 0 end)
	local deadline = tick() + 12
	repeat
		task.wait(0.15)
		character = Players.LocalPlayer.Character
	until tick() >= deadline or (character and character ~= oldCharacter
		and character:FindFirstChild("HumanoidRootPart")
		and character:FindFirstChildOfClass("Humanoid")
		and character:FindFirstChildOfClass("Humanoid").Health > 0)
	character = Players.LocalPlayer.Character
	root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		local holdUntil = tick() + 0.45
		repeat
			root.CFrame = targetCFrame + Vector3.new(0, 6, 0)
			RunService.Heartbeat:Wait()
		until tick() >= holdUntil or not root.Parent
	end
	return true
end

function resetTeleportToTrainingIsland(forceReset, requestedIsland)
	local islandName = requestedIsland or assignTrainingIsland()
	local target = getTrainingIslandTarget(islandName)
	if not target then
		status("No training island target for reset teleport")
		return false
	end
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return false
	end
	M:stopTween()

	local templeDistance = (root.Position - TEMPLE_ENTRY_POSITION).Magnitude
	if templeDistance < 3000 then
		status("Escaping Temple -> reset to default spawn first")
		substatus("Reset thoat Temple")
		local oldChar = character
		pcall(function() humanoid.Health = 0 end)
		local deadline = tick() + 12
		repeat
			task.wait(0.15)
			character = Players.LocalPlayer.Character
		until tick() >= deadline or (character and character ~= oldChar
			and character:FindFirstChild("HumanoidRootPart")
			and character:FindFirstChildOfClass("Humanoid")
			and character:FindFirstChildOfClass("Humanoid").Health > 0)
		character = Players.LocalPlayer.Character
		root = character and character:FindFirstChild("HumanoidRootPart")
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 then
			return false
		end
		task.wait(0.5)
	end

	local targetPos = typeof(target) == "CFrame" and target.Position or target
	local startPos = root.Position
	local totalDist = (startPos - targetPos).Magnitude

	if totalDist > SMART_TELE_MAX_HOP then
		status("Long distance (" .. math.floor(totalDist) .. " studs) -> tween direct to island")
		topos(target)
		task.wait(0.3)
		character = Players.LocalPlayer.Character
		root = character and character:FindFirstChild("HumanoidRootPart")
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 then
			return false
		end
	end

	status("Reset teleport to [" .. tostring(islandName) .. "]")
	character = Players.LocalPlayer.Character
	root = character and character:FindFirstChild("HumanoidRootPart")
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return false
	end
	if forceReset or getgenv().Config.ResetTeleportAfterTrial ~= false then
		local wantedSpawn = findSpawnNameNear(target.Position, 1500)
		local spawnOk = false
		for attempt = 1, 3 do
			spawnOk = setTrainingSpawnPoint(target) == true
			if not wantedSpawn or getLastSpawnPointValue() == wantedSpawn then
				spawnOk = true
				break
			end
			status("Spawn point not applied (try " .. attempt .. ") - retrying")
			task.wait(0.4)
		end
		if wantedSpawn and getLastSpawnPointValue() ~= wantedSpawn then
			status("Spawn point locked - tween to island instead of reset")
			if not topos(target) then return false end
			setTrainingSpawnPoint(target)
			return true
		end
		local oldCharacter = character
		pcall(function()
			humanoid.Health = 0
		end)
		local deadline = tick() + 12
		repeat
			task.wait(0.15)
			character = Players.LocalPlayer.Character
		until tick() >= deadline or (character and character ~= oldCharacter
			and character:FindFirstChild("HumanoidRootPart")
			and character:FindFirstChildOfClass("Humanoid")
			and character:FindFirstChildOfClass("Humanoid").Health > 0)
		character = Players.LocalPlayer.Character
		root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			local settleTime = math.max(0.2, tonumber(getgenv().Config.ResetTeleportSettleTime) or 0.45)
			local holdUntil = tick() + settleTime
			repeat
				root.CFrame = target + Vector3.new(0, 6, 0)
				RunService.Heartbeat:Wait()
			until tick() >= holdUntil or not root.Parent
			pcall(function()
				CommF_:InvokeServer("SetSpawnPoint")
			end)
		end
	end
	character = Players.LocalPlayer.Character
	root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - target.Position).Magnitude > 900 then
		status("Reset spawn missed - moving to training island")
		if not topos(target) then return false end
	end
	setTrainingSpawnPoint(target)
	return true
end

function beginPostTrialFarmTransition(reason)
	if not isUper or not isMyUpgearTurn() or postTrialTransitionInProgress then
		return false
	end
	if tick() - lastPostTrialTransitionAt < 8 then
		return false
	end
	postTrialTransitionInProgress = true
	lastPostTrialTransitionAt = tick()
	isCurrentlyTraining = true
	AttackConfig.AutoClickEnabled = false
	_G.SHOULDSPAMSKILLS = false
	releaseCurrentGroup(reason or "post_trial")
	local ok, result = pcall(resetTeleportToTrainingIsland)
	if not ok then
		status("Reset teleport failed: " .. tostring(result):sub(1, 60))
	end
	invalidateV4Status()
	AttackConfig.AutoClickEnabled = true
	isCurrentlyTraining = false
	postTrialTransitionInProgress = false
	return ok and result == true
end

-- ============ TRIAL DETECTION + RUN (v4.lua 3353-4300) ============
function getNearestTrialEnemy(trialLocation)
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local best, bestDistance = nil, math.huge
	local folders = {}
	for _, name in ipairs({ "Enemies", "Characters", "NPCs", "Mobs" }) do
		local folder = workspace:FindFirstChild(name)
		if folder then
			folders[#folders + 1] = folder
		end
	end
	local origin = workspace:FindFirstChild("_WorldOrigin")
	if origin then
		local originEnemies = origin:FindFirstChild("Enemies")
		if originEnemies then
			folders[#folders + 1] = originEnemies
		end
	end
	for _, folder in ipairs(folders) do
		for _, enemy in ipairs(folder:GetChildren()) do
			if enemy:IsA("Model") and enemy ~= character then
				local isRealPlayer = false
				pcall(function()
					if Players:GetPlayerFromCharacter(enemy) then
						isRealPlayer = true
					end
				end)
				if not isRealPlayer then
					local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
						or enemy:FindFirstChild("UpperTorso")
						or enemy:FindFirstChild("Torso")
						or enemy:FindFirstChild("Head")
						or enemy.PrimaryPart
					local humanoid = enemy:FindFirstChildOfClass("Humanoid")
					if enemyRoot and humanoid and humanoid.Health > 0
						and (enemyRoot.Position - trialLocation.Position).Magnitude < 1800
					then
						local distance = root and (enemyRoot.Position - root.Position).Magnitude or 0
						if distance < bestDistance then
							best, bestDistance = enemy, distance
						end
					end
				end
			end
		end
	end
	return best
end

local trialPartCache = {}
local lastTrialPartSearchAt = {}

function findTrialPart(race, trialLocation, preferredNames)
	local cached = trialPartCache[race]
	if cached and cached.Parent and cached:IsA("BasePart") then
		return cached
	end
	if tick() - (lastTrialPartSearchAt[race] or 0) < 0.75 then
		return nil
	end
	lastTrialPartSearchAt[race] = tick()
	local wanted = {}
	for _, name in ipairs(preferredNames) do
		wanted[string.lower(name)] = true
	end
	local map = workspace:FindFirstChild("Map")
	if not map then
		return nil
	end
	local best, bestDistance = nil, math.huge
	for _, item in ipairs(map:GetDescendants()) do
		if item:IsA("BasePart") and wanted[string.lower(item.Name)] then
			local distance = (item.Position - trialLocation.Position).Magnitude
			if distance < 2500 and distance < bestDistance then
				best, bestDistance = item, distance
			end
		end
	end
	trialPartCache[race] = best
	return best
end

trialAutomationBusy = false
trialRaceLock = nil
trialStartedAt = 0
trialCompletedHoldUntil = 0
trialAttemptCharacter = nil
trialFailureGeneration = 0
trialRetryPending = false
trialHumanFirstMobAt = 0

local function getSeaBeastTargetPart(model)
	if not model or not model:IsA("Model") then return nil end
	local head = model:FindFirstChild("Head")
	local hitbox = model:FindFirstChild("Hitbox")
	local hrp = model:FindFirstChild("HumanoidRootPart")

	if head and head:IsA("BasePart") then
		return head
	end
	if hitbox and hitbox:IsA("BasePart") then
		return hitbox
	end
	if hrp and hrp:IsA("BasePart") then
		return hrp
	end

	local bestPart, bestScore = nil, -math.huge
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			local name = string.lower(desc.Name)
			if name:find("head") then
				return desc
			end
			local vol = desc.Size.X * desc.Size.Y * desc.Size.Z
			local score = vol + desc.Position.Y * 100
			if score > bestScore then
				bestScore = score
				bestPart = desc
			end
		end
	end
	return bestPart or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end

local function findTrialSeaBeast()
	local character = Players.LocalPlayer.Character
	local ownRoot = character and character:FindFirstChild("HumanoidRootPart")
	local bestBeast, bestPart, bestHealth, bestDistance = nil, nil, 0, math.huge
	if not ownRoot then return nil, nil, 0 end

	local function tryCandidate(candidate)
		if not candidate or not candidate:IsA("Model") or candidate == character then return end
		local candidateRoot = getSeaBeastTargetPart(candidate)
		if not candidateRoot then return end
		local hum = candidate:FindFirstChildOfClass("Humanoid")
		local healthVal = candidate:FindFirstChild("Health")
		local hp = (hum and hum.Health)
			or (healthVal and healthVal:IsA("ValueBase") and tonumber(healthVal.Value))
			or 100000
		if hp <= 0 then return end
		local dist = ownRoot and (ownRoot.Position - candidateRoot.Position).Magnitude or 0
		if dist < 5000 and dist < bestDistance then
			bestBeast = candidate
			bestPart = candidateRoot
			bestHealth = hp
			bestDistance = dist
		end
	end

	local seaBeasts = workspace:FindFirstChild("SeaBeasts")
	if seaBeasts then
		for _, child in ipairs(seaBeasts:GetChildren()) do
			tryCandidate(child)
		end
	end

	if not bestBeast then
		for _, child in ipairs(workspace:GetChildren()) do
			local name = string.lower(tostring(child.Name or ""))
			if name:find("seabeast") or name:find("sea beast") or name:find("leviathan") or name:find("water") then
				tryCandidate(child)
			end
		end
		for _, folderName in ipairs({"Enemies", "Characters", "Mobs", "NPCs"}) do
			local folder = workspace:FindFirstChild(folderName)
			if folder and not bestBeast then
				for _, child in ipairs(folder:GetChildren()) do
					local name = string.lower(tostring(child.Name or ""))
					if name:find("seabeast") or name:find("sea beast") or name:find("leviathan") or name:find("water") then
						tryCandidate(child)
					end
				end
			end
		end
	end

	return bestBeast, bestPart, bestHealth
end

function runCurrentRaceTrial(race, trialLocation)
	if tick() - lastTrialActionAt < 0.12 then
		return true
	end
	lastTrialActionAt = tick()
	race = canonicalRaceName(race)
	_G.SHOULDSPAMSKILLS = false
	status("Doing trial: " .. race)
	if race == "Mink" then
		local model = workspace.Map:FindFirstChild("MinkTrial")
		local ceiling = model and model:FindFirstChild("Ceiling")
		if not ceiling then
			status("Trial of Speed - waiting MinkTrial.Ceiling")
			return true
		end
		topos(ceiling.CFrame * CFrame.new(0, -20, 0))
		return true
	elseif race == "Skypiea" then
		local model = workspace.Map:FindFirstChild("SkyTrial")
		local course = model and model:FindFirstChild("Model")
		local finish = course and course:FindFirstChild("FinishPart")
		if not finish then
			status("Trial of the King - waiting SkyTrial.Model.FinishPart")
			return true
		end
		topos(finish.CFrame)
		return true
	elseif race == "Cyborg" then
		local model = workspace.Map:FindFirstChild("CyborgTrial")
		local floor = model and model:FindFirstChild("Floor")
		if not floor then
			status("Trial of the Machine - waiting CyborgTrial.Floor")
			return true
		end
		topos(floor.CFrame * CFrame.new(0, 500, 0))
		return true
	elseif race == "Human" or race == "Ghoul" then
		_G.TYRANT_FARMING = false
		AttackConfig.AutoClickEnabled = false
		local hoverHeight = math.max(4, math.min(15, tonumber(getgenv().Config.HumanTrialHoverHeight) or 10))
		local killDelay = math.max(0.2, math.min(2.0, tonumber(getgenv().Config.HumanTrialKillDelay) or 0.45))
		local postKillDelay = math.max(0.1, math.min(1.0, tonumber(getgenv().Config.HumanTrialPostKillDelay) or 0.25))
		local waveDelay = math.max(0.5, math.min(3.0, tonumber(getgenv().Config.HumanTrialWaveDelay) or 1.2))
		local deadline = tick() + 120
		while tick() < deadline do
			local enemy = getNearestTrialEnemy(trialLocation)
			if not enemy then
				trialHumanFirstMobAt = 0
				status("Trial of Strength - waiting for mobs...")
				topos(trialLocation.CFrame * CFrame.new(0, 10, 0))
				return true
			end
			if trialHumanFirstMobAt == 0 then
				trialHumanFirstMobAt = tick()
				status("Trial of Strength - mob found, waiting " .. string.format("%.1f", waveDelay) .. "s...")
				return true
			end
			if tick() - trialHumanFirstMobAt < waveDelay then
				return true
			end
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
				or enemy:FindFirstChild("UpperTorso")
				or enemy:FindFirstChild("Torso")
				or enemy:FindFirstChild("Head")
				or enemy.PrimaryPart
			local humanoid = enemy:FindFirstChildOfClass("Humanoid")
			if not enemyRoot or not humanoid or humanoid.Health <= 0 then
				task.wait(0.1)
			else
				local mobName = tostring(enemy.Name or "Mob")
				local attemptCharacter = Players.LocalPlayer.Character
				M:stopTween()

				local snapStart = tick()
				local healthKilled = false
				repeat
					task.wait(0.03)
					enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
						or enemy:FindFirstChild("UpperTorso")
						or enemy:FindFirstChild("Torso")
						or enemy:FindFirstChild("Head")
						or enemy.PrimaryPart
					humanoid = enemy:FindFirstChildOfClass("Humanoid")
					if enemyRoot and enemyRoot.Parent then
						local char = Players.LocalPlayer.Character
						local myRoot = char and char:FindFirstChild("HumanoidRootPart")
						if myRoot then
							pcall(function()
								local snapPos = enemyRoot.Position + Vector3.new(0, hoverHeight, 0)
								myRoot.CFrame = safeLookAt(snapPos, enemyRoot.Position)
								myRoot.Velocity = Vector3.zero
								myRoot.AssemblyLinearVelocity = Vector3.zero
							end)
						end
						if not healthKilled and (tick() - snapStart >= killDelay) then
							if humanoid and humanoid.Health > 0 then
								pcall(function()
									humanoid.Health = 0
								end)
								healthKilled = true
							end
						end
					end
				until Players.LocalPlayer.Character ~= attemptCharacter
					or not attemptCharacter.Parent
					or not attemptCharacter:FindFirstChildOfClass("Humanoid")
					or attemptCharacter:FindFirstChildOfClass("Humanoid").Health <= 0
					or not enemy.Parent or not enemyRoot or not humanoid or humanoid.Health <= 0

				if postKillDelay > 0 then
					task.wait(postKillDelay)
				end
			end
			task.wait(0.05)
		end
		AttackConfig.AutoClickEnabled = true
		return true
	elseif race == "Fishman" then
		_G.SHOULDSPAMSKILLS = true
		_G.TRIAL_SKILL_TARGET = nil

		local standHeight = tonumber(getgenv().Config.FishTrialStandHeight) or 350
		local function getSeaBeastStandCFrame(targetRoot)
			return targetRoot.CFrame * CFrame.new(0, standHeight, 0)
		end

		local beast, root, healthVal = findTrialSeaBeast()
		if not beast or not root then
			status("Trial of Water - searching Sea Beast")
			topos(trialLocation.CFrame * CFrame.new(0, standHeight, 0))
			task.wait(0.4)
			return true
		end

		local character = Players.LocalPlayer.Character
		local ownRoot = character and character:FindFirstChild("HumanoidRootPart")
		status("Trial of Water - locking Sea Beast")
		local standCFrame = getSeaBeastStandCFrame(root)
		topos(standCFrame)

		character = Players.LocalPlayer.Character
		ownRoot = character and character:FindFirstChild("HumanoidRootPart")
		if not ownRoot or not root then
			return true
		end

		local function clearSkillForces(char)
			if not char then return end
			for _, desc in ipairs(char:GetDescendants()) do
				if desc:IsA("BodyVelocity") or desc:IsA("BodyPosition") or desc:IsA("BodyGyro")
					or desc:IsA("BodyAngularVelocity") or desc:IsA("BodyForce")
					or desc:IsA("LinearVelocity") or desc:IsA("VectorForce")
					or desc:IsA("AlignPosition") or desc:IsA("AlignOrientation") then
					pcall(function() desc:Destroy() end)
				end
			end
		end

		equipTrialCombatTool()
		pcall(function() CommF_:InvokeServer("Buso") end)
		_G.TRIAL_SKILL_TARGET = root
		_G.SKILL_AIM_TARGET = root
		_G.SHOULDSPAMSKILLS = true

		local attemptCharacter = character
		local loopCount = 0
		setTweenNoclip(true)

		local lockActive = true
		local steppedConn = RunService.Stepped:Connect(function()
			if not lockActive then return end
			local char = Players.LocalPlayer.Character
			local r = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if r and root and root.Parent then
				clearSkillForces(char)
				if hum then
					pcall(function()
						hum.Sit = false
						hum.PlatformStand = false
					end)
				end
				local targetCF = getSeaBeastStandCFrame(root)
				r.CFrame = targetCF
				r.Velocity = Vector3.zero
				pcall(function()
					r.AssemblyLinearVelocity = Vector3.zero
					r.AssemblyAngularVelocity = Vector3.zero
				end)
			end
		end)

		local heartbeatConn = RunService.Heartbeat:Connect(function()
			if not lockActive then return end
			local char = Players.LocalPlayer.Character
			local r = char and char:FindFirstChild("HumanoidRootPart")
			if r and root and root.Parent then
				local targetCF = getSeaBeastStandCFrame(root)
				r.CFrame = targetCF
				r.Velocity = Vector3.zero
				pcall(function()
					r.AssemblyLinearVelocity = Vector3.zero
					r.AssemblyAngularVelocity = Vector3.zero
				end)
			end
		end)

		repeat
			task.wait(0.1)
			loopCount = loopCount + 1
			local currentBeast, currentRoot, currentHp = findTrialSeaBeast()
			if currentRoot then
				root = currentRoot
				beast = currentBeast
				_G.TRIAL_SKILL_TARGET = root
				_G.SKILL_AIM_TARGET = root
				standCFrame = getSeaBeastStandCFrame(root)

				local myChar = Players.LocalPlayer.Character
				local myR = myChar and myChar:FindFirstChild("HumanoidRootPart")
				if myR and (myR.Position - standCFrame.Position).Magnitude > 80 then
					pcall(function()
						clearSkillForces(myChar)
						myR.CFrame = standCFrame
						myR.Velocity = Vector3.zero
						myR.AssemblyLinearVelocity = Vector3.zero
					end)
				end

				if loopCount % 5 == 0 then
					status("Trial of Water - slaying Sea Beast [" .. math.floor(currentHp) .. " HP]")
				end
			else
				break
			end
		until Players.LocalPlayer.Character ~= attemptCharacter
			or not attemptCharacter.Parent
			or not attemptCharacter:FindFirstChildOfClass("Humanoid")
			or attemptCharacter:FindFirstChildOfClass("Humanoid").Health <= 0
			or not beast.Parent

		lockActive = false
		if steppedConn then steppedConn:Disconnect() end
		if heartbeatConn then heartbeatConn:Disconnect() end
		setTweenNoclip(false)
		_G.SHOULDSPAMSKILLS = false
		_G.TRIAL_SKILL_TARGET = nil
		_G.SKILL_AIM_TARGET = nil
		return true
	end
	return false
end

function getTrialTimerVisible()
	local visible = false
	pcall(function()
		visible = Players.LocalPlayer.PlayerGui.Main.Timer.Visible == true
	end)
	if visible then
		return true
	end
	pcall(function()
		local timer = Players.LocalPlayer:FindFirstChild("PlayerGui")
		timer = timer and timer:FindFirstChild("Timer", true)
		visible = timer ~= nil and timer:IsA("GuiObject") and timer.Visible == true
	end)
	return visible
end

equipTrialCombatTool = function()
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end
	local equipped = character:FindFirstChildOfClass("Tool")
	if equipped then
		if _G.USESWORD and equipped.ToolTip == "Sword" then return true end
		if not _G.USESWORD and equipped.ToolTip == "Melee" then return true end
	end
	local backpack = Players.LocalPlayer.Backpack
	local wantTip = _G.USESWORD and "Sword" or "Melee"
	local fallbackTip = _G.USESWORD and "Melee" or "Sword"
	local found = nil
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.ToolTip == wantTip then
			found = tool; break
		end
	end
	if not found then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool.ToolTip == fallbackTip then
				found = tool; break
			end
		end
	end
	if found then
		pcall(function() humanoid:EquipTool(found) end)
		task.wait(0.1)
	else
		M:eq()
	end
	equipped = character:FindFirstChildOfClass("Tool")
	return equipped ~= nil and (equipped.ToolTip == "Melee" or equipped.ToolTip == "Sword")
end

local function resetFailedTrialAttempt(reason)
	if trialCycleDone then
		return
	end
	trialFailureGeneration = trialFailureGeneration + 1
	trialAutomationBusy = false
	trialRaceLock = nil
	trialStartedAt = 0
	trialHumanFirstMobAt = 0
	trialCompletedHoldUntil = 0
	trialAttemptCharacter = nil
	trialRetryPending = true
	lastTrialActionAt = 0
	v3ReadySince = 0
	abilityCooldown = 0
	readySent = false
	scheduledRoundId = ""
	failedRoundId = ""
	handledRoundId = ""
	pairV3ActivatedAt = 0
	pairTrialCycleStarted = false
	lastTempleForceAt = 0
	lastTempleProgressAt = 0
	lastTempleDistance = math.huge
	_G.SHOULDSPAMSKILLS = false
	_G.TRIAL_SKILL_TARGET = nil
	AttackConfig.AutoClickEnabled = true
	pcall(function()
		M:stopTween()
	end)
	resetTrialBarrierState()
	status("Trial failed - returning to race door" .. (reason and (" (" .. reason .. ")") or ""))
end

function isNearOwnTrialArena()
	local race, trialLocation = getOwnTrialLocation()
	if not trialLocation then
		return false, race, nil
	end
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if trialCompletedHoldUntil > tick() then
		local stillNear = root and (root.Position - trialLocation.Position).Magnitude < 1800
		if stillNear and not getTrialTimerVisible() then
			return false, trialRaceLock or race, trialLocation
		end
		trialCompletedHoldUntil = 0
		if not stillNear then
			trialRaceLock = nil
			trialStartedAt = 0
			trialHumanFirstMobAt = 0
		end
	end
	local inside = root ~= nil and humanoid ~= nil and humanoid.Health > 0
		and (root.Position - trialLocation.Position).Magnitude < 1800
	if inside and trialRaceLock == nil then
		trialRaceLock = race
		trialStartedAt = tick()
		trialAttemptCharacter = character
		trialRetryPending = false
	end
	if inside and trialRaceLock and trialRaceLock ~= race then
		race = trialRaceLock
		trialLocation = races_trial_place[race]
	end
	return inside, race, trialLocation
end

function markOwnTrialCompleted(reason)
	trialCompletedHoldUntil = math.huge
	trialRaceLock = nil
	trialStartedAt = 0
	trialHumanFirstMobAt = 0
	trialTimerSeen = false
	trialTimerLostAt = 0
	_G.SHOULDSPAMSKILLS = false
	_G.TRIAL_SKILL_TARGET = nil
	pcall(function()
		M:stopTween()
	end)
	if not trialCycleDone then
		trialCycleDone = true
		trialCycleDoneAt = tick()
	end
	status("Trial completed (" .. tostring(reason or "done") .. ") - holding in Temple")
end

function evaluateOwnTrialCompletion(insideArena)
	if not trialRaceLock or trialStartedAt <= 0 then
		return false
	end
	if isFFAActive() then
		return true, "ffa_started"
	end
	local elapsed = tick() - trialStartedAt
	if not insideArena and elapsed > 8 and (trialTimerSeen or isFFAActive()) then
		if getTrialTimerVisible() then
			return false
		end
		return true, "left_arena"
	end
	if getTrialTimerVisible() then
		trialTimerSeen = true
		trialTimerLostAt = 0
		return false
	end
	if trialTimerSeen then
		if trialTimerLostAt == 0 then
			trialTimerLostAt = tick()
		elseif tick() - trialTimerLostAt >= 2 then
			return true, "timer_ended"
		end
		return false
	end
	if elapsed > 90 and trialTimerSeen then
		return true, "timeout"
	end
	return false
end

function tryRunOwnRaceTrial()
	local inside, race, trialLocation = isNearOwnTrialArena()
	local finished, finishReason = evaluateOwnTrialCompletion(inside)
	if finished then
		markOwnTrialCompleted(finishReason)
		return false
	end
	if not inside then
		if trialRaceLock == "Fishman" and trialStartedAt > 0 and getTrialTimerVisible() then
			local beast, beastRoot = findTrialSeaBeast()
			if beastRoot then
				local standH = tonumber(getgenv().Config.FishTrialStandHeight) or 350
				status("Fish trial - returning above Sea Beast")
				topos(beastRoot.CFrame * CFrame.new(0, standH, 0))
			end
		end
		return false
	end
	if race == "Fishman" or trialRaceLock == "Fishman" then
		_G.SHOULDSPAMSKILLS = true
	end
	pairTrialCycleStarted = true
	if trialAutomationBusy then
		return true
	end
	local attemptGeneration = trialFailureGeneration
	trialAutomationBusy = true
	local ok, result = pcall(runCurrentRaceTrial, race, trialLocation)
	trialAutomationBusy = false
	if attemptGeneration ~= trialFailureGeneration then
		return false
	end
	if not ok then
		_G.SHOULDSPAMSKILLS = false
		_G.TRIAL_SKILL_TARGET = nil
		status("Trial automation error: " .. tostring(result):sub(1, 70))
	end
	return true
end

function isFFAActive()
	local pgui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if pgui then
		for _, gui in ipairs(pgui:GetChildren()) do
			if gui:IsA("ScreenGui") and gui.Enabled then
				for _, desc in ipairs(gui:GetDescendants()) do
					if desc:IsA("TextLabel") and desc.Visible and desc.TextTransparency < 1 then
						local txt = string.lower(tostring(desc.Text or ""))
						if txt:find("fight", 1, true) then
							return true
						end
					end
				end
			end
		end
	end
	local ok, transparency = pcall(function()
		return workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency
	end)
	return ok and transparency == 0
end

function isPlayerInsideAnyTrialArena(plr)
	local character = plr and plr.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return false
	end
	for raceName, _ in pairs(trial_location_names) do
		local location = races_trial_place[raceName]
		if location and (root.Position - location.Position).Magnitude < 1800 then
			return true
		end
	end
	return false
end

function isPlayerBackInTemple(plr)
	local character = plr and plr.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	if (root.Position - TEMPLE_ENTRY_POSITION).Magnitude < 1500 then
		return true
	end
	for _, pos in pairs(pos_plr_trial) do
		if (root.Position - pos.Position).Magnitude < 150 then
			return true
		end
	end
	return false
end

function runTrialCompletionBarrier()
	if not trialCycleDone then
		return
	end
	local postTrialState = getV4Status(false)
	if postTrialState and (postTrialState.needsTraining or postTrialState.needsPurchase or postTrialState.complete) then
		local reason = postTrialState.needsTraining and "post_trial_training"
			or (postTrialState.needsPurchase and "post_trial_upgrade" or "race_v4_completed")
		status(postTrialState.detail or postTrialState.label or "Trial cycle finished")
		resetTrialBarrierState()
		if isUper and isMyUpgearTurn() then
			releaseCurrentGroup(reason)
		end
		return
	end
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	if (root.Position - TEMPLE_ENTRY_POSITION).Magnitude > 3000 then
		pcall(function()
			CommF_:InvokeServer("requestEntrance", TEMPLE_ENTRY_POSITION)
		end)
	else
		pcall(function()
			M:stopTween()
		end)
	end

	local ffaActive = isFFAActive()
	local isHelperRole = isAlly or (isUper and not isMyUpgearTurn())

	if not ffaActive then
		if not matchState.assigned then
			status("Hub cancelled group while holding - resetting for re-pair")
			resetTrialBarrierState()
			return
		end
		if barrierProgressAt <= 0 then
			barrierProgressAt = tick()
		end
		local waiting = math.floor(tick() - barrierProgressAt)
		local roleTimeout = isHelperRole and math.min(50, TRIAL_BARRIER_TIMEOUT)
			or math.min(90, TRIAL_BARRIER_TIMEOUT)
		if tick() - barrierProgressAt > roleTimeout then
			if isHelperRole then
				pcall(releaseCurrentGroup, 'helper_ffa_timeout')
				status("Helper FFA timeout - releasing for re-pair")
			else
				status("Trial barrier timeout - resetting for next trial")
				resetTrialBarrierState()
			end
			return
		end
		status("Trial done - holding in Temple, waiting FFA signal (" .. tostring(waiting) .. "s)")
		return
	end

	if isHelperRole then
		if not helperSacrificeDone then
			if trialBarrierSacrificeAt == 0 then
				trialBarrierSacrificeAt = tick() + 1.5
				status("FFA started - Helper resetting for Main")
				return
			end
			if tick() < trialBarrierSacrificeAt then
				return
			end
			helperSacrificeDone = true
			trialBarrierSacrificeAt = 0
			pcall(function() character:BreakJoints() end)
			pcall(function() humanoid.Health = 0 end)
			pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Dead) end)
			status("Helper reset - Main takes the gear")
			pcall(releaseCurrentGroup, 'helper_sacrificed')
			return
		end
		if tick() - trialCycleDoneAt > 15 then
			pcall(releaseCurrentGroup, 'helper_barrier_timeout')
			status("Helper barrier timeout - releasing for re-pair")
		end
		return
	end

	AttackConfig.AutoClickEnabled = true
	local nearest, nearestDistance = nil, math.huge
	for other in pairs(getplayers(true)) do
		local otherRoot = other:FindFirstChild("HumanoidRootPart")
		if otherRoot then
			local distance = (otherRoot.Position - root.Position).Magnitude
			if distance < nearestDistance then
				nearest, nearestDistance = otherRoot, distance
			end
		end
	end
	if nearest then
		status("FFA - Main clearing the arena")
		pcall(function() topos(nearest.CFrame * CFrame.new(0, 3, 0)) end)
		return
	end
	status("FFA cleared - Main claiming gear at Ancient Clock")
	if tick() - lastBarrierGearCheckAt >= 1.5 then
		lastBarrierGearCheckAt = tick()
		local claimed = false
		pcall(function() claimed = checkgear() end)
		if claimed then
			status("Gear claimed successfully! Trial complete.")
			invalidateV4Status()
			beginPostTrialFarmTransition("gear_claimed")
			return
		end
	end
end

local trialWorkerToken = {}
getgenv().__KAITUN_TRIAL_WORKER = trialWorkerToken
task.spawn(function()
	while getgenv().__KAITUN_TRIAL_WORKER == trialWorkerToken and task.wait(0.1) do
		pcall(tryRunOwnRaceTrial)
	end
end)

task.spawn(function()
	while getgenv().__KAITUN_TRIAL_WORKER == trialWorkerToken and task.wait(0.1) do
		if trialRaceLock and trialAttemptCharacter and not trialCycleDone then
			local currentCharacter = Players.LocalPlayer.Character
			local humanoid = trialAttemptCharacter:FindFirstChildOfClass("Humanoid")
			local replaced = currentCharacter ~= nil and currentCharacter ~= trialAttemptCharacter
			local oldDied = not trialAttemptCharacter.Parent
				or not humanoid or humanoid.Health <= 0
			local died = not replaced and oldDied
			if died then
				trialCharacterReplacedAt = 0
				resetFailedTrialAttempt("died")
			elseif replaced then
				local newRoot = currentCharacter:FindFirstChild("HumanoidRootPart")
				local ownArena = races_trial_place[trialRaceLock]
				local outsideArena = newRoot == nil or ownArena == nil
					or (newRoot.Position - ownArena.Position).Magnitude > 1800
				local elapsed = trialStartedAt > 0 and (tick() - trialStartedAt) or 0
				if oldDied and not isFFAActive() then
					trialCharacterReplacedAt = 0
					resetFailedTrialAttempt("died_in_trial")
				elseif isFFAActive() then
					trialCharacterReplacedAt = 0
					markOwnTrialCompleted("ffa_started")
				elseif outsideArena and elapsed > 8 and (trialTimerSeen or isFFAActive()) then
					trialCharacterReplacedAt = 0
					markOwnTrialCompleted("teleported_out")
				else
					if trialCharacterReplacedAt == 0 then
						trialCharacterReplacedAt = tick()
					elseif tick() - trialCharacterReplacedAt > 3 then
						trialCharacterReplacedAt = 0
						resetFailedTrialAttempt("respawned")
					end
				end
			else
				trialCharacterReplacedAt = 0
			end
		end
	end
end)
-- =====================================================================
-- PHAN 3: TYRANT FARM + RAID FARM (port verbatim v4.lua 4296-6404)
-- =====================================================================

function TyrTweenTo(targetCF, speed, keepNoclip)
	local ok, result = pcall(function()
		return M:topos(targetCF, speed or TweenSpeed, 0, true, keepNoclip ~= false)
	end)
	return ok and result
end

function TyrGetEnemyFolders()
	local folders = {}
	local enemies = workspace:FindFirstChild("Enemies")
	if enemies then
		folders[#folders + 1] = enemies
	end
	local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
	local originEnemies = worldOrigin and worldOrigin:FindFirstChild("Enemies")
	if originEnemies then
		folders[#folders + 1] = originEnemies
	end
	return folders
end

function TyrBaseEnemyName(name)
	name = tostring(name or "")
	name = name:gsub("%s*%[Lv%.%s*%d+%]", "")
	name = name:gsub("%s*%[Boss%]", "")
	name = name:gsub("%s*%[Raid Boss%]", "")
	return name
end

function TyrIsTikiMob(name)
	return TikiMobs[TyrBaseEnemyName(name)] == true
end

function TyrIsTyrant(name)
	return tostring(name or ""):lower():find("tyrant", 1, true) ~= nil
end

function TyrFindTyrant()
	local best, bestDistance = nil, math.huge
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	for _, folder in ipairs(TyrGetEnemyFolders()) do
		for _, enemy in ipairs(folder:GetChildren()) do
			if TyrIsTyrant(enemy.Name) then
				local humanoid = enemy:FindFirstChildOfClass("Humanoid")
				local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
					or enemy:FindFirstChild("UpperTorso")
					or enemy:FindFirstChild("Torso")
					or enemy.PrimaryPart
				if humanoid and enemyRoot and humanoid.Health > 0 then
					local distance = root and (enemyRoot.Position - root.Position).Magnitude or 0
					if distance < bestDistance then
						best, bestDistance = enemy, distance
					end
				end
			end
		end
	end
	return best
end

function TyrGetNearestTikiMob()
	local best, bestDistance = nil, math.huge
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	for _, folder in ipairs(TyrGetEnemyFolders()) do
		for _, enemy in ipairs(folder:GetChildren()) do
			if TyrIsTikiMob(enemy.Name) then
				local humanoid = enemy:FindFirstChildOfClass("Humanoid")
				local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
				if humanoid and enemyRoot and humanoid.Health > 0 then
					local distance = root and (enemyRoot.Position - root.Position).Magnitude or 0
					if distance < bestDistance then
						best, bestDistance = enemy, distance
					end
				end
			end
		end
	end
	return best
end

function TyrFindTikiOutpost()
	return workspace:FindFirstChild("Map")
		and workspace.Map:FindFirstChild("TikiOutpost")
end

function TyrIsEyeActive(eye)
	if not eye or not eye:IsA("BasePart") then
		return false
	end
	if eye.Transparency >= 0.85 then
		return false
	end
	local color = eye.Color
	return color.R >= 0.75
		and color.R > color.G * 1.35
		and color.R > color.B * 1.20
end

function TyrAreTyrantEyesReady()
	local outpost = TyrFindTikiOutpost()
	if not outpost then
		return false, false
	end
	local island = outpost:FindFirstChild("IslandModel")
	if not island then
		return false, false
	end
	local function findEye(parent)
		local first = parent:FindFirstChild("Eye1", true)
		local second = parent:FindFirstChild("Eye2", true)
		return first, second
	end
	local eye1, eye2 = findEye(island)
	if not eye1 or not eye2 then
		return false, false
	end
	return TyrIsEyeActive(eye1) and TyrIsEyeActive(eye2), true
end

function TyrGetObjectPart(object)
	if not object then return nil end
	if object:IsA("BasePart") then
		return object
	end
	if object:IsA("Model") then
		return object.PrimaryPart
			or object:FindFirstChild("Main")
			or object:FindFirstChild("Hitbox")
			or object:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

function TyrIsNearArena(position, radius)
	return (Vector3.new(position.X, ARENA_CENTER.Y, position.Z) - ARENA_CENTER).Magnitude <= (radius or 240)
end

function TyrHasBreakableName(name)
	name = string.lower(TyrBaseEnemyName(name))
	local keywords = { "vase", "amphora", "pot", "urn", "jar" }
	for _, keyword in ipairs(keywords) do
		if name:find(keyword, 1, true) then
			return true
		end
	end
	return false
end

function TyrHasBreakableData(object)
	if not object then return false end
	if object:GetAttribute("Breakable") ~= nil then
		return true
	end
	local ok, tags = pcall(function()
		return CollectionService:GetTags(object)
	end)
	if ok and type(tags) == "table" then
		for _, tag in ipairs(tags) do
			local t = string.lower(tostring(tag))
			if t:find("breakable") or t:find("vase") then
				return true
			end
		end
	end
	return false
end

function TyrIsArenaBreakable(object)
	local name = string.lower(tostring(object.Name or ""))
	local excluded = {
		"tyrantentrance", "bossarena1", "bossarena2", "eye1", "eye2"
	}
	for _, keyword in ipairs(excluded) do
		if name:find(keyword, 1, true) then
			return false
		end
	end
	return TyrHasBreakableName(object.Name) or TyrHasBreakableData(object)
end

function TyrGetArenaBreakables(forceRefresh)
	if not forceRefresh and tick() - (TyrState.LastBreakableScan or 0) < 0.45 then
		return TyrState.CachedBreakables
	end
	TyrState.LastBreakableScan = tick()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local list = {}
	local function addObject(object)
		local part = TyrGetObjectPart(object)
		if part and TyrIsNearArena(part.Position, 260) then
			local distance = root and (part.Position - root.Position).Magnitude or 0
			list[#list + 1] = { object = object, part = part, distance = distance }
		end
	end
	for object in pairs(TyrState.TrackedBreakables) do
		addObject(object)
	end
	local outpost = TyrFindTikiOutpost()
	if outpost then
		for _, object in ipairs(outpost:GetDescendants()) do
			if TyrIsArenaBreakable(object) then
				addObject(object)
			end
		end
	end
	local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
	if worldOrigin then
		for _, object in ipairs(worldOrigin:GetDescendants()) do
			if TyrIsArenaBreakable(object) and TyrIsNearArena(object.Position, 260) then
				addObject(object)
			end
		end
	end
	table.sort(list, function(a, b)
		return a.distance < b.distance
	end)
	TyrState.CachedBreakables = list
	return list
end

function TyrGetAttackTargets(mode)
	local targets = {}
	if mode == "VASES" then
		for _, entry in ipairs(TyrGetArenaBreakables()) do
			targets[#targets + 1] = entry.part
		end
	elseif mode == "BOSS" then
		local tyrant = TyrFindTyrant()
		if tyrant then
			local root = tyrant:FindFirstChild("HumanoidRootPart") or tyrant.PrimaryPart
			if root then
				targets[#targets + 1] = root
			end
		end
	elseif mode == "MOBS" then
		local mob = TyrGetNearestTikiMob()
		if mob then
			local root = mob:FindFirstChild("HumanoidRootPart")
			if root then
				targets[#targets + 1] = root
			end
		end
	end
	return targets
end

local tyrCombo = 0
local tyrLastAttackAt = 0

function TyrLoadAttack()
	if TyrState.AttackLoaded then
		return true
	end
	pcall(function()
		if Net and Net:FindFirstChild("seed") then
			Net:FindFirstChild("seed"):InvokeServer()
		end
	end)
	local targetRemote = nil
	for _, object in ipairs(ReplicatedStorage:GetDescendants()) do
		if object:IsA("RemoteEvent") and object:GetAttribute("Id") then
			targetRemote = object
			break
		end
	end
	if not targetRemote then
		return false
	end
	local seedNumber = math.floor(Workspace:GetServerTimeNow() / 10 % 10) + 1
	local function EncryptedRegisterHit(hitData)
		local clone = table.create(#hitData)
		for index = 1, #hitData do
			clone[index] = hitData[index]
		end
		if type(clone[4]) == "string" then
			local encrypted = ""
			for i = 1, #clone[4] do
				local byte = string.byte(clone[4], i)
				local value = bit32.bxor(byte, seedNumber)
				encrypted = encrypted .. string.char(value)
			end
			clone[4] = encrypted
		end
		local ok = pcall(function()
			targetRemote:FireServer("RE/RegisterHit", clone)
		end)
		return ok
	end

	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	local registerAttack = remotesFolder and remotesFolder:FindFirstChild("RegisterAttack")
	local registerHit = remotesFolder and remotesFolder:FindFirstChild("RegisterHit")
	if not registerAttack or not registerHit then
		return false
	end

	getgenv().TyrantFastAttack = function()
		local maxCombo = 6
		local comboResetTime = 1.4
		if tick() - tyrLastAttackAt > comboResetTime then
			tyrCombo = 0
		end
		tyrLastAttackAt = tick()
		tyrCombo = tyrCombo + 1
		local cooldown = tyrCombo >= maxCombo and 0.9 or 0.4
		pcall(function()
			registerAttack:FireServer(cooldown, tyrCombo)
		end)
		local targets = TyrGetAttackTargets(TyrState.CurrentMode)
		if #targets > 0 then
			local hitData = {}
			hitData[1] = targets[1]
			hitData[2] = {}
			for _, target in ipairs(targets) do
				hitData[2][#hitData[2] + 1] = { target.Parent, target }
			end
			hitData[4] = "078da5141"
			pcall(function()
				registerHit:FireServer(unpack(hitData))
			end)
			EncryptedRegisterHit(hitData)
		end
		if tyrCombo >= maxCombo then
			tyrCombo = 0
		end
	end

	task.spawn(function()
		while TyrState.Farming do
			task.wait(0.03)
			pcall(function()
				if getgenv().TyrantFastAttack then
					getgenv().TyrantFastAttack()
				end
			end)
		end
	end)

	TyrState.AttackLoaded = true
	return true
end

function TyrNormalAttack(duration, aimPart, lockPositionCF)
	duration = tonumber(duration) or 0.5
	local deadline = tick() + duration
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or not root then
		return false
	end
	local lookedAtSomething = false
	while tick() < deadline do
		character = Players.LocalPlayer.Character
		root = character and character:FindFirstChild("HumanoidRootPart")
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 then
			break
		end
		if lockPositionCF then
			pcall(function()
				root.CFrame = lockPositionCF
			end)
		end
		if aimPart and aimPart.Parent then
			pcall(function()
				root.CFrame = safeLookAt(root.Position, aimPart.Position)
			end)
			lookedAtSomething = true
		end
		local tool = character:FindFirstChildOfClass("Tool")
		if tool then
			pcall(function()
				tool:Activate()
			end)
			VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
			VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
		end
		if getgenv().TyrantFastAttack then
			pcall(getgenv().TyrantFastAttack)
		end
		task.wait(0.06)
	end
	return lookedAtSomething
end

function TyrBuyDragonTalon()
	TyrTweenTo(DRAGON_TALON_BUY_POS)
	task.wait(1)
	for _ = 1, 15 do
		local ok, result = pcall(function()
			return CommF_:InvokeServer("BuyDragonTalon")
		end)
		if ok and result then
			return true
		end
		task.wait(0.5)
	end
	return false
end

function TyrNormalizeName(name)
	return string.lower(tostring(name or "")):gsub("%s+", "")
end

function TyrEnsureWeapon(allowBuyDragonTalon)
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid then
		return false
	end
	local equipped = character:FindFirstChildOfClass("Tool")
	if equipped and (equipped.ToolTip == "Melee" or equipped.ToolTip == "Sword") then
		return true
	end
	local backpack = Players.LocalPlayer:FindFirstChildOfClass("Backpack")
	if not backpack then
		return false
	end
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.ToolTip == "Melee" then
			pcall(function() humanoid:EquipTool(tool) end)
			task.wait(0.2)
			return true
		end
	end
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.ToolTip == "Sword" then
			pcall(function() humanoid:EquipTool(tool) end)
			task.wait(0.2)
			return true
		end
	end
	if allowBuyDragonTalon then
		TyrBuyDragonTalon()
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool.ToolTip == "Melee" then
				pcall(function() humanoid:EquipTool(tool) end)
				return true
			end
		end
	end
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and (tool.ToolTip == "Blox Fruit" or tool.ToolTip == "Gun") then
			pcall(function() humanoid:EquipTool(tool) end)
			return true
		end
	end
	return false
end

function TyrEquipMeleeFromBackpack()
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local backpack = Players.LocalPlayer:FindFirstChildOfClass("Backpack")
	if not character or not humanoid or not backpack then
		return false
	end
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.ToolTip == "Melee" then
			pcall(function() humanoid:EquipTool(tool) end)
			return true
		end
	end
	return false
end

function isSkillKeyReady(tool, key)
	local ok, result = pcall(function()
		local skillsGui = Players.LocalPlayer.PlayerGui.Main.Skills
		local skillFrame = skillsGui:FindFirstChild(tool)
		if not skillFrame then return true end
		local keyFrame = skillFrame:FindFirstChild(key)
		if not keyFrame then return true end
		local cooldown = keyFrame:FindFirstChild("Cooldown")
		if cooldown then
			local scale = cooldown.Size.X.Scale
			local offset = cooldown.Size.X.Offset
			if scale > 0 or offset > 0 then
				return false
			end
		end
		local title = keyFrame:FindFirstChild("Title")
		if title and title:IsA("TextLabel") then
			local c = title.TextColor3
			if c.R < 0.9 or c.G < 0.9 or c.B < 0.9 then
				return false
			end
		end
		return true
	end)
	return ok and result
end

function TyrSpamMeleeSkills(aimPart)
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	if aimPart and aimPart.Parent then
		pcall(function()
			root.CFrame = safeLookAt(root.Position, aimPart.Position)
		end)
	end
	for _, key in ipairs({ "Z", "X", "C" }) do
		if isSkillKeyReady("Melee", key) then
			VirtualInputManager:SendKeyEvent(true, key, false, game)
			task.wait(0.08)
			VirtualInputManager:SendKeyEvent(false, key, false, game)
		end
	end
end

function TyrFarmEnemy(isBoss)
	local enemy = TyrFindTyrant() or TyrGetNearestTikiMob()
	if not enemy then
		return false
	end
	TyrState.CurrentTarget = enemy
	TyrState.CurrentMode = isBoss == true and "BOSS" or "MOBS"
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return false
	end
	if not TyrLoadAttack() then
		return false
	end
	TyrEnsureWeapon(true)
	pcall(function() M:haki() end)
	local stuckSince = nil
	while enemy.Parent do
		character = Players.LocalPlayer.Character
		root = character and character:FindFirstChild("HumanoidRootPart")
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 then
			break
		end
		local enemyHumanoid = enemy:FindFirstChildOfClass("Humanoid")
		if not enemyHumanoid or enemyHumanoid.Health <= 0 then
			break
		end
		local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
			or enemy:FindFirstChild("UpperTorso")
			or enemy:FindFirstChild("Torso")
			or enemy.PrimaryPart
		if not enemyRoot then
			break
		end
		local height = isBoss == true and 30 or 25
		local orbitTarget = getExtractOrbitTarget(enemyRoot.CFrame, height)
		pcall(function()
			M:topos(orbitTarget, TweenSpeed, 0, true, true)
		end)
		pcall(function() M:haki() end)
		if getgenv().TyrantFastAttack then
			pcall(getgenv().TyrantFastAttack)
		end
		if not stuckSince then
			stuckSince = tick()
		elseif tick() - stuckSince > 10 then
			stuckSince = nil
			pcall(function()
				root.CFrame = orbitTarget
			end)
			TyrNormalAttack(0.4, enemyRoot)
		end
		task.wait(0.04)
	end
	M:stopTween()
	TyrState.CurrentTarget = nil
	TyrState.CurrentMode = "SWEEP"
	return true
end

function TyrHopServer()
	local ServerBrowser = ReplicatedStorage:FindFirstChild("__ServerBrowser")
	if ServerBrowser then
		for page = 1, 100 do
			local ok, result = pcall(function()
				return ServerBrowser:InvokeServer(page)
			end)
			if ok and type(result) == "table" then
				for _, info in ipairs(result) do
					local count = tonumber(info.Count or info.count or info.Players or info.players) or 0
					local jobId = tostring(info.JobId or info.jobId or info.Id or "")
					if jobId ~= "" and count >= 1 and count < 12 then
						pcall(function()
							ServerBrowser:InvokeServer("teleport", jobId)
						end)
						return true
					end
				end
			end
			task.wait(0.1)
		end
	end
	pcall(function()
		TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
	end)
	return true
end

local VASE_MAX_TIME = 6
local VASE_REACH = 35

function TyrBreakSingleVase(entry)
	local part = entry.part or entry
	local object = entry.object or part.Parent
	local roundStart = tick()
	while object.Parent and tick() - roundStart < VASE_MAX_TIME do
		if not object.Parent then
			return true
		end
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return false
		end
		local target = CFrame.new(part.Position + Vector3.new(0, 6, 0), part.Position)
		if (root.Position - part.Position).Magnitude > VASE_REACH then
			pcall(function()
				M:topos(target, TweenSpeed, 0, true, true)
			end)
		else
			pcall(function()
				root.CFrame = safeLookAt(root.Position, part.Position)
			end)
			TyrSpamMeleeSkills(part)
			TyrNormalAttack(0.55, part)
		end
		task.wait(0.1)
	end
	return not object.Parent
end

function TyrBreakVases(sweepMode, sweepDeadline)
	if not TyrTravelToArena() then
		return false
	end
	local round = 0
	local consecutiveFails = 0
	while TyrState.Farming do
		round = round + 1
		local breakables = TyrGetArenaBreakables(true)
		if #breakables == 0 then
			if sweepMode ~= true then
				if round >= 2 then
					break
				end
			else
				if sweepDeadline and tick() >= sweepDeadline then
					break
				end
				if round >= 2 and consecutiveFails > 0 then
					TyrHopServer()
					return true
				end
				task.wait(0.5)
			end
		end
		local brokenThisRound = 0
		for _, entry in ipairs(breakables) do
			if not TyrState.Farming then
				break
			end
			local destroyed = TyrBreakSingleVase(entry)
			if destroyed then
				brokenThisRound = brokenThisRound + 1
			end
			task.wait(0.1)
		end
		if brokenThisRound == 0 then
			consecutiveFails = consecutiveFails + 1
			if consecutiveFails >= 2 then
				TyrHopServer()
				return true
			end
		else
			consecutiveFails = 0
		end
		if not sweepMode and round >= 2 then
			break
		end
		if sweepMode and sweepDeadline and tick() >= sweepDeadline then
			break
		end
	end
	return true
end

function TyrTravelToArena()
	for _ = 1, 3 do
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return false
		end
		if TyrIsNearArena(root.Position, 180) then
			return true
		end
		TyrTweenTo(TYRANT_ENTRANCE)
		task.wait(1)
		character = Players.LocalPlayer.Character
		root = character and character:FindFirstChild("HumanoidRootPart")
		if root and TyrIsNearArena(root.Position, 180) then
			return true
		end
		TyrTweenTo(ARENA_CENTER and CFrame.new(ARENA_CENTER) or TIKI_CENTER)
		task.wait(1)
	end
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and TyrIsNearArena(root.Position, 180)
end

function TyrWaitForArenaEyes(timeout)
	local deadline = tick() + (tonumber(timeout) or 5)
	while tick() < deadline do
		local ready, found = TyrAreTyrantEyesReady()
		if ready then
			return true
		end
		if not found then
			return false
		end
		task.wait(0.5)
	end
	return false
end

local VaseSweepDuration = 90
function TyrSweepArenaForVases()
	local ready, found = TyrAreTyrantEyesReady()
	if ready then
		return TyrBreakVases(false, nil)
	end
	if not found then
		return TyrBreakVases(true, tick() + VaseSweepDuration)
	end
	return false
end

function TyrSetupRegenTracker()
	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	local regenModel = remotesFolder and remotesFolder:FindFirstChild("RegenModel")
	if not regenModel or TyrState.RegenBound then
		return
	end
	TyrState.RegenBound = true
	regenModel.OnClientEvent:Connect(function(payload)
		pcall(function()
			local decoded
			if getgenv().Encode and type(getgenv().Encode) == "function" then
				decoded = getgenv().Encode("decode", payload)
			else
				decoded = payload
			end
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and type(decoded) == "table" then
				local model = decoded[1] or decoded.model
				if model and model:IsA("Instance") then
					local part = TyrGetObjectPart(model)
					if part and (part.Position - root.Position).Magnitude < 280 then
						TyrState.TrackedBreakables[model] = true
					end
				end
			end
		end)
	end)
end

local tyrantFragmentTarget = 10000
local tyrantSpawnBound = false
local tyrantLastVaseSweep = 0
local vaseSweepInterval = math.max(30, tonumber(getgenv().Config.VaseSweepInterval) or 120)

function TyrBindFarmSpawn()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	if (root.Position - TIKI_CENTER.Position).Magnitude < 120 then
		tyrantSpawnBound = true
		setTrainingSpawnPoint(TIKI_CENTER)
	end
end

function stopTyrantFarming()
	TyrState.Farming = false
	TyrState.CurrentMode = "STOPPED"
	TyrState.CurrentTarget = nil
end

function startTyrantFarming(fragmentTarget)
	tyrantFragmentTarget = tonumber(fragmentTarget) or tyrantFragmentTarget
	TyrState.Farming = true
	TyrState.CurrentMode = "STARTING"
	TyrState.CurrentTarget = nil
	TyrSetupRegenTracker()
	task.spawn(function()
		while TyrState.Farming do
			local ok, err = pcall(function()
				if RaidIsActive() then
					task.wait(1)
					return
				end
				local v4State = getV4Status(false)
				if v4State.canTrial or v4State.complete then
					task.wait(1)
					return
				end
				if getFrags() >= tyrantFragmentTarget then
					task.wait(1)
					return
				end
				local cfg = getgenv().Config["Farm Fragments"] or {}
				local autoraid = cfg.autoraid
				if autoraid and RaidFarming.RetryAt and os.time() >= RaidFarming.RetryAt then
					task.wait(1)
					return
				end
				pcall(function() AutoBusoAndMelee() end)
				TyrEnsureWeapon(true)
				local tyrant = TyrFindTyrant()
				if tyrant then
					TyrFarmEnemy(true)
					return
				end
				local ready = TyrAreTyrantEyesReady()
				if ready then
					TyrBreakVases()
					return
				end
				if tick() - tyrantLastVaseSweep > vaseSweepInterval then
					tyrantLastVaseSweep = tick()
					TyrSweepArenaForVases()
					return
				end
				local mob = TyrGetNearestTikiMob()
				if mob then
					TyrBindFarmSpawn()
					TyrFarmEnemy(false)
					return
				end
				TyrTweenTo(TIKI_CENTER)
				TyrBindFarmSpawn()
			end)
			if not ok then
				status("Tyrant loop error: " .. tostring(err):sub(1, 80))
			end
			task.wait(0.5)
		end
	end)
end

function getAndEquipHeldFruit()
	local character = Players.LocalPlayer.Character
	local backpack = Players.LocalPlayer:FindFirstChildOfClass("Backpack")
	if not backpack then
		return nil
	end
	local held = nil
	if character then
		local equipped = character:FindFirstChildOfClass("Tool")
		if equipped and equipped.ToolTip == "Blox Fruit" then
			held = equipped
		end
	end
	if not held then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool.ToolTip == "Blox Fruit" then
				held = tool
				break
			end
		end
	end
	if not held then
		return nil
	end
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and held.Parent == backpack then
		pcall(function() humanoid:EquipTool(held) end)
		task.wait(0.2)
	end
	return held
end

-- ============ RAID FARM (v4.lua 5384-6404) ============
RaidFarming = {
	Active = false,
	CurrentChip = nil,
	LastRaidAlert = "",
	LastRaidAlert2 = "",
	FruitRetryAt = 0,
	RetryAt = 0,
	Inventory = {},
}

local RAID_FRUIT_VALUES = {
	["rocket"] = 5000, ["spin"] = 7500, ["chop"] = 10000, ["spring"] = 15000,
	["bomb"] = 20000, ["smoke"] = 25000, ["spike"] = 30000, ["flame"] = 40000,
	["bird"] = 45000, ["ice"] = 50000, ["sand"] = 55000, ["dark"] = 60000,
	["diamond"] = 65000, ["light"] = 70000, ["rubber"] = 75000, ["barrier"] = 80000,
	["magma"] = 960000, ["door"] = 90000, ["quake"] = 100000, ["human"] = 110000,
	["dough"] = 120000, ["shadow"] = 130000, ["venom"] = 140000,
	["control"] = 150000, ["gas"] = 160000, ["dragon"] = 170000, [" leopard"] = 180000,
	["kitsune"] = 190000, ["yeti"] = 960000, ["mammoth"] = 200000, ["phoenix"] = 210000,
	["rumble"] = 220000, ["string"] = 230000, ["gravity"] = 240000, [" Buddha"] = 250000,
	["love"] = 260000
}

function normalizeRaidFruitName(name)
	return string.lower(tostring(name or "")):gsub("%s+", ""):gsub("fruit", "")
end

function RaidCleanLoadName(name)
	return string.gsub(tostring(name or ""), "%s+", "")
end

function RaidRefreshInventory()
	local ok, result = pcall(function()
		local ItemReplicationService = game:GetService("ItemReplicationService")
		local KEYS = require(game.ReplicatedStorage.ItemReplicationService.Keys)
		local ItemConfig = require(game.ReplicatedStorage.ItemReplicationService.Config).itemConfig
		local entries = {}
		local function addRecords(records)
			for _, record in pairs(records) do
				local itemId = record.key
				local config = ItemConfig.match(itemId):unwrap()
				if config then
					entries[#entries + 1] = {
						id = itemId,
						name = config.DebugLabel or config.StorageKey or itemId,
						quantity = record.value and record.value[KEYS.QUANTITY] or 0,
						mastery = record.value and record.value[KEYS.MASTERY] or 0,
						owned = record.value and record.value[KEYS.IS_OWNED] or false,
					}
				end
			end
		end
		addRecords(ItemReplicationService:getReplicatedItems(KEYS.QUANTITY))
		addRecords(ItemReplicationService:getReplicatedItems(KEYS.MASTERY))
		addRecords(ItemReplicationService:getReplicatedItems(KEYS.IS_OWNED))
		return entries
	end)
	if ok then
		RaidFarming.Inventory = result
	end
	return ok
end

function RaidGetOwnedUnder1MFruits()
	local owned = {}
	if not RaidRefreshInventory() then
		local character = Players.LocalPlayer.Character
		local backpack = Players.LocalPlayer:FindFirstChildOfClass("Backpack")
		if not backpack then
			return owned
		end
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool.ToolTip == "Blox Fruit" then
				owned[#owned + 1] = { name = tool.Name, value = RAID_FRUIT_VALUES[normalizeRaidFruitName(tool.Name)] or 5000 }
			end
		end
		table.sort(owned, function(a, b) return a.value < b.value end)
		return owned
	end
	for _, record in ipairs(RaidFarming.Inventory) do
		if record.owned then
			local value = RAID_FRUIT_VALUES[normalizeRaidFruitName(record.name)]
				or RAID_FRUIT_VALUES[normalizeRaidFruitName(record.id)] or 5000
			if value < 1000000 then
				local isDup = false
				for _, existing in ipairs(owned) do
					if existing.name == record.name then
						isDup = true
						break
					end
				end
				if not isDup then
					owned[#owned + 1] = { name = record.name, value = value }
				end
			end
		end
	end
	table.sort(owned, function(a, b) return a.value < b.value end)
	return owned
end

function RaidCheckSpecialMicrochip()
	local character = Players.LocalPlayer.Character
	local backpack = Players.LocalPlayer:FindFirstChildOfClass("Backpack")
	local containers = { character, backpack }
	for _, container in ipairs(containers) do
		if container then
			local chip = container:FindFirstChild("Special Microchip")
				or container:FindFirstChild("Microchip")
			if chip then
				return chip
			end
			for _, item in ipairs(container:GetChildren()) do
				local name = tostring(item.Name or "")
				if name:find("Microchip") or name:find("Special") then
					return item
				end
			end
		end
	end
	return nil
end

function RaidRefreshRaidType()
	local ok, result = pcall(function()
		local fruit = tostring(Players.LocalPlayer.Data.DevilFruit.Value)
		fruit = fruit:gsub("Blox Fruit", ""):gsub("%s+", "")
		local raids = require(ReplicatedStorage:WaitForChild("Raids")).raids
		for theme, data in pairs(raids) do
			if string.lower(theme) == string.lower(fruit) then
				return theme
			end
			for _, alias in ipairs(type(data) == "table" and data.aliases or {}) do
				if string.lower(alias) == string.lower(fruit) then
					return theme
				end
			end
		end
		return "Flame"
	end)
	return ok and result or "Flame"
end

function RaidBuyChip(stage)
	local chipType = RaidRefreshRaidType()
	local ok, result = pcall(function()
		return CommF_:InvokeServer("RaidsNpc", "Select", chipType)
	end)
	if not ok then
		return false, "invoke_failed"
	end
	if result == 1 then
		if stage == 1 then
			return true
		end
		return true
	elseif type(result) == "string" then
		return false, result
	end
	if result == 0 then
		return false, "level_too_low"
	end
	return false, tostring(result)
end

function RaidLoadFruitForChip()
	local ok, equippedFruit = pcall(function()
		return getAndEquipHeldFruit()
	end)
	if not ok or not equippedFruit then
		return false
	end
	local candidates = {}
	local function addCandidate(name)
		if name and name ~= "" then
			for _, existing in ipairs(candidates) do
				if existing == name then return end
			end
			candidates[#candidates + 1] = name
		end
	end
	addCandidate(equippedFruit.Name)
	addCandidate(equippedFruit.Name and RaidCleanLoadName(equippedFruit.Name))
	pcall(function()
		addCandidate(equippedFruit:GetAttribute("OriginalName"))
	end)
	local clean = RaidCleanLoadName(equippedFruit.Name):gsub("BloxFruit", "")
	addCandidate(clean)
	for _, candidate in ipairs(candidates) do
		local okBuy, _ = pcall(function()
			return CommF_:InvokeServer("LoadFruit", candidate)
		end)
		if okBuy then
			local deadline = tick() + 2.5
			repeat
				task.wait(0.25)
				local fruitInBackpack = RaidCheckSpecialMicrochip()
				if fruitInBackpack then
					return true
				end
			until tick() >= deadline
		end
	end
	return false
end

function RaidGetTimerText()
	local ok, result = pcall(function()
		for _, gui in ipairs(Players.LocalPlayer.PlayerGui:GetChildren()) do
			if gui:IsA("ScreenGui") then
				for _, label in ipairs(gui:GetDescendants()) do
					if label:IsA("TextLabel") then
						local text = string.lower(tostring(label.Text or ""))
						if text:find("time left", 1, true) then
							return label.Text
						end
					end
				end
			end
		end
		return nil
	end)
	return ok and result or nil
end

function RaidIsActive()
	return RaidGetTimerText() ~= nil
end

function RaidGetIslands()
	local ok, locations = pcall(function()
		return Workspace._WorldOrigin.Locations:GetChildren()
	end)
	if not ok then
		return {}
	end
	local found = {}
	for _, item in ipairs(locations) do
		local name = tostring(item.Name or "")
		local num = tonumber(name:match("Island%s*(%d)"))
		if num and num >= 1 and num <= 5 then
			local part = item:IsA("BasePart") and item
				or (item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")))
			local originPart = Workspace._WorldOrigin:FindFirstChildWhichIsA("BasePart")
			if part and ((part.Position).Magnitude > 7000) then
				found[num] = part.Position
			end
		end
	end
	local islands = {}
	for i = 1, 5 do
		if found[i] then
			islands[#islands + 1] = found[i]
		end
	end
	return islands
end

function RaidGetCurrentIsland()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local islands = RaidGetIslands()
	for _, position in ipairs(islands) do
		if (root.Position - position).Magnitude < 2000 then
			return position
		end
	end
	return nil
end

function currentRaidWave()
	local enemies = {}
	for _, folder in ipairs(TyrGetEnemyFolders()) do
		for _, enemy in ipairs(folder:GetChildren()) do
			local humanoid = enemy:FindFirstChildOfClass("Humanoid")
			local root = enemy:FindFirstChild("HumanoidRootPart")
			if humanoid and root and humanoid.Health > 0 then
				enemies[#enemies + 1] = { enemy = enemy, root = root }
			end
		end
	end
	if #enemies == 0 then
		return nil
	end
	return enemies
end

function RaidGetActiveWaveIsland()
	local islands = RaidGetIslands()
	for _, position in ipairs(islands) do
		for _, folder in ipairs(TyrGetEnemyFolders()) do
			for _, enemy in ipairs(folder:GetChildren()) do
				local root = enemy:FindFirstChild("HumanoidRootPart")
				local humanoid = enemy:FindFirstChildOfClass("Humanoid")
				if root and humanoid and humanoid.Health > 0 and (root.Position - position).Magnitude < 2000 then
					return position
				end
			end
		end
	end
	return nil
end

function RaidGetAllEnemies()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local list = {}
	for _, folder in ipairs(TyrGetEnemyFolders()) do
		for _, enemy in ipairs(folder:GetChildren()) do
			local humanoid = enemy:FindFirstChildOfClass("Humanoid")
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
				or enemy:FindFirstChild("UpperTorso")
				or enemy:FindFirstChild("Torso")
				or enemy.PrimaryPart
			if humanoid and enemyRoot and humanoid.Health > 0 then
				local distance = root and (enemyRoot.Position - root.Position).Magnitude or 0
				if distance < 1000 then
					list[#list + 1] = { enemy = enemy, root = enemyRoot, distance = distance }
				end
			end
		end
	end
	table.sort(list, function(a, b) return a.distance < b.distance end)
	return list
end

function RaidFightAllIslands(maxDuration)
	maxDuration = maxDuration or 600
	local startedAt = tick()
	TyrEnsureWeapon(false)
	while tick() - startedAt < maxDuration do
		if not RaidIsActive() then
			return true
		end
		local enemies = RaidGetAllEnemies()
		if #enemies > 0 then
			for _, entry in ipairs(enemies) do
				pcall(function() M:haki() end)
				local orbitTarget = getExtractOrbitTarget(entry.root.CFrame, 22)
				pcall(function()
					M:topos(orbitTarget, 220, 0, true, true)
				end)
				pcall(function()
					local character = Players.LocalPlayer.Character
					local root = character and character:FindFirstChild("HumanoidRootPart")
					if root then
						root.CFrame = safeLookAt(root.Position, entry.root.Position)
					end
				end)
				if getgenv().TyrantFastAttack then
					pcall(getgenv().TyrantFastAttack)
				end
				TyrNormalAttack(0.2, entry.root)
			end
		else
			local island = RaidGetActiveWaveIsland()
			if island then
				pcall(function()
					M:topos(CFrame.new(island + Vector3.new(0, 100, 0)), 220, 0, true, true)
				end)
			else
				task.wait(1)
			end
		end
		task.wait(0.1)
	end
	return false
end

local RAID_SUMMON_POS = CFrame.new(-5102.186, 310.564, -2922.053)

function RaidFindSummonClickDetector()
	local map = workspace:FindFirstChild("Map")
	local castle = map and map:FindFirstChild("Boat Castle")
	if not castle then
		return nil
	end
	local summon = castle:FindFirstChild("RaidSummon2")
		or castle:FindFirstChild("MainRaid")
	local button = summon and (summon:FindFirstChild("Button") or summon:FindFirstChild("Main"))
	if button then
		return button:FindFirstChildOfClass("ClickDetector")
	end
	return nil
end

function RaidStartSummon()
	if RaidIsActive() then
		return false
	end
	pcall(function()
		M:topos(RAID_SUMMON_POS * CFrame.new(0, 8, 0), TweenSpeed, 0, true, true)
	end)
	task.wait(1)
	local chip = RaidCheckSpecialMicrochip()
	if chip then
		local humanoid = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			pcall(function() humanoid:EquipTool(chip) end)
			task.wait(0.3)
		end
	end
	local detector = RaidFindSummonClickDetector()
	if detector then
		fireclickdetector(detector)
		return true
	end
	return false
end

function RaidWaitForStart(timeout)
	local deadline = tick() + (tonumber(timeout) or 30)
	while tick() < deadline do
		if RaidIsActive() then
			return true
		end
		task.wait(0.5)
	end
	return false
end

function RaidRunOnce(fragmentTarget)
	fragmentTarget = tonumber(fragmentTarget) or tyrantFragmentTarget
	if getFrags() >= fragmentTarget then
		return "stop"
	end
	if RaidIsActive() then
		RaidFightAllIslands()
		return "farmed"
	end
	local level = 0
	pcall(function()
		level = tonumber(Players.LocalPlayer.Data.Level.Value) or 0
	end)
	if level < 1100 then
		return "stop"
	end
	local chip = RaidCheckSpecialMicrochip()
	if not chip then
		local bought, err = RaidBuyChip(1)
		if not bought then
			if type(err) == "string" and #err > 0 then
				RaidFarming.FruitRetryAt = tick() + 10
				RaidFarming.RetryAt = os.time() + 60
				return "wait", err
			end
			RaidFarming.RetryAt = os.time() + 60
			return "wait"
		end
		local loaded = RaidLoadFruitForChip()
		if not loaded then
			RaidFarming.FruitRetryAt = tick() + 10
			RaidFarming.RetryAt = os.time() + 60
			return "wait", "fruit_load_failed"
		end
		local bought2, err2 = RaidBuyChip(2)
		if not bought2 then
			RaidFarming.RetryAt = os.time() + 30
			return "wait", tostring(err2)
		end
		RaidFarming.RetryAt = os.time() + 30
		return "retry"
	end
	if RaidFarming.RetryAt and os.time() < RaidFarming.RetryAt then
		return "wait"
	end
	if not RaidStartSummon() then
		return "retry"
	end
	if not RaidWaitForStart() then
		return "retry"
	end
	RaidFightAllIslands()
	return "farmed"
end

function stopRaidFarming()
	RaidFarming.Active = false
end

function startRaidFarming(fragmentTarget)
	RaidFarming.Active = true
	task.spawn(function()
		while RaidFarming.Active do
			local ok, result, err = pcall(RaidRunOnce, fragmentTarget)
			if not ok then
				status("Raid loop error: " .. tostring(result):sub(1, 80))
			elseif result == "stop" then
				RaidFarming.Active = false
				break
			end
			task.wait(2)
		end
	end)
end

function handleFragmentFarming(fragmentTarget)
	local cfg = getgenv().Config["Farm Fragments"] or getgenv().Config.FarmFragments or { autoraid = true, autotyrant = true }
	local current = getFrags()
	local need = (tonumber(fragmentTarget) or 10000) - current
	if need <= 0 then
		stopTyrantFarming()
		stopRaidFarming()
		return
	end
	substatus("Farm frag: " .. tostring(current) .. "/" .. tostring(fragmentTarget))
	if cfg.autotyrant and not TyrState.Farming then
		startTyrantFarming(fragmentTarget)
	end
	if cfg.autoraid and not RaidFarming.Active then
		local level = 0
		pcall(function()
			level = tonumber(Players.LocalPlayer.Data.Level.Value) or 0
		end)
		if level >= 1100 then
			startRaidFarming(fragmentTarget)
		end
	end
end

function buyPendingV4Upgrade()
	local state = getV4Status(true)
	if not state.needsPurchase then
		return false
	end
	local fallbackCosts = {
		[2] = 1000,
		[4] = 2000,
		[7] = 3250,
		[9] = 4000,
	}
	local cost = tonumber(state.cost) or 0
	if cost <= 0 and state.code then
		cost = fallbackCosts[state.code] or 0
	end
	local fragments = getFrags()
	if cost > 0 and fragments < cost then
		substatus("Can V4: " .. fragments .. "/" .. cost .. " frags")
		handleFragmentFarming(cost)
		return false
	end
	stopTyrantFarming()
	stopRaidFarming()
	local ok, result = pcall(function()
		return invokeUpgradeRace("Buy")
	end)
	invalidateV4Status()
	return ok and result ~= false
end
-- =====================================================================
-- PHAN 4: TRAINING WORK + MAIN ORCHESTRATOR + AIM/SKILL SPAM
-- (port verbatim v4.lua 6406-7304)
-- =====================================================================

function runRaceTrainingWork(trainingState)
	trainingState = trainingState or {}
	local character = Players.LocalPlayer.Character
	if not character then
		status("Training - waiting for character")
		task.wait(0.5)
		return false
	end
	local state = getV4Status(true)
	if state.complete then
		return true
	end
	if state.canTrial and not isAlly then
		return true
	end
	if state.needsPurchase and not isAlly then
		return buyPendingV4Upgrade()
	end
	local raceTransformed = character:FindFirstChild("RaceTransformed")
	if not raceTransformed then
		talktoonggianaodo()
		invalidateV4Status()
		return false
	end
	stopTyrantFarming()
	isCurrentlyTraining = true

	local nextReadyCheck = 0
	local function shouldStopTrainingCycle()
		if tick() < nextReadyCheck then
			return false
		end
		nextReadyCheck = tick() + 0.8
		if isNearOwnTrialArena() then
			return true
		end
		if isAlly then
			return raceTransformed ~= nil
		end
		local s = getV4Status(true)
		if s.canTrial or s.complete or s.needsPurchase then
			return true
		end
		return false
	end

	local raceEnergy = character:FindFirstChild("RaceEnergy")
	if raceEnergy and raceEnergy.Value >= 1 and not raceTransformed.Value then
		pcall(function()
			VirtualInputManager:SendKeyEvent(true, "Y", false, game)
			task.wait(0.1)
			VirtualInputManager:SendKeyEvent(false, "Y", false, game)
		end)
	end

	local islandName = assignTrainingIsland()
	local islandData = TrainingIslandData[islandName]
	local trainingPositions = islandData and (islandData.Positions
		or (islandData.Position and { islandData.Position } or {})) or {}

	local characterReplaced = false
	local charAddedConn
	charAddedConn = Players.LocalPlayer.CharacterAdded:Connect(function()
		characterReplaced = true
	end)

	local function cleanup()
		if charAddedConn then
			charAddedConn:Disconnect()
			charAddedConn = nil
		end
		_G.SHOULDSPAMSKILLS = false
		_G.TRIAL_SKILL_TARGET = nil
		AttackConfig.AutoClickEnabled = false
		pcall(function()
			M:stopTween()
		end)
		invalidateV4Status()
		forceReassignIsland()
		isCurrentlyTraining = false
	end

	local char = Players.LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and trainingPositions[1] and getdis(trainingPositions[1]) >= 1500 then
		cleanup()
		return resetTeleportToTrainingIsland(true, islandName)
	end

	local spawnTarget = trainingPositions[1]
	if spawnTarget then
		setTrainingSpawnPoint(spawnTarget)
	end

	local mobNames = {}
	if islandData and islandData.Mobs then
		for name, _ in pairs(islandData.Mobs) do
			mobNames[#mobNames + 1] = name
		end
	end
	if #mobNames == 0 then
		mobNames = { "Isle Outlaw", "Island Boy", "Sun-kissed Warrior", "Isle Champion" }
	end

	local orbitHeight = math.max(10, tonumber(getgenv().Config["Trial Orbit Height"]) or 30)
	AttackConfig.AutoClickEnabled = true
	equipTrialCombatTool()
	while not characterReplaced do
		char = Players.LocalPlayer.Character
		root = char and char:FindFirstChild("HumanoidRootPart")
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 then
			task.wait(0.5)
			break
		end
		if shouldStopTrainingCycle() then
			break
		end
		local mob = CheckMonster(unpack(mobNames))
		if not mob then
			topos(getCurrentPos())
			task.wait(0.8)
		else
			local mobRoot = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
			repeat
				task.wait()
				pcall(function() M:eq() end)
				pcall(function() M:haki() end)
				char = Players.LocalPlayer.Character
				root = char and char:FindFirstChild("HumanoidRootPart")
				local mobHumanoid = mob:FindFirstChildOfClass("Humanoid")
				if not root or not mobRoot or not root.Parent
					or not mobRoot.Parent or not mobHumanoid or mobHumanoid.Health <= 0 then
					break
				end
				if raceTransformed.Value then
					AttackConfig.AutoClickEnabled = false
					pcall(function()
						M:topos(getExtractOrbitTarget(root.CFrame, 150), TweenSpeed, 0, true, true)
					end)
				else
					AttackConfig.AutoClickEnabled = true
					pcall(function()
						M:topos(getExtractOrbitTarget(mobRoot.CFrame, orbitHeight), TweenSpeed, 0, true, true)
					end)
					pcall(function()
						VirtualInputManager:SendKeyEvent(true, "Y", false, game)
						task.wait(0.05)
						VirtualInputManager:SendKeyEvent(false, "Y", false, game)
					end)
				end
			until characterReplaced
				or Players.LocalPlayer.Character ~= char
				or shouldStopTrainingCycle()
				or not mob:FindFirstChildOfClass("Humanoid")
				or mob:FindFirstChildOfClass("Humanoid").Health <= 0
		end
	end
	cleanup()
	return true
end

function runWaitingAccountWork()
	local state = getV4Status(true)
	if state.needsPurchase then
		substatus("Waiting acc - buying V4 upgrade")
		return buyPendingV4Upgrade()
	end
	if state.needsTraining then
		substatus("Waiting acc - training V4")
		return runRaceTrainingWork({})
	end
	if state.canTrial then
		substatus("Waiting acc - ready for trial, waiting pair")
		return false
	end
	if state.complete then
		substatus("Waiting acc - race complete")
		return false
	end
	substatus("Waiting acc - default training")
	return runRaceTrainingWork({})
end

-- ============ MAIN ORCHESTRATOR (v4.lua 6692-7013) ============
task.spawn(function()
	while task.wait(0.1) do
		local ok, err = pcall(function()
			if not isUper and not isAlly then
				return
			end
			if postTrialTransitionInProgress then
				return
			end
			if trialCycleDone then
				if trialCompletedHoldUntil == math.huge then
					runTrialCompletionBarrier()
				end
				return
			end
			if trialRetryPending then
				forceMatchedAccountToTemple(true)
				tryActivateAbility()
				return
			end
			if isNearOwnTrialArena() then
				return
			end
			local v4s = getV4Status(false)
			local needsIndependentWork = v4s and (v4s.needsTraining or v4s.needsPurchase)
			if needsIndependentWork then
				local mainFinishingTrial = isUper and isMyUpgearTurn()
					and (pairTrialCycleStarted or pairV3ActivatedAt > 0 or handledRoundId ~= "")
				if not mainFinishingTrial then
					if matchState.assigned then
						runWaitingAccountWork()
					else
						runRaceTrainingWork({})
					end
					return
				end
			end
			if not matchState.assigned then
				substatus("Waiting for pair group")
				return
			end
			if tostring(matchState.main_job_id or "") ~= tostring(game.JobId) then
				status("Joining matched Main server")
				return
			end
			if isUper and isMyUpgearTurn() then
				if isInsideOwnTrial() then
					pairTrialCycleStarted = true
					return
				end
			end
			if not (isnight() and isfullmoon()) then
				if pairTrialCycleStarted or pairV3ActivatedAt > 0 then
					status("Waiting full moon - trial already started")
					return
				end
				releaseCurrentGroup("full_moon_ended")
				matchState.assigned = false
				runWaitingAccountWork()
				return
			end
			forceMatchedAccountToTemple()
			local doorState = localDoorState()
			if doorState.timerVisible then
				return
			end
			if doorState.nearDoor then
				local ready, _, info = computeV3ReadyState()
				if ready then
					status(string.format("Paired - at door (%s) waiting V3 sync", tostring(info and info.race or "")))
					tryActivateAbility()
				end
			else
				substatus(string.format("Paired - moving to door (%.0f studs)", doorState.distance))
			end
		end)
		if not ok then
			status("Orchestrator error: " .. tostring(err):sub(1, 90))
		end
	end
end)

-- ============ AIM + SKILL SPAM (v4.lua 7015-7304) ============
local TRIAL_AIM_MAX_DISTANCE = 2000
local TRIAL_AIM_BIND_NAME = "KaitunTrialAim"
local TRIAL_AIM_HOLD = math.max(0.05, 0.35)
local SKILL_AIM_MAX_DISTANCE = math.max(60, 260)
local trialAimHoldUntil = 0

local function getTrialAimPoint(targetCharacter)
	if not targetCharacter then
		return nil
	end
	local hitbox = targetCharacter:FindFirstChild("Hitbox")
	local head = targetCharacter:FindFirstChild("Head")
	local hrp = targetCharacter:FindFirstChild("HumanoidRootPart")
	if hitbox and hitbox:IsA("BasePart") then
		return hitbox
	end
	if head and head:IsA("BasePart") then
		return head
	end
	if hrp and hrp:IsA("BasePart") then
		return hrp
	end
	return targetCharacter.PrimaryPart
end

local function getTrialAimState()
	local aimPart = getActiveAimPart()
	if not aimPart then
		return false, nil
	end
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false, nil
	end
	local distance = (aimPart.Position - root.Position).Magnitude
	if distance > TRIAL_AIM_MAX_DISTANCE then
		return false, nil
	end
	trialAimHoldUntil = tick() + TRIAL_AIM_HOLD
	return true, aimPart
end

RunService:BindToRenderStep(TRIAL_AIM_BIND_NAME, Enum.RenderPriority.Character.Value + 1, function()
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local active, aimPart = getTrialAimState()
	if active and aimPart then
		pcall(function()
			root.CFrame = safeLookAt(root.Position, aimPart.Position)
		end)
	end
end)

local function aimAtSkillTarget()
	local target = _G.SKILL_AIM_TARGET or _G.TRIAL_SKILL_TARGET
	if not target or not target.Parent then
		return
	end
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local distance = (target.Position - root.Position).Magnitude
	if distance <= SKILL_AIM_MAX_DISTANCE then
		pcall(function()
			root.CFrame = safeLookAt(root.Position, target.Position)
		end)
	end
end

local oldNamecallIndex = nil
local oldMouseHit = nil
local oldMouseTarget = nil
pcall(function()
	oldNamecallIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
		if not checkcaller() and self == Players.LocalPlayer:GetMouse() then
			if key == "Hit" then
				local target = _G.SKILL_AIM_TARGET or _G.TRIAL_SKILL_TARGET
				if target and target.Parent then
					return CFrame.new(target.Position)
				end
			elseif key == "Target" then
				local target = _G.SKILL_AIM_TARGET or _G.TRIAL_SKILL_TARGET
				if target and target.Parent then
					return target
				end
			end
		end
		return oldNamecallIndex(self, key)
	end), true)
end)

local function findToolByTip(tip)
	local character = Players.LocalPlayer.Character
	local equipped = character and character:FindFirstChildOfClass("Tool")
	if equipped and equipped.ToolTip == tip then
		return equipped
	end
	local backpack = Players.LocalPlayer:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool.ToolTip == tip then
				return tool
			end
		end
	end
	return nil
end

local function equipTool(tool)
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end
	pcall(function() humanoid:EquipTool(tool) end)
	local deadline = tick() + 0.4
	repeat
		task.wait(0.05)
	until character:FindFirstChildOfClass("Tool") == tool or tick() >= deadline
	return character:FindFirstChildOfClass("Tool") == tool
end

local skillSpamToken = {}
getgenv().__KAITUN_SKILL_SPAM = skillSpamToken
task.spawn(function()
	local fruitsList = {
		"Bomb", "Spike", "Chop", "Spring", "Flame", "Bird", "Smoke", "Spin",
		"Blizzard", "Ice", "Dough", "Dark", "Diamond", "Light", "Rubber",
		"Barrier", "Magma", "Quake", "Buddha", "Love", "Rumble", "Pain",
		"Gravity", "Door", "Shadow", "Venom", "Control", "Gas", "Dragon",
		"Kitsune", "Leopard", "Mammoth", "T-Rex", "Phoenix", "Soul", "Yeti",
		"Battlefield"
	}
	local function isFruitTool(tool)
		for _, name in ipairs(fruitsList) do
			if tostring(tool.Name):find(name) then
				return true
			end
		end
		return false
	end
	local function spamAllReadySkills(toolName, toolTip)
		local ok = pcall(function()
			local skillsGui = Players.LocalPlayer.PlayerGui.Main.Skills
			local toolFrame = skillsGui:FindFirstChild(toolName)
			if not toolFrame then return end
			for _, keyFrame in ipairs(toolFrame:GetChildren()) do
				local keyName = keyFrame.Name
				if keyName == "Z" or keyName == "X" or keyName == "C" or keyName == "V" then
					if keyName == "V" and toolTip ~= "Blox Fruit" then
						continue_placeholder = nil
					else
						local cdFrame = keyFrame:FindFirstChild("Cooldown")
						local titleFrame = keyFrame:FindFirstChild("Title")
						local cdReady = true
						if cdFrame and cdFrame:IsA("Frame") then
							if cdFrame.Size.X.Scale > 0.05 then
								cdReady = false
							end
						end
						local titleReady = true
						if titleFrame and titleFrame:IsA("TextLabel") then
							if titleFrame.TextTransparency >= 0.5 then
								titleReady = false
							end
						end
						if cdReady and titleReady then
							VirtualInputManager:SendKeyEvent(true, keyName, false, game)
							task.wait(0.04)
							VirtualInputManager:SendKeyEvent(false, keyName, false, game)
						end
					end
				end
			end
		end)
		return ok
	end
	while getgenv().__KAITUN_SKILL_SPAM == skillSpamToken do
		if _G.SHOULDSPAMSKILLS then
			local aimTarget = _G.TRIAL_SKILL_TARGET or _G.SKILL_AIM_TARGET
			if aimTarget and aimTarget.Parent then
				aimAtSkillTarget()
			end
			local cycle = { "Melee", "Sword", "Blox Fruit" }
			for _, tip in ipairs(cycle) do
				local tool = findToolByTip(tip)
				if tool then
					equipTool(tool)
					spamAllReadySkills(tool.Name, tip)
				end
			end
			task.wait(0.03)
		else
			task.wait(0.25)
		end
	end
end)

-- ============ SERVER DATA POSTER (v4.lua 7306-7400) ============
local function gettimeserver()
	return math.floor(workspace.DistributedGameTime + 0.5)
end

_G.ShouldSendData = true
task.spawn(function()
	while task.wait(5) do
		if _G.ShouldSendData then
			local ok = pcall(function()
				local request = req()
				if not request then return end
				local payload = {
					name = USERNAME,
					race = getLocalRaceName(),
					status = tostring(getgenv().KaitunStatus or ""),
					substatus = tostring(getgenv().KaitunSubStatus or ""),
					fragments = getFrags(),
					beli = getBeli(),
					jobId = game.JobId,
					placeId = game.PlaceId,
					time = gettimeserver()
				}
				request({
					Url = "https://baorph.x10.mx/data/apiv4.php",
					Method = "POST",
					Headers = { ["Content-Type"] = "application/json" },
					Body = HttpService:JSONEncode(payload)
				})
			end)
			if not ok then
			end
		end
	end
end)

function hopRandom()
	local count = #Players:GetPlayers()
	if count < 12 then
		pcall(function()
			TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
		end)
	end
end
-- =====================================================================
-- PHAN 5: COORDINATOR — CENTRAL HUB WS + FULL MOON HOP + TELEPORT
-- (port verbatim v4.lua 7627-8327)
-- =====================================================================

local function requestFunc(reqr, ...)
	if type(reqr) == "function" then
		return reqr(...)
	end
	return nil
end

local oldCoordinator = getgenv().__KAITUN_V4_COORDINATOR
if oldCoordinator then
	pcall(function()
		if oldCoordinator.socket then
			oldCoordinator.socket:Close()
		end
	end)
	pcall(function()
		if oldCoordinator.localSocket then
			oldCoordinator.localSocket:Close()
		end
	end)
	pcall(function()
		if oldCoordinator.teleportFailureConnection then
			oldCoordinator.teleportFailureConnection:Disconnect()
		end
	end)
end

local coordinator = {
	socket = nil,
	localSocket = nil,
	lastTeleportTick = -math.huge,
	nextTeleportTick = 0,
	pendingJobId = nil,
	failedJobs = {},
	startedAt = tick(),
	requestInFlight = false,
	nextCentralConnectTick = 0,
	centralConnectBackoff = 3,
	localConnectBackoff = 2,
	lastHopReason = "starting",
}
getgenv().__KAITUN_V4_COORDINATOR = coordinator

local function isCoordinatorActive()
	return getgenv().__KAITUN_V4_COORDINATOR == coordinator
end

local function inTrial()
	return trialCycleDone or trialRaceLock ~= nil or isInsideOwnTrial()
end

local function canInterruptForTeleport()
	if isCurrentlyTraining then
		return false
	end
	if postTrialTransitionInProgress then
		return false
	end
	return not inTrial()
end

local function canAcceptHubTeleport()
	if next(HelpWhitelist or {}) ~= nil then
		return true
	end
	local v4State = getV4Status(false)
	return v4State.canTrial == true
		and not v4State.needsTraining
		and not v4State.needsPurchase
		and not v4State.complete
end

local function teleportToJob(jobId, placeId, force)
	local jobId = tostring(jobId or "")
	local placeId = tonumber(placeId) or game.PlaceId
	local requestedJobId = readJobId()
	local requestedPlaceId = readPlaceId()
	if jobId == "" or placeId <= 0 then
		return false
	end
	if jobId == requestedJobId and placeId == requestedPlaceId then
		return false
	end
	if jobId == game.JobId and placeId == game.PlaceId then
		return false
	end
	local now = tick()
	if now < coordinator.nextTeleportTick then
		return false
	end
	if coordinator.failedJobs[jobId] and now - coordinator.failedJobs[jobId] < 60 then
		return false
	end
	if not force and not canInterruptForTeleport() then
		return false
	end
	coordinator.nextTeleportTick = now + 12
	coordinator.lastTeleportTick = now
	coordinator.pendingJobId = jobId

	local teleportOk = false
	if placeId == game.PlaceId then
		local ServerBrowser = ReplicatedStorage:FindFirstChild("__ServerBrowser")
		if ServerBrowser then
			pcall(function()
				ServerBrowser:InvokeServer("teleport", jobId)
				teleportOk = true
			end)
		end
	end
	if not teleportOk then
		pcall(function()
			TeleportService:TeleportToPlaceInstance(placeId, jobId, Players.LocalPlayer)
			teleportOk = true
		end)
	end
	if not teleportOk then
		coordinator.failedJobs[jobId] = now
		coordinator.nextTeleportTick = now + 20
	end
	return teleportOk
end

coordinator.teleportFailureConnection = TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
	if player ~= Players.LocalPlayer then
		return
	end
	if coordinator.pendingJobId then
		coordinator.failedJobs[coordinator.pendingJobId] = tick()
	end
	coordinator.nextTeleportTick = tick() + 20
	task.wait(2)
	teleportToJob(coordinator.pendingJobId, nil, true)
end)

local function getServerList(payload)
	if type(payload) ~= "table" then
		return {}
	end
	if type(payload.data) == "table" and type(payload.data.servers) == "table" then
		return payload.data.servers
	end
	if type(payload.servers) == "table" then
		return payload.servers
	end
	if type(payload.data) == "table" and type(payload.data.jobs) == "table" then
		return payload.data.jobs
	end
	return {}
end

local function parseTimeOfDay(value)
	if type(value) ~= "string" then
		return nil
	end
	local hours, minutes, seconds = value:match("(%d+):(%d+):(%d+)")
	if not hours then
		return nil
	end
	local h = tonumber(hours) or 0
	local m = tonumber(minutes) or 0
	local s = tonumber(seconds) or 0
	return h + m / 60 + s / 3600
end

local function getVerifiedClockTime(report)
	local todValue = report and (report.TimeOfDay or report.timeOfDay or report.time_of_day)
	local todHours = parseTimeOfDay(todValue)
	if todHours == nil then
		return nil
	end
	return todHours
end

local function getFullMoonSecondsRemaining(report)
	local hoursRemaining = tonumber(report and (report.hoursRemaining
		or report.HoursRemaining or report.hours_remaining))
	if not hoursRemaining then
		return 0
	end
	local generatedAt = tonumber(report.generated_at or report.GeneratedAt) or 0
	local freshFor = tonumber(report.fresh_for or report.FreshFor) or 30
	local reportAge = DateTime.now().UnixTimestamp - generatedAt
	local fullMoonCycleSeconds = 25 * 3600
	local rawRemaining = hoursRemaining * (fullMoonCycleSeconds / 24)
	if reportAge >= 0 and reportAge < freshFor then
		return rawRemaining
	end
	local adjusted = rawRemaining - (reportAge - freshFor)
	if adjusted < 0 then
		adjusted = 0
	end
	return adjusted
end

local function currentServerHasFullMoon()
	return isfullmoon() and isnight()
end

local fullMoonPollInterval = math.max(5, tonumber(getgenv().Config.FullMoonPollInterval) or 15)
local fullMoonMinRemaining = math.max(30, tonumber(getgenv().Config.FullMoonMinRemaining) or 120)
local fullMoonMaxPlayers = math.max(1, tonumber(getgenv().Config.FullMoonMaxPlayers) or 8)

local function hopToFullMoonServer(reason)
	local currentPlace = readPlaceId()
	local currentJob = readJobId()
	if not canInterruptForTeleport() then
		return false
	end
	if currentServerHasFullMoon() then
		return false
	end
	local request = req()
	if not request then
		return false
	end
	local ok, response = pcall(function()
		return request({
			Url = tostring(getgenv().Config.FullMoonApiUrl or "https://vortexz-hub.xyz/fullmoon"),
			Method = "GET",
			Headers = { ["Content-Type"] = "application/json" }
		})
	end)
	if not ok or not response or not response.Body then
		return false
	end
	local okDecode, report = pcall(function()
		return HttpService:JSONDecode(response.Body)
	end)
	if not okDecode or type(report) ~= "table" then
		return false
	end
	local generatedAt = tonumber(report.generated_at or report.GeneratedAt) or 0
	local freshFor = tonumber(report.fresh_for or report.FreshFor) or 30
	local reportAge = DateTime.now().UnixTimestamp - generatedAt
	if reportAge < 0 or reportAge > freshFor + 60 then
		return false
	end

	local currentJobIdStr = tostring(currentJob or game.JobId)
	local candidates = {}
	for _, server in ipairs(getServerList(report)) do
		if type(server) == "table" then
			if server.Online ~= false
				and server.FullMoon == true
				and server.FullMoonActive == true
				and server.IsFull ~= true
			then
				local sea = tonumber(server.Sea or server.sea)
				local players = tonumber(server.Players or server.players or server.Count or server.count) or 0
				local jobId = tostring(server.JobId or server.jobId or server.job_id or "")
				local placeId = tonumber(server.PlaceId or server.placeId or server.place_id) or currentPlace
				local secondsRemaining = tonumber(server.secondsRemaining
					or server.SecondsRemaining or server.seconds_remaining) or 0
				if sea == 3
					and players <= fullMoonMaxPlayers
					and secondsRemaining >= fullMoonMinRemaining
					and jobId ~= ""
					and jobId ~= currentJobIdStr
					and placeId > 0
					and not coordinator.failedJobs[jobId]
				then
					candidates[#candidates + 1] = {
						jobId = jobId,
						placeId = placeId,
						players = players,
						secondsRemaining = secondsRemaining,
					}
				end
			end
		end
	end
	table.sort(candidates, function(a, b)
		if a.secondsRemaining ~= b.secondsRemaining then
			return a.secondsRemaining > b.secondsRemaining
		end
		return a.players < b.players
	end)
	if #candidates == 0 then
		return false
	end
	local target = candidates[1]
	return teleportToJob(target.jobId, target.placeId, false)
end

local function getConfiguredHubRole()
	if next(HelpWhitelist or {}) ~= nil then
		return "helper"
	end
	return "main"
end

local function getHubStatus()
	if inTrial() then
		return "IN_TRIAL"
	end
	if matchState and matchState.assigned then
		return "MATCHED"
	end
	local v4State = getV4Status(false)
	if isCurrentlyTraining then
		return "TRAINING"
	end
	if v4State.complete then
		return "MAX_V4"
	end
	if v4State.canTrial then
		if currentServerHasFullMoon() then
			return "WAITING_V4"
		end
		return "SEARCHING_FULL_MOON"
	end
	if v4State.needsTraining or v4State.needsPurchase then
		return "TRAINING"
	end
	return "BUSY"
end

local function applyHubAssignment(payload)
	if type(payload) ~= "table" then
		return false
	end
	local members = payload.members or payload.Members
	if type(members) ~= "table" then
		return false
	end
	local includesLocalPlayer = false
	for _, entry in ipairs(members) do
		local name = type(entry) == "table" and (entry.name or entry.Name) or entry
		if tostring(name) == USERNAME then
			includesLocalPlayer = true
			break
		end
	end
	if not includesLocalPlayer then
		return false
	end
	if #members < 2 then
		return false
	end
	local leader = tostring(payload.leader or payload.Leader or "")
	local groupId = tostring(payload.groupId or payload.group_id or "")
	local targetJobId = tostring(payload.targetJobId or payload.jobId or payload.job_id or "")
	local targetPlaceId = tonumber(payload.targetPlaceId or payload.placeId or payload.place_id) or 0
	if leader == "" or groupId == "" or targetJobId == "" or targetPlaceId <= 0 then
		return false
	end
	getgenv().__KAITUN_HUB_ASSIGNMENT = {
		groupId = groupId,
		leader = leader,
		members = members,
		mode = tostring(payload.mode or "v3"),
		targetJobId = targetJobId,
		targetPlaceId = targetPlaceId,
		receivedAt = tick(),
	}
	matchState.assigned = true
	matchState.group_id = groupId
	matchState.main_username = leader
	matchState.main_job_id = targetJobId
	local helpers = {}
	for _, entry in ipairs(members) do
		local name = type(entry) == "table" and (entry.name or entry.Name) or entry
		if tostring(name) ~= leader then
			helpers[#helpers + 1] = tostring(name)
		end
	end
	matchState.helpers = helpers
	matchState.all_in_job = payload.all_in_job == true
	if matchState.all_in_job then
		scheduleMatchedTempleMove(groupId)
	end
	return true
end

local function sendHubSocketMessage(messageType, payload)
	local socket = coordinator.socket
	if not socket then
		return false
	end
	local ok = pcall(function()
		local send = socket.Send or socket.send
		assert(type(send) == "function", "WebSocket send method is unavailable")
		send(socket, HttpService:JSONEncode({
			type = messageType,
			sender = USERNAME,
			unpack(payload or {})
		}))
	end)
	return ok
end

local function clearHubAssignment()
	templeMoveGeneration = (templeMoveGeneration or 0) + 1
	getgenv().__KAITUN_HUB_ASSIGNMENT = nil
end

local function getWebSocketConnect(url)
	if WebSocket and WebSocket.connect then
		return WebSocket.connect(url)
	end
	if websocket and websocket.connect then
		return websocket.connect(url)
	end
	if syn and syn.websocket and syn.websocket.connect then
		return syn.websocket.connect(url)
	end
	return nil
end

local function bindSocketEvent(socket, onMessage, onClose)
	if not socket then
		return
	end
	pcall(function()
		socket.OnMessage:Connect(function(message)
			onMessage(message)
		end)
	end)
	pcall(function()
		socket.OnClose:Connect(function()
			if onClose then onClose() end
		end)
	end)
end

local function handleHubMessage(rawText)
	local ok, raw = pcall(function()
		return HttpService:JSONDecode(rawText)
	end)
	if not ok or type(raw) ~= "table" then
		return
	end
	local messageType = tostring(raw.type or raw.Type or "")
	if messageType == "V3_COMMAND" then
		if V3_WS_SYNC then
			handleV3CommandMessage(raw)
		end
	elseif messageType == "CANCEL_ASSIGNMENT" then
		local groupId = tostring(raw.groupId or raw.group_id or "")
		local assignment = getgenv().__KAITUN_HUB_ASSIGNMENT
		if not assignment or tostring(assignment.groupId) == groupId then
			clearHubAssignment()
		end
	elseif messageType == "TELEPORT_JOB" then
		local jobId = tostring(raw.jobId or raw.job_id or "")
		local placeId = tonumber(raw.placeId or raw.place_id) or 0
		local force = raw.force == true
		if jobId ~= "" and canAcceptHubTeleport() then
			local ack = applyHubAssignment(raw.payload or raw)
			sendHubSocketMessage("ASSIGNMENT_ACK", { groupId = tostring(raw.groupId or "") , jobId = jobId })
			teleportToJob(jobId, placeId, force)
		end
	end
end

local function closeSocket(socket)
	pcall(function()
		socket:Close()
	end)
end

local function connectCentralHub()
	if not isCoordinatorActive() then
		return
	end
	local url = tostring(getgenv().Config.CentralHubWS or "")
	if url == "" or url:find("HOANGLAM_ISGAY", 1, true) then
		return
	end
	local socket = getWebSocketConnect(url)
	if not socket then
		coordinator.centralConnectBackoff = math.min(30, (coordinator.centralConnectBackoff or 3) * 2)
		coordinator.nextCentralConnectTick = tick() + coordinator.centralConnectBackoff
		return
	end
	coordinator.socket = socket
	coordinator.centralConnectBackoff = 3
	bindSocketEvent(socket, function(message)
		local ok, err = pcall(handleHubMessage, message)
		if not ok then
			status("Hub message error: " .. tostring(err):sub(1, 60))
		end
	end, function()
		coordinator.socket = nil
		coordinator.nextCentralConnectTick = tick() + (coordinator.centralConnectBackoff or 3)
	end)
	status("Central Hub connected")
end

local function getFragmentCount()
	return getFrags()
end

-- Central heartbeat
task.spawn(function()
	while task.wait(3) do
		if not isCoordinatorActive() then break end
		if coordinator.socket then
			local v3fields = getV3HeartbeatFields()
			local fmRemaining = 0
			pcall(function()
				local fm = getFullMoonTimeRemaining()
				fmRemaining = tonumber(fm and fm.secondsRemaining or fm) or 0
			end)
			sendHubSocketMessage("HEARTBEAT", {
				race = tostring(getLocalRaceName()),
				role = getConfiguredHubRole(),
				status = getHubStatus(),
				hopReason = tostring(coordinator.lastHopReason or ""),
				v3Ready = v3fields.v3Ready,
				v3Race = v3fields.v3Race,
				v3DoorDistance = v3fields.v3DoorDistance,
				v3GroupId = v3fields.v3GroupId,
				v3AbilityReady = v3fields.v3AbilityReady,
				fullMoon = currentServerHasFullMoon(),
				fullMoonActive = isfullmoon(),
				fullMoonRemaining = fmRemaining,
				fullMoonText = "",
				task = tostring(getgenv().KaitunStatus or ""),
				subTask = tostring(getgenv().KaitunSubStatus or ""),
				jobId = game.JobId,
				placeId = game.PlaceId,
			})
		elseif centralHubConfigured and tick() >= (coordinator.nextCentralConnectTick or 0) then
			connectCentralHub()
		end
	end
end)

-- Full moon poll
task.spawn(function()
	while task.wait(fullMoonPollInterval) do
		if not isCoordinatorActive() then break end
		local role = getConfiguredHubRole()
		local hubStatus = getHubStatus()
		if role == "main" and hubStatus == "SEARCHING_FULL_MOON" then
			local v4State = getV4Status(false)
			if v4State.canTrial and not v4State.complete and not currentServerHasFullMoon() and canInterruptForTeleport() then
				hopToFullMoonServer("searching_full_moon")
			end
		end
	end
end)
-- =====================================================================
-- PHAN 6: PIPELINE MULTI-RACE (FG Engine / Ghoul V1 / Cyborg V1 / V2 / V3
-- / Mirage + Lever) + FSM CHINH (tick 2.22s) — port tu master_engine v1
-- + ghoulv1.lua + uknow.lua + v3.lua + ghoulv3.lua
-- =====================================================================

-- ============ HOP SERVER (ke thua ghoulv1.lua) ============
local function RobloxServerList(cursor)
	local url = "https://games.roblox.com/v1/games/" .. game.PlaceId
		.. "/servers/Public?sortOrder=Asc&limit=100"
	if cursor then url = url .. "&cursor=" .. cursor end
	local ok, result = pcall(function()
		return HttpService:JSONDecode(game:HttpGet(url))
	end)
	if ok then return result end
	return nil
end

function HopServer(maxPlayers)
	maxPlayers = maxPlayers or 10
	local cursor, found = nil, false
	while not found do
		local servers = RobloxServerList(cursor)
		if servers and servers.data then
			local eligible = {}
			for _, s in ipairs(servers.data) do
				if s.playing >= 1 and s.playing <= maxPlayers then
					table.insert(eligible, s)
				end
			end
			if #eligible > 0 then
				local pick = eligible[math.random(1, #eligible)]
				local ok = pcall(function()
					TeleportService:TeleportToPlaceInstance(game.PlaceId, pick.id, Players.LocalPlayer)
				end)
				if ok then found = true end
			end
		end
		if servers and servers.nextPageCursor then
			cursor = servers.nextPageCursor
		else
			break
		end
		task.wait(0.5)
	end
	task.wait(10)
end

-- Tu dong retry khi teleport fail / kick
task.spawn(function()
	while task.wait(1) do
		pcall(function()
			local overlay = CoreGui.RobloxPromptGui.promptOverlay
			if overlay and overlay:FindFirstChild("ErrorPrompt")
				and not string.find(
					overlay.ErrorPrompt.MessageArea.ErrorFrame.ErrorMessage.Text,
					"Server is full") then
				TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
			end
		end)
	end
end)

-- ============ MODULE 0: FG ENGINE ============
local FGMARKER_DIR = "KaitunDraco"

local function markerPath(name)
	return FGMARKER_DIR .. "/" .. name
end

local function hasFGMarker(playerName, race)
	local ok = pcall(function()
		return readfile(markerPath(playerName .. "_" .. race .. "_FG.txt"))
	end)
	return ok
end

local function writeFGMarker(playerName, race)
	pcall(function()
		if not isfolder(FGMARKER_DIR) then makefolder(FGMARKER_DIR) end
		writefile(markerPath(playerName .. "_" .. race .. "_FG.txt"), "COMPLETED_FG")
	end)
end

local function fgPostData(playerName, race)
	pcall(function()
		local req = (syn and syn.request) or http_request or request
			or (fluxus and fluxus.request)
		local payload = HttpService:JSONEncode({
			Player = playerName,
			Race = race,
			Status = "FG_DONE",
			JobId = game.JobId,
			PlaceId = game.PlaceId,
		})
		if req then
			req({
				Url = "https://vortexz-hub.xyz/api/game-data",
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = payload,
			})
		end
	end)
end

function IsFullGear()
	local ok, v229, v228, v227 = pcall(function()
		return CommF_:InvokeServer("UpgradeRace", "Check")
	end)
	if not ok then return false end
	v229 = tonumber(v229)
	v227 = tonumber(v227)
	if v229 == 5 or v229 == 8 then return true end
	if v229 == 7 and table.find({ 3000, 3250, 3500, 3750, 4000 }, v227) then
		return true
	end
	return false
end

function NextRaceToUpgrade()
	local current = getRace()
	for _, race in ipairs(getgenv().Config.RacesToUpgrade) do
		if race ~= current and not hasFGMarker(Player.Name, race) then
			return race
		end
	end
	return nil
end

-- ============ DOI TOC (Roll tai NPC Tort) ============
function RollRaceTort(targetRace)
	if getRace() == targetRace then return true end
	if not getgenv().Config.AutoRollRace then return false end
	pcall(function()
		CommF_:InvokeServer("Tort", "BuyRace", targetRace)
	end)
	task.wait(2)
	if getRace() == targetRace then return true end
	pcall(function()
		CommF_:InvokeServer("BuyChangeRace", true)
	end)
	task.wait(2)
	return getRace() == targetRace
end

-- ============ MODULE 1: FARM BELI (Haunted Castle - Sea 3) ============
local HauntedMobs = {
	"Reborn Skeleton", "Living Zombie", "Demonic Soul", "Possessed Mummy"
}

-- Di chuyen giua cac Sea bang remote (changefg.lua):
--   Sea1 -> Sea2 : CommF_:InvokeServer("TravelDressrosa")
--   Sea2 -> Sea3 : CommF_:InvokeServer("TravelZou")
-- Dung PLACE_TO_SEA runtime lookup (SEA1/SEA2/SEA3 local bi freeze sau teleport)
local function waitForSeaChange(targetSea, timeout)
	local deadline = tick() + (timeout or 20)
	while tick() < deadline do
		if GetCurrentSea() == targetSea then
			return true
		end
		task.wait(0.5)
	end
	return GetCurrentSea() == targetSea
end

function TravelToSea3()
	if GetCurrentSea() == 3 then return true end
	if GetCurrentSea() == 1 then
		for _ = 1, 3 do
			pcall(function() CommF_:InvokeServer("TravelDressrosa") end)
			if waitForSeaChange(2, 12) then break end
			task.wait(2)
		end
	end
	if GetCurrentSea() == 2 then
		for _ = 1, 3 do
			pcall(function() CommF_:InvokeServer("TravelZou") end)
			if waitForSeaChange(3, 12) then break end
			task.wait(2)
		end
	end
	return GetCurrentSea() == 3
end

function TravelToSea2()
	if GetCurrentSea() == 2 then return true end
	if GetCurrentSea() == 3 then
		for _ = 1, 3 do
			pcall(function() CommF_:InvokeServer("TravelDressrosa") end)
			if waitForSeaChange(2, 12) then break end
			task.wait(2)
		end
	end
	return GetCurrentSea() == 2
end

function TravelToSea1()
	if GetCurrentSea() == 1 then return true end
	if GetCurrentSea() == 3 then
		TravelToSea2()
	end
	if GetCurrentSea() == 2 then
		for _ = 1, 3 do
			pcall(function() CommF_:InvokeServer("TravelDressrosa") end)
			if waitForSeaChange(1, 12) then break end
			task.wait(2)
		end
	end
	return GetCurrentSea() == 1
end

local HAUNTED_CASTLE_POS = CFrame.new(-9530.61035, 200.860657, 5763.13477)

function FarmBeliHauntedCastle()
	TravelToSea3()
	topos(HAUNTED_CASTLE_POS)
	local startBeli = getBeli()
	while getBeli() < getgenv().Config.MinBeli do
		AutoBusoAndMelee()
		local mob = DetectMob(HauntedMobs)
		if mob then
			topos(mob.HumanoidRootPart.CFrame * CFrame.new(0, getgenv().Config.FarmHeight * 0.5, 0), 200)
			if getdis(mob.HumanoidRootPart.CFrame) < getgenv().Config.AttackDistance then
				FireDamageToTargets({ mob })
			end
		else
			topos(HAUNTED_CASTLE_POS * CFrame.new(math.random(-50, 50), 0, math.random(-50, 50)))
		end
		task.wait(0.25)
	end
end

-- ============ MODULE 2A: GHOUL V1 (ke thua ghoulv1.lua) ============
local ShipMobs = {
	"Ship Deckhand", "Ship Steward", "Ship Officer", "Ship Engineer"
}

function GhoulV1()
	if getRace() == "Ghoul" then return true end
	TravelToSea2()
	pcall(function()
		local spawnPos = Workspace.Map.GhostShipInterior.TeleportSpawn.Position
		CommF_:InvokeServer("requestEntrance", spawnPos)
	end)
	task.wait(2)
	while CheckStore("Ectoplasm") < getgenv().Config.GhoulEctoplasmTarget do
		AutoBusoAndMelee()
		local mob = DetectMob(ShipMobs)
		if mob then
			topos(mob.HumanoidRootPart.CFrame * CFrame.new(7, 20, 0), 200)
			if getdis(mob.HumanoidRootPart.CFrame) < 60 then
				FireDamageToTargets({ mob })
			end
		else
			task.wait(1)
		end
	end
	while not CheckTool("Hellfire Torch") do
		if isnight() then
			local boss = Workspace.Enemies and Workspace.Enemies:FindFirstChild("Cursed Captain")
			if boss and CheckAlive(boss) then
				AutoBusoAndMelee()
				topos(boss.HumanoidRootPart.CFrame * CFrame.new(7, 20, 0), 200)
				if getdis(boss.HumanoidRootPart.CFrame) < 60 then
					FireDamageToTargets({ boss })
				end
			else
				HopServer()
				return false
			end
		else
			task.wait(5)
		end
	end
	pcall(function()
		CommF_:InvokeServer("Ectoplasm", "Buy", 4)
	end)
	task.wait(2)
	return getRace() == "Ghoul"
end

-- ============ MODULE 2B: CYBORG V1 (chest reset bypass + SAFETY LOCK) ============
function poscheckspawn(pos)
	local dist, name = math.huge, nil
	local spawns = Workspace["_WorldOrigin"].PlayerSpawns.Pirates
	for _, v in pairs(spawns:GetChildren()) do
		if v:IsA("Model") then
			local m = (v.Part.Position - pos).Magnitude
			if m < dist then dist, name = m, v end
		end
	end
	return name
end

local SAFETY_LOCK = false

local function HasSafetyItem()
	for _, item in ipairs(getgenv().Config.SafetyLockItems) do
		if CheckTool(item) then return item end
	end
	return nil
end

function ResetTeleportBypass(targetPos)
	-- SAFETY LOCK: cam reset khi co FoD / Core Brain / Hellfire Torch
	if HasSafetyItem() then
		SAFETY_LOCK = true
		return false
	end
	local spawn = poscheckspawn(targetPos)
	if not spawn then return false end
	if spawn.Name == plr.Data.LastSpawnPoint.Value then return true end
	plr.Character.LastSpawnPoint.Disabled = true
	local t = tick()
	repeat task.wait()
		plr.Character.LastSpawnPoint.Disabled = true
		pcall(function()
			CommF_:InvokeServer("SetLastSpawnPoint", spawn.Name)
		end)
		plr.Character.HumanoidRootPart.CFrame = spawn.Part.CFrame
		if tick() - t >= 3 and plr.Character.Humanoid.Health > 0 then
			plr.Character.Humanoid.Health = 0
			t = tick()
		end
	until spawn.Name == plr.Data.LastSpawnPoint.Value
	plr.Character.Humanoid.Health = 0
	repeat task.wait()
	until plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0
	return true
end

local LAB_POS = CFrame.new(28282.5, 14896.8, 105.1)

function SafeFlyToLab()
	SAFETY_LOCK = true
	StopTween()
	topos(LAB_POS, 250)
	return true
end

function CyborgV1ChestFarm()
	TravelToSea2()
	local collected = 0
	while not CheckTool("Fist of Darkness") do
		if HasSafetyItem() then
			SafeFlyToLab()
			return "SAFETY_LOCKED"
		end
		local chests = {}
		for _, v in pairs(CollectionService:GetTagged("_ChestTagged")) do
			if v and not v:GetAttribute("IsDisabled") then
				table.insert(chests, v)
			end
		end
		if #chests == 0 then
			task.wait(2)
			if collected >= 7 then
				if not ResetTeleportBypass(Workspace.Map["WaterBase-Plane"].Position) then
					HopServer()
					return false
				end
				collected = 0
			end
		else
			local best, bestDis = nil, math.huge
			for _, chest in ipairs(chests) do
				local d = getdis(chest:GetPivot())
				if d < bestDis then best, bestDis = chest, d end
			end
			if best then
				local pivot = best:GetPivot()
				if getdis(pivot) > 3000 then
					ResetTeleportBypass(pivot.Position)
				else
					topos(pivot, 325)
					VirtualInputManager:SendKeyEvent(true, "Q", false, game)
					task.wait()
					VirtualInputManager:SendKeyEvent(false, "Q", false, game)
					collected = collected + 1
				end
			end
		end
		task.wait(0.5)
	end
	SafeFlyToLab()
	return "FIST_ACQUIRED"
end

function CyborgV1LabAndOrder()
	if CheckTool("Fist of Darkness") then
		EquipWeapon("Fist of Darkness")
		task.wait(0.5)
		pcall(function()
			fireclickdetector(Workspace.Map.CircleIsland.RaidSummon.Button.Main.ClickDetector)
		end)
		task.wait(3)
	end
	if not CheckTool("Core Brain") then
		pcall(function()
			CommF_:InvokeServer("BlackbeardReward", "Microchip", "2")
		end)
		task.wait(2)
		pcall(function()
			fireclickdetector(Workspace.Map.CircleIsland.RaidSummon.Button.Main.ClickDetector)
		end)
		task.wait(3)
	end
	local killedAt = tick()
	while not CheckTool("Core Brain") and tick() - killedAt < 300 do
		local order = Workspace.Enemies and Workspace.Enemies:FindFirstChild("Order")
			or ReplicatedStorage:FindFirstChild("Order")
		if order and CheckAlive(order) then
			AutoBusoAndMelee()
			topos(order.HumanoidRootPart.CFrame * CFrame.new(0, 25, 0), 200)
			if getdis(order.HumanoidRootPart.CFrame) < getgenv().Config.AttackDistance then
				FireDamageToTargets({ order })
			end
		else
			task.wait(1)
		end
	end
	if CheckTool("Core Brain") then
		SAFETY_LOCK = true
		pcall(function()
			fireclickdetector(Workspace.Map.CircleIsland.RaidSummon.Button.Main.ClickDetector)
		end)
		task.wait(3)
		pcall(function()
			CommF_:InvokeServer("CyborgTrainer", "Buy")
		end)
		task.wait(3)
		return getRace() == "Cyborg"
	end
	return false
end

function CyborgV1()
	if getRace() == "Cyborg" then return true end
	local ok, result = pcall(CyborgV1ChestFarm)
	if result == "SAFETY_LOCKED" or result == "FIST_ACQUIRED" then
		return CyborgV1LabAndOrder()
	end
	return false
end

-- ============ MODULE 3: RACE V2 (Alchemist 3 hoa) ============
local function AlchemistFlowerQuest()
	local alchOk, alchStatus = pcall(function()
		return CommF_:InvokeServer("Alchemist", "1")
	end)
	if not alchOk then return false end
	if alchStatus == 0 then
		CommF_:InvokeServer("Alchemist", "2")
		task.wait(1)
		return false
	elseif alchStatus == 1 then
		if not CheckTool("Flower 1") then
			if isnight() then
				if Workspace:FindFirstChild("Flower1") then
					topos(Workspace.Flower1.CFrame)
				end
			else
				HopServer()
			end
		elseif not CheckTool("Flower 2") then
			local mob = DetectMob("Swan Pirate")
			if mob then
				AutoBusoAndMelee()
				topos(mob.HumanoidRootPart.CFrame * CFrame.new(0, 20, 0))
				FireDamageToTargets({ mob })
			else
				topos(CFrame.new(840.431, 121.896, 1239.82))
			end
		elseif not CheckTool("Flower 3") then
			if not isnight() then
				if Workspace:FindFirstChild("Flower3") then
					topos(Workspace.Flower3.CFrame)
				end
			else
				task.wait(5)
			end
		end
		return false
	elseif alchStatus == 2 then
		CommF_:InvokeServer("Alchemist", "3")
		task.wait(2)
		return true
	elseif alchStatus == -2 then
		return true
	end
	return false
end

-- ============ MODULE 4: RACE V3 (Arowe + PvP WS) ============
local raceMap = {
	["Human"] = "Last Resort",
	["Mink"] = "Agility",
	["Fishman"] = "Water Body",
	["Skypiea"] = "Heavenly Blood",
	["Ghoul"] = "Heightened Senses",
	["Cyborg"] = "Energy Core",
	["Draco"] = "Primordial Reign"
}

function CheckRaceV3()
	local ability = raceMap[getRace()]
	if not ability then return "Not Have V3" end
	if plr.Backpack:FindFirstChild(ability)
		or (plr.Character and plr.Character:FindFirstChild(ability)) then
		if plr.Backpack:FindFirstChild("Awakening")
			or (plr.Character and plr.Character:FindFirstChild("Awakening")) then
			return "Have V4"
		end
		return "Have V3"
	end
	return "Not Have V3"
end

local wsSocket = nil
local function wsConnect()
	local connect = (WebSocket and WebSocket.connect)
		or (websocket and websocket.connect)
		or (syn and syn.websocket and syn.websocket.connect)
	if not connect then return nil end
	local ok, sock = pcall(connect, getgenv().Config.CentralHubWS)
	if ok then return sock end
	return nil
end

function RequestPvpHelper(targetRace)
	wsSocket = wsSocket or wsConnect()
	if not wsSocket then return false end
	pcall(function()
		local send = wsSocket.Send or wsSocket.send
		send(wsSocket, HttpService:JSONEncode({
			type = "V3_PVP_REQUEST",
			sender = Player.Name,
			targetRace = targetRace,
			jobId = game.JobId,
			placeId = 4442272183
		}))
	end)
	return true
end

function WaitForHelperAtRendezvous(timeout)
	timeout = timeout or 120
	local startAt = tick()
	while tick() - startAt < timeout do
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				local d = (p.Character.HumanoidRootPart.Position
					- getgenv().Config.PvpRendezvous.Position).Magnitude
				if d < 30 then return p end
			end
		end
		task.wait(2)
	end
	return nil
end

function KillHelperAtRendezvous(helper, killsNeeded)
	killsNeeded = killsNeeded or 1
	local kills = 0
	pcall(function() CommF_:InvokeServer("EnablePvp") end)
	while kills < killsNeeded do
		if not helper or not helper.Character or not CheckAlive(helper.Character) then
			kills = kills + 1
			if kills >= killsNeeded then break end
			helper = WaitForHelperAtRendezvous(20)
			if not helper then break end
		else
			AutoBusoAndMelee()
			topos(helper.Character.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0), 250)
			if getdis(helper.Character.HumanoidRootPart.CFrame) < 10 then
				FireDamageToTargets({ helper.Character })
				for _, key in ipairs({ Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C }) do
					VirtualInputManager:SendKeyEvent(true, key, false, game)
					task.wait(0.05)
					VirtualInputManager:SendKeyEvent(false, key, false, game)
				end
			end
		end
		task.wait(0.1)
	end
end

local function RaceV3Quest()
	local race = getRace()
	local wenOk, wen = pcall(function()
		return CommF_:InvokeServer("Wenlocktoad", "1")
	end)
	if not wenOk then return false end
	if wen == 0 then
		CommF_:InvokeServer("Wenlocktoad", "2")
		return false
	elseif wen == -1 then
		return false
	elseif wen == 2 then
		CommF_:InvokeServer("Wenlocktoad", "3")
		return true
	elseif wen == -2 then
		return true
	elseif wen == 1 then
		if race == "Human" then
			local bosses = { "Jeremy", "Diamond", "Orbitus" }
			local boss = DetectMob(bosses)
			if boss then
				AutoBusoAndMelee()
				topos(boss.HumanoidRootPart.CFrame * CFrame.new(0, 20, 0))
				if getdis(boss.HumanoidRootPart.CFrame) < getgenv().Config.AttackDistance then
					FireDamageToTargets({ boss })
				end
			else
				topos(CFrame.new(840.431, 121.896, 1239.82))
				task.wait(2)
			end
		elseif race == "Mink" then
			local chest = nil
			local bestDis = math.huge
			for _, v in pairs(CollectionService:GetTagged("_ChestTagged")) do
				if v and not v:GetAttribute("IsDisabled") then
					local d = getdis(v:GetPivot())
					if d < bestDis then chest, bestDis = v, d end
				end
			end
			if chest then
				topos(chest:GetPivot(), 325)
				VirtualInputManager:SendKeyEvent(true, "Q", false, game)
				task.wait()
				VirtualInputManager:SendKeyEvent(false, "Q", false, game)
			else
				HopServer()
			end
		elseif race == "Fishman" then
			local sb = Workspace:FindFirstChild("SeaBeasts")
				and Workspace.SeaBeasts:GetChildren()[1]
			if sb then
				if plr.Character.Humanoid.Sit then
					plr.Character.Humanoid.Sit = false
				end
				topos(sb.HumanoidRootPart.CFrame * CFrame.new(0, 20, 0), 250)
				AutoBusoAndMelee()
				for _, key in ipairs({ Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C }) do
					VirtualInputManager:SendKeyEvent(true, key, false, game)
					task.wait(0.05)
					VirtualInputManager:SendKeyEvent(false, key, false, game)
				end
				FireDamageToTargets({ sb })
			else
				pcall(function()
					if not CheckTool("Sharkman Karate") and SEA2 then
						CommF_:InvokeServer("BuySharkmanKarate", true)
					end
				end)
				local boat = CFrame.new(-14.674, 10.25, 2956.18)
				topos(boat)
				pcall(function()
					CommF_:InvokeServer("BuyBoat", "MarineBrigade")
				end)
				task.wait(5)
			end
		elseif race == "Cyborg" then
			local fruit = nil
			local ok, inv = pcall(function()
				return CommF_:InvokeServer("getInventory")
			end)
			if ok and type(inv) == "table" then
				for _, v in pairs(inv) do
					if v.Type == "Blox Fruit" then fruit = v.Name break end
				end
			end
			if fruit then
				pcall(function()
					CommF_:InvokeServer("LoadFruit", fruit)
				end)
			else
				pcall(function()
					CommF_:InvokeServer("PurchaseOddFruit", true)
				end)
			end
		elseif race == "Skypiea" or race == "Ghoul" then
			RequestPvpHelper(race == "Skypiea" and "Skypiea" or "Any")
			topos(getgenv().Config.PvpRendezvous)
			local helper = WaitForHelperAtRendezvous(90)
			if helper then
				KillHelperAtRendezvous(helper, race == "Ghoul" and 5 or 1)
				task.wait(2)
				pcall(function()
					if CommF_:InvokeServer("Wenlocktoad", "1") == 2 then
						CommF_:InvokeServer("Wenlocktoad", "3")
					end
				end)
				return true
			end
		end
	end
	return false
end

-- ============ MODULE 5: MIRAGE NIGHT + BLUE GEAR + PULL LEVER ============
function HighestPoint(island)
	if not island then return nil end
	for _, v in pairs(island:GetDescendants()) do
		if v:IsA("MeshPart") and v.MeshId == "rbxassetid://6745037796" then
			return v
		end
	end
	local maxY = -math.huge
	local topPart = nil
	for _, v in pairs(island:GetDescendants()) do
		if v:IsA("BasePart") and v.Position.Y > maxY then
			maxY, topPart = v.Position.Y, v
		end
	end
	return topPart
end

function MirageNightBlueGear()
	-- CHI CAN BAN DEM (khong can Full Moon)
	while not getBlueGear() do
		local island = Workspace.Map:FindFirstChild("MysticIsland")
		if island and isnight() then
			local top = HighestPoint(island)
			if top then
				topos(top.CFrame * CFrame.new(0, 5, 0))
			end
			local startAt = tick()
			while tick() - startAt < 15 do
				pcall(function()
					if CommE then CommE:FireServer("ActivateAbility") end
				end)
				task.wait(0.5)
			end
			local bg = getBlueGear()
			if bg then
				topos(bg.CFrame)
			end
			task.wait(5)
		end
		task.wait(1)
	end
	return CheckTool("Blue Gear")
end

function PullLeverTempleOfTime()
	local temple = Workspace.Map:FindFirstChild("Temple of Time")
	if not temple then return false end
	local lever = temple:FindFirstChild("Lever", true)
		or temple:FindFirstChild("PullLever", true)
		or temple:FindFirstChild("SecretRoom", true)
	if lever then
		topos(lever:GetPivot())
		local cd = lever:FindFirstChildWhichIsA("ClickDetector", true)
		if cd then
			pcall(function() fireclickdetector(cd) end)
			return true
		end
		pcall(function()
			fireclickdetector(lever:FindFirstChild("ClickDetector", true))
		end)
		return true
	end
	return false
end

-- ============ FSM PIPELINE (tick 2.22s) ============
local CurrentTask = "Idle"

local function SetTask(name)
	CurrentTask = name
	status("[FSM] " .. name)
end

local function CompleteFG()
	local race = getRace()
	writeFGMarker(Player.Name, race)
	fgPostData(Player.Name, race)
	SetTask("FG_DONE:" .. race .. " -> chuyen toc ke tiep")
	getgenv().__KAITUN_V4_PHASE = false
	local nextRace = NextRaceToUpgrade()
	if nextRace then
		RollRaceTort(nextRace)
	else
		SetTask("TAT CA TOC DA FG - HOAN THANH")
		return false
	end
	return true
end

local function V4TrialSyncPhase()
	SetTask("V4: Cho dong bo WS + Full Moon")
	local st = getV4Status(true)
	if st.complete then return "FG" end
	if st.canTrial then
		SetTask("V4: Trial door + ActivateAbility sync")
		pcall(function()
			if CommE then CommE:FireServer("ActivateAbility") end
		end)
	end
	return nil
end

getgenv().EngineRunning = true
getgenv().__KAITUN_V4_PHASE = false

task.spawn(function()
	while getgenv().EngineRunning do
		local ok, err = pcall(function()
			-- V4 phase: orchestrator (phan 4) + coordinator (phan 5) dieu phoi
			if getgenv().__KAITUN_V4_PHASE then
				if IsFullGear() then
					if not CompleteFG() then
						getgenv().EngineRunning = false
						return
					end
				end
				return
			end

			-- ================= BUOC 0: CHECK FG =================
			if IsFullGear() then
				if not CompleteFG() then
					getgenv().EngineRunning = false
					return
				end
				return
			end

			-- ================= BUOC 1: TAI NGUYEN =================
			local currentRace = getRace()
			local beli = getBeli()
			local frags = getFrags()

			if beli < getgenv().Config.MinBeli then
				SetTask("Farm Beli: Haunted Castle (Beli=" .. beli .. ")")
				FarmBeliHauntedCastle()
				return
			end

			local targetRace = nil
			for _, r in ipairs(getgenv().Config.RacesToUpgrade) do
				if not hasFGMarker(Player.Name, r) then
					targetRace = r
					break
				end
			end

			if targetRace == "Cyborg" and currentRace ~= "Cyborg" and frags < getgenv().Config.CyborgMinFrags then
				SetTask("Farm Frag cho Cyborg: Tyrant/Raid (Frag=" .. frags .. ")")
				TravelToSea3()
				handleFragmentFarming(getgenv().Config.CyborgMinFrags)
				return
			end

			-- ================= BUOC 2: LAY TOC HIEM =================
			if targetRace and currentRace ~= targetRace then
				if targetRace == "Ghoul" then
					SetTask("Toc hiem: Ghoul V1 (Cursed Ship)")
					GhoulV1()
					return
				elseif targetRace == "Cyborg" then
					SetTask("Toc hiem: Cyborg V1 (Chest + Lab)")
					CyborgV1()
					return
				else
					SetTask("Roll toc: " .. targetRace .. " (Tort)")
					RollRaceTort(targetRace)
					return
				end
			end

			-- ================= BUOC 3: V2 =================
			local alchOk, alchStatus = pcall(function()
				return CommF_:InvokeServer("Alchemist", "1")
			end)
			if alchOk and alchStatus ~= -2 then
				SetTask("V2: Alchemist Flowers")
				AlchemistFlowerQuest()
				return
			end

			-- ================= BUOC 4: V3 =================
			local wenOk, wen = pcall(function()
				return CommF_:InvokeServer("Wenlocktoad", "1")
			end)
			if wenOk and wen ~= -2 then
				SetTask("V3: Arowe Quest (" .. currentRace .. ")")
				RaceV3Quest()
				return
			end

			-- ================= BUOC 5: MIRAGE + LEVER =================
			if not CheckTool("Blue Gear") then
				SetTask("Mirage Night: soi trang + Blue Gear")
				TravelToSea3()
				MirageNightBlueGear()
				return
			end

			local leverDone = false
			pcall(function()
				local p = CommF_:InvokeServer("RaceV4Progress", "Check")
				leverDone = (tonumber(p) or 0) >= 3
			end)
			if not leverDone then
				SetTask("Pull Lever: Temple of Time")
				TravelToSea3()
				PullLeverTempleOfTime()
				return
			end

			-- ================= BUOC 6: V4 ============
			local v4st = getV4Status(true)
			if v4st.complete then
				CompleteFG()
				return
			end
			SetTask("V4 phase: orchestrator + coordinator tiep quan")
			getgenv().__KAITUN_V4_PHASE = true
		end)
		if not ok then
			status("[FSM error] " .. tostring(err):sub(1, 100))
		end
		task.wait(getgenv().Config.TickInterval)
	end
end)

-- Team setup (changefg.lua: repeat SetTeam until Team + wait Character)
task.spawn(function()
	pcall(function()
		repeat
			CommF_:InvokeServer("SetTeam", getgenv().Config.Team)
			task.wait(1)
		until Player.Team
		repeat task.wait() until Player.Character
	end)
end)

-- Tu dong sang Sea 2 khi o Sea 1 (runtime check, khong bi freeze sau teleport)
task.spawn(function()
	while task.wait(5) do
		pcall(function()
			if GetCurrentSea() == 1 then
				CommF_:InvokeServer("TravelDressrosa")
			end
		end)
	end
end)

print("[Kaitun Draco] Master Engine FULL loaded - FSM tick " .. tostring(getgenv().Config.TickInterval) .. "s")
