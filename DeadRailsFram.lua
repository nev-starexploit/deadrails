-- ======================================================
-- DEAD RAILS | AUTO FARM BONDS
-- Author: [Nama Lo]
-- Version: 1.0
-- Open Source - Baca & Pelajari!
-- ======================================================

-- ==========================================
-- 1. LOAD UI LIBRARY (Rayfield)
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Dead Rails | Farm Hub",
   LoadingTitle = "Memuat Script...",
   LoadingSubtitle = "by [nev-star]",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "DeadRailsFarm",
      FileName = "Config"
   },
   KeySystem = false
})

-- ==========================================
-- 2. TAB & VARIABEL GLOBAL
-- ==========================================
local FarmTab = Window:CreateTab("🌾 Farm", 4483362458)
local PlayerTab = Window:CreateTab("👤 Player", 4483362458)
local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)
local InfoTab = Window:CreateTab("📊 Info", 4483362458)

-- State variabel
_G.AutoFarm = false
_G.AutoCollect = false
_G.AutoExchange = false
_G.FreezePlayer = false
_G.FarmSpeed = 0.5

-- Counter
_G.TotalBonds = 0
_G.StartTime = tick()

-- ==========================================
-- 3. REFERENSI REMOTE EVENTS
-- ==========================================
-- Cari remote event di game (sesuaikan kalau nama beda)
local function getRemote(name)
    for _, obj in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if obj.Name == name and obj:IsA("RemoteEvent") then
            return obj
        end
    end
    return nil
end

-- Ambil remote (bisa nil kalau belum ketemu, jadi pakai pcall)
local StoreRemote = getRemote("Store")
local ActionableRemote = getRemote("Actionable")

-- ==========================================
-- 4. FUNGSI UTAMA
-- ==========================================

-- 4A. Freeze / Unfreeze Player
local function freezePlayer()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.Anchored = true
    end
end

local function unfreezePlayer()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.Anchored = false
    end
end

-- 4B. Auto Collect Bonds
-- Logika: cari object Bond di workspace, lalu ambil via touch
local function startAutoCollect()
    task.spawn(function()
        while _G.AutoCollect do
            pcall(function()
                local player = game.Players.LocalPlayer
                local char = player.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                
                local hrp = char.HumanoidRootPart
                
                -- Scan workspace untuk Bonds
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name:lower():find("bond") then
                        -- Teleport bond ke player & touch
                        obj.CFrame = CFrame.new(hrp.Position)
                        firetouchinterest(hrp, obj, 0)
                        task.wait()
                        firetouchinterest(hrp, obj, 1)
                        _G.TotalBonds = _G.TotalBonds + 1
                    end
                end
            end)
            task.wait(_G.FarmSpeed)
        end
    end)
end

-- 4C. Auto Exchange (Keluarkan & Collect)
-- Logika: fire remote Store & Actionable
local function startAutoExchange()
    task.spawn(function()
        while _G.AutoExchange do
            pcall(function()
                -- Fire Store remote (klaim/setor)
                if StoreRemote then
                    StoreRemote:FireServer(true)
                    task.wait(0.05)
                    StoreRemote:FireServer(nil)
                end
                
                -- Fire Actionable remote (aksi/collect)
                if ActionableRemote then
                    ActionableRemote:FireServer(true)
                end
                
                -- Cari ProximityPrompt exchange di sekitar
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        local action = obj.ActionText:lower()
                        if action:find("exchange") or action:find("collect") or action:find("deposit") then
                            fireproximityprompt(obj)
                        end
                    end
                end
            end)
            task.wait(1)
        end
    end)
end

-- 4D. Auto Farm Utama (gabungan)
local function startAutoFarm()
    task.spawn(function()
        while _G.AutoFarm do
            if _G.FreezePlayer then
                freezePlayer()
            end
            
            if _G.AutoCollect then
                startAutoCollect()
                task.wait(0.1)
            end
            
            if _G.AutoExchange then
                startAutoExchange()
            end
            
            task.wait(_G.FarmSpeed)
        end
        unfreezePlayer()
    end)
end

-- 4E. Auto Private Server
local function createPrivateServer()
    pcall(function()
        local remote = getRemote("Store")
        if remote then
            remote:FireServer({
                isPrivate = true,
                maxMembers = 1,
                trainId = "default",
                gameMode = "normal"
            })
            Rayfield:Notify({
                Title = "Private Server",
                Content = "Mencoba membuat private server...",
                Duration = 3
            })
        end
    end)
end

-- 4F. Auto Rejoin
local function autoRejoin()
    task.spawn(function()
        while _G.AutoRejoin do
            task.wait(5)
            pcall(function()
                game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
            end)
        end
    end)
end

-- ==========================================
-- 5. UI TOGGLES - FARM TAB
-- ==========================================
FarmTab:CreateSection("Fitur Utama")

