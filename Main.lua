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
local Window = Library.CreateLib("IshkebHub - Ultimate Version", "BloodTheme")

-- Globals
local CachedNPCs = {}
local CurrentLockedTarget = nil
_G._G_NPCESP = false
_G._G_NPCAimbot = false
_G._G_ItemESP = false
_G.AimbotFOV = 200
_G.AimbotSmoothness = 5
_G.ItemESPDistance = 1000

-- FOV Circle UI
local FOV_UI = Instance.new("ScreenGui")
FOV_UI.Name = "FOV_UI"
FOV_UI.ResetOnSpawn = false
pcall(function() FOV_UI.Parent = game:GetService("CoreGui") end)

local AimbotCircle = Instance.new("Frame")
AimbotCircle.Size = UDim2.new(0, _G.AimbotFOV * 2, 0, _G.AimbotFOV * 2)
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

-- Category Colors
local CategoryColors = {
    ["Weapon"] = Color3.fromRGB(255, 0, 0),
    ["Explosive"] = Color3.fromRGB(128, 0, 128),
    ["Healing"] = Color3.fromRGB(0, 255, 0),
    ["Armor"] = Color3.fromRGB(0, 255, 127),
    ["Tool"] = Color3.fromRGB(255, 165, 0),
    ["Utility"] = Color3.fromRGB(0, 255, 255),
    ["Valuable"] = Color3.fromRGB(255, 255, 0),
    ["Junk"] = Color3.fromRGB(180, 180, 180),
    ["Ammo"] = Color3.fromRGB(0, 0, 255),
    ["Fuel"] = Color3.fromRGB(139, 0, 0),
    ["Special"] = Color3.fromRGB(0, 200, 255),
    ["Playable"] = Color3.fromRGB(255, 105, 180),
    ["Misc"] = Color3.fromRGB(255, 255, 255)
}

-- Whitelisted Items
local WhitelistedItems = {
    ["revolver"] = "Weapon", ["navy revolver"] = "Weapon", ["mauser c96"] = "Weapon",
    ["shotgun"] = "Weapon", ["sawed-off shotgun"] = "Weapon", ["rifle"] = "Weapon",
    ["bolt-action rifle"] = "Weapon", ["cavalry sword"] = "Weapon", ["tomahawk"] = "Weapon",
    ["pickaxe"] = "Weapon", ["shovel"] = "Weapon", ["jade sword"] = "Weapon",
    ["vampire knife"] = "Weapon", ["electrocutioner"] = "Weapon", ["maxim turret"] = "Weapon",
    ["cannon"] = "Weapon", ["dynamite"] = "Explosive", ["molotov"] = "Explosive",
    ["holy water"] = "Explosive", ["crucifix"] = "Explosive", ["revolver ammo"] = "Ammo",
    ["shotgun shells"] = "Ammo", ["rifle ammo"] = "Ammo", ["turret ammo"] = "Ammo",
    ["cannon shells"] = "Ammo", ["cannon balls"] = "Ammo", ["bandage"] = "Healing",
    ["snake oil"] = "Healing", ["dr rico's cure"] = "Healing", ["helmet"] = "Armor",
    ["chestplate"] = "Armor", ["mining helmet"] = "Armor", ["ironclad's helmet"] = "Armor",
    ["ironclad's chestplate"] = "Armor", ["ironclad's left shoulder pad"] = "Armor",
    ["ironclad's right shoulder pad"] = "Armor", ["torch"] = "Tool", ["banjo"] = "Playable",
    ["barbed wire"] = "Tool", ["sheet metal"] = "Tool", ["lantern"] = "Tool",
    ["lightning rod"] = "Tool", ["rope"] = "Tool", ["camera"] = "Tool",
    ["saddle"] = "Tool", ["horse cart"] = "Tool", ["kinder egg"] = "Tool",
    ["metal sheet"] = "Tool", ["coal"] = "Fuel", ["chair"] = "Fuel",
    ["tumbleweed"] = "Fuel", ["wooden painting"] = "Fuel", ["book"] = "Fuel",
    ["newspaper"] = "Fuel", ["wanted poster"] = "Fuel", ["barrel"] = "Fuel",
    ["wheel"] = "Fuel", ["vase"] = "Fuel", ["teapot"] = "Fuel", ["gold bar"] = "Valuable",
    ["gold nugget"] = "Valuable", ["silver bar"] = "Valuable", ["silver nugget"] = "Valuable",
    ["gold watch"] = "Valuable", ["silver watch"] = "Valuable", ["gold cup"] = "Valuable",
    ["silver cup"] = "Valuable", ["gold plate"] = "Valuable", ["silver plate"] = "Valuable",
    ["gold statue"] = "Valuable", ["silver statue"] = "Valuable", ["stone statue"] = "Valuable",
    ["gold painting"] = "Valuable", ["silver painting"] = "Valuable", ["money bag"] = "Valuable",
    ["strange mask"] = "Valuable", ["brain in jar"] = "Valuable", ["unicorn"] = "Valuable",
    ["jade mask"] = "Valuable", ["nikola tesla's brain"] = "Special", ["werewolf torso"] = "Special",
    ["werewolf's left arm"] = "Special", ["werewolf's right arm"] = "Special",
    ["werewolf's left leg"] = "Special", ["werewolf's right leg"] = "Special",
    ["supply depot key"] = "Special", ["jade tablet"] = "Special", ["fool's gold"] = "Special",
    ["bank combo"] = "Special", ["bonds"] = "Misc", ["starter box"] = "Misc", ["strange machine"] = "Misc",
    ["sack"] = "Misc"
}

