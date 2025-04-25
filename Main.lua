local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("IshkebHub", "BloodTheme")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local CachedNPCs = {}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 0, 0)
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Transparency = 0.6
FOVCircle.NumSides = 100
FOVCircle.Visible = false
FOVCircle.Radius = 200

_G.NPCESP = false
_G.NPCAimbot = false
_G.AimbotFOV = 200
local RANGE = 200 -- Lowered range to reduce load

-- 👁️ Refresh NPC List
local function refreshNPCList()
	local camPos = Camera.CFrame.Position
	CachedNPCs = {}
	for _, npc in pairs(workspace:GetDescendants()) do
		if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("Head") and not Players:GetPlayerFromCharacter(npc) then
			local hrp = npc:FindFirstChild("HumanoidRootPart")
			if hrp and (hrp.Position - camPos).Magnitude <= RANGE and npc.Humanoid.Health > 0 then
				table.insert(CachedNPCs, npc)
			end
		end
	end
end

-- 🎯 Closest Target
local function getClosestAliveNPC()
	local closest, dist = nil, math.huge
	local camPos = Camera.CFrame.Position
	for _, npc in pairs(CachedNPCs) do
		local hum = npc:FindFirstChild("Humanoid")
		if hum and hum.Health > 0 then
			local head = npc.Head.Position
			if (head - camPos).Magnitude <= RANGE then
				local screenPos, visible = Camera:WorldToViewportPoint(head)
				if visible then
					local mag = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
					if mag < dist and mag <= _G.AimbotFOV then
						closest = npc
						dist = mag
					end
				end
			end
		end
	end
	return closest
end

-- 📦 UI Tabs
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Visuals & Aimbot")

MainSection:NewToggle("NPC ESP", "Highlights NPCs with glow", function(state)
	_G.NPCESP = state
	if not state then
		for _, npc in pairs(CachedNPCs) do
			if npc:FindFirstChild("ESP_Highlight") then
				npc.ESP_Highlight:Destroy()
			end
		end
	end
end)

MainSection:NewToggle("NPC Aimbot", "Locks to NPC on M2", function(state)
	_G.NPCAimbot = state
	FOVCircle.Visible = state
end)

local BondTab = Window:NewTab("AutoBond")
local BondSection = BondTab:NewSection("Execute Script")

BondSection:NewButton("Run AutoBond Script", "Executes Luarmor Loader and hides UI", function()
	for _, gui in pairs(game:GetService("CoreGui"):GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Name:match("Kavo") then
			gui.Enabled = false
		end
	end
	loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/869d818021af0445799bf14959327df4.lua"))()
end)

-- 🔄 Refresh NPC List Loop
task.spawn(function()
	while true do
		refreshNPCList()
		task.wait(3) -- Slower refresh for performance
	end
end)

-- 💡 Highlight ESP (Patched)
local lastESPCheck = 0

RunService.Heartbeat:Connect(function()
	local camPos = Camera.CFrame.Position
	local screenSize = Camera.ViewportSize

	if _G.NPCAimbot then
		FOVCircle.Position = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
		FOVCircle.Radius = _G.AimbotFOV
	end

	-- Highlight ESP
	if _G.NPCESP and tick() - lastESPCheck >= 0.5 then
		lastESPCheck = tick()

		for _, npc in pairs(CachedNPCs) do
			pcall(function()
				local hum = npc:FindFirstChild("Humanoid")
				local head = npc:FindFirstChild("Head")
				if hum and hum.Health > 0 and head then
					if not npc:FindFirstChild("ESP_Highlight") then
						local hl = Instance.new("Highlight")
						hl.Name = "ESP_Highlight"
						hl.Adornee = npc
						hl.FillColor = Color3.fromRGB(255, 0, 0)
						hl.OutlineColor = Color3.fromRGB(255, 255, 255)
						hl.FillTransparency = 0.4
						hl.OutlineTransparency = 0
						hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						hl.Parent = npc
					end
				elseif npc:FindFirstChild("ESP_Highlight") then
					npc.ESP_Highlight:Destroy()
				end
			end)
		end
	end
end)

-- 🎯 Aimbot Locking
RunService.Heartbeat:Connect(function()
	if _G.NPCAimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		local npc = getClosestAliveNPC()
		if npc and npc:FindFirstChild("Head") then
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, npc.Head.Position)
		end
	end
end)

-- ✅ Notifs
game.StarterGui:SetCore("SendNotification", {Title = "IshkebHub", Text = "Script Loaded Successfully!", Duration = 5})
game.StarterGui:SetCore("SendNotification", {Title = "Heads up!", Text = "Heads up! if you want to use autobond move the menu to the side", Duration = 15})
