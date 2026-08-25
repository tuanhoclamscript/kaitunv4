local getgenv = (typeof(getgenv) == "function" and getgenv) or function() return _G end
print("[v4] script start")
getgenv().Config = {
	["Team"] = "Marines",
	["Farm Fragments"] = {
		autoraid = true,
		autotyrant = true
	},
	["Gear"] = "A-B-B",
	["ChangeBestGear"] = true,
	["V3 Door Distance"] = 50,
	["V3 Countdown"] = 6,
	["V3 Ready Hold Time"] = 0.6,
	["V3 Require Different Races"] = true,
	["V3 Fire Count"] = 1,
	["V3 Fire Interval"] = 0.05,
	["V3 WebSocket Sync"] = true,
	["Reset Teleport After Trial"] = true,
	["Reset Teleport Settle Time"] = 0.45,
	["Pair Temple Timeout"] = 35,
	["Pair Sticky Until Trial Complete"] = true,
	["Pair Release After Trial"] = true,
	["Pair Requeue Delay"] = 15,
	["Pair Force Temple Interval"] = 0.8,
	["Trial Barrier Timeout"] = 50,
	["Fish Trial Stand Height"] = 25,
	["Fish Trial Stand Offset"] = 35,
	["Full Moon API URL"] = "https://vortexz-hub.xyz/fullmoon",
	["Full Moon Poll Interval"] = 15,
	["Full Moon Cycle Seconds"] = 600,
	["Full Moon Minimum Remaining"] = 120,
	["Full Moon Max Players"] = 8,
	["Central Hub WebSocket"] = "ws://13.75.105.170/?token=ditnhaukhong",
	["Central Hub Heartbeat Interval"] = 3,
	["Local Tool Enabled"] = false,
	["Local Tool WebSocket"] = "ws://127.0.0.1:20425/client",
	["Local Tool Heartbeat Interval"] = 1,
	["Training Islands"] = {
		--"Tiki Outpost",
		"Ice Cream Island",
		--"Haunted Castle",
		--"Great Tree",
		--"Port Town",
		--"Peanut Island"
	}
}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local CollectionService = game:GetService("CollectionService")

local function safeFiresignal(signal)
	if not signal then return end
	if typeof(firesignal) == "function" then
		pcall(firesignal, signal)
		return
	end
	if typeof(getconnections) == "function" then
		for _, conn in ipairs(getconnections(signal) or {}) do
			if conn.Function then
				pcall(conn.Function)
			elseif conn.Fire then
				pcall(conn.Fire, conn)
			end
		end
	end
end

local function safeGetGuiParent()
	local parent = nil
	pcall(function()
		parent = gethui and gethui()
	end)
	if not parent then
		pcall(function()
			parent = CoreGui
		end)
	end
	if not parent then
		pcall(function()
			parent = Player and Player:FindFirstChild("PlayerGui")
		end)
	end
	return parent
end

if not game:IsLoaded() then
	pcall(function()
		game.Loaded:Wait()
	end)
end

pcall(function()
	local mapStash = ReplicatedStorage:WaitForChild("MapStash", 5)
	local temple = mapStash and mapStash:WaitForChild("Temple of Time", 5)
	local map = workspace:WaitForChild("Map", 5)
	if temple and map then
		temple.Parent = map
	end
end)

local Player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local LocalPlayer = Player

local Modules = ReplicatedStorage:WaitForChild("Modules", 10)
local Net = Modules and Modules:WaitForChild("Net", 10)
local NetRequired = nil
pcall(function()
	if Net then
		NetRequired = require(Net)
	end
end)
local RegisterAttack = nil
local RegisterHit = nil
pcall(function()
	if NetRequired and type(NetRequired.RemoteEvent) == "function" then
		RegisterAttack = NetRequired:RemoteEvent("RegisterAttack", true)
		RegisterHit = NetRequired:RemoteEvent("RegisterHit", true)
	end
end)
if not RegisterAttack and Net then
	RegisterAttack = Net:FindFirstChild("RE/RegisterAttack") or Net:WaitForChild("RE/RegisterAttack", 5)
end
if not RegisterHit and Net then
	RegisterHit = Net:FindFirstChild("RE/RegisterHit") or Net:WaitForChild("RE/RegisterHit", 5)
end
local ShootGunEvent = Net and (Net:FindFirstChild("RE/ShootGunEvent") or Net:WaitForChild("RE/ShootGunEvent", 5))
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local GunValidator = Remotes and Remotes:WaitForChild("Validator2", 10)
local CommF_ = Remotes and Remotes:WaitForChild("CommF_", 10)
print("[v4] remotes resolved CommF_=" .. tostring(CommF_ ~= nil))

local _bloxttack_seed = nil
local _bloxttack_remoteAttack = nil
local _bloxttack_remoteId = nil

local function GetBloxRemoteAttack()
	if _bloxttack_remoteAttack and _bloxttack_remoteAttack.Parent and _bloxttack_remoteId then
		return true
	end
	_bloxttack_remoteAttack = nil
	_bloxttack_remoteId = nil
	for _, folderName in ipairs({ "Util", "Common", "Remotes", "Assets", "FX" }) do
		local folder = ReplicatedStorage:FindFirstChild(folderName)
		if folder then
			for _, object in ipairs(folder:GetChildren()) do
				if object:IsA("RemoteEvent") and object:GetAttribute("Id") then
					_bloxttack_remoteAttack = object
					_bloxttack_remoteId = object:GetAttribute("Id")
					return true
				end
			end
		end
	end
	return false
end

local function FireEncryptedHit(hitData)
	if not _bloxttack_seed and Net then
		pcall(function()
			local seedRemote = Net:FindFirstChild("seed") or Net:WaitForChild("seed", 2)
			if seedRemote then
				_bloxttack_seed = seedRemote:InvokeServer()
			end
		end)
	end
	if not GetBloxRemoteAttack() or not _bloxttack_seed then
		return
	end
	pcall(function()
		local encodedName = string.gsub("RE/RegisterHit", ".", function(character)
			return string.char(bit32.bxor(string.byte(character), math.floor(Workspace:GetServerTimeNow() / 10 % 10) + 1))
		end)
		_bloxttack_remoteAttack:FireServer(encodedName, bit32.bxor(_bloxttack_remoteId + 909090, _bloxttack_seed * 2), unpack(hitData))
	end)
end

function FireDamageToTargets(targets)
	if not targets or #targets == 0 then
		return false
	end
	local hitData = {
		[1] = nil,
		[2] = {},
		[4] = "078da5141"
	}
	for _, enemy in ipairs(targets) do
		if enemy and enemy.Parent then
			local hitPart = enemy:FindFirstChild("Head")
				or enemy:FindFirstChild("HumanoidRootPart")
				or enemy:FindFirstChild("UpperTorso")
				or enemy:FindFirstChild("Torso")
				or enemy.PrimaryPart
			local hrp = enemy:FindFirstChild("HumanoidRootPart")
				or enemy:FindFirstChild("UpperTorso")
				or enemy:FindFirstChild("Torso")
				or hitPart
			if hitPart and hrp then
				if not hitData[1] then
					hitData[1] = hitPart
				end
				table.insert(hitData[2], { [1] = enemy, [2] = hrp })
				table.insert(hitData[2], enemy)
			end
		end
	end
	if not hitData[1] or #hitData[2] == 0 then
		return false
	end

	-- 1. RegisterAttack: 0 cooldown
	pcall(function()
		if RegisterAttack then
			RegisterAttack:FireServer(0)
		end
		local rawAttack = Net and Net:FindFirstChild("RE/RegisterAttack")
		if rawAttack and rawAttack ~= RegisterAttack then
			rawAttack:FireServer(0)
		end
	end)

	-- 2. RegisterHit: unpack(hitData)
	pcall(function()
		if RegisterHit then
			RegisterHit:FireServer(unpack(hitData))
		end
		local rawHit = Net and Net:FindFirstChild("RE/RegisterHit")
		if rawHit and rawHit ~= RegisterHit then
			rawHit:FireServer(unpack(hitData))
		end
	end)

	-- 3. Encrypted remote pipeline
	pcall(function()
		FireEncryptedHit(hitData)
	end)

	return true
end

local function getCurrentJobId()
	return tostring(game.JobId or "")
end

local function readJobId(value, fallback)
	if type(value) == "table" then
		value = value.JobId or value.JobID or value.jobId or value.jobID
			or value.job_id or value.jobid or value.id or value.Id
	end
	value = tostring(value or fallback or ""):gsub("^%s+", ""):gsub("%s+$", "")
	return value ~= "" and value or nil
end

local function readPlaceId(value, fallback)
	if type(value) == "table" then
		value = value.PlaceId or value.PlaceID or value.placeId or value.placeID
			or value.place_id or value.placeid
	end
	local placeId = tonumber(value or fallback)
	return placeId and placeId > 0 and placeId or nil
end

local cfg = getgenv().Config or {}
local team = cfg["Team"] or getgenv().Team or "Marines"
team = tostring(team)
if team == "Pirate" then
	team = "Pirates"
end
if team ~= "Marines" and team ~= "Pirates" then
	team = "Marines"
end

task.spawn(function()
	local deadline = tick() + 10
	while (not Player.Team or Player.Team.Name ~= team) and tick() < deadline do
		pcall(function()
			if CommF_ then
				CommF_:InvokeServer("SetTeam", team)
			end
		end)
		task.wait(1)
	end
end)

pcall(function()
	if workspace:GetAttribute("MAP") and workspace:GetAttribute("MAP") ~= "Sea3" and CommF_ then
		CommF_:InvokeServer("TravelZou")
	end
end)

getgenv().TyrantConfig = getgenv().TyrantConfig or {
	Team = "Marines",
	Weapon = "Dragon Talon",
	AutoBuyDragonTalon = true,
	AutoBuso = true,
	TweenSpeed = 200,
	FarmHeight = 25,
	BossHeight = 30,
	AttackDistance = 105,
	AttackDelay = 0.03,
	BringMobs = false,
	VaseSweepInterval = 120,
	VaseSweepDuration = 60
}

if not getgenv().Config then
	getgenv().Config = {
		["Team"] = "Marines",
		["ChangeBestGear"] = true,
		["Gear"] = "A-B-B",
		["Farm Fragments"] = {
			autoraid = true,
			autotyrant = true
		},
		["V3 Door Distance"] = 50,
		["V3 Countdown"] = 6,
		["V3 Ready Hold Time"] = 0.6,
		["V3 WebSocket Sync"] = true,
		["V3 Require Different Races"] = true,
		["V3 Fire Count"] = 1,
		["V3 Fire Interval"] = 0.05,
		["Pair Temple Timeout"] = 35,
		["Pair Sticky Until Trial Complete"] = true,
		["Pair Release After Trial"] = true,
		["Pair Requeue Delay"] = 15,
		["Pair Force Temple Interval"] = 0.8,
		["Training Islands"] = {
			--"Tiki Outpost",
			"Ice Cream Island",
			--"Haunted Castle",
			--"Great Tree",
			--"Port Town",
			--"Peanut Island"
		}
	}
end

local bestGearForRace = {
	Ghoul = "B-B-A",
	Cyborg = "A-B-B",
	Mink = "B-B-A",
	Skypiea = "B-B-A",
	Human = "B-A-A",
	Fishman = "B-A-A"
}

if not getgenv().Config["Gear"] or #getgenv().Config["Gear"] ~= 5 then
	getgenv().Config["Gear"] = getgenv().Config["Gear"] or "A-B-B"
end

local isUper = false
local isAlly = false
local mainAccountName = ""
local isMain = false
local isallies = {}

local HelpWhitelist = {}
do
	local rawHelpList = [[
       AntonioMoses4
	   BarryHaas945
	   JodyAli0566
    ]]
	for name in rawHelpList:gmatch("[^\r\n]+") do
		name = name:gsub("^%s+", ""):gsub("%s+$", "")
		if name ~= "" then
			HelpWhitelist[name] = true
		end
	end
end

getgenv().UpdateRoles = function()
	if HelpWhitelist[Player.Name] ~= true then
		-- Every account not explicitly listed as Helper is a Main.
		isUper = true;
		isAlly = false;
		mainAccountName = Player.Name
	else
		isUper = false;
		isAlly = true;
		mainAccountName = ""
	end

	-- Hub assignment overrides the legacy Helper list for this trial group.
	-- The configured role sent in heartbeats remains main/helper as declared.
	local hubAssignment = getgenv().__KAITUN_HUB_ASSIGNMENT
	local assignmentActive = type(hubAssignment) == "table"
		and type(hubAssignment.members) == "table"
		and tick() - (tonumber(hubAssignment.receivedAt) or 0) < 900
	local assignedToGroup = false
	if assignmentActive then
		for _, memberName in ipairs(hubAssignment.members) do
			if memberName == Player.Name then
				assignedToGroup = true
				break
			end
		end
	end
	if assignedToGroup then
		mainAccountName = tostring(hubAssignment.leader or "")
		isUper = Player.Name == mainAccountName
		isAlly = not isUper
	end
	isMain = isUper

    -- C p nh t danh s ch  ng minh
	isallies = {}
	if assignedToGroup then
		for _, memberName in ipairs(hubAssignment.members) do
			if memberName ~= Player.Name then
				isallies[memberName] = true
			end
		end
	elseif isUper then
		for _, p in ipairs(Players:GetPlayers()) do
            -- CH  thu n p nh ng acc C  T N trong danh s ch HelpAccount l m  .
            -- B  qua ho n to n c c acc Main kh c.
			if p.Name ~= Player.Name and HelpWhitelist[p.Name] then
				isallies[p.Name] = true
			end
		end
	elseif isAlly then
		if mainAccountName ~= "" then
			isallies[mainAccountName] = true
		end
	end
end

-- Ch y l n  u ti n
getgenv().UpdateRoles()

getgenv().Config["Team"] = getgenv().Config["Team"]
    and (getgenv().Config["Team"] == "Marines" or getgenv().Config["Team"] == "Pirates")
    and getgenv().Config["Team"] or "Marines"

function thuaaa()
	if Player.Team then
		return
	end
	pcall(function()
		local targetTeam = (getgenv().Team == "Pirates" or (getgenv().Config and getgenv().Config["Team"] == "Pirates")) and "Pirates" or "Marines"
		if CommF_ then
			CommF_:InvokeServer("SetTeam", targetTeam)
		end
	end)
end

thuaaa()

task.spawn(function()
	while task.wait() do
		local char = Player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local bv = hrp:FindFirstChild("BodyClip")
			if not bv then
				bv = Instance.new("BodyVelocity")
				bv.Name = "BodyClip"
				bv.Parent = hrp
				bv.MaxForce = Vector3.new(100000, 100000, 100000)
			end
			bv.Velocity = Vector3.new(0, 0, 0)
		end
	end
end)

pcall(function()
	local pgui = Player:FindFirstChild("PlayerGui")
	local L_207_ = pgui and pgui:FindFirstChild("ChooseTeam", true)
	local L_208_ = pgui and pgui:FindFirstChild("UIController", true)
	if L_207_ and L_207_.Visible and typeof(getgc) == "function" and typeof(getconstants) == "function" and typeof(getfenv) == "function" then
		for _, f in pairs(getgc(true)) do
			if type(f) == "function" and getfenv(f).script == L_208_ then
				local c = getconstants(f)
				pcall(function()
					if (c[1] == "Pirates" or c[1] == "Marines") and #c == 1 then
						f(getgenv().Team or "Marines")
					end
				end)
			end
		end
	end

	if pgui then
		for _, v in pairs(pgui:GetChildren()) do
			if v:FindFirstChild("ChooseTeam") and v.ChooseTeam:FindFirstChild("Container") then
				local targetTeam = getgenv().Config and getgenv().Config["Team"] or "Marines"
				local frame = v.ChooseTeam.Container:FindFirstChild(targetTeam)
				local thua = frame and frame:FindFirstChild("Frame") and frame.Frame:FindFirstChild("TextButton")
				if thua then
					safeFiresignal(thua.Activated)
				end
			end
		end
	end
end)

local module = {}

pcall(function()
	local pgui = Player:FindFirstChild("PlayerGui")
	if pgui and pgui:FindFirstChild("LoadingScreen") then
		local startCheck = tick()
		repeat
			task.wait(0.2)
		until not pgui:FindFirstChild("LoadingScreen") or tick() - startCheck > 6
	end
end)

local player = Player
local char = player.Character
local hrp = char and char:FindFirstChild("HumanoidRootPart")

function module:eq()
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		return
	end
	local character = player.Character
	if not character or not character:FindFirstChild("Humanoid") then
		return
	end
	for _, L in pairs(backpack:GetChildren()) do
		if L:IsA("Tool") and L["ToolTip"] == "Melee" and not _G.USESWORD then
			local a = pcall(function()
				character.Humanoid:EquipTool(L)
			end)
			if a then
				break
			end
		elseif L:IsA("Tool") and L["ToolTip"] == "Sword" and _G.USESWORD then
			local a = pcall(function()
				character.Humanoid:EquipTool(L)
			end)
			if a then
				break
			end
		end
	end
end

local lastHakiRequestAt = -math.huge
function module:haki()
	local character = player.Character
	if character and not character:FindFirstChild("HasBuso") and tick() - lastHakiRequestAt >= 2 then
		lastHakiRequestAt = tick()
		CommF_:InvokeServer("Buso")
	end
end

smoothTweenId = 0
smoothTweenRunning = false
smoothTweenTarget = nil
smoothTweenSpeed = 200
tweenNoclipConnection = nil
tweenCollisionStates = {}
extractOrbitAngle = 30
extractOrbitLastChange = tick()