-- UI Tabs
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Visuals & Aimbot")

MainSection:NewToggle("NPC ESP", "Highlight NPCs", function(state)
    _G._G_NPCESP = state
end)

MainSection:NewToggle("Item ESP (RuntimeItems Only)", "Highlight Items", function(state)
    _G._G_ItemESP = state
end)

MainSection:NewToggle("NPC Aimbot", "Lock onto NPCs (Hold Right Mouse)", function(state)
    _G._G_NPCAimbot = state
    AimbotCircle.Visible = state
end)

MainSection:NewSlider("Aimbot FOV", "Adjust Aimbot Circle Size", 600, 50, function(value)
    _G.AimbotFOV = value
    AimbotCircle.Size = UDim2.new(0, value * 2, 0, value * 2)
end)

MainSection:NewSlider("Aimbot Smoothness", "Higher = Smoother but slower", 20, 1, function(value)
    _G.AimbotSmoothness = value
end)

MainSection:NewSlider("Item ESP Distance", "Max Distance to Show Items", 3000, 100, function(value)
    _G.ItemESPDistance = value
end)

local function refreshNPCList()
    CachedNPCs = {}
    for _, npc in ipairs(workspace:GetDescendants()) do
        if npc:IsA("Model") and npc:FindFirstChildWhichIsA("Humanoid") and npc:FindFirstChild("Head") and not Players:GetPlayerFromCharacter(npc) then
            if npc.Humanoid.Health > 0 then
                table.insert(CachedNPCs, npc)
            end
        end
    end
end

-- ESP System
task.spawn(function()
    local lastUpdate = 0
    while task.wait(0.1) do
        local now = tick()
        if now - lastUpdate >= 2 then
            lastUpdate = now
            if _G._G_NPCESP then
                refreshNPCList()
                for _, npc in ipairs(CachedNPCs) do
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
                end
            end

            if _G._G_ItemESP then
                local runtimeItems = workspace:FindFirstChild("RuntimeItems")
                if runtimeItems then
                    for _, obj in ipairs(runtimeItems:GetChildren()) do
                        if (obj:IsA("Model") or obj:IsA("Tool")) and not obj:FindFirstChild("ESP_Highlight_Item") then
                            local itemPos = nil
                            if obj:IsA("Model") and obj.PrimaryPart then
                                itemPos = obj.PrimaryPart.Position
                            elseif obj:IsA("Tool") and obj:FindFirstChild("Handle") then
                                itemPos = obj.Handle.Position
                            elseif obj:IsA("Model") then
                                for _, part in ipairs(obj:GetDescendants()) do
                                    if part:IsA("BasePart") then
                                        itemPos = part.Position
                                        break
                                    end
                                end
                            end

                            if itemPos then
                                local playerHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                local dist = playerHRP and (itemPos - playerHRP.Position).Magnitude or math.huge

                                if dist <= _G.ItemESPDistance then
                                    for itemName, itemType in pairs(WhitelistedItems) do
                                        if obj.Name:lower():find(itemName) then
                                            local hl = Instance.new("Highlight")
                                            hl.Name = "ESP_Highlight_Item"
                                            hl.Adornee = obj
                                            hl.FillColor = CategoryColors[itemType] or Color3.fromRGB(255, 255, 255)
                                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                            hl.FillTransparency = 0.4
                                            hl.OutlineTransparency = 0
                                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                            hl.Parent = obj
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Aimbot System
RunService.Heartbeat:Connect(function(delta)
    if AimbotCircle.Visible then
        AimbotCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
        AimbotCircle.Size = UDim2.new(0, _G.AimbotFOV * 2, 0, _G.AimbotFOV * 2)
    end

    if _G._G_NPCAimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if not CurrentLockedTarget or not CurrentLockedTarget:IsDescendantOf(workspace) or CurrentLockedTarget:FindFirstChildWhichIsA("Humanoid").Health <= 0 then
            CurrentLockedTarget = nil
            local closest = _G.AimbotFOV
            for _, npc in ipairs(CachedNPCs) do
                local hum = npc:FindFirstChildWhichIsA("Humanoid")
                local head = npc:FindFirstChild("Head")
                if hum and head and hum.Health > 0 then
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
            local direction = (headPos - camPos).Unit
            local currentLook = Camera.CFrame.LookVector
            local smoothDirection = currentLook:Lerp(direction, math.clamp(delta * _G.AimbotSmoothness, 0, 1))
            Camera.CFrame = CFrame.new(camPos, camPos + smoothDirection)
        end
    else
        CurrentLockedTarget = nil
    end
end)

-- Final Notification
pcall(function()
    game.StarterGui:SetCore("SendNotification", {
        Title = "IshkebHub",
        Text = "✅ FULLY LOADED - ESP + Smooth Aimbot Ready!",
        Duration = 6
    })
end)
