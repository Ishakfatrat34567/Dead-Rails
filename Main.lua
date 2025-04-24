local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("IshkebHub", "BloodTheme")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local CachedNPCs = {}
local DrawingBoxes = {}

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
local RANGE = 400

local function createBox()
	return {
		Top = Drawing.new("Line"),
		Bottom = Drawing.new("Line"),
		Left = Drawing.new("Line"),
		Right = Drawing.new("Line")
	}
end

local function refreshNPCList()
	local camPos = Camera.CFrame.Position
	CachedNPCs = {}
	for _, npc in pairs(workspace:GetDescendants()) do
		if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("Head") and not Players:GetPlayerFromCharacter(npc) then
			local hrp = npc:FindFirstChild("HumanoidRootPart")
			if hrp and (hrp.Position - camPos).Magnitude <= RANGE then
				table.insert(CachedNPCs, npc)
			end
		end
	end
end

local function getClosestAliveNPC()
	local closest, dist = nil, math.huge
	local camPos = Camera.CFrame.Position
	for _, npc in pairs(CachedNPCs) do
		local hum = npc:FindFirstChild("Humanoid")
		if hum and hum.Health > 0 and hum.Parent ~= nil then
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

local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Visuals & Aimbot")

MainSection:NewToggle("NPC ESP", "Outlines NPCs", function(state)
	_G.NPCESP = state
	if not state then
		for _, box in pairs(DrawingBoxes) do
			for _, line in pairs(box) do
				line:Remove()
			end
		end
		table.clear(DrawingBoxes)
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

task.spawn(function()
	while true do
		refreshNPCList()
		task.wait(1.5)
	end
end)

RunService.Heartbeat:Connect(function()
	local camPos = Camera.CFrame.Position
	local screenSize = Camera.ViewportSize

	if _G.NPCAimbot then
		FOVCircle.Position = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
		FOVCircle.Radius = _G.AimbotFOV
	end

	if _G.NPCESP then
		for _, npc in pairs(CachedNPCs) do
			local hum = npc:FindFirstChild("Humanoid")
			local hrp = npc:FindFirstChild("HumanoidRootPart")
			if hum and hum.Health > 0 and hrp and (hrp.Position - camPos).Magnitude <= RANGE then
				local pos, vis = Camera:WorldToViewportPoint(hrp.Position)
				if vis then
					if not DrawingBoxes[npc] then
						DrawingBoxes[npc] = createBox()
					end

					local size = Vector3.new(2, 3, 1.5)
					local box = DrawingBoxes[npc]
					local c1 = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(-size.X, size.Y, 0))
					local c2 = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(size.X, size.Y, 0))
					local c3 = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(-size.X, -size.Y, 0))
					local c4 = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(size.X, -size.Y, 0))

					box.Top.From = Vector2.new(c1.X, c1.Y)
					box.Top.To = Vector2.new(c2.X, c2.Y)
					box.Bottom.From = Vector2.new(c3.X, c3.Y)
					box.Bottom.To = Vector2.new(c4.X, c4.Y)
					box.Left.From = Vector2.new(c1.X, c1.Y)
					box.Left.To = Vector2.new(c3.X, c3.Y)
					box.Right.From = Vector2.new(c2.X, c2.Y)
					box.Right.To = Vector2.new(c4.X, c4.Y)

					for _, line in pairs(box) do
						line.Visible = true
						line.Color = Color3.fromRGB(255, 0, 0)
						line.Thickness = 1.5
					end
				end
			elseif DrawingBoxes[npc] then
				for _, line in pairs(DrawingBoxes[npc]) do
					line.Visible = false
				end
			end
		end
	end
end)

RunService.Heartbeat:Connect(function()
	if _G.NPCAimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		local npc = getClosestAliveNPC()
		if npc and npc:FindFirstChild("Head") then
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, npc.Head.Position)
		end
	end
end)
game.StarterGui:SetCore("SendNotification", {Title = "IshkebHub", Text = "Script Loaded Successfully!", Duration = 5})
game.StarterGui:SetCore("SendNotification", {Title = "Heads up!", Text = "Heads up! if you want to use autobond move the menu to the side", Duration = 15})