local function setTweenNoclip(enabled)
	if enabled then
		if tweenNoclipConnection then
			return
		end
		tweenNoclipConnection = RunService.Stepped:Connect(function()
			local character = player.Character
			if not character then
				return
			end
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					if tweenCollisionStates[part] == nil then
						tweenCollisionStates[part] = part.CanCollide
					end
					part.CanCollide = false
				end
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

-- CFrame.lookAt is undefined when the direction is parallel to the up vector.
-- The Sea Beast trial hovered exactly above its target, so the lock produced a
-- NaN CFrame and the skills fired at nothing.
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

-- Aim target dung chung cho ca trial (Sea Beast) va farm/dap binh.
-- _G.TRIAL_SKILL_TARGET chi song khi _G.SHOULDSPAMSKILLS = true, con
-- _G.SKILL_AIM_TARGET dung cho moi truong hop khac (binh, Tyrant, mob):
-- khong lock camera, chi quay than nhan vat va con tro dung luc ban skill.
_G.SKILL_AIM_TARGET = nil

-- Doc part dang can aim, uu tien target cua trial de khong doi hanh vi cu.
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

-- The tween writes the root CFrame every Heartbeat, after the aim RenderStep,
-- so a plain CFrame.new(position) erased the rotation skills are fired along.
function trialAimLookCFrame(position)
	local target = getActiveAimPart()
	if target then
		return safeLookAt(position, target.Position)
	end
	return CFrame.new(position)
end

local function normalizeTweenTarget(target)
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

-- Extract keeps the player moving around the target instead of hovering at one
-- fixed point. The angle advances in 80 degree steps every 0.4 seconds.
local function getExtractOrbitTarget(target, height)
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

function module:stopTween()
	smoothTweenId = smoothTweenId + 1
	smoothTweenRunning = false
	smoothTweenTarget = nil
	setTweenNoclip(false)
end

function module:topos(target, speed, heightOffset, useNoclip, keepNoclip)
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

	local character = player.Character or player.CharacterAdded:Wait()
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
	local reachedTarget = false
	local lastSubUpdate = 0
	while currentTweenId == smoothTweenId do
		if _G.Stop then
			break
		end
		character = player.Character
		local currentRoot = character and character:FindFirstChild("HumanoidRootPart")
		if currentRoot ~= root then
			break
		end
		local progress = math.min((tick() - startedAt) / duration, 1)
		root.CFrame = trialAimLookCFrame(startPosition:Lerp(destination, progress))
		if tick() - lastSubUpdate >= 0.5 then
			lastSubUpdate = tick()
			local remDist = (destination - root.Position).Magnitude
			substatus(string.format("Tweening (%.0fm)", remDist))
		end
		if progress >= 1 then
			reachedTarget = true
			break
		end
		RunService.Heartbeat:Wait()
	end

	if currentTweenId == smoothTweenId then
		smoothTweenRunning = false
		smoothTweenTarget = nil
		if not keepNoclip then
			setTweenNoclip(false)
		end
	end
	return reachedTarget
end

function module:join(v2)
	v2 = v2 and (v2 == "Marines" or v2 == "Pirates") and v2 or "Marines"
	pcall(function()
		local pgui = player:FindFirstChild("PlayerGui")
		if not pgui then return end
		for i, v in pairs(pgui:GetChildren()) do
			if v:FindFirstChild("ChooseTeam") and v.ChooseTeam:FindFirstChild("Container") then
				local container = v.ChooseTeam.Container:FindFirstChild(v2)
				local thua = container and container:FindFirstChild("Frame") and container.Frame:FindFirstChild("TextButton")
				if thua then
					safeFiresignal(thua.Activated)
				end
			end
		end
	end)
end

function module:tele(v)
	pcall(function()
		local serverBrowser = ReplicatedStorage:FindFirstChild("__ServerBrowser")
		if serverBrowser then
			serverBrowser:InvokeServer("teleport", v or game.JobId)
		else
			TeleportService:TeleportToPlaceInstance(game.PlaceId, v or game.JobId, Player)
		end
	end)
end

function module:noclip(v)
	task.spawn(function()
		while task.wait(0.1) do
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local shouldNoclip = false
			if type(v) == "function" then
				pcall(function() shouldNoclip = v() == true end)
			elseif type(v) == "string" then
				pcall(function() shouldNoclip = loadstring(v)() == true end)
			elseif v == true then
				shouldNoclip = true
			end
			if shouldNoclip and hum and not hum.Sit and root then
				if not root:FindFirstChild("BodyClip") then
					local L_348_ = Instance.new("BodyVelocity")
					L_348_.Name = "BodyClip"
					L_348_.Parent = root
					L_348_.MaxForce = Vector3.new(100000, 100000, 100000)
					L_348_.Velocity = Vector3.new(0, 0, 0)
				end
				for _, d in pairs(char:GetDescendants()) do
					if d:IsA("BasePart") then
						d.CanCollide = false
					end
				end
			else
				pcall(function()
					if root and root:FindFirstChild("BodyClip") then
						root.BodyClip:Destroy()
					end
				end)
			end
		end
	end)
end

function module:getdis(x, y)
	if not x then return math.huge end
	local xPos = typeof(x) == "CFrame" and x.Position or (typeof(x) == "Vector3" and x or (x:IsA("BasePart") and x.Position or Vector3.zero))
	if not y then
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return math.huge end
		return (xPos - hrp.Position).Magnitude
	end
	local yPos = typeof(y) == "CFrame" and y.Position or (typeof(y) == "Vector3" and y or (y:IsA("BasePart") and y.Position or Vector3.zero))
	return (xPos - yPos).Magnitude
end

player.Idled:Connect(function()
	pcall(function()
		game:GetService("VirtualUser"):Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
		task.wait(1)
		game:GetService("VirtualUser"):Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
	end)
end)

local topofgreattree = CFrame.new(3035.15137, 2281.15918, -7325.19189)

function getdoor(vv)
	if not vv then
		vv = getLocalRaceName()
	end
	local corridorRaceAliases = { Rabbit = "Mink", Shark = "Fishman", Angel = "Skypiea" }
	vv = corridorRaceAliases[tostring(vv)] or tostring(vv)
	local temple = workspace.Map:FindFirstChild("Temple of Time")
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

function getdis(...)
	return module:getdis(...)
end

local topos = function(v)
	pcall(function()
		if getdis(v) > 2500 and getdis(CFrame.new(28310.0234, 14895.1123, 109.456741)) < 1500 then
		end
	end)
	return module:topos(v)
end

local pos_plr_trial = {
	CFrame.new(28692.3477, 14887.5605, -53.7669983),
	CFrame.new(28782.7246, 14898.9902, -59.6069946),
	CFrame.new(28700.875, 14888.2598, -154.110992),
	CFrame.new(28795.7715, 14888.2598, -112.917999),
	CFrame.new(28658.4551, 14888.2598, -121.372009),
	CFrame.new(28742.4688, 14887.5596, -18.2120056)
}

function isplrshouldkill(plr)
	if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
		for i, v in pairs(pos_plr_trial) do
			if getdis(plr.Character.HumanoidRootPart.CFrame, v) < 5 then
				return true
			end
		end
	end
	return false
end

local race_abilities = {
	["Human"] = "Last Resort",
	["Mink"] = "Agility",
	["Fishman"] = "Water Body",
	["Skypiea"] = "Heavenly Blood",
	["Ghoul"] = "Heightened Senses",
	["Cyborg"] = "Energy Core"
}

local race_name_aliases = {
	Rabbit = "Mink",
	Shark = "Fishman",
	Angel = "Skypiea"
}

function canonicalRaceName(race)
	race = tostring(race or "")
	return race_name_aliases[race] or race
end

local trial_location_names = {
	Human = "Trial of Strength",
	Mink = "Trial of Speed",
	Fishman = "Trial of Water",
	Skypiea = "Trial of the King",
	Ghoul = "Trial of Carnage",
	Cyborg = "Trial of the Machine"
}

local races_trial_place = setmetatable({}, {
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

_G.playersinserver = {}
function updateplayers()
	if not _G.playersinserver then
		_G.playersinserver = {}
	end
	local players = {}
	for i, v in pairs(game.Players:GetChildren()) do
		pcall(function()
			local data = v:FindFirstChild("Data")
			local raceObj = data and data:FindFirstChild("Race")
			local raceVal = raceObj and raceObj.Value
			if raceVal then
				local doorEntrance = nil
				pcall(function()
					local map = workspace:FindFirstChild("Map")
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
	for i, v in pairs(workspace.Characters:GetChildren()) do
		if v.Name ~= player.Name and v:FindFirstChild("HumanoidRootPart") then
			local theirrace = game.Players:FindFirstChild(v.Name).Data.Race.Value
			local corridor = workspace.Map["Temple of Time"]:FindFirstChild(theirrace .. "Corridor")
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
		until module:getdis(CFrame.new(28286.35546875, 14896.5078125, 102.62469482422)) <= 15 or tick() - startAt > 30
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
	if not game.workspace.Map:FindFirstChild("MysticIsland") then
		return nil
	end
	for o, c in pairs(game.workspace.Map.MysticIsland:GetChildren()) do
		if c:IsA("MeshPart") and c.MeshId == "rbxassetid://10153114969" then
			return c
		end
	end
end

function isnight()
	local c = game.Lighting.ClockTime
	return c >= 18 or c < 5
end

function isfullmoon()
	return game:GetService("Lighting"):GetAttribute("MoonPhase") == 5
end

function getFullMoonTimeRemaining()
	local moonPhase = tonumber(game:GetService("Lighting"):GetAttribute("MoonPhase"))
	local isFM = (moonPhase == 5)

	local clockTime = tonumber(game:GetService("Lighting").ClockTime) or 12
	clockTime = clockTime % 24
	local isNight = (clockTime >= 18 or clockTime < 5)

	-- Fallback: dung moonTexture chi khi dang la ban dem va moonPhase chua san sang
	if not isFM and isNight and moonPhase == nil then
		local sky = game:GetService("Lighting"):FindFirstChildOfClass("Sky")
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
		if v ~= player and v.Character then
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

function checkbackpack(v)
	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character
	return (backpack and backpack:FindFirstChild(v)) or (character and character:FindFirstChild(v))
end

local V4StatusCache = {
	at = 0,
	data = nil
}
local V4_STATUS_CACHE_TIME = 5  -- Tăng từ 3→5s: giảm tần suất gọi blocking RemoteFunction

function getLocalRaceName()
	local race = "Unknown"
	pcall(function()
		race = tostring(Players.LocalPlayer.Data.Race.Value)
	end)
	return race
end

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

    -- B N FIX M NH NH T: B p script,  p acc Help ph i l m   d  Max V4
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

    -- [B N FIX T  CH I  I H U]:  p acc Help lu n b o "s n s ng"  i l n c a d    Max V4
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
local AttackConfig = {
	AttackDistance = 65,
	AttackMobs = true,
	AttackPlayers = true,
	AttackCooldown = 0.06,
	ComboResetTime = 0.3,
	MaxCombo = 4,
	HitboxLimbs = {
		"Head",
		"HumanoidRootPart",
		"Torso",
		"UpperTorso",
		"Right Arm",
		"Left Arm",
		"RightLowerArm",
		"RightUpperArm",
		"LeftLowerArm",
		"LeftUpperArm",
		"RightHand",
		"LeftHand"
	},
	AutoClickEnabled = true
}

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
		GunValidator:FireServer(self:GetValidator2())
		if ShootType == "TAP" then
			Equipped.RemoteEvent:FireServer("TAP", TargetPosition)
		else
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
		equipTrialCombatTool()
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

-- seexme.lua keeps the normal combat controller alive on every physics step.
-- Trial movement only positions/equips the character; this loop performs the
-- actual validated melee hit sequence used by Human and Ghoul trials.
local previousAttackConnection = getgenv().__KAITUN_ATTACK_CONNECTION
if previousAttackConnection then
	pcall(function()
		previousAttackConnection:Disconnect()
	end)
end
local AttackInstance = FastAttack.new()
local attackConnection = RunService.Stepped:Connect(function()
	-- _G.TYRANT_FARMING: khi farm Tyrant, TyrFastAttack la nguoi duy nhat
	-- ban RegisterAttack/RegisterHit. Hai luong cung ban se bi server
	-- rate-validate va drop het -> "attack loi".
	if AttackConfig.AutoClickEnabled and not _G.TYRANT_FARMING then
		pcall(function()
			module:haki()
			AttackInstance:Attack()
		end)
	end
end)
table.insert(AttackInstance.Connections, attackConnection)
getgenv().__KAITUN_ATTACK_CONNECTION = attackConnection

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

local lastExtractAttackAt = -math.huge
local function extractAttack()
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
			-- Server doc hit list theo cap {entity, part} roi mot bang rong dem.
			-- Day thang entity vao lam lech moi cap phia sau -> huy ca goi hit.
			hitList[#hitList + 1] = { entity, entityRoot }
			hitList[#hitList + 1] = {}
		end
	end
	if not firstHit then
		return false
	end

	-- RegisterAttack chi can mot lan cho moi goi hit, khong phai moi target.
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

local extractAttackToken = {}
getgenv().__KAITUN_EXTRACT_ATTACK = extractAttackToken

_G.ShouldSendData = false
local issobusy = false

print("[v4] remote hub scripts skipped")

local JOB_ID = game.JobId
local USERNAME = Players.LocalPlayer.Name
local readySent = false
local abilityCooldown = 0

-- ============================================================
--   LOCAL GROUP (thay th  h  th ng gh p c p qua server API)
--   matchState gi  lu n = 1 object c   nh, kh ng g i API n a.
--   Main = every executing account not listed in HelpWhitelist.
--   Help = accounts explicitly listed in HelpWhitelist.
--   isallies    c set s n t  block whitelist ph a tr n.
-- ============================================================
local configuredCentralHubUrl = tostring((getgenv().Config or {})["Central Hub WebSocket"] or "")
local centralHubConfigured = configuredCentralHubUrl ~= ""
	and not configuredCentralHubUrl:find("HOANGLAM_ISGAY", 1, true)
local localGroupId = "local_" .. mainAccountName
local matchState = {
	assigned = not centralHubConfigured and (mainAccountName ~= ""),
	group_id = localGroupId,
	main_username = mainAccountName,
	main_job_id = game.JobId,
	helpers = {},
	all_in_job = true,
}
local isCurrentlyTraining  = false
task.spawn(function()
	while task.wait(2) do
		if getgenv().UpdateRoles then
			getgenv().UpdateRoles()
		end
		if matchState then
			-- [FIX] Check V4 state: n u c n training/purchase th  T T paired mode
			--   main loop ch y v o runWaitingAccountWork()   farm mobs
			local v4s = nil
			pcall(function() v4s = getV4Status(false) end)
			local needsIndependentWork = v4s and (v4s.needsTraining or v4s.needsPurchase)
			local hubAssignment = getgenv().__KAITUN_HUB_ASSIGNMENT
			local hubAssignmentActive = type(hubAssignment) == "table"
				and tick() - (tonumber(hubAssignment.receivedAt) or 0) < 900
			if needsIndependentWork then
				matchState.assigned = false
			elseif hubAssignmentActive then
				-- applyHubAssignment owns the group fields while the Hub assignment is active.
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
currentTaskStatus = "starting"
currentSubTask = "starting"
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
local PAIR_TEMPLE_TIMEOUT = math.max(15, tonumber(getgenv().Config["Pair Temple Timeout"]) or 35)
local stickyPairSetting = getgenv().Config["Pair Sticky Until Trial Complete"]
if stickyPairSetting == nil then
	stickyPairSetting = getgenv().Config["Pair Sticky Until Gear"]
end
local PAIR_STICKY_UNTIL_TRIAL_COMPLETE = stickyPairSetting ~= false
local PAIR_RELEASE_AFTER_TRIAL = getgenv().Config["Pair Release After Trial"] ~= false
local PAIR_REQUEUE_DELAY = math.max(5, tonumber(getgenv().Config["Pair Requeue Delay"]) or 15)
local PAIR_FORCE_TEMPLE_INTERVAL = math.max(0.25, tonumber(getgenv().Config["Pair Force Temple Interval"]) or 0.8)
local V3_DOOR_DISTANCE = math.max(10, tonumber(getgenv().Config["V3 Door Distance"]) or 50)
local V3_COUNTDOWN = math.max(1, tonumber(getgenv().Config["V3 Countdown"]) or 6)
local V3_READY_HOLD = math.max(0.2, tonumber(getgenv().Config["V3 Ready Hold Time"]) or 0.6)
local V3_WS_SYNC = getgenv().Config["V3 WebSocket Sync"] ~= false
local V3_REQUIRE_DIFFERENT_RACES = getgenv().Config["V3 Require Different Races"] ~= false
local V3_FIRE_COUNT = math.max(1, math.floor(tonumber(getgenv().Config["V3 Fire Count"]) or 1))
local V3_FIRE_INTERVAL = math.max(0.03, tonumber(getgenv().Config["V3 Fire Interval"]) or 0.05)

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

-- apiPost/apiGet kh ng c n g i server th t n a   h  th ng gh p c p
-- gi  ch y ho n to n local, c c h m n y gi  l i   kh ng v  ch  g i c 
-- nh ng lu n tr  nil (no-op), kh ng c  request HTTP n o  c g i.
function apiPost(path, body)
	return nil
end

function apiGet(path)
	return nil
end

-- Trial barrier state: once our own Trial ends we hold inside the Temple until
-- every member finished, then Helpers reset so the Main survives the FFA.
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
    -- V i local group c   nh, kh ng c n reset matchState v  nil n a
    -- v  matchState lu n t n t i (g n c ng t  whitelist l c load script).
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
    -- Local group: Main lu n  c coi l   ng l t c a ch nh m nh,
    -- kh ng c n ph  thu c v o d  li u tr  v  ( i khi sai) t  API.
	return isUper
end

function isOtherUpgearTraining()
    -- Help: "ng i kh c"  ang train lu n l  Main trong group local c a m nh
	if not isAlly then
		return false
	end
	return mainAccountName ~= ""
end

function updateDynamicGroupConfig(response)
    -- Kh ng c n d ng   group config gi  c   nh t  whitelist, kh ng
    -- nh n d  li u  ng t  server n a.
end

function refreshMatch()
    -- Kh ng g i API n a. matchState    c g n c   nh l c script load.
    -- H m n y gi  l i (no-op)   c c task.spawn g i refreshMatch  nh k 
    -- kh ng b  l i "attempt to call a nil value".
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

function autoEquipGear()
	local gearConfig = getgenv().Config["Gear"]
	if not gearConfig or #gearConfig ~= 5 then
		return
	end
	local slot1Type = string.sub(gearConfig, 1, 1)
	local slot2Type = string.sub(gearConfig, 3, 3)
	local slot3Type = string.sub(gearConfig, 5, 5)
	local accessoryMap = {
		["A"] = {
			"Pale Scarf",
			"Pink Coat",
			"Valentine's Necklace",
			"Black Cape",
			"Swan Glasses",
			"Tomoe Ring",
			"Dark Coat",
			"Musketeer Hat",
			"Kitsune Mask",
			"Kitsune Ribbon",
			"Lei",
			"Pretty Helmet"
		},
		["B"] = {
			"Ghoul Mask",
			"Winter Sky",
			"Black Spikey Coat",
			"Koko's Glasses",
			"Berserker Mask",
			"Warrior Helmet",
			"Water Key Necklace",
			"Pilot Helmet"
		},
		["C"] = {
			"Marine Cap",
			"Swordsman Hat",
			"Usoap's Hat",
			"Choppa's Hat",
			"Robin's Glasses",
			"Namis Glasses",
			"Brook's Glasses",
			"Bobby's Glasses",
			"Jaw's Glasses",
			"Bear Ears",
			"Cool Shades",
			"Skeleton Mask"
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
					bestPriority = priority;
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
			rawGears = {
				gearParts[1],
				gearParts[2],
				gearParts[3]
			}
		}
	end
	local ok, beforeData = pcall(function()
		return CommF_:InvokeServer("TempleClock", "Check")
	end)
	local before = ok and snapshot(beforeData) or nil
	if not before then
		return finish(false)
	end

    -- L y config gear (M c  nh ho c T i  u theo t c)
	local pattern = getgenv().Config and getgenv().Config["Gear"] or "B-B-A"
	if getgenv().Config and getgenv().Config["ChangeBestGear"] then
		local race = Players.LocalPlayer.Data.Race.Value
		if bestGearForRace and bestGearForRace[race] then
			pattern = bestGearForRace[race]
		end
	end
	local g1, g2, g3 = tostring(pattern):match("^([AB])%-([AB])%-([AB])$")
	if not g1 or not g2 or not g3 then
		g1, g2, g3 = "B", "B", "A"
	end
	local convert = {
		A = "Alpha",
		B = "Omega"
	}
	local targetGears = {
		convert[g1],
		convert[g2],
		convert[g3]
	}
	local installedCount = before.a + before.b

    -- === T NH N NG M I: T   NG XOAY/ I GEAR KHI   MAX V4 ===
	if installedCount >= 3 then
		local changedAny = false
		for i = 1, 3 do
            -- N u gear hi n t i kh c v i gear mong mu n trong Config, ti n h nh  i
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
        
        -- N u gear   chu n theo Config -> Kh ng c n  i, pass qua
		finish(false)
		return false
	end

    -- === T NH N NG C : CLAIM (L Y) GEAR M I KHI C  POINT ===
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
		local slotPattern = {
			g1,
			g2,
			g3
		}
		slotName = "Gear" .. tostring(slotIndex)
		choose = convert[slotPattern[installedCount + 1]]

        -- Lu t c a Blox Fruits: T i  a 2 Alpha ho c 2 Omega
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

local TEMPLE_ENTRY_POSITION = Vector3.new(28310.0234, 14895.1123, 109.456741)
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
		-- Our Trial is already over: stay in the Temple instead of tweening back
		-- to our own race door while the other members are still fighting.
		return true
	end
	local v4st = getV4Status(false)
	if not isRetry and v4st and v4st.needsGearClaim then
		return true
	end
	if tick() - lastTempleForceAt < PAIR_FORCE_TEMPLE_INTERVAL then
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

-- ============================================================
-- V3 synchronized activation via Central Hub WebSocket. Door-ready is reported in
-- HEARTBEAT as v3Ready/v3Race; Hub broadcasts V3_COMMAND to all
-- members with fireAt = now+V3_COUNTDOWN.
-- ============================================================
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
		-- Khi da co assignment tu Hub, chi dem thanh vien thuc su cua group do.
		-- Acc whitelist/ally khac cung server nhung khong thuoc group se lam
		-- barrier bi ket "waiting 2/3" mai mai.
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

local TyrState = {
	AttackLoaded = false,
	Farming = true,
	CurrentMode = "STARTING",
	CurrentTarget = nil,
	LastStatus = "",
	TrackedBreakables = setmetatable({}, {
		__mode = "k"
	}),
	CachedBreakables = {},
	LastBreakableScan = 0
}

local TIKI_CENTER = CFrame.new(-16682.7, 215, 524.2)
local TYRANT_ENTRANCE = CFrame.new(-16342.5, 174, 1397)
local ARENA_CENTER = Vector3.new(-16335, 174, 1397)
local DRAGON_TALON_BUY_POS = CFrame.new(5661.616211, 1211.299438, 865.999451)

local TikiMobs = {
	["Isle Outlaw"] = true,
	["Island Boy"] = true,
	["Sun-kissed Warrior"] = true,
	["Isle Champion"] = true,
	["Serpent Hunter"] = true,
	["Skull Slayer"] = true
}

local TrainingIslandData = {
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

local TrainingIslandOrder = getgenv().Config["Training Islands"] or {
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
	local args = {
		...
	}
	local containers = {
		workspace.Enemies,
		ReplicatedStorage
	}
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

-- Server luu diem respawn qua Data.LastSpawnPoint (script LastSpawnPoint cua
-- game poll moi 1s roi goi SetLastSpawnPoint khi nguoi choi dung trong vung
-- _WorldOrigin.Locations chua mot model trong PlayerSpawns.<Team>). Chi goi
-- SetSpawnPoint la khong du: khi reset, server restore LastSpawnPoint cu nen
-- nhan vat giat ve dao truoc do.
function getLastSpawnPointValue()
	local data = Players.LocalPlayer:FindFirstChild("Data")
	local node = data and data:FindFirstChild("LastSpawnPoint")
	return node and tostring(node.Value) or nil
end

-- Tim ten spawn trong PlayerSpawns gan vi tri dich nhat (bat ke Team nao).
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
	if wasTweening then module:stopTween() end
	root.CFrame = target + Vector3.new(0, 6, 0)
	task.wait(0.2)
	local ok = pcall(function()
		CommF_:InvokeServer("SetSpawnPoint")
	end)
	-- Ep luon LastSpawnPoint theo ten spawn cua dao dich, roi cho Data cap nhat
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

-- Thu thap tat ca spawn points tu _WorldOrigin lam waypoints cho smart teleport.
-- Tra ve { {Name=string, Position=Vector3}, ... }
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

-- BFS tim duong di ngan nhat tu startPos toi goalPos qua cac waypoints,
-- moi buoc khong vuot qua maxHop studs. Tra ve danh sach waypoints (khong gom start).
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

-- Thuc hien 1 buoc reset teleport toi 1 waypoint (set spawn + tu sat + cho respawn)
function doSingleResetHop(targetCFrame, hopLabel)
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return false end
	module:stopTween()
	if hopLabel then substatus("Reset hop → " .. tostring(hopLabel)) end
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
	module:stopTween()

	-- Neu dang o trong Temple (rat xa) -> reset 1 phat de thoat ra truoc
	local templeDistance = (root.Position - TEMPLE_ENTRY_POSITION).Magnitude
	if templeDistance < 3000 then
		status("Escaping Temple → reset to default spawn first")
		substatus("Reset thoát Temple")
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

	-- Smart teleport: neu khoang cach > 5000 thi tim duong di qua waypoints
	if totalDist > SMART_TELE_MAX_HOP then
		local path = findSmartTelePath(startPos, targetPos, SMART_TELE_MAX_HOP)
		if path and #path > 0 then
			for hopIdx, waypoint in ipairs(path) do
				status("Smart tele hop " .. hopIdx .. "/" .. #path .. " → " .. tostring(waypoint.Name))
				local hopCFrame = typeof(waypoint.Position) == "CFrame" and waypoint.Position
					or CFrame.new(waypoint.Position)
				if not doSingleResetHop(hopCFrame, waypoint.Name) then
					status("Smart tele hop failed at " .. tostring(waypoint.Name))
					break
				end
				task.wait(0.3)
			end
		end
	end

	status("Reset teleport to [" .. tostring(islandName) .. "]")
	character = Players.LocalPlayer.Character
	root = character and character:FindFirstChild("HumanoidRootPart")
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return false
	end
	if forceReset or getgenv().Config["Reset Teleport After Trial"] ~= false then
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
			local settleTime = math.max(0.2, tonumber(getgenv().Config["Reset Teleport Settle Time"]) or 0.45)
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
local equipTrialCombatTool
local TRIAL_BARRIER_TIMEOUT = math.max(60, tonumber(getgenv().Config["Trial Barrier Timeout"]) or 240)

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
		-- Khong danh melee: bay toi tung quai roi set Health = 0 truc tiep.
		_G.TYRANT_FARMING = false
		AttackConfig.AutoClickEnabled = false
		local orbitHeight = math.max(8, math.min(20, tonumber(getgenv().Config["Trial Orbit Height"]) or 15))
		local deadline = tick() + 120
		while tick() < deadline do
			local enemy = getNearestTrialEnemy(trialLocation)
			if not enemy then
				status("Trial of Strength - waiting for mobs...")
				topos(trialLocation.CFrame * CFrame.new(0, 20, 0))
				return true
			end
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
				or enemy:FindFirstChild("UpperTorso")
				or enemy:FindFirstChild("Torso")
				or enemy:FindFirstChild("Head")
				or enemy.PrimaryPart
			local humanoid = enemy:FindFirstChildOfClass("Humanoid")
			if not enemyRoot or not humanoid then
				task.wait(0.1)
			else
				local mobName = tostring(enemy.Name or "Mob")
				local attemptCharacter = Players.LocalPlayer.Character
				repeat
					task.wait(0.03)
					enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
						or enemy:FindFirstChild("UpperTorso")
						or enemy:FindFirstChild("Torso")
						or enemy:FindFirstChild("Head")
						or enemy.PrimaryPart
					humanoid = enemy:FindFirstChildOfClass("Humanoid")
					if enemyRoot then
						-- Teleport trung vi tri mob, set Health = 0 ngay lap tuc.
						local char = Players.LocalPlayer.Character
						local myRoot = char and char:FindFirstChild("HumanoidRootPart")
						if myRoot and enemyRoot.Parent then
							pcall(function()
								myRoot.CFrame = CFrame.new(enemyRoot.Position)
								myRoot.Velocity = Vector3.zero
								myRoot.AssemblyLinearVelocity = Vector3.zero
							end)
						end
						if humanoid and humanoid.Health > 0 then
							pcall(function()
								humanoid.Health = 0
							end)
						end
					end
				until Players.LocalPlayer.Character ~= attemptCharacter
					or not attemptCharacter.Parent
					or not attemptCharacter:FindFirstChildOfClass("Humanoid")
					or attemptCharacter:FindFirstChildOfClass("Humanoid").Health <= 0
					or not enemy.Parent or not enemyRoot or not humanoid or humanoid.Health <= 0
			end
			task.wait(0.1)
		end
		AttackConfig.AutoClickEnabled = true
		return true
	elseif race == "Fishman" then
		_G.SHOULDSPAMSKILLS = false
		_G.TRIAL_SKILL_TARGET = nil

		-- Tim Sea Beast gan nhat theo distance (uu tien folder SeaBeasts, fallback workspace scan)
		local function findTrialSeaBeast()
			local character = Players.LocalPlayer.Character
			local ownRoot = character and character:FindFirstChild("HumanoidRootPart")
			local bestBeast, bestPart, bestHealth, bestDistance = nil, nil, 0, math.huge

			local function tryCandidate(candidate)
				if not candidate:IsA("Model") or candidate == character then return end
				local candidateRoot = candidate:FindFirstChild("HumanoidRootPart")
					or candidate:FindFirstChild("Hitbox")
					or candidate:FindFirstChild("Head")
					or candidate:FindFirstChild("Torso")
					or candidate.PrimaryPart
					or candidate:FindFirstChildWhichIsA("BasePart")
				if not candidateRoot then return end
				local hum = candidate:FindFirstChildOfClass("Humanoid")
				local healthVal = candidate:FindFirstChild("Health")
				local hp = (hum and hum.Health)
					or (healthVal and healthVal:IsA("ValueBase") and tonumber(healthVal.Value))
					or 100000
				if hp <= 0 then return end
				local dist = ownRoot and (ownRoot.Position - candidateRoot.Position).Magnitude or 0
				if dist < 4000 and dist < bestDistance then
					bestBeast = candidate
					bestPart = candidateRoot
					bestHealth = hp
					bestDistance = dist
				end
			end

			-- Uu tien folder SeaBeasts chinh thuc
			local seaBeasts = workspace:FindFirstChild("SeaBeasts")
			if seaBeasts then
				for _, child in ipairs(seaBeasts:GetChildren()) do
					tryCandidate(child)
				end
			end

			-- Neu chua tim duoc, scan workspace top-level va cac folder phu
			if not bestBeast then
				for _, child in ipairs(workspace:GetChildren()) do
					local name = string.lower(tostring(child.Name or ""))
					if name:find("seabeast") or name:find("sea beast") or name:find("leviathan") then
						tryCandidate(child)
					end
				end
				for _, folderName in ipairs({"Enemies", "Characters", "Mobs"}) do
					local folder = workspace:FindFirstChild(folderName)
					if folder and not bestBeast then
						for _, child in ipairs(folder:GetChildren()) do
							local name = string.lower(tostring(child.Name or ""))
							if name:find("seabeast") or name:find("sea beast") or name:find("leviathan") then
								tryCandidate(child)
							end
						end
					end
				end
			end

			return bestBeast, bestPart, bestHealth
		end

		local beast, root, healthVal = findTrialSeaBeast()
		if not beast or not root then
			status("Trial of Water - searching Sea Beast")
			task.wait(0.5)
			return true
		end

			-- Dung giua SeaBeast: root.Position + (0, 30, 0), look thang xuong than beast
			local function getSeaBeastStandCFrame(targetRoot)
				local hoverHeight = math.max(10, tonumber(getgenv().Config["Fish Trial Stand Height"]) or 30)
				local hoverPos = targetRoot.Position + Vector3.new(0, hoverHeight, 0)
				return safeLookAt(hoverPos, targetRoot.Position)
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

		-- Equip vu khi tot nhat
		equipTrialCombatTool()
		pcall(function() CommF_:InvokeServer("Buso") end)
		_G.TRIAL_SKILL_TARGET = root
		_G.SKILL_AIM_TARGET = root
		_G.SHOULDSPAMSKILLS = true

		local attemptCharacter = character
		local loopCount = 0
		setTweenNoclip(true)
		repeat
			task.wait(0.03)
			loopCount = loopCount + 1
			local currentBeast, currentRoot, currentHp = findTrialSeaBeast()
			if currentRoot then
				root = currentRoot
				beast = currentBeast
				_G.TRIAL_SKILL_TARGET = root
				_G.SKILL_AIM_TARGET = root

				standCFrame = getSeaBeastStandCFrame(root)

				ownRoot = attemptCharacter and attemptCharacter:FindFirstChild("HumanoidRootPart")
				if ownRoot then
					-- Khoa chat vi tri tren khong tai standCFrame, triet tieu velocity tranh roi xuong nuoc
					ownRoot.CFrame = standCFrame
					ownRoot.Velocity = Vector3.zero
					pcall(function() ownRoot.AssemblyLinearVelocity = Vector3.zero end)
				end

				if loopCount % 10 == 0 then
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
	-- Fallback for layout changes: any visible GuiObject named Timer inside
	-- PlayerGui still means the Trial countdown is running.
	pcall(function()
		local timer = Players.LocalPlayer:FindFirstChild("PlayerGui")
		timer = timer and timer:FindFirstChild("Timer", true)
		visible = timer ~= nil and timer:IsA("GuiObject") and timer.Visible == true
	end)
	return visible
end

-- [FIX] equipTrialCombatTool:  u ti n Sword n u _G.USESWORD = true,
-- fallback v  Melee.  m b o Fish trial spam skill  ng weapon.
equipTrialCombatTool = function()
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end
	local equipped = character:FindFirstChildOfClass("Tool")
	-- N u   c m  ng lo i r i th  th i
	if equipped then
		if _G.USESWORD and equipped.ToolTip == "Sword" then return true end
		if not _G.USESWORD and equipped.ToolTip == "Melee" then return true end
	end
	-- T m v  equip  ng weapon
	local backpack = Players.LocalPlayer.Backpack
	local wantTip = _G.USESWORD and "Sword" or "Melee"
	local fallbackTip = _G.USESWORD and "Melee" or "Sword"
	local found = nil
	-- T m  u ti n
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.ToolTip == wantTip then
			found = tool; break
		end
	end
	-- Fallback n u kh ng t m th y  u ti n
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
		module:eq()  -- fallback gọi module:eq() như cũ
	end
	equipped = character:FindFirstChildOfClass("Tool")
	return equipped ~= nil and (equipped.ToolTip == "Melee" or equipped.ToolTip == "Sword")
end

local function resetFailedTrialAttempt(reason)
	if trialCycleDone then
		-- Trial cua minh da xong: reset o day se xoa trialCycleDone (qua
		-- resetTrialBarrierState) va keo account bay ve cua trial giua luc
		-- dang phai dung im doi ca nhom.
		return
	end
	trialFailureGeneration = trialFailureGeneration + 1
	trialAutomationBusy = false
	trialRaceLock = nil
	trialStartedAt = 0
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
		module:stopTween()
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
		-- Do not let a transient/stale Data.Race value switch a live Trial branch.
		race = trialRaceLock
		trialLocation = races_trial_place[race]
	end
	return inside, race, trialLocation
end

function markOwnTrialCompleted(reason)
	trialCompletedHoldUntil = math.huge
	trialRaceLock = nil
	trialStartedAt = 0
	trialTimerSeen = false
	trialTimerLostAt = 0
	_G.SHOULDSPAMSKILLS = false
	_G.TRIAL_SKILL_TARGET = nil
	pcall(function()
		module:stopTween()
	end)
	if not trialCycleDone then
		trialCycleDone = true
		trialCycleDoneAt = tick()
	end
	status("Trial completed (" .. tostring(reason or "done") .. ") - holding in Temple")
end

-- The old detector treated "12 seconds without a visible timer" as a win, so a
-- single GUI read failure looked exactly like a finished Trial. Completion now
-- follows the timer the Trial itself opens, leaving the arena, or the FFA start.
function evaluateOwnTrialCompletion(insideArena)
	if not trialRaceLock or trialStartedAt <= 0 then
		return false
	end
	if isFFAActive() then
		return true, "ffa_started"
	end
	local elapsed = tick() - trialStartedAt
	if not insideArena and elapsed > 8 and (trialTimerSeen or isFFAActive()) then
		-- Phai xet TRUOC getTrialTimerVisible(): PlayerGui.Main.Timer
		-- ("Time Left") van hien khi dang dung trong Temple, nen nhanh timer
		-- ben duoi return false vinh vien -> khong bao gio ket luan la xong.
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
		return false
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
	-- 1. Check PlayerGui for "FIGHT!" text label (Blox Fruits FFA banner)
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
	-- 2. Check Forcefield transparency in workspace
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

-- Finished Trial -> wait inside the Temple -> FFA signal arrives when all
-- members pass, then Helpers reset so the Main survives and takes the gear.
-- Group-member tracking is intentionally removed: the FFA flag is the
-- authoritative "everyone done" signal emitted by the game server itself.
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
	-- Stay near Temple while waiting for FFA
	if (root.Position - TEMPLE_ENTRY_POSITION).Magnitude > 3000 then
		pcall(function()
			CommF_:InvokeServer("requestEntrance", TEMPLE_ENTRY_POSITION)
		end)
	else
		pcall(function()
			module:stopTween()
		end)
	end

	local ffaActive = isFFAActive()
	local isHelperRole = isAlly or (isUper and not isMyUpgearTurn())

	if not ffaActive then
		-- Hub cancelled the assignment while we were waiting → reset immediately
		-- so the Hub can re-pair this account instead of waiting the full timeout.
		if not matchState.assigned then
			status("Hub cancelled group while holding - resetting for re-pair")
			resetTrialBarrierState()
			return
		end
		-- Keep the timeout clock ticking; reset it only when we first start waiting
		if barrierProgressAt <= 0 then
			barrierProgressAt = tick()
		end
		local waiting = math.floor(tick() - barrierProgressAt)
		if tick() - barrierProgressAt > TRIAL_BARRIER_TIMEOUT then
			status("Trial barrier timeout - resetting for next trial")
			resetTrialBarrierState()
			return
		end
		status("Trial done - holding in Temple, waiting FFA signal (" .. tostring(waiting) .. "s)")
		return
	end

	-- FFA is active: Helpers reset, Main claims gear
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
			return
		end
		if not isFFAActive() and tick() - trialCycleDoneAt > 20 then
			resetTrialBarrierState()
			status("Helper waiting next Trial cycle")
		end
		return
	end

	-- Main: fight FFA if opponents remain, then claim gear
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

-- Trial work must not share the pairing/training task. A blocking training cycle
-- used to prevent every race handler below it from ever running after teleport.
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
			-- Trial ket thuc thi game reload character, y het luc chet. Phai xet
			-- "bi thay the" TRUOC, vi character cu bi Destroy nen check Health
			-- cung dung. Bat retry o day se keo account ve cua trial thay vi
			-- dung yen cho barrier.
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
				-- Old char CHET roi moi bi thay = trial FAIL (SeaBeast gieta / roi
				-- xuong nuoc). Game chi thay character khi trial thanh cong voi nhan
				-- vat van con song, nen oldDied phai duoc xet truoc ffa/outside.
				if oldDied and not isFFAActive() then
					trialCharacterReplacedAt = 0
					resetFailedTrialAttempt("died_in_trial")
				elseif isFFAActive() then
					trialCharacterReplacedAt = 0
					markOwnTrialCompleted("ffa_started")
				elseif outsideArena and elapsed > 8 and (trialTimerSeen or isFFAActive()) then
					-- Het trial thi game thay character va day minh ra khoi
					-- arena. Truoc day nhanh nay goi resetFailedTrialAttempt
					-- ("respawned") vi Main.Timer van hien -> trialCycleDone
					-- bi xoa, barrier khong bao gio chay, account bay ve cua
					-- trial va ket o do.
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

function TyrTweenTo(targetCF, speed, keepNoclip)
	return module:topos(targetCF, speed or getgenv().TyrantConfig.TweenSpeed, 0, true, keepNoclip == true)
end

function TyrGetEnemyFolders()
	local folders = {}
	local enemies = Workspace:FindFirstChild("Enemies")
	if enemies then
		folders[#folders + 1] = enemies
	end
	local origin = Workspace:FindFirstChild("_WorldOrigin")
	if origin and origin:FindFirstChild("Enemies") then
		folders[#folders + 1] = origin.Enemies
	end
	return folders
end

function TyrBaseEnemyName(name)
	local clean = tostring(name or "")
	clean = clean:gsub("%s*%[Lv%.%s*%d+%]", ""):gsub("%s*%[Lv%s*%d+%]", "")
	clean = clean:gsub("%s*%[Boss%]", ""):gsub("%s*%[Raid Boss%]", "")
	return clean:gsub("%s+$", "")
end

function TyrIsTikiMob(enemy)
	return enemy and TikiMobs[TyrBaseEnemyName(enemy.Name)] == true
end

function TyrIsTyrant(enemy)
	if not enemy then
		return false
	end
	return string.find(string.lower(enemy.Name), "tyrant", 1, true) ~= nil
end

function TyrFindTyrant()
	for _, folder in ipairs(TyrGetEnemyFolders()) do
		for _, enemy in ipairs(folder:GetChildren()) do
			local hum = enemy:FindFirstChildOfClass("Humanoid")
			local root = enemy:FindFirstChild("HumanoidRootPart")
			if hum and root and hum.Health > 0 and TyrIsTyrant(enemy) then
				return enemy
			end
		end
	end
	return nil
end

function TyrGetNearestTikiMob()
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local nearest, nearestDist = nil, math.huge
	for _, folder in ipairs(TyrGetEnemyFolders()) do
		for _, enemy in ipairs(folder:GetChildren()) do
			local hum = enemy:FindFirstChildOfClass("Humanoid")
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
			if hum and enemyRoot and hum.Health > 0 and TyrIsTikiMob(enemy) then
				local distance = (root.Position - enemyRoot.Position).Magnitude
				if distance < nearestDist then
					nearest = enemy;
					nearestDist = distance
				end
			end
		end
	end
	return nearest
end

function TyrFindTikiOutpost()
	local map = Workspace:FindFirstChild("Map")
	return map and map:FindFirstChild("TikiOutpost")
end

function TyrIsEyeActive(eye)
	if not eye or not eye:IsA("BasePart") then
		return false
	end
	local color = eye.Color
	return eye.Transparency < 0.85 and color.R >= 0.75 and color.R > color.G * 1.35 and color.R > color.B * 1.20
end

-- Tra ve (ready, found). Eye1/Eye2 nam trong
-- Workspace.Map.TikiOutpost.IslandModel, cach cho farm mob (TIKI_CENTER)
-- gan 950 stud nen streaming thuong chua replicate chung. found=false nghia la
-- "khong doc duoc mat", khac han "mat chua do".
function TyrAreTyrantEyesReady()
	local tiki = TyrFindTikiOutpost()
	if not tiki then
		return false, false
	end
	local islandModel = tiki:FindFirstChild("IslandModel")
	if not islandModel then
		return false, false
	end
	local eye1 = islandModel:FindFirstChild("Eye1", true)
	local eye2 = islandModel:FindFirstChild("Eye2", true)
	if not eye1 or not eye2 then
		return false, false
	end
	return TyrIsEyeActive(eye1) and TyrIsEyeActive(eye2), true
end

function TyrGetObjectPart(object)
	if not object or not object.Parent then
		return nil
	end
	if object:IsA("BasePart") then
		return object
	end
	if object:IsA("Model") then
		return object.PrimaryPart or object:FindFirstChild("HumanoidRootPart")
            or object:FindFirstChild("Head") or object:FindFirstChildWhichIsA("BasePart", true)
	end
	return object:FindFirstChildWhichIsA("BasePart", true)
end

function TyrIsNearArena(object, radius)
	local part = TyrGetObjectPart(object)
	return part and (part.Position - ARENA_CENTER).Magnitude <= (radius or 240)
end

function TyrHasBreakableName(object)
	local name = string.lower(object.Name)
	return string.find(name, "vase", 1, true) or string.find(name, "pot", 1, true)
        or string.find(name, "jar", 1, true) or string.find(name, "urn", 1, true)
        or string.find(name, "breakable", 1, true) or string.find(name, "destructible", 1, true)
end

function TyrHasBreakableData(object)
	for _, attribute in ipairs({
		"Health",
		"HP",
		"HitPoints",
		"Breakable",
		"Destructible"
	}) do
		if object:GetAttribute(attribute) ~= nil then
			return true
		end
	end
	local ok, tags = pcall(function()
		return CollectionService:GetTags(object)
	end)
	if ok then
		for _, tag in ipairs(tags) do
			local lowerTag = string.lower(tag)
			if string.find(lowerTag, "break", 1, true) or string.find(lowerTag, "destroy", 1, true)
                or string.find(lowerTag, "vase", 1, true) or string.find(lowerTag, "pot", 1, true) then
				return true
			end
		end
	end
	return false
end

function TyrIsArenaBreakable(object)
	if not object or not object.Parent or not TyrIsNearArena(object, 260) then
		return false
	end
	local lowerName = string.lower(object.Name)
	if lowerName == "tyrantentrance" or lowerName == "bossarena1" or lowerName == "bossarena2"
        or lowerName == "eye1" or lowerName == "eye2" then
		return false
	end
	return TyrHasBreakableName(object) or TyrHasBreakableData(object) or TyrState.TrackedBreakables[object] == true
end

function TyrGetArenaBreakables(forceRefresh)
	if not forceRefresh and tick() - TyrState.LastBreakableScan < 0.45 then
		local validCache = {}
		for _, data in ipairs(TyrState.CachedBreakables) do
			if data.Object and data.Object.Parent and data.Part and data.Part.Parent then
				validCache[#validCache + 1] = data
			end
		end
		TyrState.CachedBreakables = validCache
		return TyrState.CachedBreakables
	end
	TyrState.LastBreakableScan = tick()
	local results = {}
	local added = {}
	local function AddCandidate(object)
		if object and not added[object] and TyrIsArenaBreakable(object) then
			local part = TyrGetObjectPart(object)
			if part then
				added[object] = true;
				results[#results + 1] = {
					Object = object,
					Part = part
				}
			end
		end
	end
	for object in pairs(TyrState.TrackedBreakables) do
		AddCandidate(object)
	end
	local tiki = TyrFindTikiOutpost()
	if tiki then
		for _, object in ipairs(tiki:GetDescendants()) do
			if object:IsA("Model") or object:IsA("BasePart") then
				AddCandidate(object)
			end
		end
	end
	local origin = Workspace:FindFirstChild("_WorldOrigin")
	if origin then
		for _, object in ipairs(origin:GetDescendants()) do
			if object:IsA("Model") or object:IsA("BasePart") then
				if TyrIsNearArena(object, 260) then
					AddCandidate(object)
				end
			end
		end
	end
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if root then
		table.sort(results, function(a, b)
			return (a.Part.Position - root.Position).Magnitude < (b.Part.Position - root.Position).Magnitude
		end)
	end
	TyrState.CachedBreakables = results
	return TyrState.CachedBreakables
end

function TyrGetAttackTargets()
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local targets = {}
	if not root then
		return targets
	end
	local config = getgenv().TyrantConfig
	if TyrState.CurrentMode == "VASES" then
		for _, data in ipairs(TyrGetArenaBreakables()) do
			if data.Part and data.Part.Parent and (data.Part.Position - root.Position).Magnitude <= config.AttackDistance then
				targets[#targets + 1] = {
					data.Object,
					data.Part
				}
			end
		end
		return targets
	end
	for _, folder in ipairs(TyrGetEnemyFolders()) do
		for _, enemy in ipairs(folder:GetChildren()) do
			local hum = enemy:FindFirstChildOfClass("Humanoid")
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
			local head = enemy:FindFirstChild("Head")
			local valid = false
			if hum and enemyRoot and hum.Health > 0 then
				if TyrState.CurrentMode == "BOSS" then
					valid = enemy == TyrState.CurrentTarget or TyrIsTyrant(enemy)
				elseif TyrState.CurrentMode == "MOBS" then
					valid = TyrIsTikiMob(enemy)
				end
			end
			if valid and (enemyRoot.Position - root.Position).Magnitude <= config.AttackDistance then
				targets[#targets + 1] = {
					enemy,
					head or enemyRoot
				}
			end
		end
	end
	return targets
end

function TyrLoadAttack()
	if TyrState.AttackLoaded then
		return
	end
	TyrState.AttackLoaded = true
		local modules = ReplicatedStorage:WaitForChild("Modules", 5)
	local net = modules and modules:WaitForChild("Net", 5)
	local registerAttack = net and net:WaitForChild("RE/RegisterAttack", 5)
	local registerHit = net and net:WaitForChild("RE/RegisterHit", 5)
	local remoteAttack = nil
	local remoteId = nil
	local seed = nil
	local lastAttack = 0
	pcall(function()
		if net then
			seed = net:WaitForChild("seed", 3) and net.seed:InvokeServer()
		end
	end)
	local function GetRemoteAttack()
		if remoteAttack and remoteAttack.Parent and remoteId then
			return true
		end
		remoteAttack = nil;
		remoteId = nil
		for _, folder in ipairs({
			ReplicatedStorage:FindFirstChild("Util"),
			ReplicatedStorage:FindFirstChild("Common"),
			ReplicatedStorage:FindFirstChild("Remotes"),
			ReplicatedStorage:FindFirstChild("Assets"),
			ReplicatedStorage:FindFirstChild("FX")
		}) do
			if folder then
				for _, object in ipairs(folder:GetChildren()) do
					if object:IsA("RemoteEvent") and object:GetAttribute("Id") then
						remoteAttack = object;
						remoteId = object:GetAttribute("Id");
						return true
					end
				end
			end
		end
		return false
	end
	local function EncryptedRegisterHit(hitData)
		if not seed and net then
			pcall(function()
				local seedRemote = net:WaitForChild("seed", 3)
				if seedRemote then
					seed = seedRemote:InvokeServer()
				end
			end)
		end
		if not GetRemoteAttack() or not seed then
			return
		end
		pcall(function()
			local encodedName = string.gsub("RE/RegisterHit", ".", function(character)
				return string.char(bit32.bxor(string.byte(character), math.floor(Workspace:GetServerTimeNow() / 10 % 10) + 1))
			end)
			remoteAttack:FireServer(encodedName, bit32.bxor(remoteId + 909090, seed * 2), unpack(hitData))
		end)
	end
	local tyrCombo = 0
	local tyrComboDebounce = 0
	local function TyrFastAttack()
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not char or not hum or hum.Health <= 0 then
			return
		end
		-- Khong goi TyrEnsureWeapon() o day: no co task.wait(0.15) ben trong,
		-- chay trong vong lap 0.03s se lam nghen ca luong attack.
		if not char:FindFirstChildWhichIsA("Tool") then
			return
		end
		if tick() - lastAttack < getgenv().TyrantConfig.AttackDelay then
			return
		end
		local targets = TyrGetAttackTargets()
		if #targets == 0 then
			return
		end
		local hitData = {
			[1] = targets[1][2],
			[2] = {},
			[4] = "078da5141"
		}
		for _, target in ipairs(targets) do
			hitData[2][#hitData[2] + 1] = {
				target[1],
				target[2]
			}
		end
		pcall(function()
			local maxCombo = AttackConfig.MaxCombo or 4
			local resetTime = AttackConfig.ComboResetTime or 1.5
			tyrCombo = (tick() - tyrComboDebounce) <= resetTime and tyrCombo or 0
			tyrCombo = tyrCombo >= maxCombo and 1 or tyrCombo + 1
			tyrComboDebounce = tick()
			registerAttack:FireServer(tyrCombo >= maxCombo and 0.9 or 0.4, tyrCombo)
		end)
		pcall(function()
			registerHit:FireServer(unpack(hitData))
		end)
		EncryptedRegisterHit(hitData)
		lastAttack = tick()
	end
	getgenv().TyrantFastAttack = TyrFastAttack
	task.spawn(function()
		while task.wait(0.03) do
			if TyrState.Farming then
				pcall(TyrFastAttack)
			end
		end
	end)
end

-- aimPart: dat _G.SKILL_AIM_TARGET trong suot duration de moi click chuot
-- deu ban theo huong toi muc tieu (binh/mob), quay than nhan vat (khong can thiep chuot/camera).
-- lockPositionCF: neu co, khoa chat vi tri khong cho nhan vat bi roi/tụt xuong nuoc trong luc danh.
function TyrNormalAttack(duration, aimPart, lockPositionCF)
	local char = LocalPlayer.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or not root then
		return
	end
	local previousAim = _G.SKILL_AIM_TARGET
	local hasAim = typeof(aimPart) == "Instance" and aimPart:IsA("BasePart")
	if hasAim then
		_G.SKILL_AIM_TARGET = aimPart
	end
	local started = tick()
	repeat
		if lockPositionCF and typeof(lockPositionCF) == "CFrame" then
			if hasAim and aimPart.Parent then
				root.CFrame = safeLookAt(lockPositionCF.Position, aimPart.Position)
			else
				root.CFrame = lockPositionCF
			end
			root.Velocity = Vector3.zero
		elseif hasAim then
			if not aimPart.Parent then
				break
			end
			-- Quay nhan vat ve huong target (khong lock chuot vat ly, khong giat camera)
			root.CFrame = safeLookAt(root.Position, aimPart.Position)
		end
		local tool = hum and char:FindFirstChildWhichIsA("Tool")
		if tool then
			pcall(function()
				if tool.Parent ~= char then
					hum:EquipTool(tool)
					task.wait(0.12)
				end
				tool:Activate()
			end)
		end
		pcall(function()
			VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
			VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
		end)
		if getgenv().TyrantFastAttack then
			pcall(getgenv().TyrantFastAttack)
		end
		task.wait(0.06)
	until tick() - started >= (duration or 0.6) or TyrFindTyrant()
	if hasAim then
		_G.SKILL_AIM_TARGET = previousAim
	end
end

function TyrBuyDragonTalon()
	local char = LocalPlayer.Character
	if char and (char:FindFirstChild("Dragon Talon") or char:FindFirstChild("DragonTalon")) then
		return true
	end
	local bp = LocalPlayer:FindFirstChild("Backpack")
	if bp and (bp:FindFirstChild("Dragon Talon") or bp:FindFirstChild("DragonTalon")) then
		return true
	end
	if not getgenv().TyrantConfig.AutoBuyDragonTalon then
		return false
	end
	local commf = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
	if not commf then
		return false
	end
	status("Buying Dragon Talon")
	TyrTweenTo(DRAGON_TALON_BUY_POS, getgenv().TyrantConfig.TweenSpeed)
	task.wait(0.8)
	for _ = 1, 15 do
		pcall(function()
			commf:InvokeServer("BuyDragonTalon")
		end)
		task.wait(0.5)
		local c = LocalPlayer.Character
		local b = LocalPlayer:FindFirstChild("Backpack")
		if (c and (c:FindFirstChild("Dragon Talon") or c:FindFirstChild("DragonTalon")))
            or (b and (b:FindFirstChild("Dragon Talon") or b:FindFirstChild("DragonTalon"))) then
			return true
		end
	end
	return false
end

function TyrNormalizeName(name)
	return tostring(name or ""):gsub("%s+", ""):lower()
end

function TyrEnsureWeapon(allowBuyDragonTalon)
	local char = LocalPlayer.Character
	local bp = LocalPlayer:FindFirstChild("Backpack")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return nil
	end
	allowBuyDragonTalon = allowBuyDragonTalon == true
	local config = getgenv().TyrantConfig
	local weaponName = config.Weapon or "Dragon Talon"

	-- Helper: t m tool theo t n trong char ho c backpack
	local function findTool(toolName)
		if char then
			for _, tool in ipairs(char:GetChildren()) do
				if tool:IsA("Tool") and TyrNormalizeName(tool.Name) == TyrNormalizeName(toolName) then
					return tool
				end
			end
		end
		if bp then
			for _, tool in ipairs(bp:GetChildren()) do
				if tool:IsA("Tool") and TyrNormalizeName(tool.Name) == TyrNormalizeName(toolName) then
					return tool
				end
			end
		end
		return nil
	end

	-- T m weapon  c y u c u
	local requested = findTool(weaponName)
	if requested then
		--   equip  ng weapon r i   kh ng c n equip l i
		if requested.Parent == char then
			return requested
		end
		-- Weapon  ang   backpack   equip l n
		pcall(function() hum:EquipTool(requested) end)
		task.wait(0.15)
		local afterEquip = findTool(weaponName)
		if afterEquip and afterEquip.Parent == char then
			return afterEquip
		end
	end

	-- Chi mua Dragon Talon khi farm Tyrant goi ro allowBuyDragonTalon=true.
	-- Raid/training khong duoc bo raid de chay di mua Talon.
	if allowBuyDragonTalon and TyrNormalizeName(weaponName) == TyrNormalizeName("Dragon Talon") then
		TyrBuyDragonTalon()
		local afterBuy = findTool(weaponName)
		if afterBuy and afterBuy.Parent ~= char then
			pcall(function() hum:EquipTool(afterBuy) end)
			task.wait(0.15)
		end
		return findTool(weaponName)
	end

	-- Fallback: dung vu khi dang co san, khong trigger mua.
	local function findFallback()
		local priority = {"Melee", "Sword", "Blox Fruit", "Gun"}
		for _, containers in ipairs({char, bp}) do
			if containers then
				for _, tool in ipairs(containers:GetChildren()) do
					if tool:IsA("Tool") then
						local tt = tool.ToolTip or ""
						for _, p in ipairs(priority) do
							if tt == p then return tool end
						end
					end
				end
			end
		end
		return nil
	end

	local fallback = findFallback()
	if fallback and fallback.Parent ~= char then
		pcall(function() hum:EquipTool(fallback) end)
		task.wait(0.15)
	end
	return char and char:FindFirstChildWhichIsA("Tool")
end
-- Keep the equip/skill sequence used by sexme.lua: resolve the melee by
-- ToolTip, equip the Backpack instance, then fire the three melee skills.
function TyrEquipMeleeFromBackpack()
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if not humanoid or not backpack then return nil end
	local equipped = character:FindFirstChildWhichIsA("Tool")
	if equipped and equipped.ToolTip == "Melee" then return equipped end
	local melee
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.ToolTip == "Melee" then
			melee = tool
			break
		end
	end
	if not melee then return nil end
	humanoid:EquipTool(melee)
	local deadline = tick() + 0.8
	repeat
		task.wait(0.05)
		equipped = character:FindFirstChild(melee.Name)
	until tick() >= deadline or (equipped and equipped.Parent == character)
	return equipped and equipped.Parent == character and equipped or nil
end

-- Doc cooldown skill tu PlayerGui.Main.Skills.<tool>.<key>. Truoc day spam
-- Z/X/C vo dieu kien: phim bam trong cooldown bi game bo qua nhung script van
-- tinh la "da danh" roi doi target -> binh khong nhan du damage de vo.
function isSkillKeyReady(toolName, key)
	local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	local main = playerGui and playerGui:FindFirstChild("Main")
	local skills = main and main:FindFirstChild("Skills")
	local ui = skills and skills:FindFirstChild(toolName)
	local entry = ui and ui:FindFirstChild(key)
	if not entry then
		-- Khong doc duoc UI (streaming/GUI khac) -> coi nhu san sang de khong
		-- chan hoan toan viec danh.
		return true
	end
	local cooldown = entry:FindFirstChild("Cooldown")
	local title = entry:FindFirstChild("Title")
	if not cooldown or not title then
		return true
	end
	local titleReady = title.TextColor3 == Color3.new(1, 1, 1)
		or title.TextColor3 == Color3.fromRGB(255, 255, 255)
	local cooldownReady = cooldown.Size.X.Scale == 0 and cooldown.Size.X.Offset == 0
	return titleReady and cooldownReady
end

-- aimPart: khi co, quay than nhan vat ve target truoc moi skill (khong can thiep chuot/camera)
function TyrSpamMeleeSkills(aimPart)
	local melee = TyrEquipMeleeFromBackpack()
	if not melee then return false end
	local previousAim = _G.SKILL_AIM_TARGET
	if typeof(aimPart) == "Instance" and aimPart:IsA("BasePart") then
		_G.SKILL_AIM_TARGET = aimPart
	end
	local fired = 0
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	for _, key in ipairs({"Z", "X", "C"}) do
		if isSkillKeyReady(melee.Name, key) then
			if _G.SKILL_AIM_TARGET and root and _G.SKILL_AIM_TARGET.Parent then
				root.CFrame = safeLookAt(root.Position, _G.SKILL_AIM_TARGET.Position)
			end
			VirtualInputManager:SendKeyEvent(true, key, false, game)
			VirtualInputManager:SendKeyEvent(false, key, false, game)
			fired = fired + 1
			task.wait(0.08)
		end
	end
	_G.SKILL_AIM_TARGET = previousAim
	return fired > 0
end

function TyrFarmEnemy(enemy, isBoss)
	local hum = enemy and enemy:FindFirstChildOfClass("Humanoid")
	local enemyRoot = enemy and enemy:FindFirstChild("HumanoidRootPart")
	if not hum or not enemyRoot or hum.Health <= 0 then
		return
	end
	TyrState.CurrentTarget = enemy
	TyrState.CurrentMode = isBoss and "BOSS" or "MOBS"
	_G.SHOULDSPAMSKILLS = false
	local config = getgenv().TyrantConfig
	local height = isBoss and (config.BossHeight or 30) or (config.FarmHeight or 25)
	local speed = tonumber(config.TweenSpeed) or 200

	local stuckAt = tick()
	local previousHealth = hum.Health
	while enemy.Parent and hum.Parent and enemyRoot.Parent and hum.Health > 0 do
		local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		local playerHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if not root or not playerHum or playerHum.Health <= 0 then
			break
		end
		-- Dam bao vu khi va buso haki
		local selfCharacter = LocalPlayer.Character
		if not (selfCharacter and selfCharacter:FindFirstChildWhichIsA("Tool")) then
			TyrEnsureWeapon(true)
		end
		module:haki()

		-- Bay xung quanh tung con quai (orbit 3D) giong che do training
		local orbitTarget = getExtractOrbitTarget(enemyRoot.CFrame, height)
			or CFrame.new(enemyRoot.Position + Vector3.new(0, height, 0), enemyRoot.Position)
		module:topos(orbitTarget, speed, 0, true, true)

		-- Quay nhan vat ve huong quai
		root.CFrame = safeLookAt(root.Position, enemyRoot.Position)

		-- FastAttack
		if getgenv().TyrantFastAttack then
			pcall(getgenv().TyrantFastAttack)
		end

		if hum.Health < previousHealth then
			previousHealth = hum.Health
			stuckAt = tick()
		elseif tick() - stuckAt > 10 then
			-- Neu danh lau khong tut mau (mob ket): tele sat orbit va chem don M1
			root.CFrame = orbitTarget
			TyrNormalAttack(0.4, enemyRoot)
			stuckAt = tick()
		end
		task.wait(0.04)
	end
	-- Don noclip sau khi tieu diet xong mob
	module:stopTween()
	TyrState.CurrentTarget = nil
end

-- Hop server helper khi binh bi bug/khong the vo
function TyrHopServer(reason)
	status("Hopping server: " .. tostring(reason or "vase unbroken"))
	module:stopTween()
	_G.SHOULDSPAMSKILLS = false
	TyrState.Farming = false
	_G.TYRANT_FARMING = false
	task.spawn(function()
		task.wait(0.3)
		local ok, ServerBrowser = pcall(function()
			return ReplicatedStorage:FindFirstChild("__ServerBrowser") or ReplicatedStorage:WaitForChild("__ServerBrowser", 5)
		end)
		if ok and ServerBrowser then
			for i = 1, 100 do
				local ok2, servers = pcall(function()
					return ServerBrowser:InvokeServer(i)
				end)
				if ok2 and type(servers) == "table" then
					for jobId, info in pairs(servers) do
						local count = type(info) == "table" and (info.Count or info.count or 0) or tonumber(info) or 0
						if jobId ~= game.JobId and count < 12 and count >= 1 then
							pcall(function()
								ServerBrowser:InvokeServer("teleport", jobId)
							end)
							task.wait(1)
							return
						end
					end
				end
			end
		end
		-- Fallback to TeleportService
		pcall(function()
			TeleportService:Teleport(game.PlaceId, Player)
		end)
	end)
end

-- Bam vao 1 binh cho den khi no thuc su bien mat (Parent == nil) hoac het
-- thoi gian. Tra ve true neu binh da vo, false neu het thoi gian ma khong vo.
local VASE_MAX_TIME = 6
local VASE_REACH = 35

function TyrBreakSingleVase(data, deadline)
	local part = data and data.Part
	local object = data and data.Object
	if not part or not part.Parent then
		return true
	end
	local speed = getgenv().TyrantConfig.TweenSpeed
	local started = tick()

	local function vaseGone()
		if object and not object.Parent then
			return true
		end
		if not part or not part.Parent then
			return true
		end
		return false
	end

	local function timeLeft()
		if tick() - started >= VASE_MAX_TIME then
			return false
		end
		if deadline and tick() >= deadline then
			return false
		end
		return not TyrFindTyrant()
	end

	while timeLeft() do
		if vaseGone() then
			return true
		end
		local target = CFrame.new(part.Position + Vector3.new(0, 6, 0), part.Position)
		local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - part.Position).Magnitude > VASE_REACH then
			TyrTweenTo(target, speed, true)
			root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		end
		if vaseGone() then
			return true
		end
		if not root then
			task.wait(0.1)
		elseif (root.Position - part.Position).Magnitude > VASE_REACH then
			-- Tween bi ngat (lag/noclip): keo thang toi roi danh tiep
			pcall(function()
				root.CFrame = target
			end)
			task.wait(0.08)
		else
			-- Quay than nhan vat huong ve binh (khong can thiep vao chuot vat ly hay camera)
			root.CFrame = safeLookAt(root.Position, part.Position)
			TyrSpamMeleeSkills(part)
			if vaseGone() then
				return true
			end
			TyrNormalAttack(0.55, part)
		end
	end
	return vaseGone()
end

-- force=true: dap binh du chua doc duoc mat (bi streaming an), gioi han
-- boi deadline de khong dinh mai o arena.
function TyrBreakVases(force, deadline)
	TyrState.CurrentMode = "VASES"
	TyrState.CurrentTarget = nil
	status(force and "Sweeping arena - breaking vases" or "Eyes red - breaking vases")
	_G.SHOULDSPAMSKILLS = false
	if not TyrTravelToArena() then
		status("Tyrant entrance not reached - skip vase skills")
		module:stopTween()
		return
	end
	task.wait(0.5)
	local round = 0
	local consecutiveFails = 0
	local function keepBreaking()
		if TyrFindTyrant() then
			return false
		end
		if force then
			return not deadline or tick() < deadline
		end
		return (TyrAreTyrantEyesReady())
	end
	while keepBreaking() do
		local breakables = TyrGetArenaBreakables(true)
		if #breakables > 0 then
			for _, data in ipairs(breakables) do
				if TyrFindTyrant() then
					_G.SHOULDSPAMSKILLS = false
					module:stopTween()
					return
				end
				if data.Part and data.Part.Parent then
					local success = TyrBreakSingleVase(data, deadline)
					if success then
						consecutiveFails = 0
					else
						consecutiveFails = consecutiveFails + 1
						status("Vase failed to break (" .. consecutiveFails .. " failed)")
						-- Neu 2 binh lien tiep danh mai khong vo (server bug/bat tu/desync) -> hop server ngay
						if consecutiveFails >= 2 then
							TyrHopServer("Vases unbroken (server bugged/desynced)")
							return
						end
					end
				end
			end
		end
		round = round + 1
		local radius = 42
		local points = 12
		for index = 1, points do
			if TyrFindTyrant() then
				_G.SHOULDSPAMSKILLS = false
				module:stopTween()
				return
			end
			local angle = math.rad((index - 1) * (360 / points) + (round % 2) * 15)
			local point = ARENA_CENTER + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
			TyrTweenTo(CFrame.new(point + Vector3.new(0, 7, 0), ARENA_CENTER), getgenv().TyrantConfig.TweenSpeed, true)
			TyrNormalAttack(0.7)
		end
		TyrTweenTo(CFrame.new(ARENA_CENTER + Vector3.new(0, 8, 0)), getgenv().TyrantConfig.TweenSpeed, true)
		TyrNormalAttack(1)
		task.wait(0.8)

		-- Sau 2 round quét quanh arena ma van con binh chua vo duoc -> hop server
		local remaining = TyrGetArenaBreakables(true)
		if #remaining > 0 and round >= 2 and consecutiveFails > 0 then
			TyrHopServer("Arena vases unbreakable after " .. round .. " rounds")
			return
		end
	end
	-- D n noclip khi tho t vase loop
	_G.SHOULDSPAMSKILLS = false
	module:stopTween()
end

function TyrTravelToArena()
	for attempt = 1, 3 do
		TyrTweenTo(TYRANT_ENTRANCE, getgenv().TyrantConfig.TweenSpeed, true)
		local character = LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - TYRANT_ENTRANCE.Position).Magnitude <= 180 then
			return true
		end
		if attempt < 3 then
			task.wait(0.4)
		end
	end
	return false
end

-- Doi Eye1/Eye2 replicate sau khi den arena roi moi ket luan mat do hay chua.
function TyrWaitForArenaEyes(timeout)
	local deadline = tick() + (tonumber(timeout) or 5)
	repeat
		local ready, found = TyrAreTyrantEyesReady()
		if found then
			return ready, true
		end
		task.wait(0.25)
	until tick() >= deadline
	return false, false
end

-- Farm mob o TIKI_CENTER khong bao gio thay mat, nen dinh ky ve arena kiem tra.
-- Neu mat do -> dap binh binh thuong; neu van khong doc duoc mat thi van dap
-- binh trong VaseSweepDuration giay roi quay lai farm mob.
function TyrSweepArenaForVases()
	local config = getgenv().TyrantConfig
	status("Checking Tyrant arena for vases")
	if not TyrTravelToArena() then
		return false
	end
	local ready, found = TyrWaitForArenaEyes(6)
	if TyrFindTyrant() then
		return true
	end
	if found then
		if ready then
			TyrBreakVases()
			return true
		end
		-- Doc duoc mat va mat chua do -> Tyrant chua the spawn, dap binh vo ich.
		status("Tyrant eyes not red - back to mobs")
		return false
	end
	-- Khong doc duoc mat ke ca khi da dung trong arena: dap binh trong mot cua
	-- so thoi gian gioi han thay vi bo qua han nhu truoc.
	local duration = math.max(10, tonumber(config.VaseSweepDuration) or 60)
	TyrBreakVases(true, tick() + duration)
	return true
end

function TyrSetupRegenTracker()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local regen = remotes and remotes:FindFirstChild("RegenModel")
	if not regen or not regen:IsA("RemoteEvent") then
		return
	end
	regen.OnClientEvent:Connect(function(encoded)
		local object = nil
		if typeof(encoded) == "Instance" then
			object = encoded
		elseif type(_G.Encode) == "function" then
			pcall(function()
				object = _G.Encode(encoded)
			end)
		end
		if object and typeof(object) == "Instance" and TyrIsNearArena(object, 280) then
			TyrState.TrackedBreakables[object] = true
		end
	end)
end

function TyrSetupBringMobs()
	-- Bring mobs da duoc tat theo yeu cau, farm danh tung con va bay orbit quanh quai
	if not getgenv().TyrantConfig.BringMobs then
		return
	end
end

local tyrantFarmingActive = false
local tyrantFarmingTask = nil
local tyrantSetupDone = false
local tyrantFragmentTarget = 10000
local tyrantSpawnBound = false
local tyrantLastVaseSweep = 0

local function vaseSweepInterval()
	return math.max(30, tonumber(getgenv().TyrantConfig.VaseSweepInterval) or 120)
end

function TyrBindFarmSpawn()
	if tyrantSpawnBound then return true end
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	if (root.Position - TIKI_CENTER.Position).Magnitude > 120 then return false end
	tyrantSpawnBound = setTrainingSpawnPoint(TIKI_CENTER) == true
	if tyrantSpawnBound then status("Tyrant farm spawn saved") end
	return tyrantSpawnBound
end

function stopTyrantFarming()
	tyrantFarmingActive = false
	TyrState.Farming = false
	_G.TYRANT_FARMING = false
	TyrState.CurrentMode = "STARTING"
	tyrantFarmingTask = nil
	-- Cancel bất kỳ tween đang chạy tới TIKI_CENTER để tránh acc trôi về Tiki
	-- khi loop farming bị dừng giữa chừng (VD: chuyển sang training island).
	module:stopTween()
end

function startTyrantFarming(targetFragments)
	tyrantFragmentTarget = math.max(0, tonumber(targetFragments) or tyrantFragmentTarget or 10000)
	if tyrantFarmingTask then
		tyrantFarmingActive = true
		TyrState.Farming = true
		_G.TYRANT_FARMING = true
		return
	end
	tyrantFarmingActive = true
	TyrState.Farming = true
	_G.TYRANT_FARMING = true
	if not tyrantSetupDone then
		tyrantSetupDone = true
		pcall(TyrLoadAttack)
		pcall(TyrSetupRegenTracker)
		pcall(TyrSetupBringMobs)
	end
	tyrantFarmingTask = task.spawn(function()
		while tyrantFarmingActive do
			-- DANG TRONG TRAN RAID THAT -> DUNG TYRANT NGAY LAP TUC!
			if RaidIsActive() then
				break
			end

			local v4State = getV4Status(false)
			local fragments = tonumber(LocalPlayer.Data.Fragments.Value) or 0
			if v4State.canTrial or v4State.complete or fragments >= tyrantFragmentTarget then
				break
			end

			-- Neu autoraid bat va raid het cooldown (RetryAt het) -> thoat Tyrant de quay lai thu Raid
			local farmConfig = getgenv().Config["Farm Fragments"]
			local autoraid = type(farmConfig) == "table" and farmConfig.autoraid == true
			if autoraid and os.time() >= RaidFarming.RetryAt then
				break
			end

			local config = getgenv().TyrantConfig
			if config and config.AutoBuso then
				local c = LocalPlayer.Character
				if c and not c:FindFirstChild("HasBuso") then
					pcall(function() CommF_:InvokeServer("Buso") end)
				end
			end

			local playerHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if not playerHum or playerHum.Health <= 0 then
				status("Respawning before fragment farm")
				task.wait(1)
			else
				TyrEnsureWeapon(true)
				local moonSuffix = (isnight() and isfullmoon()) and " | Full Moon" or ""
				local tyrant = TyrFindTyrant()
				if tyrant then
					status("Fighting Tyrant for V4 fragments" .. moonSuffix)
					TyrFarmEnemy(tyrant, true)
				elseif TyrAreTyrantEyesReady() then
					status("Breaking vases for Tyrant" .. moonSuffix)
					TyrBreakVases()
					tyrantLastVaseSweep = tick()
				elseif tick() - tyrantLastVaseSweep >= vaseSweepInterval() then
					tyrantLastVaseSweep = tick()
					TyrSweepArenaForVases()
				else
					local mob = TyrGetNearestTikiMob()
					if mob then
						TyrBindFarmSpawn()
						TyrFarmEnemy(mob, false)
					else
						status("Tyrant farm - moving to Tiki center")
						TyrTweenTo(TIKI_CENTER, getgenv().TyrantConfig.TweenSpeed, true)
						TyrBindFarmSpawn()
						task.wait(0.5)
					end
				end
			end
			task.wait(0.1)
		end
		module:stopTween()
		tyrantFarmingTask = nil
		tyrantFarmingActive = false
		TyrState.Farming = false
		_G.TYRANT_FARMING = false
		TyrState.CurrentMode = "STARTING"
	end)
end

function readReadyFiles()
	return 0, {}
end

-- ===================== RAID FRAGMENT FARMING =====================
-- Port tu Extract.lua + remotes da verify trong src.rbxlx:
--  - Inventory: ItemReplicationService:GetItems(KEYS.*) + ItemConfig.match
--  - Mua chip: CommF_:InvokeServer("RaidsNpc", "Select", <theme>)
--    -> tra 1 la thanh cong, 0 la level < 1100, string la error/cooldown
--  - Lay fruit ra quy doi: CommF_:InvokeServer("LoadFruit", <StorageKey>)

local RaidFarming = {
	Active = false,
	CurrentChip = nil,
	LastRaidAlert = 0,   -- "go!" notification
	LastRaidAlert2 = 0,  -- "raid" notification
	FruitRetryAt = 0,    -- os.time(): sau thoi diem nay moi thu lay fruit lai
	RetryAt = 0,         -- backoff khi mua chip that bai
	Inventory = {},      -- item table theo Extract.lua RefreshInventory
}

local RAID_FRUIT_VALUES = {
	rocket = 5000, spin = 7500, blade = 30000, chop = 30000, spring = 60000,
	bomb = 80000, smoke = 100000, spike = 180000, flame = 250000,
	falcon = 300000, ice = 350000, sand = 420000, dark = 500000,
	diamond = 600000, light = 650000, rubber = 750000,
	barrier = 800000, ghost = 940000, revive = 940000, magma = 960000,
}

function normalizeRaidFruitName(value)
	local name = string.lower(tostring(value or ""))
	name = name:gsub("%b[]", "")
	name = name:gsub("%b()", "")
	name = name:gsub("physicalmoveset", "")
	name = name:gsub("moveset", "")
	name = name:gsub(" fruit", "")
	name = name:gsub("%-", " ")
	name = name:gsub("%s+", " ")
	name = name:gsub("^%s+", ""):gsub("%s+$", "")
	local first, second = name:match("^([^%s]+)%s+([^%s]+)$")
	if first and second and first == second then
		name = first
	end
	return name
end

function RaidCleanLoadName(value)
	local name = tostring(value or "")
	name = name:gsub("%s*%b[]", "")
	name = name:gsub("%s*%b()", "")
	name = name:gsub("%s*[Mm]oveset%s*", "")
	name = name:gsub("%s*[Pp]hysical[Mm]oveset%s*", "")
	name = name:gsub("^%s+", ""):gsub("%s+$", "")
	name = name:gsub("%s+", " ")
	return name
end

function RaidRefreshInventory()
	for key in pairs(RaidFarming.Inventory) do
		RaidFarming.Inventory[key] = nil
	end
	local RS = game:GetService("ReplicatedStorage")
	local okService, ItemReplicationService = pcall(require, RS:WaitForChild("ItemReplicationService", 3))
	local okKeys, ItemKeys = pcall(require, RS:WaitForChild("ItemReplicationService", 3):WaitForChild("KEYS", 3))
	local okConfig, ItemConfig = pcall(require, RS:WaitForChild("ItemConfig", 3))
	if not okService or not okKeys or not okConfig or type(ItemReplicationService) ~= "table" then
		return false
	end

	local function getReplicatedItems(key)
		if not key then return {} end
		local ok, result = pcall(function()
			return ItemReplicationService:GetItems(key)
		end)
		return ok and type(result) == "table" and result or {}
	end

	local quantityItems = getReplicatedItems(ItemKeys.QUANTITY)
	local masteryItems = getReplicatedItems(ItemKeys.MASTERY)
	local ownedItems = getReplicatedItems(ItemKeys.IS_OWNED)

	local function readField(source, ...)
		if type(source) ~= "table" then return nil end
		for index = 1, select("#", ...) do
			local key = select(index, ...)
			if source[key] ~= nil then return source[key] end
		end
		return nil
	end

	-- GetItems tra ve {ItemId, NetworkedUID, Value} records, merge 3 loai key
	local replicatedItems = {}
	local function mergeRecords(records, field)
		for legacyKey, record in pairs(records) do
			local itemId = legacyKey
			local value = record
			if type(record) == "table" and record.ItemId ~= nil then
				itemId = record.ItemId
				value = record.Value
			end
			local entry = replicatedItems[itemId]
			if not entry then
				entry = {}
				replicatedItems[itemId] = entry
			end
			if field == "Quantity" then
				entry.Quantity = (tonumber(entry.Quantity) or 0) + (tonumber(value) or 0)
			elseif field == "Mastery" then
				entry.Mastery = math.max(tonumber(entry.Mastery) or 0, tonumber(value) or 0)
			elseif field == "Owned" then
				entry.Owned = entry.Owned or value == true
			end
		end
	end
	mergeRecords(quantityItems, "Quantity")
	mergeRecords(masteryItems, "Mastery")
	mergeRecords(ownedItems, "Owned")

	for itemId, replicated in pairs(replicatedItems) do
		local okMatch, itemData = pcall(function()
			local matched = ItemConfig.match(itemId)
			if type(matched) == "table" and type(matched.unwrap) == "function" then
				return matched:unwrap()
			end
			return matched
		end)
		if okMatch and itemData then
			local indexData = itemData.Index or itemData
			local itemLabel = readField(indexData, "DebugLabel", "Name", "DisplayName", "InternalName")
				or tostring(itemId)
			local itemName = readField(indexData, "StorageKey")
			if not itemName then
				itemName = tostring(itemLabel):gsub("%s*%[[%w%-]+%]%s*$", "")
			end
			itemName = tostring(itemName)
			if itemName == "" then itemName = tostring(itemLabel) end
			local itemType = readField(indexData, "IdType", "Type") or readField(itemData, "IdType", "Type")
			local count = tonumber(replicated.Quantity) or 0
			local mastery = tonumber(replicated.Mastery) or 0
			local owned = replicated.Owned == true or count > 0 or mastery > 0
			local entry = {
				Name = itemName,
				Label = tostring(itemLabel),
				Count = count,
				Quantity = count,
				Mastery = mastery,
				Owned = owned,
				Type = readField(indexData, "Type", "ItemType", "Category")
					or readField(itemData, "Type", "ItemType", "Category"),
				IdType = itemType,
				Value = tonumber(readField(indexData, "Value", "Price", "Cost"))
					or tonumber(readField(itemData, "Value", "Price", "Cost")),
				ItemId = itemId,
				Data = itemData,
			}
			local existing = RaidFarming.Inventory[entry.Name]
			if not existing or (existing.IdType == "Moveset" and itemType ~= "Moveset") then
				RaidFarming.Inventory[entry.Name] = entry
			end
			RaidFarming.Inventory[entry.Label] = entry
		end
	end
	return true
end

-- Quet chinh xac cac trai hien co trong Inventory Storage cua nguoi choi co gia < 1M Beli
function RaidGetOwnedUnder1MFruits()
	local ownedFruits = {}
	local seen = {}

	local function addFruit(internalName, displayName, rawPrice, count)
		local cleanInternal = tostring(internalName or ""):gsub("%s*%b[]%s*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
		if cleanInternal == "" then return end
		local cleanDisplay = tostring(displayName or cleanInternal)
		local fName = normalizeRaidFruitName(cleanDisplay)
		if fName == "" then fName = normalizeRaidFruitName(cleanInternal) end
		local price = tonumber(rawPrice) or 0
		if price <= 0 then
			price = RAID_FRUIT_VALUES[fName] or 999999
		end
		if price < 1000000 and not seen[cleanInternal] then
			seen[cleanInternal] = true
			table.insert(ownedFruits, {
				Name = cleanInternal,
				InternalName = cleanInternal,
				DisplayName = cleanDisplay,
				CleanName = fName,
				Value = price,
				Count = tonumber(count) or 1
			})
		end
	end

	-- 1. Quet qua ReplicatedStorage ItemReplicationService (Chuan theo Blox Fruits)
	pcall(function()
		local RS = game:GetService("ReplicatedStorage")
		local okService, ItemReplicationService = pcall(require, RS:WaitForChild("ItemReplicationService", 3))
		local okKeys, KEYS = pcall(require, RS:WaitForChild("ItemReplicationService", 3):WaitForChild("KEYS", 3))
		local okConfig, ItemConfig = pcall(require, RS:WaitForChild("ItemConfig", 3))

		if okService and okKeys and okConfig and type(ItemReplicationService) == "table" then
			local qKey = (type(KEYS) == "table" and (KEYS.QUANTITY or KEYS.Count or KEYS.Amount)) or 1
			local quantityItems = ItemReplicationService:GetItems(qKey)
			if type(quantityItems) == "table" then
				for key, item in pairs(quantityItems) do
					local itemId = nil
					local count = 0
					if type(item) == "table" then
						itemId = tonumber(item.ItemId or item.ItemID or item.Id)
						count = tonumber(item.Value or item.Count or item.Quantity or item.Amount) or 0
					else
						itemId = tonumber(key)
						count = tonumber(item) or 0
					end

					if itemId and count > 0 then
						local okMatch, matched = pcall(function()
							local res = ItemConfig.match(itemId)
							if type(res) == "table" and type(res.unwrap) == "function" then
								return res:unwrap()
							end
							return res
						end)
						if okMatch and type(matched) == "table" then
							local index = matched.Index
							local label = nil
							if type(index) == "table" then
								label = index.DebugLabel or index.DisplayName or index.Name or matched.Name
							else
								label = matched.DebugLabel or matched.DisplayName or matched.Name
							end
							label = tostring(label or "")
							local cleanName = label:gsub("%s*%b[]%s*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
							local canonical = normalizeRaidFruitName(cleanName)
							local val = tonumber(RAID_FRUIT_VALUES[canonical]) or 0
							if val > 0 or cleanName:find("-") or cleanName:lower():find("fruit") then
								addFruit(cleanName, canonical, val, count)
							end
						end
					end
				end
			end
		end
	end)

	-- 2. Quet qua Server Remote: getInventory
	pcall(function()
		local res = CommF_:InvokeServer("getInventory")
		if type(res) == "table" then
			for _, item in pairs(res) do
				if type(item) == "table" then
					local itemType = tostring(item.Type or item.Category or item.Section or "")
					local name = item.Name or item.name or item.StorageKey or item.ItemName or ""
					local count = tonumber(item.Count or item.Quantity or item.count) or 1
					local fName = normalizeRaidFruitName(name)
					local looksLikeFruit = itemType:lower():find("fruit", 1, true) ~= nil
						or name:lower():find("fruit", 1, true) ~= nil
						or name:find("-", 1, true) ~= nil
						or RAID_FRUIT_VALUES[fName] ~= nil
					if looksLikeFruit and count > 0 then
						addFruit(name, fName, item.Value or item.Price or RAID_FRUIT_VALUES[fName] or 0, count)
					end
				end
			end
		end
	end)

	-- 3. Quet truc tiep PlayerGui neu cac phuong phap tren bi block
	if #ownedFruits == 0 then
		pcall(function()
			local pgui = LocalPlayer:FindFirstChild("PlayerGui")
			local main = pgui and pgui:FindFirstChild("Main")
			local inv = main and (main:FindFirstChild("FruitStorage", true) or main:FindFirstChild("Inventory", true))
			if inv then
				for _, frame in ipairs(inv:GetDescendants()) do
					if frame:IsA("Frame") or frame:IsA("TextButton") then
						local title = frame:FindFirstChild("ItemName") or frame:FindFirstChild("Title") or frame:FindFirstChild("NameLabel")
						local countLabel = frame:FindFirstChild("ItemCount") or frame:FindFirstChild("Count")
						if title and title:IsA("TextLabel") and title.Text ~= "" then
							local count = countLabel and tonumber(tostring(countLabel.Text):match("%d+")) or 1
							local fName = normalizeRaidFruitName(title.Text)
							if RAID_FRUIT_VALUES[fName] then
								addFruit(title.Text, fName, RAID_FRUIT_VALUES[fName], count)
							end
						end
					end
				end
			end
		end)
	end

	-- Sap xep theo gia tang dan (re nhat len dau)
	table.sort(ownedFruits, function(a, b)
		if a.Value == b.Value then return tostring(a.Name) < tostring(b.Name) end
		return a.Value < b.Value
	end)

	return ownedFruits
end

function RaidCheckSpecialMicrochip()
	for _, container in ipairs({
		LocalPlayer.Character,
		LocalPlayer:FindFirstChildOfClass("Backpack"),
	}) do
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") and (tool.Name == "Special Microchip" or tool.Name:find("Microchip") or tool.Name:find("Special")) then
					return tool
				end
			end
		end
	end
	return nil
end

-- Chon theme chip trung voi devil fruit dang cầm, else "Flame"
function RaidRefreshRaidType()
	local currentFruit = ""
	pcall(function()
		currentFruit = tostring(LocalPlayer.Data.DevilFruit.Value)
	end)
	local ok, raidsModule = pcall(function()
		return require(game:GetService("ReplicatedStorage"):WaitForChild("Raids", 3))
	end)
	local themes = ok and type(raidsModule) == "table" and raidsModule.raids
	if type(themes) == "table" then
		for _, theme in ipairs(themes) do
			if string.find(currentFruit, theme, 1, true) then
				RaidFarming.CurrentChip = theme
				return theme
			end
		end
	end
	RaidFarming.CurrentChip = "Flame"
	return "Flame"
end

function RaidBuyChip(maxAttempts)
	maxAttempts = tonumber(maxAttempts) or 5
	for attempt = 1, maxAttempts do
		if RaidCheckSpecialMicrochip() then return true end
		local chipType = RaidRefreshRaidType()
		status("Buying raid chip " .. attempt .. "/" .. maxAttempts .. " (" .. chipType .. ")")
		local ok, result = pcall(function()
			return CommF_:InvokeServer("RaidsNpc", "Select", chipType)
		end)
		-- result == 1: thanh cong; 0: level < 1100; string: error/cooldown
		if ok and result == 1 then
			task.wait(1)
			if RaidCheckSpecialMicrochip() then return true end
		elseif ok and type(result) == "string" then
			-- Cooldown hoac loi: dua ra ngoai de caller quyet dinh fallback
			return false, result
		end
		task.wait(1.25)
		if RaidCheckSpecialMicrochip() then return true end
	end
	return false, "chip buy failed"
end

-- Unstore trai < 1M thuc su co trong inventory va equip len tay de doi chip
function RaidLoadFruitForChip()
	local function getAndEquipHeldFruit()
		local character = LocalPlayer.Character
		local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		for _, container in ipairs({character, backpack}) do
			if container then
				for _, tool in ipairs(container:GetChildren()) do
					if tool:IsA("Tool") then
						local tip = string.lower(tostring(tool.ToolTip or ""))
						local toolName = string.lower(tostring(tool.Name or ""))
						local isFruit = tip:find("fruit", 1, true) ~= nil
							or toolName:find("fruit", 1, true) ~= nil
							or tool:FindFirstChild("Fruit") ~= nil
							or RAID_FRUIT_VALUES[normalizeRaidFruitName(tool.Name)] ~= nil
						if isFruit then
							if tool.Parent ~= character and humanoid then
								pcall(function() humanoid:EquipTool(tool) end)
								task.wait(0.3)
							end
							return tool
						end
					end
				end
			end
		end
		return nil
	end

	-- 1. Neu da co fruit tren tay / trong backpack thi dung luon
	local held = getAndEquipHeldFruit()
	if held then return true end

	-- 2. Quet chinh xac inventory de lay danh sach trai nguoi choi DANG CO TRONG KHO
	local ownedFruits = RaidGetOwnedUnder1MFruits()
	if #ownedFruits == 0 then
		status("No owned fruits < 1M in inventory storage to trade chip")
		return false
	end

	-- 3. Lay tung trai re nhat thu unstore
	for _, fruit in ipairs(ownedFruits) do
		local rawName = tostring(fruit.InternalName or fruit.Name or "")
		local cleanName = RaidCleanLoadName(rawName)
		local candidates = {}
		local function addCandidate(c)
			c = tostring(c or ""):gsub("^%s+", ""):gsub("%s+$", "")
			if c ~= "" and not table.find(candidates, c) then
				table.insert(candidates, c)
			end
		end

		addCandidate(rawName)
		addCandidate(cleanName)
		if fruit.DisplayName and fruit.DisplayName ~= "" then
			local title = fruit.DisplayName:gsub("^%l", string.upper)
			addCandidate(title)
			addCandidate(title .. " Fruit")
			addCandidate(title .. "-" .. title)
		end
		local left, right = cleanName:match("^(.-)%-(.-)$")
		if left and right and left:gsub("%s", "") == right:gsub("%s", "") then
			addCandidate(left .. " Fruit")
			addCandidate(left)
		end

		for _, candidateName in ipairs(candidates) do
			status("Unstoring fruit [" .. candidateName .. "] (" .. formatNumber(fruit.Value) .. " Beli)")
			pcall(function()
				CommF_:InvokeServer("LoadFruit", candidateName)
			end)
			local started = tick()
			repeat
				held = getAndEquipHeldFruit()
				if held then break end
				task.wait(0.2)
			until tick() - started >= 2.5

			if held then
				status("Unstored and holding: " .. held.Name)
				return true
			end
		end
	end

	return false
end

-- Doc text Timer "Time Left: MM:SS" tren GUI neu dang trong tran Raid
function RaidGetTimerText()
	local pgui = LocalPlayer:FindFirstChild("PlayerGui")
	if not pgui then return nil end
	for _, gui in ipairs(pgui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Enabled then
			for _, desc in ipairs(gui:GetDescendants()) do
				if desc:IsA("TextLabel") and desc.Visible and desc.TextTransparency < 1 then
					local txt = tostring(desc.Text or "")
					if string.find(string.lower(txt), "time left", 1, true) then
						return txt
					end
				end
			end
		end
	end
	return nil
end

-- Kiem tra xem nguoi choi co dang trong tran Raid khong
function RaidIsActive()
	-- 1. Raid dang chay khi va chi khi Timer "Time Left" dang ton tai va hien thi tren man hinh
	local timer = RaidGetTimerText()
	if timer then
		return true
	end
	-- 2. Khi het Timer tren man hinh -> Tran Raid DA KET THUC (Thang, Thua, hoac Timeout)
	return false
end

-- Lay danh sach tat ca 5 dao cua Raid tu _WorldOrigin.Locations
-- Lay danh sach 5 dao thuoc dung cluster tran Raid hien tai cua player
function RaidGetIslands()
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local origin = Workspace:FindFirstChild("_WorldOrigin")
	local locations = origin and origin:FindFirstChild("Locations")
	if not locations then return {} end

	local islandsByNum = { {}, {}, {}, {}, {} }
	for _, region in ipairs(locations:GetChildren()) do
		local name = tostring(region.Name or "")
		if string.find(name, "Island", 1, true) then
			local num = name:match("Island%s*(%d+)") or name:match("^Island(%d+)")
			local idx = tonumber(num)
			if idx and idx >= 1 and idx <= 5 then
				local part = region:IsA("BasePart") and region
					or (region:IsA("Model") and (region.PrimaryPart or region:FindFirstChildWhichIsA("BasePart")))
				if part and (part.Position - Vector3.new(0, 0, 0)).Magnitude > 7000 then
					table.insert(islandsByNum[idx], part)
				end
			end
		end
	end

	-- 1. Tim Island 1 gan vi tri cua player nhat
	local resolvedIslands = {}
	local startPos = root and root.Position or Vector3.new(0, 0, 0)
	local island1, bestDist = nil, math.huge
	for _, part in ipairs(islandsByNum[1]) do
		local dist = (part.Position - startPos).Magnitude
		if dist < bestDist then
			island1 = part
			bestDist = dist
		end
	end

	if not island1 and #islandsByNum[1] > 0 then
		island1 = islandsByNum[1][1]
	end
	resolvedIslands[1] = island1

	-- 2. Cac dao 2, 3, 4, 5 phai thuoc cung cluster voi dao lien truoc (< 2500 studs)
	for i = 2, 5 do
		local prev = resolvedIslands[i - 1]
		local refPos = prev and prev.Position or startPos
		local bestPart, nearest = nil, math.huge
		for _, part in ipairs(islandsByNum[i]) do
			local dist = (part.Position - refPos).Magnitude
			if dist < nearest then
				bestPart = part
				nearest = dist
			end
		end
		resolvedIslands[i] = bestPart
	end

	return resolvedIslands
end

-- Tim dao raid hien tai cua player: dao co so lon nhat trong ban kinh 2000 studs
function RaidGetCurrentIsland()
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil, 0 end
	local islands = RaidGetIslands()
	for i = 5, 1, -1 do
		if islands[i] then
			local dist = (islands[i].Position - root.Position).Magnitude
			if dist < 2000 then
				return islands[i], i
			end
		end
	end
	return nil, 0
end

-- Bien luu tien do Wave/Dao hien tai cua Raid (1 -> 2 -> 3 -> 4 -> 5), khong bao gio tut lui
local currentRaidWave = 1

-- Xac dinh dao hien tai dua vao vi tri player (khong tu tien wave)
function RaidGetActiveWaveIsland()
	local island, idx = RaidGetCurrentIsland()
	if island and idx > 0 then
		if idx > currentRaidWave then
			currentRaidWave = idx
		end
		return currentRaidWave, island
	end
	local islands = RaidGetIslands()
	currentRaidWave = math.clamp(currentRaidWave, 1, 5)
	return currentRaidWave, islands[currentRaidWave]
end

-- Lay danh sach tat ca quai song gan player (trong ban kinh 1000 studs)
function RaidGetAllEnemies()
	local list = {}
	local folders = {}
	if Workspace:FindFirstChild("Enemies") then table.insert(folders, Workspace.Enemies) end
	if Workspace:FindFirstChild("Characters") then table.insert(folders, Workspace.Characters) end
	local origin = Workspace:FindFirstChild("_WorldOrigin")
	if origin and origin:FindFirstChild("Enemies") then table.insert(folders, origin.Enemies) end

	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	for _, folder in ipairs(folders) do
		for _, enemy in ipairs(folder:GetChildren()) do
			if enemy:IsA("Model") and enemy ~= LocalPlayer.Character then
				local hum = enemy:FindFirstChildOfClass("Humanoid")
				local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head")
				if hum and enemyRoot and hum.Health > 0 then
					local dist = root and (enemyRoot.Position - root.Position).Magnitude or 99999
					if dist < 1000 then
						table.insert(list, {
							Model = enemy,
							Humanoid = hum,
							Root = enemyRoot,
							Distance = dist,
							Position = enemyRoot.Position
						})
					end
				end
			end
		end
	end
	table.sort(list, function(a, b) return a.Distance < b.Distance end)
	return list
end

-- Combat tu dong clear dao trong Raid — game tu teleport player sang dao tiep theo
function RaidFightAllIslands(maxDuration)
	maxDuration = maxDuration or 600
	local started = tick()
	currentRaidWave = 1

	while tick() - started < maxDuration and RaidIsActive() do
		local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		local playerHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if not root or not playerHum or playerHum.Health <= 0 then
			task.wait(1)
		else
			TyrEnsureWeapon()
			module:haki()

			local currentIsland, waveNum = RaidGetCurrentIsland()
			if waveNum > currentRaidWave then
				currentRaidWave = waveNum
			end

			local allEnemies = RaidGetAllEnemies()
			local targetEnemy = nil

			if #allEnemies > 0 then
				targetEnemy = allEnemies[1]
			end

			if targetEnemy then
				local enemyRoot = targetEnemy.Root
				local enemyHum = targetEnemy.Humanoid
				local enemyName = targetEnemy.Model.Name

				status("Raid Island " .. tostring(currentRaidWave) .. "/5: killing " .. enemyName .. " [" .. math.floor(enemyHum.Health) .. " HP]")

				local orbit = getExtractOrbitTarget(enemyRoot.CFrame, 22)
					or CFrame.new(enemyRoot.Position + Vector3.new(0, 22, 0))
				module:topos(orbit, 220, 0, true, true)

				root.CFrame = safeLookAt(root.Position, enemyRoot.Position)

				if getgenv().TyrantFastAttack then
					pcall(getgenv().TyrantFastAttack)
				end
				TyrNormalAttack(0.2, enemyRoot)
			else
				if currentIsland then
					status("Raid Island " .. tostring(currentRaidWave) .. "/5: waiting for mobs...")
					module:topos(currentIsland.CFrame + Vector3.new(0, 100, 0), 220, 0, true, true)
				else
					status("Raid: waiting for island teleport...")
				end
				task.wait(0.5)
			end
		end
		task.wait(0.04)
	end

	currentRaidWave = 1
	module:stopTween()
end

-- Bam nut RaidSummon2 de start raid
local RAID_SUMMON_POS = CFrame.new(-5102.186, 310.564, -2922.053)
local RAID_SCIENTIST_POS = CFrame.new(-5008.5127, 313.853, -2817.0974)

function RaidFindSummonClickDetector()
	local candidates = {}
	local map = Workspace:FindFirstChild("Map")
	if map then
		candidates[#candidates + 1] = map:FindFirstChild("Boat Castle")
	end
	candidates[#candidates + 1] = Workspace:FindFirstChild("Boat Castle")
	for _, raidMap in ipairs(candidates) do
		if raidMap then
			for _, summonName in ipairs({"RaidSummon2", "MainRaid"}) do
				local summon = raidMap:FindFirstChild(summonName, true)
				local button = summon and (summon:FindFirstChild("Button", true) or summon:FindFirstChild("Main", true))
				local detector = button and button:FindFirstChildOfClass("ClickDetector")
					or (summon and summon:FindFirstChildWhichIsA("ClickDetector", true))
				if detector then
					return detector
				end
			end
			local detector = raidMap:FindFirstChildWhichIsA("ClickDetector", true)
			if detector then
				local parentName = string.lower(tostring(detector.Parent and detector.Parent.Name or ""))
				local ancestorName = string.lower(tostring(detector.Parent and detector.Parent.Parent and detector.Parent.Parent.Name or ""))
				if parentName:find("main", 1, true) or parentName:find("button", 1, true)
					or ancestorName:find("raid", 1, true) then
					return detector
				end
			end
		end
	end
	return nil
end

function RaidStartSummon()
	-- Neu da o trong Raid thi khong di chuyen ve Boat Castle
	if RaidIsActive() then return true end

	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - RAID_SUMMON_POS.Position).Magnitude > 180 then
		status("Moving to raid summon")
		module:topos(RAID_SUMMON_POS + Vector3.new(0, 8, 0), 220, 0, true, true)
		task.wait(1)
	end
	local clickDetector
	local deadline = tick() + 8
	repeat
		clickDetector = RaidFindSummonClickDetector()
		if clickDetector then break end
		task.wait(0.25)
	until tick() >= deadline
	if not clickDetector then
		return false
	end
	local chip = RaidCheckSpecialMicrochip()
	if chip and chip.Parent ~= LocalPlayer.Character then
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:EquipTool(chip) end
		task.wait(0.2)
	end
	fireclickdetector(clickDetector)
	return true
end

-- Cho raid start: 2 notification "raid" roi "go!", hoac nhan dien qua RaidIsActive()
function RaidWaitForStart(timeout)
	local started = os.time()
	timeout = timeout or 30
	repeat
		if RaidIsActive() then return true end
		task.wait(0.2)
	until os.time() - started > timeout
	return RaidIsActive()
end

-- Mot vong raid hoan chinh. Tra ve:
--   "farmed"  : dang trong raid hoac vua hoan thanh mot tran raid
--   "wait"    : khong co chip, mua beli fail, khong co fruit / mua fruit fail -> chuyen Tyrant farm neu co
--   "retry"   : dang thu lai thao tac raid summon / cho stream
--   "stop"    : da du fragment hoac level < 1100
function RaidRunOnce(targetFragments)
	local frags = tonumber(LocalPlayer.Data.Fragments.Value) or 0
	if frags >= targetFragments then
		return "stop"
	end

	-- 1. Dang trong tran Raid -> Danh thang tu dao 1 toi dao 5, khong lam bat ky viec gi khac!
	if RaidIsActive() then
		status("In Raid - clearing islands 1 to 5")
		RaidFightAllIslands(600)
		return "farmed"
	end

	-- Gate level (raid yeu cau level >= 1100)
	local level = tonumber(LocalPlayer.Data.Level.Value) or 0
	if level < 1100 then
		return "stop"
	end

	-- 2. Co chip chua?
	local chip = RaidCheckSpecialMicrochip()
	if not chip then
		-- Thu 1: Mua chip bang Beli
		local boughtWithBeli, beliErr = RaidBuyChip(1)
		if not boughtWithBeli then
			status("Chip buy with Beli failed (" .. tostring(beliErr) .. ") - trying fruit trade")
			-- Thu 2: Unstore fruit < 1M va equip len tay de doi chip
			local fruitLoaded = RaidLoadFruitForChip()
			if fruitLoaded then
				task.wait(0.3)
				-- Thu mua lai khi da cam fruit tren tay
				local boughtWithFruit, fruitErr = RaidBuyChip(2)
				if not boughtWithFruit then
					status("Chip buy with fruit failed (" .. tostring(fruitErr) .. ")")
					RaidFarming.RetryAt = os.time() + 60
					return "wait"
				end
			else
				-- Khong co fruit < 1M trong inventory storage
				status("No fruit < 1M in storage - cannot buy raid chip")
				RaidFarming.RetryAt = os.time() + 60
				return "wait"
			end
		end
	end

	-- Kiem tra lai xem chip da co tren tay / backpack chua
	chip = RaidCheckSpecialMicrochip()
	if not chip then
		RaidFarming.RetryAt = os.time() + 30
		return "wait"
	end

	-- 3. Bat dau trieu hoi Raid (bam nut summon)
	if not RaidStartSummon() then
		status("Raid summon button not reached - retrying")
		task.wait(1)
		return "retry"
	end

	-- 4. Cho raid bat dau va dich chuyen vao map raid
	if not RaidWaitForStart(30) then
		if not RaidIsActive() then
			RaidFarming.RetryAt = os.time() + 10
			return "retry"
		end
	end

	status("Raid started - fighting islands")
	task.wait(0.5)
	if RaidIsActive() then
		RaidFightAllIslands(600)
	end
	return "farmed"
end

local raidFarmingActive = false
local raidFarmingTask = nil
local raidFragmentTarget = 10000

function stopRaidFarming()
	raidFarmingActive = false
	if raidFarmingTask then
		raidFarmingTask = nil
	end
	module:stopTween()
end

function startRaidFarming(targetFragments)
	raidFragmentTarget = math.max(0, tonumber(targetFragments) or raidFragmentTarget or 10000)
	if raidFarmingTask then
		return
	end
	raidFarmingActive = true
	raidFarmingTask = task.spawn(function()
		while raidFarmingActive do
			local v4State = getV4Status(false)
			local frags = tonumber(LocalPlayer.Data.Fragments.Value) or 0
			if v4State.canTrial or v4State.complete or frags >= raidFragmentTarget then
				break
			end

			-- Neu dang trong tran Raid -> danh het 5 dao
			if RaidIsActive() then
				RaidFightAllIslands(600)
			elseif os.time() < RaidFarming.RetryAt then
				local farmConfig = getgenv().Config["Farm Fragments"]
				local autotyrant = type(farmConfig) == "table" and farmConfig.autotyrant == true
				if autotyrant then
					break
				else
					status("Raid on cooldown - waiting")
					task.wait(2)
				end
			else
				local ok, result = pcall(RaidRunOnce, raidFragmentTarget)
				if not ok then
					RaidFarming.RetryAt = os.time() + 30
					task.wait(2)
				elseif result == "farmed" then
					task.wait(0.5)
				elseif result == "retry" then
					task.wait(1.5)
				elseif result == "wait" then
					break
				else -- "stop"
					break
				end
			end
			task.wait(0.1)
		end
		module:stopTween()
		raidFarmingTask = nil
		raidFarmingActive = false
	end)
end

function handleFragmentFarming(requiredFragments)
	local farmConfig = getgenv().Config["Farm Fragments"]
	if not farmConfig then
		return false
	end
	local state = getV4Status(false)
	if state.canTrial or state.complete then
		if tyrantFarmingActive then stopTyrantFarming() end
		if raidFarmingActive then stopRaidFarming() end
		return false
	end
	local target = math.max(0, tonumber(requiredFragments) or 10000)
	local frags = tonumber(LocalPlayer.Data.Fragments.Value) or 0
	if frags >= target then
		if tyrantFarmingActive then stopTyrantFarming() end
		if raidFarmingActive then stopRaidFarming() end
		return false
	end

	local autoraid = type(farmConfig) == "table" and farmConfig.autoraid == true
	local autotyrant = type(farmConfig) == "table" and farmConfig.autotyrant == true

	-- 1. Neu dang trong tran Raid that -> Uu tien tuyet doi, TUYET DOI khong de Tyrant keo di!
	if RaidIsActive() then
		if tyrantFarmingActive then
			stopTyrantFarming()
		end
		startRaidFarming(target)
		return true
	end

	-- 2. Neu bat Auto Raid:
	if autoraid then
		if os.time() < RaidFarming.RetryAt then
			if autotyrant then
				if raidFarmingActive then
					stopRaidFarming()
				end
				status("Raid blocked - farming Tyrant for fragments (" .. tostring(frags) .. "/" .. tostring(target) .. ")")
				startTyrantFarming(target)
				return tyrantFarmingActive
			else
				status("Raid on cooldown - waiting (" .. tostring(RaidFarming.RetryAt - os.time()) .. "s)")
				return true
			end
		end

		if tyrantFarmingActive then
			stopTyrantFarming()
		end
		startRaidFarming(target)
		return raidFarmingActive
	end

	-- 3. Neu chi bat Auto Tyrant:
	if autotyrant then
		if raidFarmingActive then
			stopRaidFarming()
		end
		startTyrantFarming(target)
		return tyrantFarmingActive
	end

	return false
end

function buyPendingV4Upgrade(v4State, roleLabel)
	if not v4State or not v4State.needsPurchase then
		return false
	end
	roleLabel = tostring(roleLabel or "Account")
	local fragments = tonumber(LocalPlayer.Data.Fragments.Value) or 0
	local cost = tonumber(v4State.cost) or 0
	if cost <= 0 then
		local fallbackCosts = {
			[2] = 1000,
			[4] = 2000,
			[7] = 3250,
			[9] = 4000,
		}
		cost = fallbackCosts[tonumber(v4State.code)] or 1000
	end

	-- 1. Kiem tra xem co du fragment de mua gear/upgrade khong
	if fragments < cost then
		substatus("Farm F: " .. formatNumber(fragments) .. "/" .. formatNumber(cost) .. " (thiếu " .. formatNumber(cost - fragments) .. ")")
		status(roleLabel .. " needs " .. tostring(cost - fragments) .. " more fragments to buy upgrade (" .. formatNumber(fragments) .. "/" .. formatNumber(cost) .. " F)")
		if handleFragmentFarming(cost) then
			return true
		end
		return true
	end

	-- 2. Da du fragment -> dung farm va mua upgrade ngay lap tuc
	if tyrantFarmingActive then
		stopTyrantFarming()
	end
	if raidFarmingActive then
		stopRaidFarming()
	end
	substatus("Mua gear " .. formatNumber(fragments) .. "/" .. formatNumber(cost) .. "F")
	status(roleLabel .. " has enough fragments (" .. formatNumber(fragments) .. "/" .. formatNumber(cost) .. " F) - buying V4 upgrade")
	local ok, bought = pcall(function()
		return invokeUpgradeRace("Buy")
	end)
	invalidateV4Status()
	if ok and bought then
		status(roleLabel .. " V4 upgrade purchased successfully!")
	else
		status(roleLabel .. " V4 purchase failed - retrying")
	end
	task.wait(0.6)
	return true
end
function HopRandom()
	task.spawn(function()
		local serverBrowser = ReplicatedStorage:FindFirstChild("__ServerBrowser") or ReplicatedStorage:WaitForChild("__ServerBrowser", 5)
		if not serverBrowser then return end
		for i = 1, 100 do
			local success, servers = pcall(function()
				return serverBrowser:InvokeServer(i)
			end)
			if success and type(servers) == "table" then
				for i2, v in pairs(servers) do
					if (v.Count or 0) >= 9 and i2 ~= game.JobId then
						pcall(function()
							serverBrowser:InvokeServer("teleport", i2)
						end)
						return
					end
				end
			end
		end
	end)
end

function runRaceTrainingWork(trainingState, roleLabel)
    roleLabel = tostring(roleLabel or "Account")
    local character = Players.LocalPlayer.Character
    if not character then
        status(roleLabel .. " waiting character")
        task.wait(1)
        return false
    end

    local initialV4State = getV4Status(false)
    if initialV4State.complete then
        status(roleLabel .. " Race V4 completed")
        return true
    end
    if initialV4State.canTrial and not isAlly then
        -- Helper lu n canTrial=true (faked), n n skip check n y cho helper
        status(roleLabel .. " training complete - ready for trial")
        return true
    end
    if initialV4State.needsPurchase and not isAlly then
        buyPendingV4Upgrade(initialV4State, roleLabel)
        return false
    end

    if not character:FindFirstChild("RaceTransformed") then
        status(roleLabel .. " " .. tostring(initialV4State.label))
        talktoonggianaodo()
        invalidateV4Status()
        return false
    end

    if tyrantFarmingActive then stopTyrantFarming() end

    -- Set flag:  ang training   block hop trong main loop
    isCurrentlyTraining = true

    local fullMoonTraining = isnight() and isfullmoon()
    local remainingText = type(trainingState) == "number" and (" (" .. tostring(trainingState) .. " left)") or ""
    status(roleLabel .. (fullMoonTraining and " Full Moon - training" or " training") .. remainingText)

    local nextReadyCheck = 0
    local cycleFinished = false
    local function shouldStopTrainingCycle()
        if cycleFinished then return true end
		local trialCheckOk, insideTrial = pcall(function()
			return isNearOwnTrialArena()
		end)
		if trialCheckOk and insideTrial then
			cycleFinished = true
			isCurrentlyTraining = false
			status(roleLabel .. " entered Trial - stopping training")
			return true
		end
        if tick() < nextReadyCheck then return false end
        nextReadyCheck = tick() + 0.8

        -- Helper: check RaceTransformed c n t n t i kh ng (=  ang train)
        -- Kh ng d ng canTrial v  helper lu n canTrial=true (faked)
        if isAlly then
            local char = Players.LocalPlayer.Character
            if not char or not char:FindFirstChild("RaceTransformed") then
                cycleFinished = true
                status(roleLabel .. " training session ended")
                return true
            end
            return false
        end

        local state = getV4Status(true)
        if state.canTrial then
            cycleFinished = true
            status(roleLabel .. " training complete - ready for trial")
            return true
        end
        if state.complete then
            cycleFinished = true
            status(roleLabel .. " Race V4 completed")
            return true
        end
        if state.needsPurchase then
            cycleFinished = true
            status(roleLabel .. " training complete - V4 upgrade available")
            return true
        end
        return false
    end

    pcall(function()
        local energy = Players.LocalPlayer.Character:FindFirstChild("RaceEnergy")
        local transformed = Players.LocalPlayer.Character:FindFirstChild("RaceTransformed")
        if energy and energy.Value >= 1 and transformed and not transformed.Value then
            VirtualInputManager:SendKeyEvent(true, "Y", false, game)
            VirtualInputManager:SendKeyEvent(false, "Y", false, game)
        end
    end)

    -- L y island 1 l n, kh ng re-query trong su t cycle
    local islandName = assignTrainingIsland()
    if not islandName then
        -- T t c  island b n ho c API l i   reset flag v  ch  v ng sau
        status(roleLabel .. " no island available - retry next cycle")
        isCurrentlyTraining = false
        return false
    end
    local islandData = TrainingIslandData[islandName]
    if not islandData then
        status(roleLabel .. " unknown island: " .. tostring(islandName) .. " - retry")
        forceReassignIsland()  -- xóa cache island sắt
        isCurrentlyTraining = false
        return false
    end
    local trainingPositions = nil
    if islandData.Positions then
        trainingPositions = islandData.Positions
    elseif islandData.Position then
        trainingPositions = { islandData.Position }
    else
        status("Island has no position data")
        isCurrentlyTraining = false
        return false
    end

    local currentPosIndex = 1
    local function getCurrentPos()
        return trainingPositions[currentPosIndex]
    end

    local function advancePosition()
        currentPosIndex = currentPosIndex + 1
        if currentPosIndex > #trainingPositions then currentPosIndex = 1 end
    end

    local trainingPosition = getCurrentPos()
    if getdis(trainingPosition) >= 1500 then
        local dist = math.floor(getdis(trainingPosition))
        substatus("Tele → " .. tostring(islandName) .. " (" .. tostring(dist) .. " studs)")
        status(roleLabel .. " moving to [" .. tostring(islandName) .. "] for training")
        resetTeleportToTrainingIsland(true, islandName)
        isCurrentlyTraining = false
        return false
    end
	-- Refresh the server spawn even when we already started on the island.
	setTrainingSpawnPoint(trainingPosition)

    local mobNames = {}
    for name in pairs(islandData.Mobs) do
        table.insert(mobNames, name)
    end

    local orbitHeight = math.max(10, tonumber(getgenv().Config["Trial Orbit Height"]) or 30)
    AttackConfig.AutoClickEnabled = true
    equipTrialCombatTool()

    while not shouldStopTrainingCycle() do
        local mob = CheckMonster(table.unpack(mobNames))
        if not mob then
            AttackConfig.AutoClickEnabled = true
            substatus("[" .. tostring(islandName) .. "] chờ mob spawn")
            status(roleLabel .. " [" .. tostring(islandName) .. "] waiting for mobs...")
            topos(getCurrentPos())
            task.wait(0.8)
            advancePosition()
        else
            local root = mob:FindFirstChild("HumanoidRootPart")
            local humanoid = mob:FindFirstChild("Humanoid")
            if root and humanoid and humanoid.Health > 0 then
                local attemptCharacter = Players.LocalPlayer.Character
                repeat
                    task.wait()
                    module:eq()
                    module:haki()
                    local currentCharacter = Players.LocalPlayer.Character
                    local energy = currentCharacter and currentCharacter:FindFirstChild("RaceEnergy")
                    local transformed = currentCharacter and currentCharacter:FindFirstChild("RaceTransformed")
                    if transformed and transformed.Value then
                        AttackConfig.AutoClickEnabled = false
                        substatus("[" .. tostring(islandName) .. "] transform active")
                        status(roleLabel .. " [" .. tostring(islandName) .. "] wait transform end")
                        root = mob:FindFirstChild("HumanoidRootPart")
                        if root then
                            topos(getExtractOrbitTarget(root.CFrame, 150) or (root.CFrame * CFrame.new(0, 150, 0)))
                        end
                    else
                        AttackConfig.AutoClickEnabled = true
                        local mobHp = humanoid and math.floor(humanoid.Health) or 0
                        substatus("[" .. tostring(islandName) .. "] " .. tostring(mob.Name) .. " " .. tostring(mobHp) .. "HP")
                        status(roleLabel .. " [" .. tostring(islandName) .. "] killing mobs + charge")
                        root = mob:FindFirstChild("HumanoidRootPart")
                        if root then
                            local orbit = getExtractOrbitTarget(root.CFrame, orbitHeight)
                            topos(orbit or (root.CFrame * CFrame.new(0, orbitHeight, 0)))
                        end
                        if energy and energy.Value >= 1 then
                            VirtualInputManager:SendKeyEvent(true, "Y", false, game)
                            VirtualInputManager:SendKeyEvent(false, "Y", false, game)
                        end
                    end
                    humanoid = mob:FindFirstChild("Humanoid")
                until Players.LocalPlayer.Character ~= attemptCharacter
                    or not attemptCharacter.Parent
                    or not attemptCharacter:FindFirstChildOfClass("Humanoid")
                    or attemptCharacter:FindFirstChildOfClass("Humanoid").Health <= 0
                    or not mob.Parent or not root or not humanoid or humanoid.Health <= 0
                    or shouldStopTrainingCycle()
            end
        end
    end

    AttackConfig.AutoClickEnabled = true
    invalidateV4Status()
    forceReassignIsland()
    isCurrentlyTraining = false
    return cycleFinished
end

function runWaitingAccountWork()
    local roleLabel = isUper and "Main" or "Help"
    local fullMoonNow = isnight() and isfullmoon()
    local v4State = getV4Status(false)
    local fragments = tonumber(LocalPlayer.Data.Fragments.Value) or 0

    -- UU TIEN #1: KIEM TRA MUA GEAR / UPGRADE & KIEM TRA FRAGMENT TRUOC TIEN
    if v4State.needsPurchase then
        local cost = tonumber(v4State.cost) or 0
        if cost <= 0 then
            local fallbackCosts = { [2] = 1000, [4] = 2000, [7] = 3250, [9] = 4000 }
            cost = fallbackCosts[tonumber(v4State.code)] or 1000
        end
        if fragments < cost then
            substatus("Gear " .. formatNumber(fragments) .. "/" .. formatNumber(cost) .. "F → farm")
        else
            substatus("Gear " .. formatNumber(fragments) .. "/" .. formatNumber(cost) .. "F → mua")
        end
        buyPendingV4Upgrade(v4State, roleLabel)
        return
    end

    -- UU TIEN #2: TRAINING ISLAND (neu can train)
    if v4State.needsTraining then
        if tyrantFarmingActive then stopTyrantFarming() end
        if raidFarmingActive then stopRaidFarming() end
        local remaining = v4State.remainingTraining
        if remaining and type(remaining) == "number" then
            substatus("Train còn " .. tostring(remaining) .. " session")
        else
            substatus("Training " .. tostring(v4State.key or ""))
        end
        local trainingState = remaining or (v4State.needsTraining and "training" or v4State.key)
        local trainingDone = runRaceTrainingWork(trainingState, roleLabel)
        if trainingDone then invalidateV4Status() end
        return
    end

    -- UU TIEN #3: TRIAL (neu can trial)
    if v4State.canTrial then
        if tyrantFarmingActive then stopTyrantFarming() end
        if raidFarmingActive then stopRaidFarming() end
        if fullMoonNow then
            substatus("Full Moon - chờ ghép nhóm")
            status("Full Moon + trial-ready - waiting auto pair 1 Main + 2 Help")
        else
            substatus("Chờ Full Moon")
            status("Ready for trial - waiting Full Moon and auto pair")
        end
        return
    end

    if v4State.complete then
        if tyrantFarmingActive then stopTyrantFarming() end
        if raidFarmingActive then stopRaidFarming() end
        substatus("V4 hoàn thành")
        status("Race V4 completed - no more training needed")
        return
    end

    if tyrantFarmingActive then stopTyrantFarming() end
    if raidFarmingActive then stopRaidFarming() end
    substatus("Check V4 state: " .. tostring(v4State.key or "unknown"))
    local trainingState = v4State.remainingTraining or (v4State.needsTraining and "training" or v4State.key)
    local trainingDone = runRaceTrainingWork(trainingState, roleLabel)
    if trainingDone then
        invalidateV4Status()
    end
end


task.spawn(function()
	while task.wait(0.1) do
		repeat
		if not isUper and not isAlly then
			status("Set Main or Help = true")
			task.wait(2)
			break
		end
		if postTrialTransitionInProgress then
			status("Post-Trial reset teleport in progress")
			task.wait(0.2)
			break
		end
		if trialCycleDone then
			local postTrialState = getV4Status(false)
			if postTrialState and (postTrialState.needsTraining or postTrialState.needsPurchase or postTrialState.complete) then
				resetTrialBarrierState()
				matchState.assigned = false
				pcall(runWaitingAccountWork)
			elseif not matchState.assigned then
				-- Hub đã cancel assignment (member timeout / expired) trong lúc
				-- đang đứng barrier. Reset để Hub ghép nhóm mới thay vì đứng mãi.
				status("Hub cancelled group while in barrier - resetting for re-pair")
				resetTrialBarrierState()
				helperSacrificeDone = false
				pcall(runWaitingAccountWork)
			else
				pcall(runTrialCompletionBarrier)
			end
			task.wait(0.25)
			break
		end
		if trialCompletedHoldUntil == math.huge then
			task.wait(0.2)
			break
		end
		if trialRetryPending then
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 then
				local atRaceDoor = forceMatchedAccountToTemple(true)
				if atRaceDoor then
					status("Trial retry - at race door, waiting V3 sync")
					pcall(tryActivateAbility)
				end
			end
			task.wait(0.2)
			break
		end
		-- The independent worker performs the trial; this branch only prevents
		-- pairing/training movement from competing with it.
		local trialCheckOk, insideActiveTrial = pcall(isNearOwnTrialArena)
		if trialCheckOk and insideActiveTrial then
			task.wait(0.1)
			break
		end
		--  
		-- [FIX] V4 STATE   matchState.assigned (inline trong loop)
		-- N u c n training/purchase th  T T paired mode ngay l p t c
		--   script ch y v o runWaitingAccountWork()   farm mobs
		--  
		if matchState then
			local v4s = nil
			pcall(function() v4s = getV4Status(false) end)
			local needsIndependentWork = v4s and (v4s.needsTraining or v4s.needsPurchase)
			local mainFinishingTrial = isUper and isMyUpgearTurn()
				and (pairTrialCycleStarted or pairV3ActivatedAt > 0 or handledRoundId ~= "")
			if needsIndependentWork and not mainFinishingTrial then
				matchState.assigned = false
			end
		end
		if not matchState or not matchState.assigned then
			local wok, werr = pcall(runWaitingAccountWork)
			if not wok then
				isCurrentlyTraining = false
				status("⚠ training err: " .. tostring(werr):sub(1, 60))
				task.wait(1)
			end
			task.wait(0.2)
			break
		end
		if matchState.main_job_id and matchState.main_job_id ~= game.JobId then
			status("Joining matched Main server")
			task.wait(1)
			break
		end
		local pairedV4State = getV4Status(false)
		-- B  getV4Status(true): canTrial v  needsTraining kh ng x y ra  ng th i, call n y blocking g y gi t
		local pairedReady = pairedV4State.canTrial == true and not pairedV4State.needsTraining
		local pairedTrainingState = pairedV4State.remainingTraining or (pairedV4State.needsTraining and "training" or pairedV4State.key)
		if isUper and isMyUpgearTurn() then
			local trialOrTimerActive = isInsideOwnTrial()
			local ffaStarted = false
			pcall(function()
				ffaStarted = workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0
			end)
			if trialOrTimerActive or ffaStarted then
				pairTrialCycleStarted = true
			end
		end
		if not pairedReady then
			pairTempleReadyAt = 0
			lastTempleReadyCount = 0
			local trialCycleConfirmed = pairTrialCycleStarted or pairV3ActivatedAt > 0 or handledRoundId ~= "" or isInsideOwnTrial()
			if PAIR_RELEASE_AFTER_TRIAL and isUper and isMyUpgearTurn() and trialCycleConfirmed then
				local claimed = false
				pcall(function() claimed = checkgear() end)
				if claimed then
					pairTrialCycleStarted = true
					status("Gear claimed successfully - proceeding to next step")
					invalidateV4Status()
					beginPostTrialFarmTransition("gear_claimed")
					break
				end
			end
			if pairedV4State.complete then
				if tyrantFarmingActive then
					stopTyrantFarming()
				end
				status("Paired account has completed Race V4")
				if isUper and isMyUpgearTurn() then
					releaseCurrentGroup("race_v4_completed")
				end
				task.wait(1)
			elseif pairedV4State.needsPurchase then
				buyPendingV4Upgrade(pairedV4State, isUper and "Main" or "Help")
				task.wait(0.2)
			else
				if tyrantFarmingActive then
					stopTyrantFarming()
				end
				status("Paired but not trial-ready - continue training")
				local tok, terr = pcall(runRaceTrainingWork, pairedTrainingState, isUper and "Main" or "Help")
				if not tok then
					isCurrentlyTraining = false
					status("⚠ pair train err: " .. tostring(terr):sub(1, 50))
				end
			end
			break
		end
		local fullMoonNow = isnight() and isfullmoon()
		if not fullMoonNow then
			pairTempleReadyAt = 0
			lastTempleReadyCount = 0
			if isInsideOwnTrial() then
				status("Trial in progress - keeping pair until completion")
				substatus("Hoàn thành Trial")
			else
				pairTrialCycleStarted = false
				pairV3ActivatedAt = 0
				handledRoundId = ""
				if isUper and isMyUpgearTurn() then
					releaseCurrentGroup("full_moon_ended")
				else
					status("Full Moon ended - waiting next cycle")
				end
				matchState.assigned = false
				local wok, werr = pcall(runWaitingAccountWork)
				if not wok then
					isCurrentlyTraining = false
					status("⚠ work err: " .. tostring(werr):sub(1, 60))
				end
			end
			task.wait(0.5)
			break
		end
		if tyrantFarmingActive then
			stopTyrantFarming()
		end
		if pairAllInJobAt > 0 and pairTempleReadyAt <= 0 then
			pairTempleReadyAt = tick()
			lastTempleReadyCount = 0
		end
		forceMatchedAccountToTemple()
		if isUper and isMyUpgearTurn() and pairTempleReadyAt > 0 then
			local timeoutAnchor = math.max(pairTempleReadyAt, lastTempleProgressAt or 0)
			if tick() - timeoutAnchor > PAIR_TEMPLE_TIMEOUT then
				local readyCount = 0
				pcall(function()
					readyCount = select(1, readReadyFiles())
				end)
				if readyCount > lastTempleReadyCount then
					lastTempleReadyCount = readyCount
					pairTempleReadyAt = tick()
				elseif readyCount < 3 and not isInsideOwnTrial() then
					if PAIR_STICKY_UNTIL_TRIAL_COMPLETE then
						pairTempleReadyAt = tick()
						lastTempleProgressAt = tick()
						lastTempleDistance = math.huge
						readySent = false
						status("Temple ready timeout - keeping pair until Trial completes")
					else
						releaseCurrentGroup("temple_ready_timeout")
						task.wait(1)
						break
					end
				end
			end
		end
		local doorCallOk, doorResult = pcall(function()
			return CommF_:InvokeServer("CheckTempleDoor")
		end)
		local checktempledoor = doorCallOk and doorResult == true
		if not checktempledoor then
			status(doorCallOk and "Temple door is not available yet" or "CheckTempleDoor remote failed")
			task.wait(0.5)
		else
			_G.ShouldSendData = true
			if not workspace.Map:FindFirstChild("Temple of Time") then
				local templeRef = ReplicatedStorage.MapStash:FindFirstChild("Temple of Time")
				if templeRef then
					templeRef.Parent = workspace.Map
				end
			elseif workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0 then
				_G.SHOULDSPAMSKILLS = false
				if isMain then
					status("Killing players after trial...")
					for plr, i in pairs(getplayers(true)) do
						if plr then
							repeat
								task.wait()
								pcall(function()
									topos(plr.HumanoidRootPart.CFrame * CFrame.new((function()
										local x, y, z = 0, 3, 0
										x = math.random(1, 4);
										z = math.random(1, 4)
										if math.random(1, 2) == 1 then
											x = x * -1
										end
										if math.random(1, 2) == 1 then
											z = z * -1
										end
										return x, y, z
									end)()))
								end)
							until not plr or not plr.Parent or not plr:FindFirstChild("Humanoid")
                                or not plr:FindFirstChild("HumanoidRootPart") or plr.Humanoid.Health <= 0
                                or workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 1
						end
					end
                -- Main (isUper and isMyUpgearTurn()) KH NG BAO GI  t  reset
                -- character trong l c trial  ang ch y, b t k  vai tr  c 
                -- c a API tr  v   ng/sai. Ch  Help (Ally ho c Helper kh ng
                -- ph i l t) m i reset   d n  ng cho Main.
				elseif isUper and isMyUpgearTurn() then
					status("Main is in trial - never auto-reset")
				elseif (isAlly or (isUper and not isMyUpgearTurn())) and not helperSacrificeDone then
					helperSacrificeDone = true
					status("Helper yielding FFA once for Main")
					local character = Players.LocalPlayer.Character
					local humanoid = character and character:FindFirstChildOfClass("Humanoid")
					if humanoid and humanoid.Health > 0 then
						humanoid.Health = 0
					end
				elseif isAlly then
					status("Helper FFA yield completed - waiting next Trial")
				end
			else
				local myrace, race_trial_place = getOwnTrialLocation()
				if race_trial_place and getdis(race_trial_place.CFrame) < 1500 then
					pcall(runCurrentRaceTrial, myrace, race_trial_place)
				else
					if Players.LocalPlayer.PlayerGui.Main.Timer.Visible == false then
						local khang = nil
						local timeout = 0
						repeat
							task.wait();
							khang = getdoor();
							timeout = timeout + 1
							if timeout > 300 then
								break
							end
						until khang ~= nil
						if khang and getdis(khang.CFrame) < 1500 then
							topos(khang.CFrame)
							status("At door - waiting")
							if trialable() then
								if isUper then
									if isMyUpgearTurn() then
										readySent = true
										status("Ready trials")
									else
										readySent = false
										status("waiting my turn")
										task.wait(1)
									end
								elseif isAlly then
									readySent = true
									status("Helper ready")
								end
							else
								if isUper and not isMyUpgearTurn() then
									status("waiting turn")
									task.wait(1)
								end
							end
						else
							CommF_:InvokeServer("requestEntrance", Vector3.new(28310.0234, 14895.1123, 109.456741))
						end
					end
				end
			end
			if tryActivateAbility() then
				task.wait(0.2)
			end
		end
		until true
	end
end)

local fruits = {
	["Buddha-Buddha"] = true,
	["T-Rex-T-Rex"] = true,
	["Dragon-Dragon"] = true,
	["Yeti-Yeti"] = true,
	["Leopard-Leopard"] = true,
	["Venom-Venom"] = true,
	["Phoenix-Phoenix"] = true,
	["Kitsune-Kitsune"] = true,
	["Mammoth-Mammoth"] = true,
	["Gas-Gas"] = true,
	["Portal-Portal"] = true
}
local isvalidtooltip = {
	["Melee"] = true,
	["Blox Fruit"] = true,
	["Sword"] = true,
	["Gun"] = true
}
local isvalidnameui = {
	["Z"] = true,
	["X"] = true,
	["C"] = true,
	["V"] = true,
	["F"] = true
}

function getallweapon()
	local weapon = {}
	for i, v in pairs(Players.LocalPlayer.Backpack:GetChildren()) do
		if v:IsA("Tool") and isvalidtooltip[v.ToolTip] then
			table.insert(weapon, v)
		end
	end
	for i, v in pairs(Players.LocalPlayer.Character:GetChildren()) do
		if v:IsA("Tool") and isvalidtooltip[v.ToolTip] then
			table.insert(weapon, v)
		end
	end
	return weapon
end

function EquipTool(v)
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	local equipped = character:FindFirstChild(v)
	if equipped and equipped:IsA("Tool") then return true end
	local tool = Players.LocalPlayer.Backpack:FindFirstChild(v)
	if not tool or not tool:IsA("Tool") then return false end
	humanoid:EquipTool(tool)
	task.wait(0.12)
	return character:FindFirstChild(v) ~= nil
end

_G.SHOULDSPAMSKILLS = false

local TRIAL_AIM_MAX_DISTANCE = 2000  -- SeaBeast trial range tăng lên để không bị tắt aim
local TRIAL_AIM_PREDICT_TIME = 0.12
local TRIAL_AIM_BIND_NAME = "KaitunTrialAim"
local TRIAL_AIM_HOLD = math.max(0.05, tonumber(getgenv().Config["Trial Aim Hold"]) or 0.35)
-- Aim cho binh/mob/Tyrant: tam gan hon trial nhieu, chi can phu ban kinh
-- attack + orbit (~105 + 40 stud) nen 260 la du va tranh aim vao vat o xa.
local SKILL_AIM_MAX_DISTANCE = math.max(60, tonumber(getgenv().Config["Skill Aim Distance"]) or 260)
trialAimHoldUntil = 0

local previousTrialAimConnection = getgenv().__KAITUN_TRIAL_AIM_CONNECTION
if previousTrialAimConnection then
	pcall(function()
		previousTrialAimConnection:Disconnect()
	end)
	getgenv().__KAITUN_TRIAL_AIM_CONNECTION = nil
end
pcall(function()
	RunService:UnbindFromRenderStep(TRIAL_AIM_BIND_NAME)
end)

-- Aim th ng tr c ti p v o t m Sea Beast (Head / Hitbox / HumanoidRootPart)
-- Kh ng clamp bounding-box hay nh n velocity lead qu  m c khi n skill b  x t ra ngo i
function getTrialAimPoint(target)
	if not target or not target.Parent then
		return nil
	end
	if target:IsA("Model") then
		local head = target:FindFirstChild("Hitbox") or target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
		if head and head:IsA("BasePart") then
			return head.Position
		end
	end
	if target:IsA("BasePart") then
		local parent = target.Parent
		if parent and parent:IsA("Model") then
			local head = parent:FindFirstChild("Hitbox") or parent:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				return head.Position
			end
		end
		return target.Position
	end
	return nil
end

function getTrialAimState()
	local target, isTrialTarget = getActiveAimPart()
	if not target then
		return nil
	end
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local maxDistance = isTrialTarget and TRIAL_AIM_MAX_DISTANCE or SKILL_AIM_MAX_DISTANCE
	if not root or not humanoid or humanoid.Health <= 0
		or (root.Position - target.Position).Magnitude > maxDistance
	then
		return nil
	end
	local aimPoint = getTrialAimPoint(target)
	if not aimPoint then
		return nil
	end
	return aimPoint, root, isTrialTarget
end

-- Aimbot chi xoay than nhan vat (HumanoidRootPart), TUYET DOI KHONG can thiep
-- vao Camera.CFrame hoac chuot vat ly cua nguoi dung (moveTrialMouseTo / SendMouseMoveEvent).
RunService:BindToRenderStep(TRIAL_AIM_BIND_NAME, Enum.RenderPriority.Character.Value + 1, function()
	if tick() >= trialAimHoldUntil then
		return
	end
	local aimPoint, root = getTrialAimState()
	if not aimPoint or not root then
		return
	end
	if (aimPoint - root.Position).Magnitude > 0.5 then
		root.CFrame = safeLookAt(root.Position, aimPoint)
	end
end)

-- Snap huong nhan vat vao muc tieu truoc khi ban skill
function aimAtSkillTarget(holdTime)
	local aimPoint, root = getTrialAimState()
	if not aimPoint or not root then
		return false
	end
	trialAimHoldUntil = tick() + math.max(0.03, tonumber(holdTime) or TRIAL_AIM_HOLD)
	if (aimPoint - root.Position).Magnitude > 0.5 then
		root.CFrame = safeLookAt(root.Position, aimPoint)
	end
	return true
end

local function aimAtTrialSkillTarget()
	return aimAtSkillTarget(nil)
end

-- Silent aim qua metamethod hook cho Mouse.Hit / Mouse.Target:
-- Khi script cua game kiem tra vi tri chuot de phong skill, no tu dong nhan
-- duoc toa do target ma khong he can di chuyen con tro chuot tren man hinh.
pcall(function()
	if typeof(hookmetamethod) == "function" then
		local oldIndex
		oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
			if not checkcaller() and typeof(self) == "Instance" and self:IsA("Mouse") then
				if key == "Hit" or key == "hit" then
					local target = getActiveAimPart()
					if target and typeof(target) == "Instance" and target:IsA("BasePart") and target.Parent then
						local aimPoint = getTrialAimPoint(target)
						if aimPoint then
							return CFrame.new(aimPoint)
						end
					end
				elseif key == "Target" or key == "target" then
					local target = getActiveAimPart()
					if target and typeof(target) == "Instance" and target.Parent then
						return target
					end
				end
			end
			return oldIndex(self, key)
		end))
	end
end)

-- Skill spam loop: cycle Melee   Sword   Melee li n t c, kh ng ng i ch  cooldown
-- M i v ng: equip Melee   spam h t skill s n   equip Sword   spam h t skill s n   l p l i
task.spawn(function()
	-- T m tool theo ToolTip trong character + backpack
	local function findToolByTip(tip)
		local char = Players.LocalPlayer.Character
		local bp = Players.LocalPlayer.Backpack
		if char then
			for _, t in ipairs(char:GetChildren()) do
				if t:IsA("Tool") and t.ToolTip == tip then return t end
			end
		end
		if bp then
			for _, t in ipairs(bp:GetChildren()) do
				if t:IsA("Tool") and t.ToolTip == tip then return t end
			end
		end
		return nil
	end

	-- Equip tool v   i n  v o character, tr  v  tool   equip ho c nil
	local function equipTool(tool)
		local char = Players.LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum or not tool then return nil end
		if tool.Parent == char then return tool end
		pcall(function() hum:EquipTool(tool) end)
		local deadline = tick() + 0.4
		repeat task.wait(0.03) until tick() >= deadline
			or (char:FindFirstChild(tool.Name) ~= nil)
		return char:FindFirstChild(tool.Name)
	end

	-- Spam tat ca skill san sang cua tool dang equip
	local function spamAllReadySkills(toolName)
		local skillsGui = Players.LocalPlayer.PlayerGui:FindFirstChild("Main")
			and Players.LocalPlayer.PlayerGui.Main:FindFirstChild("Skills")
		local ui = skillsGui and skillsGui:FindFirstChild(toolName)
		if not ui then return 0 end
		local fired = 0
		for _, vl in pairs(ui:GetChildren()) do
			if isvalidnameui[vl.Name] then
				local cdFrame = vl:FindFirstChild("Cooldown")
				local titleFrame = vl:FindFirstChild("Title")
				if cdFrame and titleFrame then
					local titleReady = titleFrame.TextColor3 == Color3.new(1, 1, 1)
						or titleFrame.TextColor3 == Color3.fromRGB(255, 255, 255)
					local cdReady = cdFrame.Size.X.Scale == 0 and cdFrame.Size.X.Offset == 0
					if titleReady and cdReady then
						aimAtTrialSkillTarget()
						task.wait(0.02)
						if vl.Name == "V" then
							if not fruits[ui.Name] then
								VirtualInputManager:SendKeyEvent(true, "V", false, game)
								task.wait(0.05)
								VirtualInputManager:SendKeyEvent(false, "V", false, game)
								fired = fired + 1
							end
						else
							VirtualInputManager:SendKeyEvent(true, vl.Name, false, game)
							task.wait(0.05)
							VirtualInputManager:SendKeyEvent(false, vl.Name, false, game)
							fired = fired + 1
						end
						task.wait(0.03)
					end
				end
			end
		end
		return fired
	end

	while task.wait(0.05) do
		if _G.SHOULDSPAMSKILLS then
			local char = Players.LocalPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				local meleeT = findToolByTip("Melee")
				local swordT = findToolByTip("Sword")
				local fruitT = findToolByTip("Blox Fruit")

				for _, weaponTip in ipairs({"Melee", "Sword", "Blox Fruit"}) do
					if not _G.SHOULDSPAMSKILLS then break end
					local tool = weaponTip == "Melee" and meleeT or (weaponTip == "Sword" and swordT or fruitT)
					if tool then
						local equipped = equipTool(tool)
						if equipped then
							spamAllReadySkills(equipped.Name)
						end
					end
				end
			end
		end
	end
end)

local Ec = Players.LocalPlayer
function Bc(x)
	if not x then
		return false
	end
	local L = x:FindFirstChild("Humanoid")
	return L and L["Health"] > 0
end
function Pc(x, L)
	local V = Players:GetPlayers()
	local H = {}
	local r = (x:GetPivot())["Position"]
	local leader = Players:FindFirstChild(mainAccountName)
	for _, a in ipairs(V) do
		if a ~= Ec and a ~= leader and a["Character"] and noideaforname(a) then
			local xp = a["Character"]:FindFirstChild("HumanoidRootPart")
			if xp and Bc(a["Character"]) then
				if (xp["Position"] - r)["Magnitude"] <= L then
					table["insert"](H, a["Character"])
				end
			end
		end
	end
	for _, a in ipairs(workspace["Enemies"]:GetChildren()) do
		local xp = a:FindFirstChild("HumanoidRootPart")
		if a ~= leader and xp and Bc(a) then
			if (xp["Position"] - r)["Magnitude"] <= L then
				table["insert"](H, a)
			end
		end
	end
	return H
end
--https://fi12.bot-hosting.cloud:20777/noguchi?name=
function gettimeserver()
	local ok, res = pcall(function()
		return tonumber(game:HttpGet("http://fi12.bot-hosting.cloud:20777/timeserver"))
	end)
	if ok and type(res) == "number" then return res end
	return os.time()
end

task.spawn(function()
	while task.wait(1) do
		if _G.ShouldSendData then
			(http_request or http and http.request or request)({
				Url = "https://baorph.x10.mx/data/apiv4.php?route=baor",
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json"
				},
				Body = HttpService:JSONEncode({
					username = Players.LocalPlayer.Name,
					jobid = game.JobId
				})
			})
		end
	end
end)


function hopRandom()
	local ok, ServerBrowser = pcall(function()
		return ReplicatedStorage:FindFirstChild("__ServerBrowser") or ReplicatedStorage:WaitForChild("__ServerBrowser", 5)
	end)
	if not ok or not ServerBrowser then return false end
	for i = 1, 100 do
		local ok2, servers = pcall(function()
			return ServerBrowser:InvokeServer(i)
		end)
		if ok2 and servers then
			for jobId, info in pairs(servers) do
				if jobId ~= game.JobId and (info.Count or 0) < 12 then
					pcall(function()
						ServerBrowser:InvokeServer("teleport", jobId)
					end)
					task.wait(0.3)
					return true
				end
			end
		end
	end
	return false
end

_G[Players.LocalPlayer.Name] = true
getgenv().UseSeaUi = true

function createUI()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "NoNameHubUI"
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Parent = safeGetGuiParent() or Player:WaitForChild("PlayerGui")
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, 0, 1, 0)
	Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Frame.BackgroundTransparency = 0.3
	Frame.Parent = ScreenGui
	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, 0, 0.08, 0)
	Title.Position = UDim2.new(0, 0, 0.04, 0)
	Title.BackgroundTransparency = 1
	Title.Text = "kaitunv4"
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextScaled = true
	Title.Font = Enum.Font.Arcade
	Title.Parent = Frame
	local Icon = Instance.new("ImageLabel")
	Icon.Size = UDim2.new(0, 130, 0, 130)
	Icon.Position = UDim2.new(0.5, -65, 0.11, 0)
	Icon.BackgroundTransparency = 1
	Icon.Image = "rbxassetid://"
	Icon.Parent = Frame
	local PlayerInfo = Instance.new("TextLabel")
	PlayerInfo.Size = UDim2.new(1, 0, 0.045, 0)
	PlayerInfo.Position = UDim2.new(0, 0, 0.43, 0)
	PlayerInfo.BackgroundTransparency = 1
	PlayerInfo.Text = "Player: Loading..."
	PlayerInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
	PlayerInfo.TextScaled = true
	PlayerInfo.Font = Enum.Font.Arcade
	PlayerInfo.Parent = Frame
	local FragmentInfo = Instance.new("TextLabel")
	FragmentInfo.Size = UDim2.new(1, 0, 0.045, 0)
	FragmentInfo.Position = UDim2.new(0, 0, 0.48, 0)
	FragmentInfo.BackgroundTransparency = 1
	FragmentInfo.Text = "Fragments: 0"
	FragmentInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
	FragmentInfo.TextScaled = true
	FragmentInfo.Font = Enum.Font.Arcade
	FragmentInfo.Parent = Frame
	local V4Info = Instance.new("TextLabel")
	V4Info.Size = UDim2.new(0.94, 0, 0.055, 0)
	V4Info.Position = UDim2.new(0.03, 0, 0.53, 0)
	V4Info.BackgroundTransparency = 1
	V4Info.Text = "V4: Checking..."
	V4Info.TextColor3 = Color3.fromRGB(255, 220, 90)
	V4Info.TextScaled = true
	V4Info.TextWrapped = true
	V4Info.Font = Enum.Font.Arcade
	V4Info.Parent = Frame
	local Status = Instance.new("TextLabel")
	Status.Size = UDim2.new(0.94, 0, 0.065, 0)
	Status.Position = UDim2.new(0.03, 0, 0.595, 0)
	Status.BackgroundTransparency = 1
	Status.Text = "Status: Loading..."
	Status.TextColor3 = Color3.fromRGB(255, 255, 255)
	Status.TextScaled = true
	Status.TextWrapped = true
	Status.Font = Enum.Font.Arcade
	Status.Parent = Frame
	local SubStatus = Instance.new("TextLabel")
	SubStatus.Size = UDim2.new(0.94, 0, 0.055, 0)
	SubStatus.Position = UDim2.new(0.03, 0, 0.670, 0)
	SubStatus.BackgroundTransparency = 1
	SubStatus.Text = "Sub: Loading..."
	SubStatus.TextColor3 = Color3.fromRGB(150, 215, 255)
	SubStatus.TextScaled = true
	SubStatus.TextWrapped = true
	SubStatus.Font = Enum.Font.Arcade
	SubStatus.Parent = Frame
	local JobIdBox = Instance.new("TextBox")
	JobIdBox.Size = UDim2.new(0.46, 0, 0.055, 0)
	JobIdBox.Position = UDim2.new(0.27, 0, 0.745, 0)
	JobIdBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	JobIdBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	JobIdBox.PlaceholderText = "Input Job ID"
	JobIdBox.PlaceholderColor3 = Color3.fromRGB(170, 170, 170)
	JobIdBox.Text = ""
	JobIdBox.Font = Enum.Font.Arcade
	JobIdBox.TextScaled = true
	JobIdBox.ClearTextOnFocus = false
	JobIdBox.Parent = Frame
	local JoinButton = Instance.new("TextButton")
	JoinButton.Size = UDim2.new(0.24, 0, 0.055, 0)
	JoinButton.Position = UDim2.new(0.38, 0, 0.820, 0)
	JoinButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
	JoinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	JoinButton.Text = "Join Job ID"
	JoinButton.Font = Enum.Font.Arcade
	JoinButton.TextScaled = true
	JoinButton.Parent = Frame
	return ScreenGui, Status, SubStatus, JobIdBox, JoinButton, PlayerInfo, FragmentInfo, V4Info
end

print("[v4] creating UI")
local UI, StatusLabel, SubStatusLabel, JobIdBox, JoinButton, PlayerInfoLabel, FragmentInfoLabel, V4InfoLabel = createUI()
print("[v4] UI created - script fully loaded")

function status(text, sub)
	currentTaskStatus = tostring(text or "idle")
	if sub ~= nil then
		currentSubTask = tostring(sub)
	end
	if StatusLabel then
		StatusLabel.Text = "Status: " .. currentTaskStatus
	end
	if SubStatusLabel and sub ~= nil then
		SubStatusLabel.Text = "Sub: " .. currentSubTask
	end
end

function substatus(text)
	currentSubTask = tostring(text or "idle")
	if SubStatusLabel then
		SubStatusLabel.Text = "Sub: " .. currentSubTask
	end
end

status("idle", "ready")

function formatNumber(value)
	local text = tostring(math.floor(tonumber(value) or 0))
	while true do
		local replaced, count = text:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		text = replaced
		if count == 0 then
			break
		end
	end
	return text
end

function formatV4Info(v4State)
	v4State = v4State or {
		label = "UNKNOWN",
		energy = 0,
		transformed = false
	}
	local energyPercent = math.floor(math.clamp(tonumber(v4State.energy) or 0, 0, 1) * 100 + 0.5)
	local transformText = v4State.transformed and "ON" or "OFF"
	local detail = ""
	if v4State.needsPurchase then
		detail = " | Cost: " .. formatNumber(v4State.cost) .. " F"
	elseif v4State.code == 6 then
		detail = " | Sessions: " .. tostring(v4State.completedTraining or 0) .. "/3"
	elseif v4State.code == 8 then
		detail = " | Remaining: " .. tostring(v4State.remainingTraining or 0)
	elseif v4State.canTrial and v4State.gear ~= nil then
		detail = " | Gear: " .. tostring(v4State.gear)
	elseif v4State.code ~= nil then
		detail = " | State: " .. tostring(v4State.code)
	elseif v4State.progress ~= nil then
		detail = " | Quest: " .. tostring(v4State.progress)
	end
	return "V4: " .. tostring(v4State.label or "UNKNOWN")
        .. detail
        .. " | Energy: " .. tostring(energyPercent) .. "%"
        .. " | Transform: " .. transformText
end

function getV4StatusColor(v4State)
	if v4State and v4State.complete then
		return Color3.fromRGB(90, 220, 255)
	end
	if v4State and v4State.canTrial then
		return Color3.fromRGB(90, 255, 130)
	end
	if v4State and v4State.needsPurchase then
		return Color3.fromRGB(255, 170, 70)
	end
	if v4State and v4State.needsTraining then
		return Color3.fromRGB(255, 220, 90)
	end
	return Color3.fromRGB(255, 255, 255)
end

task.spawn(function()
	while task.wait(1) do
		local fragments = 0
		local race = "Unknown"
		pcall(function()
			fragments = Players.LocalPlayer.Data.Fragments.Value
			race = Players.LocalPlayer.Data.Race.Value
		end)
		local roleText = isUper and "MAIN" or (isAlly and "HELP" or "NONE")
		local pairText = matchState and matchState.assigned and "PAIRED" or "WAITING"
		local fmInfo = getFullMoonTimeRemaining()
		local v4State = getV4Status(false)
		if PlayerInfoLabel then
			PlayerInfoLabel.Text = "Player: " .. USERNAME .. " | Role: " .. roleText .. " | Race: " .. tostring(race)
		end
		if FragmentInfoLabel then
			FragmentInfoLabel.Text = "Fragments: " .. formatNumber(fragments) .. " | Pair: " .. pairText .. " | " .. fmInfo.formatted
		end
		if V4InfoLabel then
			V4InfoLabel.Text = formatV4Info(v4State)
			V4InfoLabel.TextColor3 = getV4StatusColor(v4State)
		end
		if StatusLabel then
			StatusLabel.Text = "Status: " .. currentTaskStatus
		end
		if SubStatusLabel then
			SubStatusLabel.Text = "Sub: " .. currentSubTask
		end
	end
end)

JoinButton.MouseButton1Click:Connect(function()
	local raw = JobIdBox.Text:gsub("%s+", "")
	if raw == "" then
		status("Input empty");
		return
	end
	status("Joining...")
	local ok = pcall(function()
		(ReplicatedStorage:FindFirstChild("__ServerBrowser") or ReplicatedStorage:WaitForChild("__ServerBrowser", 5)):InvokeServer("teleport", raw)
	end)
	if not ok then
		status("Join failed")
	else
		status("Teleporting...")
	end
end)

-- ============================================================
-- FULL MOON API + CENTRAL HUB COORDINATOR
-- Keep this block after the V4/trial helpers so background tasks can safely
-- inspect the current farming state before accepting a teleport.
-- ============================================================
task.spawn(function()
	local coordinatorConfig = getgenv().Config or {}
	local fullMoonApiUrl = tostring(coordinatorConfig["Full Moon API URL"] or "https://vortexz-hub.xyz/fullmoon")
	local fullMoonPollInterval = math.max(10, tonumber(coordinatorConfig["Full Moon Poll Interval"]) or 15)
	local fullMoonCycleSeconds = math.max(600, tonumber(coordinatorConfig["Full Moon Cycle Seconds"]) or 600)
	local minimumFullMoonSeconds = math.max(120, tonumber(coordinatorConfig["Full Moon Minimum Remaining"]) or 120)
	local fullMoonMaxPlayers = math.max(1, tonumber(coordinatorConfig["Full Moon Max Players"]) or 8)
	local centralHubUrl = tostring(coordinatorConfig["Central Hub WebSocket"] or "ws://HOANGLAM_ISGAY:20425")
	local heartbeatInterval = math.max(1, tonumber(coordinatorConfig["Central Hub Heartbeat Interval"]) or 3)
	local localToolEnabled = coordinatorConfig["Local Tool Enabled"] ~= false
	local localToolUrl = tostring(coordinatorConfig["Local Tool WebSocket"] or "ws://127.0.0.1:20425/client")
	local localHeartbeatInterval = math.max(0.5, tonumber(coordinatorConfig["Local Tool Heartbeat Interval"]) or 1)
	local requestFunc = http_request or (http and http.request) or request or (syn and syn.request)

	local oldCoordinator = getgenv().__KAITUN_V4_COORDINATOR
	if oldCoordinator and oldCoordinator.socket then
		pcall(function()
			local close = oldCoordinator.socket.Close or oldCoordinator.socket.close
			if close then
				close(oldCoordinator.socket)
			end
		end)
	end
	if oldCoordinator and oldCoordinator.localSocket then
		pcall(function()
			local close = oldCoordinator.localSocket.Close or oldCoordinator.localSocket.close
			if close then
				close(oldCoordinator.localSocket)
			end
		end)
	end
	if oldCoordinator and oldCoordinator.teleportFailureConnection then
		pcall(function()
			oldCoordinator.teleportFailureConnection:Disconnect()
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
		nextLocalConnectTick = 0,
		localConnectBackoff = 2,
		lastHopReason = "starting"
	}
	getgenv().__KAITUN_V4_COORDINATOR = coordinator

	local function isCoordinatorActive()
		return getgenv().__KAITUN_V4_COORDINATOR == coordinator
	end

	local function inTrial()
		local ok, result = pcall(isInsideOwnTrial)
		return ok and result == true
	end

	local function canInterruptForTeleport()
		return not isCurrentlyTraining and not postTrialTransitionInProgress and not inTrial()
	end

	local function canAcceptHubTeleport()
		if not canInterruptForTeleport() then
			return false
		end
		if HelpWhitelist[LocalPlayer.Name] == true then
			return true
		end
		local v4State = getV4Status(false)
		return v4State ~= nil
			and v4State.canTrial == true
			and v4State.needsTraining ~= true
			and v4State.needsPurchase ~= true
			and v4State.complete ~= true
	end

	local function teleportToJob(targetPlaceId, targetJobId, source, force)
		targetPlaceId = readPlaceId(targetPlaceId, game.PlaceId)
		targetJobId = tostring(targetJobId or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if not targetPlaceId or targetJobId == "" or targetJobId == getCurrentJobId() then
			coordinator.lastHopReason = "invalid_or_current_job"
			return false
		end
		local now = tick()
		if now < coordinator.nextTeleportTick or now - coordinator.lastTeleportTick < 12 then
			coordinator.lastHopReason = "teleport_cooldown"
			return false
		end
		if (coordinator.failedJobs[targetJobId] or 0) > now then
			coordinator.lastHopReason = "job_quarantined"
			return false
		end
		if not force and not canInterruptForTeleport() then
			coordinator.lastHopReason = "training_or_trial_busy"
			return false
		end

		coordinator.lastTeleportTick = now
		coordinator.nextTeleportTick = now + 12
		coordinator.pendingJobId = targetJobId
		coordinator.lastHopReason = "teleporting_" .. tostring(source)
		status("Teleporting via " .. tostring(source) .. "...")
		local ok = pcall(function()
			if targetPlaceId == tonumber(game.PlaceId) then
				-- Th  __ServerBrowser tr c (trong c ng PlaceId), fallback sang TeleportService n u fail
				local sbOk = pcall(function()
					(ReplicatedStorage:FindFirstChild("__ServerBrowser") or ReplicatedStorage:WaitForChild("__ServerBrowser", 5)):InvokeServer("teleport", targetJobId)
				end)
				if not sbOk then
					-- Fallback: d ng TeleportService tr c ti p
					TeleportService:TeleportToPlaceInstance(targetPlaceId, targetJobId, LocalPlayer)
				end
			else
				TeleportService:TeleportToPlaceInstance(targetPlaceId, targetJobId, LocalPlayer)
			end
		end)
		if not ok then
			coordinator.failedJobs[targetJobId] = now + 60  -- Giảm từ 120s → 60s để retry nhanh hơn
			coordinator.nextTeleportTick = now + 20
			coordinator.pendingJobId = nil
			coordinator.lastHopReason = "teleport_call_failed"
		end
		return ok
	end

	local teleportFailureConnection = TeleportService.TeleportInitFailed:Connect(function(playerWhoFailed)
		if playerWhoFailed ~= LocalPlayer or not isCoordinatorActive() then
			return
		end
		local now = tick()
		if coordinator.pendingJobId then
			coordinator.failedJobs[coordinator.pendingJobId] = now + 60  -- Giảm từ 120s → 60s
		end
		coordinator.pendingJobId = nil
		coordinator.nextTeleportTick = now + 20  -- Giảm từ 30s → 20s
		coordinator.lastHopReason = "teleport_init_failed"
		status("Teleport failed (Error 773?) - retrying another server in 20s")
	end)
	coordinator.teleportFailureConnection = teleportFailureConnection

	local function getServerList(decoded)
		if type(decoded) ~= "table" then
			return nil
		end
		if #decoded > 0 then
			return decoded
		end
		if type(decoded.data) == "table" then
			return decoded.data
		end
		if type(decoded.servers) == "table" then
			return decoded.servers
		end
		return nil
	end

	local function parseTimeOfDay(value)
		local hour, minute, second = tostring(value or ""):match("^(%d%d?):(%d%d):(%d%d)")
		hour, minute, second = tonumber(hour), tonumber(minute), tonumber(second)
		if not hour or not minute or not second or hour > 23 or minute > 59 or second > 59 then
			return nil
		end
		return hour + minute / 60 + second / 3600
	end

	local function getVerifiedClockTime(serverInfo)
		local clockTime = tonumber(serverInfo.ClockTime or serverInfo.clockTime)
		local parsedTime = parseTimeOfDay(serverInfo.TimeOfDay or serverInfo.timeOfDay)
		if not clockTime then
			return parsedTime
		end
		if parsedTime then
			local difference = math.abs(clockTime - parsedTime)
			difference = math.min(difference, 24 - difference)
			if difference > 0.1 then
				return nil
			end
		end
		return clockTime % 24
	end

	local function getFullMoonSecondsRemaining(serverInfo)
		local clockTime = getVerifiedClockTime(serverInfo)
		if not clockTime or (clockTime >= 5 and clockTime < 18) then
			return 0
		end
		local hoursRemaining = clockTime >= 18 and (24 - clockTime + 5) or (5 - clockTime)
		local reportAge = math.max(0, tonumber(serverInfo.AgeSeconds or serverInfo.ageSeconds) or 0)
		return hoursRemaining * (fullMoonCycleSeconds / 24) - reportAge
	end

	local function currentServerHasFullMoon()
		local clockTime = tonumber(game.Lighting.ClockTime) or 12
		return isfullmoon() and (clockTime >= 18 or clockTime < 5)
	end

	local function hopToFullMoonServer()
		if coordinator.requestInFlight
			or tick() - coordinator.startedAt < 15
			or currentServerHasFullMoon()
			or not canInterruptForTeleport()
		then
			coordinator.lastHopReason = currentServerHasFullMoon() and "current_server_full_moon" or "hop_gate_blocked"
			return false
		end

		coordinator.requestInFlight = true
		local ok, response = pcall(function()
			if requestFunc then
				return requestFunc({
					Url = fullMoonApiUrl,
					Method = "GET",
					Timeout = 5,
					Headers = { ["Accept"] = "application/json" }
				})
			end
			return game:HttpGet(fullMoonApiUrl, true)
		end)
		coordinator.requestInFlight = false
		if not ok or not response then
			coordinator.lastHopReason = "api_request_failed"
			return false
		end

		local body = type(response) == "string" and response or response.Body or response.body
		local decodeOk, decoded = pcall(function()
			return HttpService:JSONDecode(body)
		end)
		local servers = decodeOk and getServerList(decoded) or nil
		if not servers then
			coordinator.lastHopReason = "api_decode_or_schema_failed"
			return false
		end
		if type(decoded) == "table" then
			local generatedAt = tonumber(decoded.generated_at)
			local freshFor = math.max(1, tonumber(decoded.fresh_for) or 180)
			local nowUnix = DateTime.now().UnixTimestamp
			if generatedAt and math.abs(nowUnix - generatedAt) > freshFor then
				coordinator.lastHopReason = "api_stale"
				return false
			end
		end
		if currentServerHasFullMoon() then
			coordinator.lastHopReason = "current_server_full_moon"
			return false
		end

		local candidates = {}
		for serverKey, serverInfo in pairs(servers) do
			if type(serverInfo) == "table" then
				local targetJobId = readJobId(serverInfo, type(serverKey) == "string" and serverKey or nil)
				local targetPlaceId = tonumber(serverInfo.PlaceId or serverInfo.PlaceID or serverInfo.placeId or serverInfo.placeid)
				local playerCount = tonumber(serverInfo.Players or serverInfo.PlayerCount or serverInfo.playerCount or serverInfo.players or serverInfo.Count or serverInfo.count) or math.huge
				local secondsRemaining = getFullMoonSecondsRemaining({
					ClockTime = serverInfo.ClockTime,
					TimeOfDay = serverInfo.TimeOfDay,
					-- AgeSeconds is the API response age; ServerAge is the Roblox
					-- server lifetime and must not be subtracted from moon time.
					AgeSeconds = serverInfo.AgeSeconds or serverInfo.ageSeconds or 0
				})
				if serverInfo.Online ~= false
					and serverInfo.FullMoon == true
					and serverInfo.FullMoonActive == true
					and serverInfo.IsFull == false
					and tonumber(serverInfo.Sea or serverInfo.sea) == 3
					and playerCount <= fullMoonMaxPlayers
					and secondsRemaining > minimumFullMoonSeconds
					and targetJobId ~= getCurrentJobId()
					and targetPlaceId ~= nil
					and (coordinator.failedJobs[targetJobId] or 0) <= tick()
				then
					table.insert(candidates, {
						jobId = targetJobId,
						placeId = targetPlaceId,
						players = playerCount,
						secondsRemaining = secondsRemaining
					})
				end
			end
		end
		table.sort(candidates, function(a, b)
			if a.secondsRemaining == b.secondsRemaining then
				return a.players < b.players
			end
			return a.secondsRemaining > b.secondsRemaining
		end)
		if candidates[1] then
			coordinator.lastHopReason = "candidate_found"
			return teleportToJob(candidates[1].placeId, candidates[1].jobId, "Full Moon API", false)
		end
		coordinator.lastHopReason = "no_eligible_candidate"
		return false
	end

	local function getConfiguredHubRole()
		if HelpWhitelist[LocalPlayer.Name] == true then
			return "helper"
		end
		return "main"
	end

	local function getHubStatus(role, v4State)
		if inTrial() then
			return "IN_TRIAL"
		end
		local assignment = getgenv().__KAITUN_HUB_ASSIGNMENT
		if type(assignment) == "table"
			and tick() - (tonumber(assignment.receivedAt) or 0) < 900
		then
			return "MATCHED"
		end
		if role == "helper" then
			if isCurrentlyTraining then return "TRAINING" end
			local abilityName = race_abilities[canonicalRaceName(getLocalRaceName())]
			return abilityName and checkbackpack(abilityName) ~= nil and "IDLE" or "BUSY"
		end
		if role ~= "main" or not v4State then
			return "BUSY"
		end
		if v4State.complete == true then
			return "MAX_V4"
		end
		if isCurrentlyTraining or v4State.needsTraining == true then
			return "TRAINING"
		end
		if v4State.canTrial == true
			and v4State.needsPurchase ~= true
			and v4State.needsGearClaim ~= true
		then
			return currentServerHasFullMoon() and "WAITING_V4" or "SEARCHING_FULL_MOON"
		end
		if v4State.progress ~= nil or v4State.needsPurchase == true then
			return "QUESTING"
		end
		return "BUSY"
	end

	local function applyHubAssignment(message)
		local payload = type(message.payload) == "table" and message.payload or {}
		local rawMembers = type(payload.members) == "table" and payload.members or {}
		local memberNames = {}
		local includesLocalPlayer = false
		for _, member in ipairs(rawMembers) do
			local memberName = type(member) == "table" and member.name or member
			memberName = tostring(memberName or "")
			if memberName ~= "" then
				table.insert(memberNames, memberName)
				if memberName == LocalPlayer.Name then
					includesLocalPlayer = true
				end
			end
		end
		local leader = tostring(payload.leader or "")
		local groupId = tostring(payload.groupId or "")
		local targetJobId = readJobId(message.targetJobId or payload.targetJobId)
		local targetPlaceId = readPlaceId(message.targetPlaceId or payload.targetPlaceId)
		targetJobId = targetJobId or ""
		if not includesLocalPlayer or #memberNames ~= 3 or leader == "" or groupId == ""
			or targetJobId == "" or not targetPlaceId
		then
			return false
		end

		local previousGroupId = currentGroupId()
		getgenv().__KAITUN_HUB_ASSIGNMENT = {
			groupId = groupId,
			leader = leader,
			members = memberNames,
			mode = tostring(payload.mode or ""),
			targetJobId = targetJobId,
			targetPlaceId = targetPlaceId,
			receivedAt = tick()
		}
		local partners = {}
		for _, memberName in ipairs(memberNames) do
			if memberName ~= leader then
				table.insert(partners, memberName)
			end
		end
		matchState.assigned = true
		matchState.group_id = groupId
		matchState.main_username = leader
		matchState.main_job_id = targetJobId
		matchState.helpers = partners
		matchState.all_in_job = targetJobId == getCurrentJobId()
		mainJobId = targetJobId
		if previousGroupId ~= groupId then
			pairAssignedAt = tick()
			pairTempleReadyAt = 0
			lastTempleReadyCount = 0
			lastTempleForceAt = 0
			lastTempleProgressAt = 0
			lastTempleDistance = math.huge
			readySent = false
		end
		lastPairGroupId = groupId
		pairAllInJobAt = matchState.all_in_job and tick() or 0
		if getgenv().UpdateRoles then
			pcall(getgenv().UpdateRoles)
		end
		if matchState.all_in_job then
			scheduleMatchedTempleMove(groupId)
		end
		return true
	end

	local function sendHubSocketMessage(socket, message)
		if not socket or type(message) ~= "table" then return false end
		return pcall(function()
			local send = socket.Send or socket.send
			assert(type(send) == "function", "WebSocket send method is unavailable")
			send(socket, HttpService:JSONEncode(message))
		end)
	end

	local function clearHubAssignment(groupId, reason)
		local assignment = getgenv().__KAITUN_HUB_ASSIGNMENT
		if type(assignment) ~= "table" or tostring(assignment.groupId or "") ~= tostring(groupId or "") then
			return false
		end
		getgenv().__KAITUN_HUB_ASSIGNMENT = nil
		templeMoveGeneration = templeMoveGeneration + 1
		matchState.assigned = false
		matchState.group_id = ""
		matchState.main_username = ""
		matchState.main_job_id = game.JobId
		matchState.helpers = {}
		matchState.all_in_job = false
		mainJobId = game.JobId
		coordinator.lastHopReason = "hub_cancelled_" .. tostring(reason or "unknown")
		if getgenv().UpdateRoles then
			pcall(getgenv().UpdateRoles)
		end
		return true
	end

	local function getWebSocketConnect()
		if WebSocket and type(WebSocket.connect) == "function" then
			return WebSocket.connect
		end
		if websocket and type(websocket.connect) == "function" then
			return websocket.connect
		end
		if syn and syn.websocket and type(syn.websocket.connect) == "function" then
			return syn.websocket.connect
		end
		return nil
	end

	local function bindSocketEvent(socket, eventName, callback)
		local event = socket[eventName]
		if event and type(event.Connect) == "function" then
			event:Connect(callback)
			return true
		end
		return false
	end

	local function handleHubMessage(rawMessage, sourceSocket)
		if type(rawMessage) == "table" then
			rawMessage = rawMessage.Data or rawMessage.data
		end
		if type(rawMessage) ~= "string" then
			return
		end

		local ok, message = pcall(function()
			return HttpService:JSONDecode(rawMessage)
		end)
		if not ok or type(message) ~= "table" then
			return
		end
		if message.type == "V3_COMMAND" then
			if V3_WS_SYNC then handleV3CommandMessage(message) end
			return
		end
		if message.type == "CANCEL_ASSIGNMENT" then
			clearHubAssignment(message.groupId or message.group_id, message.reason)
			return
		end
		if message.type ~= "TELEPORT_JOB" then return end
		if not canAcceptHubTeleport() then
			coordinator.lastHopReason = "ignored_stale_hub_assignment"
			return
		end

		local targetJobId = readJobId(message.targetJobId)
		local targetPlaceId = readPlaceId(message.targetPlaceId)
		if not targetJobId and type(message.payload) == "table" then
			targetJobId = readJobId(message.payload.targetJobId)
		end
		if not targetPlaceId and type(message.payload) == "table" then
			targetPlaceId = readPlaceId(message.payload.targetPlaceId)
		end
		if applyHubAssignment(message) then
			local payload = type(message.payload) == "table" and message.payload or {}
			sendHubSocketMessage(sourceSocket or coordinator.socket, {
				type = "ASSIGNMENT_ACK",
				sender = LocalPlayer.Name,
				groupId = tostring(payload.groupId or "")
			})
			teleportToJob(targetPlaceId, targetJobId, "Central Hub", false)
		end
	end

	local function closeSocket(socket)
		if not socket then
			return
		end
		pcall(function()
			local close = socket.Close or socket.close
			if close then
				close(socket)
			end
		end)
	end

	local function connectCentralHub()
		local connect = getWebSocketConnect()
		if not connect
			or getConfiguredHubRole() == ""
			or centralHubUrl:find("HOANGLAM_ISGAY", 1, true)
		then
			return nil
		end
		local ok, socket = pcall(connect, centralHubUrl)
		if not ok or not socket then
			coordinator.nextCentralConnectTick = tick() + coordinator.centralConnectBackoff
			coordinator.centralConnectBackoff = math.min(coordinator.centralConnectBackoff * 2, 30)
			return nil
		end
		coordinator.centralConnectBackoff = 3
		coordinator.nextCentralConnectTick = 0

		bindSocketEvent(socket, "OnMessage", function(message)
			handleHubMessage(message, socket)
		end)
		bindSocketEvent(socket, "OnClose", function()
			if coordinator.socket == socket then
				coordinator.socket = nil
				coordinator.nextCentralConnectTick = tick() + coordinator.centralConnectBackoff
			end
		end)
		return socket
	end

	local function connectLocalTool()
		local connect = getWebSocketConnect()
		if not localToolEnabled or not connect or localToolUrl == "" then
			return nil
		end
		local ok, socket = pcall(connect, localToolUrl)
		if not ok or not socket then
			coordinator.nextLocalConnectTick = tick() + coordinator.localConnectBackoff
			coordinator.localConnectBackoff = math.min(coordinator.localConnectBackoff * 2, 30)
			return nil
		end
		coordinator.localConnectBackoff = 2
		coordinator.nextLocalConnectTick = 0
		bindSocketEvent(socket, "OnClose", function()
			if coordinator.localSocket == socket then
				coordinator.localSocket = nil
				coordinator.nextLocalConnectTick = tick() + coordinator.localConnectBackoff
			end
		end)
		return socket
	end

	local function getFragmentCount()
		local ok, value = pcall(function()
			return LocalPlayer.Data.Fragments.Value
		end)
		return ok and (tonumber(value) or 0) or 0
	end

	task.spawn(function()
		while isCoordinatorActive() do
			if not coordinator.socket and tick() >= coordinator.nextCentralConnectTick then
				coordinator.socket = connectCentralHub()
			end

			local socket = coordinator.socket
			if socket then
				local role = getConfiguredHubRole()
				local v4State = getV4Status(false)
				local hubStatus = getHubStatus(role, v4State)
				local v3Fields = getV3HeartbeatFields()
				local fmInfo = getFullMoonTimeRemaining()
				local heartbeat = {
					type = "HEARTBEAT",
					sender = LocalPlayer.Name,
					payload = {
						race = getLocalRaceName(),
						role = role,
						status = hubStatus,
						hopReason = coordinator.lastHopReason,
						v3Ready = v3Fields.v3Ready,
						v3Race = v3Fields.v3Race,
						v3DoorDistance = v3Fields.v3DoorDistance,
						v3GroupId = v3Fields.v3GroupId,
						v3AbilityReady = v3Fields.v3AbilityReady,
						fullMoon = fmInfo.isActive,
						fullMoonActive = fmInfo.isActive,
						fullMoonRemaining = fmInfo.secondsRemaining,
						fullMoonText = fmInfo.shortFormatted,
						task = tostring(currentTaskStatus or ""),
						subTask = tostring(currentSubTask or "")
					},
					jobId = getCurrentJobId(),
					placeId = game.PlaceId
				}
				local sent = pcall(function()
					local send = socket.Send or socket.send
					assert(type(send) == "function", "WebSocket send method is unavailable")
					send(socket, HttpService:JSONEncode(heartbeat))
				end)
				if not sent then
					closeSocket(socket)
					coordinator.socket = nil
					coordinator.nextCentralConnectTick = tick() + coordinator.centralConnectBackoff
				end
			end
			task.wait(heartbeatInterval)
		end
	end)

	task.spawn(function()
		while isCoordinatorActive() do
			if not coordinator.localSocket and tick() >= coordinator.nextLocalConnectTick then
				coordinator.localSocket = connectLocalTool()
			end

			local socket = coordinator.localSocket
			if socket then
				local role = getConfiguredHubRole()
				local v4State = getV4Status(false)
				local fmInfo = getFullMoonTimeRemaining()
				local heartbeat = {
					type = "LOCAL_HEARTBEAT",
					sender = LocalPlayer.Name,
					sentAt = DateTime.now().UnixTimestampMillis,
					payload = {
						race = getLocalRaceName(),
						role = role ~= "" and role or "unknown",
						status = getHubStatus(role, v4State),
						moon = fmInfo.isActive,
						moonRemaining = fmInfo.secondsRemaining,
						moonText = fmInfo.shortFormatted,
						canTrial = v4State.canTrial == true,
						complete = v4State.complete == true,
						fragments = getFragmentCount(),
						task = tostring(currentTaskStatus or ""),
						subTask = tostring(currentSubTask or ""),
						hopReason = coordinator.lastHopReason,
						players = #Players:GetPlayers()
					},
					jobId = getCurrentJobId(),
					placeId = game.PlaceId
				}
				local sent = pcall(function()
					local send = socket.Send or socket.send
					assert(type(send) == "function", "Local Tool WebSocket send method is unavailable")
					send(socket, HttpService:JSONEncode(heartbeat))
				end)
				if not sent then
					closeSocket(socket)
					coordinator.localSocket = nil
					coordinator.nextLocalConnectTick = tick() + coordinator.localConnectBackoff
				end
			end
			task.wait(localHeartbeatInterval)
		end
	end)

	task.spawn(function()
		while isCoordinatorActive() do
			local v4State = getV4Status(false)
			local role = getConfiguredHubRole()
			local hubStatus = getHubStatus(role, v4State)
			if coordinator.socket ~= nil
				and role == "main"
				and hubStatus == "SEARCHING_FULL_MOON"
				and v4State.canTrial == true
				and v4State.complete ~= true
				and not currentServerHasFullMoon()
				and canInterruptForTeleport()
			then
				hopToFullMoonServer()
			end
			task.wait(fullMoonPollInterval)
		end
	end)
end)
