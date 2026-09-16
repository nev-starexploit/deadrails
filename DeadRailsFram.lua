--[[
    ==========================================
    DEAD RAILS | NEV-STAR PRIVATE HUB
    by nev-star
    Version: 2.0
    ==========================================
    No key. No lock. Langsung jalan.
    Private use only - Do not share!
]]

--// Load Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Dead Rails | nev-star",
   Icon = "Skull",
   LoadingTitle = "Memuat nev-star hub...",
   LoadingSubtitle = "by nev-star",
   Theme = "DarkBlue",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "NevStarHub",
      FileName = "Config"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false
})

--// Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Cam = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local rs = game:GetService("ReplicatedStorage")
local plr = LocalPlayer

--// Create Tabs (with SVG icons)
local FarmTab = Window:CreateTab("Farm", "DollarSign")
local AimbotTab = Window:CreateTab("Aimbot", "Crosshair")
local BringsTab = Window:CreateTab("Brings", "Package")
local ESPTab = Window:CreateTab("ESP", "Eye")
local MovementTab = Window:CreateTab("Movement", "User")
local MiscTab = Window:CreateTab("Misc", "Settings")

--==========================================
-- FARM TAB (Auto Bonds)
--==========================================

local autoCollectEnabled = false
local autoExchangeEnabled = false
local farmSpeed = 0.5
local totalBonds = 0

-- Fungsi auto collect bonds (tarik ke player)
local function startAutoCollect()
    task.spawn(function()
        while autoCollectEnabled do
            pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                local hrp = char.HumanoidRootPart
                
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name:lower():find("bond") then
                        obj.CFrame = CFrame.new(hrp.Position)
                        firetouchinterest(hrp, obj, 0)
                        task.wait()
                        firetouchinterest(hrp, obj, 1)
                        totalBonds = totalBonds + 1
                    end
                end
            end)
            task.wait(farmSpeed)
        end
    end)
end

-- Fungsi auto exchange bonds
local function startAutoExchange()
    task.spawn(function()
        while autoExchangeEnabled do
            pcall(function()
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        local txt = obj.ActionText:lower()
                        if txt:find("exchange") or txt:find("collect") or txt:find("deposit") then
                            fireproximityprompt(obj)
                        end
                    end
                end
                
                -- Cari remote event exchange
                local remote = rs:FindFirstChild("Exchange") or rs:FindFirstChild("Store")
                if remote and remote:IsA("RemoteEvent") then
                    remote:FireServer(true)
                    task.wait(0.05)
                    remote:FireServer(nil)
                end
            end)
            task.wait(1)
        end
    end)
end

FarmTab:CreateSection("Auto Bond Farm")

FarmTab:CreateToggle({
   Name = "Auto Collect Bonds",
   CurrentValue = false,
   Flag = "AutoCollect",
   Callback = function(Value)
       autoCollectEnabled = Value
       if Value then
           startAutoCollect()
           Rayfield:Notify({ Title = "Farm", Content = "Auto Collect ON", Duration = 2 })
       else
           Rayfield:Notify({ Title = "Farm", Content = "Auto Collect OFF", Duration = 2 })
       end
   end
})

FarmTab:CreateToggle({
   Name = "Auto Exchange Bonds",
   CurrentValue = false,
   Flag = "AutoExchange",
   Callback = function(Value)
       autoExchangeEnabled = Value
       if Value then
           startAutoExchange()
           Rayfield:Notify({ Title = "Farm", Content = "Auto Exchange ON", Duration = 2 })
       else
           Rayfield:Notify({ Title = "Farm", Content = "Auto Exchange OFF", Duration = 2 })
       end
   end
})

FarmTab:CreateSlider({
   Name = "Farm Speed",
   Range = {0.1, 3},
   Increment = 0.1,
   Suffix = "s",
   CurrentValue = 0.5,
   Flag = "FarmSpeed",
   Callback = function(Value)
       farmSpeed = Value
   end
})

FarmTab:CreateLabel("Bonds Collected: " .. totalBonds)

--==========================================
-- AIMBOT TAB
--==========================================