FarmTab:CreateToggle({
   Name = "🌾 Auto Farm Bonds",
   CurrentValue = false,
   Flag = "AutoFarmToggle",
   Callback = function(Value)
       _G.AutoFarm = Value
       if Value then
           startAutoFarm()
           Rayfield:Notify({Title = "Auto Farm ON", Content = "Farming dimulai...", Duration = 2})
       else
           unfreezePlayer()
           Rayfield:Notify({Title = "Auto Farm OFF", Content = "Farming dihentikan.", Duration = 2})
       end
   end,
})

FarmTab:CreateToggle({
   Name = "💰 Auto Collect (Bonds Masuk)",
   CurrentValue = false,
   Flag = "AutoCollectToggle",
   Callback = function(Value)
       _G.AutoCollect = Value
       if Value then startAutoCollect() end
   end,
})

FarmTab:CreateToggle({
   Name = "🔄 Auto Exchange (Keluarkan & Collect)",
   CurrentValue = false,
   Flag = "AutoExchangeToggle",
   Callback = function(Value)
       _G.AutoExchange = Value
       if Value then startAutoExchange() end
   end,
})

FarmTab:CreateSection("Pengaturan")

FarmTab:CreateSlider({
   Name = "Kecepatan Farm",
   Range = {0.1, 3},
   Increment = 0.1,
   Suffix = "s",
   CurrentValue = 0.5,
   Flag = "FarmSpeedSlider",
   Callback = function(Value)
       _G.FarmSpeed = Value
   end,
})

-- ==========================================
-- 6. UI - PLAYER TAB
-- ==========================================
PlayerTab:CreateSection("Karakter")

PlayerTab:CreateToggle({
   Name = "❄️ Freeze Player (Diam di Tempat)",
   CurrentValue = false,
   Flag = "FreezeToggle",
   Callback = function(Value)
       _G.FreezePlayer = Value
       if Value then freezePlayer() else unfreezePlayer() end
   end,
})

PlayerTab:CreateSlider({
   Name = "WalkSpeed",
   Range = {16, 200},
   Increment = 1,
   Suffix = "ws",
   CurrentValue = 16,
   Flag = "WalkSpeedSlider",
   Callback = function(Value)
       local char = game.Players.LocalPlayer.Character
       if char and char:FindFirstChild("Humanoid") then
           char.Humanoid.WalkSpeed = Value
       end
   end,
})

PlayerTab:CreateSlider({
   Name = "JumpPower",
   Range = {50, 500},
   Increment = 1,
   Suffix = "jp",
   CurrentValue = 50,
   Flag = "JumpSlider",
   Callback = function(Value)
       local char = game.Players.LocalPlayer.Character
       if char and char:FindFirstChild("Humanoid") then
           char.Humanoid.JumpPower = Value
       end
   end,
})

-- ==========================================
-- 7. UI - MISC TAB
-- ==========================================
MiscTab:CreateSection("Server")

MiscTab:CreateButton({
   Name = "🏠 Buat Private Server",
   Callback = function()
       createPrivateServer()
   end,
})

MiscTab:CreateToggle({
   Name = "🔁 Auto Rejoin",
   CurrentValue = false,
   Flag = "RejoinToggle",
   Callback = function(Value)
       _G.AutoRejoin = Value
       if Value then autoRejoin() end
   end,
})

MiscTab:CreateSection("Debug")

MiscTab:CreateButton({
   Name = "🔍 Scan Remote Events",
   Callback = function()
       local list = {}
       for _, obj in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
           if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
               table.insert(list, obj.Name)
           end
       end
       print("=== REMOTE EVENTS ===")
       for i, v in ipairs(list) do
           print(i .. ". " .. v)
       end
       Rayfield:Notify({Title = "Scan Selesai", Content = "Cek output console (F9)", Duration = 3})
   end,
})

-- ==========================================
-- 8. UI - INFO TAB (Counter)
-- ==========================================
InfoTab:CreateSection("Statistik")

local BondLabel = InfoTab:CreateLabel("Bonds Collected: 0")
local TimeLabel = InfoTab:CreateLabel("Time: 00:00:00")

task.spawn(function()
    while task.wait(1) do
        if BondLabel and BondLabel.Set then
            BondLabel:Set("Bonds Collected: " .. tostring(_G.TotalBonds))
        end
        
        local elapsed = tick() - _G.StartTime
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        local seconds = math.floor(elapsed % 60)
        
        if TimeLabel and TimeLabel.Set then
            TimeLabel:Set(string.format("Time: %02d:%02d:%02d", hours, minutes, seconds))
        end
    end
end)

-- ==========================================
-- 9. NOTIFIKASI DIMUAT
-- ==========================================
Rayfield:Notify({
   Title = "Script Dimuat!",
   Content = "Tekan tombol kanan ALT untuk membuka menu.",
   Duration = 5
})

-- Info remote yang ketemu
if StoreRemote then
    print("[✓] Store remote ditemukan")
else
    warn("[✗] Store remote TIDAK ditemukan - sesuaikan nama!")
end

if ActionableRemote then
    print("[✓] Actionable remote ditemukan")
else
    warn("[✗] Actionable remote TIDAK ditemukan - sesuaikan nama!")
end
