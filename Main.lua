repeat task.wait() until game:IsLoaded()
task.wait(2)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("IshkebHub", "BloodTheme")

-- Globals
local CachedNPCs = {}
local CurrentLockedTarget = nil
local _G_NPCESP = false
local _G_NPCAimbot = false
local _G_ItemESP = false
local AimbotFOV = 200
local ItemESPDistance = 2000
local AimbotSmoothness = 5

-- FOV Circle
local FOV_UI = Instance.new("ScreenGui")
FOV_UI.Name = "FOV_UI"
FOV_UI.ResetOnSpawn = false
pcall(function() FOV_UI.Parent = game:GetService("CoreGui") end)

local AimbotCircle = Instance.new("Frame")
AimbotCircle.Size = UDim2.new(0, AimbotFOV * 2, 0, AimbotFOV * 2)
AimbotCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
AimbotCircle.AnchorPoint = Vector2.new(0.5, 0.5)
AimbotCircle.BackgroundTransparency = 1
AimbotCircle.Visible = false
AimbotCircle.Parent = FOV_UI

local AimbotStroke = Instance.new("UIStroke", AimbotCircle)
AimbotStroke.Color = Color3.fromRGB(255, 0, 0)
AimbotStroke.Thickness = 2
local AimbotCorner = Instance.new("UICorner", AimbotCircle)
AimbotCorner.CornerRadius = UDim.new(1, 0)

-- UI Tabs
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Visuals & Aimbot")

MainSection:NewToggle("NPC ESP", "Highlight NPCs", function(state)
    _G_NPCESP = state
end)

MainSection:NewToggle("Item ESP", "Highlight Items", function(state)
    _G_ItemESP = state
end)

MainSection:NewToggle("NPC Aimbot", "Lock onto NPCs (Right Mouse)", function(state)
    _G_NPCAimbot = state
    AimbotCircle.Visible = state
end)

MainSection:NewSlider("Aimbot FOV", "Adjust Aimbot Circle Size", 600, 50, function(value)
    AimbotFOV = value
    AimbotCircle.Size = UDim2.new(0, value * 2, 0, value * 2)
end)

-- AutoBond Tab
local BondTab = Window:NewTab("AutoBond")
local BondSection = BondTab:NewSection("Script")

BondSection:NewButton("Run AutoBond Script", "Executes Luarmor Loader", function()
    for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name:match("Kavo") then
            gui.Enabled = false
        end
    end
    loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/869d818021af0445799bf14959327df4.lua"))()
end)

-- Refresh NPCs
local function refreshNPCList()
    CachedNPCs = {}
    for _, npc in ipairs(workspace:GetDescendants()) do
        if npc:IsA("Model") and npc:FindFirstChild("Head") and npc:FindFirstChildWhichIsA("Humanoid") and not Players:GetPlayerFromCharacter(npc) then
            if npc.Humanoid.Health > 0 then
                table.insert(CachedNPCs, npc)
            end
        end
    end
end

-- ESP Loop
task.spawn(function()
    while task.wait(2) do
        if _G_NPCESP then
            refreshNPCList()
            for _, npc in ipairs(CachedNPCs) do
                if not npc:FindFirstChild("ESP_Highlight") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "ESP_Highlight"
                    hl.Adornee = npc
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.Parent = npc
                end
            end
        end

        if _G_ItemESP then
            local runtimeItems = workspace:FindFirstChild("RuntimeItems")
            if runtimeItems then
                for _, obj in ipairs(runtimeItems:GetChildren()) do
                    if obj:IsA("Model") or obj:IsA("Tool") then
                        local pos = nil
                        if obj:IsA("Model") and obj.PrimaryPart then
                            pos = obj.PrimaryPart.Position
                        elseif obj:IsA("Tool") and obj:FindFirstChild("Handle") then
                            pos = obj.Handle.Position
                        elseif obj:IsA("Model") then
                            for _, part in ipairs(obj:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    pos = part.Position
                                    break
                                end
                            end
                        end

                        if pos then
                            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if hrp and (pos - hrp.Position).Magnitude <= ItemESPDistance then
                                if not obj:FindFirstChild("ESP_Highlight_Item") then
                                    local hl = Instance.new("Highlight")
                                    hl.Name = "ESP_Highlight_Item"
                                    hl.Adornee = obj
                                    hl.FillColor = Color3.fromRGB(0, 255, 0)
                                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                    hl.Parent = obj
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Aimbot
RunService.Heartbeat:Connect(function(delta)
    if AimbotCircle.Visible then
        AimbotCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
        AimbotCircle.Size = UDim2.new(0, AimbotFOV * 2, 0, AimbotFOV * 2)
    end

    if _G_NPCAimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if not CurrentLockedTarget or not CurrentLockedTarget:IsDescendantOf(workspace) or CurrentLockedTarget:FindFirstChildWhichIsA("Humanoid").Health <= 0 then
            CurrentLockedTarget = nil
            local closest = AimbotFOV
            for _, npc in ipairs(CachedNPCs) do
                local head = npc:FindFirstChild("Head")
                if head then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                        if dist <= closest then
                            closest = dist
                            CurrentLockedTarget = npc
                        end
                    end
                end
            end
        end

        if CurrentLockedTarget and CurrentLockedTarget:FindFirstChild("Head") then
            local headPos = CurrentLockedTarget.Head.Position
            local camPos = Camera.CFrame.Position
            local look = Camera.CFrame.LookVector
            local dir = (headPos - camPos).Unit
            local lerped = look:Lerp(dir, math.clamp(delta * AimbotSmoothness, 0, 1))
            Camera.CFrame = CFrame.new(camPos, camPos + lerped)
        end
    else
        CurrentLockedTarget = nil
    end
end)

-- Notification
pcall(function()
    game.StarterGui:SetCore("SendNotification", {
        Title = "IshkebHub",
        Text = "✅ Fully Loaded!",
        Duration = 5
    })
end)