local validNPCs = {}
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Thickness = 1
fovCircle.Color = Color3.new(1, 1, 1)
fovCircle.Transparency = 1
fovCircle.Filled = false
local fovRadius = 100
local aimbotEnabled = false
local aimbotKey = Enum.UserInputType.MouseButton2

local function updateFOV()
    fovCircle.Radius = fovRadius
    fovCircle.Position = Cam.ViewportSize / 2
end

local function isNPC(obj)
    return obj:IsA("Model")
        and obj:FindFirstChild("Humanoid")
        and obj.Humanoid.Health > 0
        and obj:FindFirstChild("Head")
        and obj:FindFirstChild("HumanoidRootPart")
        and not Players:GetPlayerFromCharacter(obj)
end

local function updateNPCs()
    local tempTable = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isNPC(obj) then tempTable[obj] = true end
    end
    for i = #validNPCs, 1, -1 do
        if not tempTable[validNPCs[i]] then table.remove(validNPCs, i) end
    end
    for obj in pairs(tempTable) do
        if not table.find(validNPCs, obj) then table.insert(validNPCs, obj) end
    end
end

workspace.DescendantAdded:Connect(function(descendant)
    if isNPC(descendant) then
        table.insert(validNPCs, descendant)
    end
end)

workspace.DescendantRemoving:Connect(function(descendant)
    if isNPC(descendant) then
        for i = #validNPCs, 1, -1 do
            if validNPCs[i] == descendant then
                table.remove(validNPCs, i)
                break
            end
        end
    end
end)

local function predictPos(target)
    local rootPart = target:FindFirstChild("HumanoidRootPart")
    local head = target:FindFirstChild("Head")
    if not rootPart or not head then return end
    local velocity = rootPart.Velocity
    local predictionTime = 0.02
    local basePosition = rootPart.Position + velocity * predictionTime
    local headOffset = head.Position - rootPart.Position
    return basePosition + headOffset
end

local function getTarget()
    local nearest = nil
    local minDistance = math.huge
    local viewportCenter = Cam.ViewportSize / 2
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    for _, npc in ipairs(validNPCs) do
        local predictedPos = predictPos(npc)
        if predictedPos then
            local screenPos, visible = Cam:WorldToViewportPoint(predictedPos)
            if visible and screenPos.Z > 0 then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
                if distance <= fovRadius then
                    local ray = workspace:Raycast(Cam.CFrame.Position, (predictedPos - Cam.CFrame.Position).Unit * 1000, raycastParams)
                    if ray and ray.Instance:IsDescendantOf(npc) then
                        if distance < minDistance then
                            minDistance = distance
                            nearest = npc
                        end
                    end
                end
            end
        end
    end
    return nearest
end

local function aim(targetPosition)
    local currentCF = Cam.CFrame
    local targetDirection = (targetPosition - currentCF.Position).Unit
    local smoothFactor = 0.581
    local newLookVector = currentCF.LookVector:Lerp(targetDirection, smoothFactor)
    Cam.CFrame = CFrame.new(currentCF.Position, currentCF.Position + newLookVector)
end

RunService.Heartbeat:Connect(function()
    if aimbotEnabled then
        local target = getTarget()
        if target then
            local predicted = predictPos(target)
            if predicted then aim(predicted) end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == aimbotKey then aimbotEnabled = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == aimbotKey then aimbotEnabled = false end
end)

AimbotTab:CreateToggle({
   Name = "Enable Aimbot (Hold Right Click)",
   CurrentValue = false,
   Flag = "AimbotToggle",
   Callback = function(Value)
       aimbotEnabled = Value
       fovCircle.Visible = Value
       Rayfield:Notify({ Title = "Aimbot", Content = Value and "ON" or "OFF", Duration = 2 })
   end
})

AimbotTab:CreateSlider({
   Name = "FOV Radius",
   Range = {50, 500},
   Increment = 10,
   CurrentValue = 100,
   Flag = "FOVSlider",
   Callback = function(Value)
       fovRadius = Value
       updateFOV()
   end
})

updateFOV()

--==========================================
-- BRINGS TAB
--==========================================

local selectedItem = nil

local function GetItemNames()
    local items = {}
    local runtimeItems = workspace:FindFirstChild("RuntimeItems")
    if runtimeItems then
        for _, item in ipairs(runtimeItems:GetDescendants()) do
            if item:IsA("Model") then table.insert(items, item.Name) end
        end
    end
    return items
end

local itemDropdown = BringsTab:CreateDropdown({
   Name = "Choose Item",
   Options = GetItemNames(),
   CurrentOption = "Select an item",
   Flag = "ItemDropdown",
   Callback = function(Value)
       selectedItem = Value
   end
})

BringsTab:CreateButton({
   Name = "Refresh Items",
   Callback = function()
       local newItems = GetItemNames()
       itemDropdown:Refresh(newItems, "Select an item")
       Rayfield:Notify({ Title = "Brings", Content = "Refreshed: " .. #newItems .. " items", Duration = 3 })
   end
})

BringsTab:CreateButton({
   Name = "Collect Selected Item",
   Callback = function()
       if not selectedItem or selectedItem == "Select an item" then
           Rayfield:Notify({ Title = "Error", Content = "Pilih item dulu!", Duration = 3 })
           return
       end
       local runtimeItems = workspace:FindFirstChild("RuntimeItems")
       if not runtimeItems then return end
       for _, item in ipairs(runtimeItems:GetDescendants()) do
           if item:IsA("Model") and item.Name == selectedItem and item.PrimaryPart then
               local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
               local hrp = char:WaitForChild("HumanoidRootPart")
               item:SetPrimaryPartCFrame(hrp.CFrame + Vector3.new(0, 1, 0))
               Rayfield:Notify({ Title = "Success", Content = selectedItem .. " collected!", Duration = 3 })
               break
           end
       end
   end
})

BringsTab:CreateButton({
   Name = "Collect All Items",
   Callback = function()
       local runtimeItems = workspace:FindFirstChild("RuntimeItems")
       if not runtimeItems then return end
       local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
       local hrp = char:WaitForChild("HumanoidRootPart")
       for _, item in ipairs(runtimeItems:GetDescendants()) do
           if item:IsA("Model") and item.PrimaryPart then
               local offset = hrp.CFrame.LookVector * 5
               item:SetPrimaryPartCFrame(hrp.CFrame + offset)
           end
       end
       Rayfield:Notify({ Title = "Success", Content = "All items collected!", Duration = 3 })
   end
})

--==========================================
-- ESP TAB
--==========================================

local ESPHandles = {}
local ESPEnabled = false
local ESPPlayerEnabled = false
local ESPZombyEnabled = false
local ESPColor = Color3.fromRGB(255, 0, 0)

local function CreateESP(object, color)
    if not object or not object.PrimaryPart then return end
    if ESPHandles[object] then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = object
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.Parent = object
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Adornee = object.PrimaryPart
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = object
    local textLabel = Instance.new("TextLabel")
    textLabel.Text = object.Name
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.TextColor3 = color
    textLabel.BackgroundTransparency = 1
    textLabel.TextSize = 7
    textLabel.Parent = billboard
    ESPHandles[object] = {Highlight = highlight, Billboard = billboard, Color = color}
end

local function ClearESP()
    for obj, handles in pairs(ESPHandles) do
        if handles.Highlight then handles.Highlight:Destroy() end
        if handles.Billboard then handles.Billboard:Destroy() end
        ESPHandles[obj] = nil
    end
end

local function UpdateESP()
    ClearESP()
    local runtimeItems = workspace:FindFirstChild("RuntimeItems")
    if runtimeItems then
        for _, item in ipairs(runtimeItems:GetDescendants()) do
            if item:IsA("Model") then CreateESP(item, Color3.new(1, 0, 0)) end
        end
    end
    local nightEnemies = workspace:FindFirstChild("NightEnemies")
    if nightEnemies then
        for _, enemy in ipairs(nightEnemies:GetDescendants()) do
            if enemy:IsA("Model") then CreateESP(enemy, Color3.new(0, 0, 1)) end
        end
    end
end

local function AddESPForPlayer(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or player == LocalPlayer then return end
    local character = player.Character
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    local espFrame = Instance.new("BillboardGui")
    espFrame.Parent = character
    espFrame.Adornee = humanoidRootPart
    espFrame.Size = UDim2.new(0, 100, 0, 40)
    espFrame.StudsOffset = Vector3.new(0, 3, 0)
    espFrame.AlwaysOnTop = true
    espFrame.Name = "ESPFrame"
    local frame = Instance.new("Frame")
    frame.Parent = espFrame
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    local healthText = Instance.new("TextLabel")
    healthText.Parent = frame
    healthText.Size = UDim2.new(1, 0, 0.3, 0)
    healthText.BackgroundTransparency = 1
    healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthText.TextSize = 10
    healthText.Text = "Health: " .. math.floor(humanoid.Health)
    humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        healthText.Text = "Health: " .. math.floor(humanoid.Health)
    end)
end

local function AddESPForEnemy(enemy)
    if not enemy or not enemy:FindFirstChild("HumanoidRootPart") then return end
    local character = enemy
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    local espFrame = Instance.new("BillboardGui")
    espFrame.Parent = character
    espFrame.Adornee = humanoidRootPart
    espFrame.Size = UDim2.new(0, 100, 0, 40)
    espFrame.StudsOffset = Vector3.new(0, 3, 0)
    espFrame.AlwaysOnTop = true
    espFrame.Name = "ESPFrame"
    local frame = Instance.new("Frame")
    frame.Parent = espFrame
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    local healthText = Instance.new("TextLabel")
    healthText.Parent = frame
    healthText.Size = UDim2.new(1, 0, 0.3, 0)
    healthText.BackgroundTransparency = 1
    healthText.TextColor3 = ESPColor
    healthText.TextSize = 10
    healthText.Text = "Health: " .. math.floor(humanoid.Health)
    humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        healthText.Text = "Health: " .. math.floor(humanoid.Health)
    end)
end

RunService.Heartbeat:Connect(function()
    if ESPPlayerEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and not player.Character:FindFirstChild("ESPFrame") then
                AddESPForPlayer(player)
            end
        end
    end
    if ESPZombyEnabled then
        for _, enemy in pairs(workspace:GetDescendants()) do
            if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(enemy) and not enemy:FindFirstChild("ESPFrame") then
                AddESPForEnemy(enemy)
            end
        end
    end
end)

ESPTab:CreateToggle({
   Name = "ESP Items and Mobs",
   CurrentValue = false,
   Flag = "ESPItems",
   Callback = function(Value)
       ESPEnabled = Value
       if Value then
           UpdateESP()
           spawn(function()
               while ESPEnabled do
                   UpdateESP()
                   wait(1)
               end
           end)
       else
           ClearESP()
       end
       Rayfield:Notify({ Title = "ESP", Content = Value and "Items/Mobs ON" or "OFF", Duration = 2 })
   end
})

ESPTab:CreateToggle({
   Name = "ESP Players",
   CurrentValue = false,
   Flag = "ESPPlayers",
   Callback = function(Value)
       ESPPlayerEnabled = Value
   end
})

ESPTab:CreateToggle({
   Name = "ESP Zombies",
   CurrentValue = false,
   Flag = "ESPZombies",
   Callback = function(Value)
       ESPZombyEnabled = Value
   end
})

--==========================================
-- MOVEMENT TAB
--==========================================

local speedHackEnabled = false
local speedValue = 16
local jumpHackEnabled = false
local jumpMultiplier = 1.5
local noClipEnabled = false
local infiniteJumpEnabled = false
local flyEnabled = false

local function applySpeedHack()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = speedHackEnabled and speedValue or 16
    end
end

local function applyJumpHack()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpHeight = jumpHackEnabled and (7.2 * jumpMultiplier) or 7.2
    end
end

local function applyNoClip()
    if LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not noClipEnabled
            end
        end
    end
end

RunService.Stepped:Connect(function()
    if noClipEnabled then applyNoClip() end
end)

MovementTab:CreateSlider({
   Name = "WalkSpeed",
   Range = {1, 500},
   Increment = 1,
   CurrentValue = 50,
   Flag = "SpeedSlider",
   Callback = function(Value)
       speedValue = Value
       applySpeedHack()
   end
})

MovementTab:CreateToggle({
   Name = "Speed Hack",
   CurrentValue = false,
   Flag = "SpeedHack",
   Callback = function(Value)
       speedHackEnabled = Value
       applySpeedHack()
   end
})

MovementTab:CreateSlider({
   Name = "Jump Height",
   Range = {10, 500},
   Increment = 1,
   CurrentValue = 50,
   Flag = "JumpSlider",
   Callback = function(Value)
       if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
           LocalPlayer.Character.Humanoid.JumpHeight = Value
       end
   end
})

MovementTab:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Flag = "InfJump",
   Callback = function(Value)
       infiniteJumpEnabled = Value
       if Value then
           UserInputService.JumpRequest:Connect(function()
               if LocalPlayer.Character then
                   LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
               end
           end)
       end
   end
})

MovementTab:CreateToggle({
   Name = "Fly",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value)
       flyEnabled = Value
       local char = LocalPlayer.Character
       local hrp = char and char:FindFirstChild("HumanoidRootPart")
       if not hrp then return end
       if Value then
           local speed = 50
           local bodyVelocity = Instance.new("BodyVelocity")
           bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
           bodyVelocity.Parent = hrp
           local bodyGyro = Instance.new("BodyGyro")
           bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
           bodyGyro.CFrame = hrp.CFrame
           bodyGyro.Parent = hrp
           spawn(function()
               while flyEnabled and hrp and hrp.Parent do
                   local cam = workspace.CurrentCamera
                   local moveDirection = Vector3.new(
                       (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
                       (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 1 or 0),
                       (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
                   ).Unit
                   bodyVelocity.Velocity = cam.CFrame:VectorToWorldSpace(moveDirection) * speed
                   bodyGyro.CFrame = cam.CFrame
                   wait()
               end
               if bodyVelocity then bodyVelocity:Destroy() end
               if bodyGyro then bodyGyro:Destroy() end
           end)
       else
           local bodyVelocity = hrp:FindFirstChildOfClass("BodyVelocity")
           local bodyGyro = hrp:FindFirstChildOfClass("BodyGyro")
           if bodyVelocity then bodyVelocity:Destroy() end
           if bodyGyro then bodyGyro:Destroy() end
       end
   end
})

MovementTab:CreateToggle({
   Name = "Jump Hack",
   CurrentValue = false,
   Flag = "JumpHack",
   Callback = function(Value)
       jumpHackEnabled = Value
       applyJumpHack()
   end
})

MovementTab:CreateSlider({
   Name = "Jump Power Multiplier",
   Range = {1, 5},
   Increment = 0.1,
   CurrentValue = 1.5,
   Flag = "JumpMulti",
   Callback = function(Value)
       jumpMultiplier = Value
       applyJumpHack()
   end
})

MovementTab:CreateToggle({
   Name = "NoClip",
   CurrentValue = false,
   Flag = "NoClip",
   Callback = function(Value)
       noClipEnabled = Value
   end
})

--==========================================
-- MISC TAB
--==========================================

MiscTab:CreateButton({
   Name = "Scan Remote Events",
   Callback = function()
       local list = {}
       for _, obj in pairs(rs:GetDescendants()) do
           if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
               table.insert(list, obj.Name)
           end
       end
       print("=== REMOTE EVENTS ===")
       for i, v in ipairs(list) do
           print(i .. ". " .. v)
       end
       Rayfield:Notify({ Title = "Scan", Content = "Cek console (F9)", Duration = 3 })
   end
})

MiscTab:CreateButton({
   Name = "Reset Farm Counter",
   Callback = function()
       totalBonds = 0
       Rayfield:Notify({ Title = "Reset", Content = "Bonds counter reset", Duration = 2 })
   end
})

--==========================================
-- NOTIFICATION
--==========================================
Rayfield:Notify({
   Title = "nev-star hub loaded",
   Content = "Tekan Right ALT untuk buka menu.",
   Duration = 5
})

print("[nev-star] Script loaded successfully")
