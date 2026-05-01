
បែបយល់អត់អាឆ្កួត --[[
    MKRA Ultimate Hub | VIP EDITION v4.0 (No External Library)
    UI ផ្ទាល់ គ្មាន Rayfield គ្មាន URL
    រចនាដោយ Oun ka - ស្អាត ឥន្ទធនូ ពន្លឺភ្លឺភ្លែត
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")

-- Settings
local Settings = {
    Fly = false,
    FlySpeed = 120,
    BoostMode = false,
    InfiniteJumpOrig = false,
    InfiniteJump99 = false,
    HitboxSize = 2,
    AutoClick = false,
    ForceField = false,
    ESP = false,
    Noclip = false,
    SpeedBoostMultiplier = 1,
    WalkSpeedDirect = 16,
    GodMode = false,
    InstantRespawn = false,
    KillAura = false,
    KillAuraRange = 30,
    KillAuraDamage = 30,
    KillAuraNPC = false,
    KillAuraRemote = "",
    KillAuraRemoteArgs = "target,damage",
    KillMobs = false,
    AutoChop = false,
    FlingAll = false
}

-- Notification function
local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end)
end

-- ===== Fly System =====
local flyConnection, bodyVelocity, bodyGyro

local function startFly()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0.1, 0)
    bodyVelocity.Parent = root

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root

    humanoid.PlatformStand = true

    flyConnection = RunService.RenderStepped:Connect(function()
        local moveDir = humanoid.MoveDirection
        local speed = Settings.FlySpeed
        if Settings.BoostMode then speed = speed * 2.5 end
        if moveDir.Magnitude > 0 then
            bodyVelocity.Velocity = moveDir * speed
        else
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        bodyGyro.CFrame = Workspace.CurrentCamera.CFrame
    end)
end

local function stopFly()
    if flyConnection then flyConnection:Disconnect() end
    if bodyVelocity then bodyVelocity:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.PlatformStand = false
    end
end

-- ===== God Mode =====
local godCons = {}

local function connectGodChar(char)
    local hum = char:WaitForChild("Humanoid")
    local c1 = hum:GetPropertyChangedSignal("Health"):Connect(function()
        if Settings.GodMode and hum.Health < hum.MaxHealth then
            hum.Health = hum.Health + (hum.MaxHealth - hum.Health) * 100
        end
    end)
    local c2 = hum.OnTakeDamage:Connect(function(damage)
        if Settings.GodMode then
            hum.MaxHealth = hum.MaxHealth + damage
            hum.Health = hum.Health + damage
        end
    end)
    table.insert(godCons, c1)
    table.insert(godCons, c2)
end

local function toggleGodMode()
    for _, c in pairs(godCons) do c:Disconnect() end
    godCons = {}
    if Settings.GodMode then
        if LocalPlayer.Character then connectGodChar(LocalPlayer.Character) end
        table.insert(godCons, LocalPlayer.CharacterAdded:Connect(connectGodChar))
    end
end

-- ===== Instant Respawn =====
local respawnCons = {}

local function toggleInstantRespawn()
    for _, c in pairs(respawnCons) do c:Disconnect() end
    respawnCons = {}
    if Settings.InstantRespawn then
        local c1 = LocalPlayer.CharacterAdded:Connect(function(char)
            local hum = char:WaitForChild("Humanoid")
            local c2 = hum.Died:Connect(function()
                task.wait(0.1)
                if Settings.InstantRespawn then LocalPlayer:LoadCharacter() end
            end)
            table.insert(respawnCons, c2)
        end)
        table.insert(respawnCons, c1)
    end
end

-- ===== Kill Aura =====
local kaConn

local function getRemote()
    if Settings.KillAuraRemote == "" then return nil end
    local r = ReplicatedStorage:FindFirstChild(Settings.KillAuraRemote)
    if not r then r = LocalPlayer:FindFirstChild(Settings.KillAuraRemote) end
    if not r then
        for _, v in Workspace:GetDescendants() do
            if v.Name == Settings.KillAuraRemote and v:IsA("RemoteEvent") then return v end
        end
    end
    return r
end

local function getTargets()
    local t = {}
    for _, plr in Players:GetPlayers() do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                table.insert(t, {Humanoid = hum, RootPart = root, IsPlayer = true})
            end
        end
    end
    if Settings.KillAuraNPC then
        for _, m in Workspace:GetDescendants() do
            if m:IsA("Model") and not Players:GetPlayerFromCharacter(m) then
                local hum = m:FindFirstChildOfClass("Humanoid")
                local root = m:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 then
                    table.insert(t, {Humanoid = hum, RootPart = root, IsPlayer = false})
                end
            end
        end
    end
    return t
end

local function toggleKillAura()
    if kaConn then kaConn:Disconnect() end
    if Settings.KillAura then
        kaConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local myRoot = char:FindFirstChild("HumanoidRootPart")
            if not myRoot then return end
            local targets = getTargets()
            local remote = getRemote()
            for _, target in pairs(targets) do
                local dist = (myRoot.Position - target.RootPart.Position).Magnitude
                if dist <= Settings.KillAuraRange then
                    if target.IsPlayer then
                        target.Humanoid:TakeDamage(Settings.KillAuraDamage)
                    else
                        if remote then
                            local args = {}
                            local argStr = Settings.KillAuraRemoteArgs:gsub("%s+", "")
                            for _, a in pairs(argStr:split(",")) do
                                if a == "target" then table.insert(args, target.RootPart)
                                elseif a == "damage" then table.insert(args, Settings.KillAuraDamage)
                                elseif a == "humanoid" then table.insert(args, target.Humanoid) end
                            end
                            if #args == 0 then args = {target.RootPart, Settings.KillAuraDamage} end
                            pcall(function() remote:FireServer(unpack(args)) end)
                        else
                            target.Humanoid.Health = math.max(0, target.Humanoid.Health - Settings.KillAuraDamage)
                        end
                    end
                end
            end
        end)
    end
end

-- ===== Kill Mobs =====
local kmConn

local function toggleKillMobs()
    if kmConn then kmConn:Disconnect() end
    if Settings.KillMobs then
        kmConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local folder = Workspace:FindFirstChild("Mobs")
            if not folder then return end
            for _, mob in folder:GetChildren() do
                local mobRoot = mob:FindFirstChild("HumanoidRootPart")
                local mobHum = mob:FindFirstChildOfClass("Humanoid")
                if mobRoot and mobHum and mobHum.Health > 0 then
                    if (root.Position - mobRoot.Position).Magnitude < 25 then
                        pcall(function()
                            ReplicatedStorage.Events.Attack:FireServer(mobHum)
                        end)
                    end
                end
            end
        end)
    end
end

-- ===== Auto Chop =====
local acConn

local function toggleAutoChop()
    if acConn then acConn:Disconnect() end
    if Settings.AutoChop then
        acConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local folder = Workspace:FindFirstChild("Trees")
            if not folder then return end
            for _, tree in folder:GetChildren() do
                local main = tree:FindFirstChild("Main")
                if main and (root.Position - main.Position).Magnitude < 20 then
                    pcall(function()
                        ReplicatedStorage.Events.Chop:FireServer(tree)
                    end)
                end
            end
        end)
    end
end

-- ===== Noclip =====
local noclipConn

local function toggleNoclip()
    if noclipConn then noclipConn:Disconnect() end
    if Settings.Noclip then
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, p in char:GetDescendants() do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end
end

-- ===== ForceField =====
local function updateForceField()
    if Settings.ForceField and LocalPlayer.Character then
        if not LocalPlayer.Character:FindFirstChild("ForceField") then
            Instance.new("ForceField", LocalPlayer.Character)
        end
    elseif LocalPlayer.Character then
        local ff = LocalPlayer.Character:FindFirstChild("ForceField")
        if ff then ff:Destroy() end
    end
end

-- ===== AutoClick =====
local acClickConn

local function isMouseOverUI()
    local mouse = LocalPlayer:GetMouse()
    local guis = CoreGui:GetGuiObjectsAtPosition(mouse.X, mouse.Y)
    for _, g in guis do
        if g:IsA("ScreenGui") and (g.Name == "MKRA_Hub" or g.Name == "FlyButton") then
            return true
        end
    end
    return false
end

local function toggleAutoClick()
    if acClickConn then acClickConn:Disconnect() end
    if Settings.AutoClick then
        acClickConn = RunService.RenderStepped:Connect(function()
            if not isMouseOverUI() then
                VirtualUser:ClickButton1(Vector2.new(0, 0))
            end
        end)
    end
end

-- ===== ESP =====
local espCons = {}

local function updateESP()
    for _, c in pairs(espCons) do c:Disconnect() end
    espCons = {}
    if Settings.ESP then
        for _, plr in Players:GetPlayers() do
            if plr ~= LocalPlayer and plr.Character then
                local hl = Instance.new("Highlight")
                hl.Name = "VIP_ESP"
                hl.Adornee = plr.Character
                hl.FillColor = Color3.fromRGB(255, 0, 0)
                hl.FillTransparency = 0.5
                hl.OutlineColor = Color3.new(1, 1, 1)
                hl.Parent = plr.Character
                local c = plr.CharacterAdded:Connect(function(ch)
                    task.wait(0.5)
                    local newHl = hl:Clone()
                    newHl.Adornee = ch
                    newHl.Parent = ch
                end)
                table.insert(espCons, c)
            end
        end
    else
        for _, plr in Players:GetPlayers() do
            if plr.Character then
                local hl = plr.Character:FindFirstChild("VIP_ESP")
                if hl then hl:Destroy() end
            end
        end
    end
end

Players.PlayerAdded:Connect(function(plr)
    if Settings.ESP then
        plr.CharacterAdded:Wait()
        updateESP()
    end
end)

-- ===== Hitbox =====
task.spawn(function()
    while task.wait(0.5) do
        if Settings.HitboxSize > 2 then
            for _, plr in Players:GetPlayers() do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = plr.Character.HumanoidRootPart
                    hrp.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
                    hrp.Transparency = 0.7
                end
            end
        end
    end
end)

-- ===== Teleport =====
local function teleportToMouse()
    local mouse = LocalPlayer:GetMouse()
    local target = mouse.Hit.p
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(target)
    end
end

-- ===== WalkSpeed =====
local function updateWalkSpeed()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local speed = math.max(Settings.SpeedBoostMultiplier * 16, Settings.WalkSpeedDirect, 16)
        LocalPlayer.Character.Humanoid.WalkSpeed = speed
    end
end

-- ===== Find Player =====
local function findPlayer(name)
    name = name:gsub("%s+", ""):lower()
    for _, plr in Players:GetPlayers() do
        if plr.Name:lower():match("^"..name) then return plr end
    end
    return nil
end

-- ===== FE Kill =====
local function executeFEKill(targetName)
    local target = findPlayer(targetName)
    if not target or not target.Character then
        notify("Kill", "រកមិនឃើញគោលដៅ", 3)
        return
    end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root or not hum then
        notify("Kill", "តួអង្គមិនទាន់រួចរាល់", 3)
        return
    end
    local savepos = root.CFrame
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not torso then
        notify("Kill", "គ្មាន Torso", 3)
        return
    end
    torso.Anchored = true
    local hat = char:FindFirstChildOfClass("Accessory")
    if not hat then
        torso.Anchored = false
        notify("Kill", "ត្រូវការមួក", 3)
        return
    end
    local tool = Instance.new("Tool", LocalPlayer.Backpack)
    local handle = hat.Handle
    handle.Parent = tool
    handle.Massless = true
    tool.GripPos = Vector3.new(0, 9e99, 0)
    tool.Parent = char
    repeat task.wait() until char:FindFirstChildOfClass("Tool")
    tool.Grip = CFrame.new()
    torso.Anchored = false
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    repeat
        task.wait()
        if not char or not char:FindFirstChild("HumanoidRootPart") then break end
        char.HumanoidRootPart.CFrame = targetRoot.CFrame
    until target.Character == nil
        or target.Character:FindFirstChild("Humanoid").Health <= 0
        or not LocalPlayer.Character
        or LocalPlayer.Character:FindFirstChild("Humanoid").Health <= 0
        or (targetRoot.Velocity.Magnitude - target.Character:FindFirstChild("Humanoid").WalkSpeed) > 50
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid"):UnequipTools()
    end
    handle.Parent = hat
    handle.Massless = false
    tool:Destroy()
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = savepos
    end
    notify("Kill", "បានសម្លាប់ ".. targetName, 3)
end

-- ===== Fling =====
local function SkidFling(targetPlayer)
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    if not Character or not Humanoid or not RootPart then
        notify("Fling", "តួអង្គមិនរួចរាល់", 3)
        return
    end
    local TCharacter = targetPlayer.Character
    if not TCharacter then return end
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")
    if RootPart.Velocity.Magnitude < 50 then
        getgenv().OldPos = RootPart.CFrame
    end
    if THumanoid and THumanoid.Sit and not Settings.FlingAll then
        notify("Fling", "កំពុងអង្គុយ", 3)
        return
    end
    if THead then
        Workspace.CurrentCamera.CameraSubject = THead
    elseif Handle then
        Workspace.CurrentCamera.CameraSubject = Handle
    elseif THumanoid then
        Workspace.CurrentCamera.CameraSubject = THumanoid
    end
    if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end
    local FPos = function(BasePart, Pos, Ang)
        RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
        Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
        RootPart.Velocity = Vector3.new(9e7, 9e8, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end
    local SFBasePart = function(BasePart)
        local TimeToWait = 2
        local Time = tick()
        local Angle = 0
        repeat
            if RootPart and THumanoid then
                if BasePart.Velocity.Magnitude < 50 then
                    Angle = Angle + 100
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)); task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)); task.wait()
                    FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)); task.wait()
                    FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)); task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0)); task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0)); task.wait()
                else
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0)); task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0)); task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0)); task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0)); task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0)); task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0)); task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0)); task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0)); task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90), 0, 0)); task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0)); task.wait()
                end
            else
                break
            end
        until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TCharacter or targetPlayer.Parent ~= Players or TCharacter ~= targetPlayer.Character or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait
    end
    workspace.FallenPartsDestroyHeight = 0 / 0
    local BV = Instance.new("BodyVelocity")
    BV.Name = "EpixVel"
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(1 / 0, 1 / 0, 1 / 0)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    if TRootPart and THead then
        if (TRootPart.Position - THead.Position).Magnitude > 5 then SFBasePart(THead) else SFBasePart(TRootPart) end
    elseif TRootPart then
        SFBasePart(TRootPart)
    elseif THead then
        SFBasePart(THead)
    elseif Handle then
        SFBasePart(Handle)
    else
        notify("Fling", "ខ្វះផ្នែក", 3)
        return
    end
    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.CurrentCamera.CameraSubject = Humanoid
    repeat
        RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
        Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
        Humanoid:ChangeState("GettingUp")
        for _, x in Character:GetChildren() do
            if x:IsA("BasePart") then
                x.Velocity, x.RotVelocity = Vector3.new(0, 0, 0), Vector3.new(0, 0, 0)
            end
        end
        task.wait()
    until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
    workspace.FallenPartsDestroyHeight = getgenv().FPDH or 500
end

local function executeFling(name)
    if name == "" then
        notify("Fling", "បញ្ចូលឈ្មោះ", 3)
        return
    end
    local target = findPlayer(name)
    if not target then
        notify("Fling", "រកមិនឃើញ", 3)
        return
    end
    SkidFling(target)
end

local function flingAllPlayers()
    for _, plr in Players:GetPlayers() do
        if plr ~= LocalPlayer and plr.Character then
            SkidFling(plr)
        end
    end
end

-- ===== Infinite Jump =====
UserInputService.JumpRequest:Connect(function()
    if Settings.InfiniteJumpOrig and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
            hum:ChangeState("Jumping")
        end
    end
end)

local function enableInfiniteJump99()
    if Settings.InfiniteJump99 then
        UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState("Jumping") end
            end
        end)
    end
end

-- ===== Rainbow Color Helper =====
local function rainbowColor(speed, offset)
    local hue = (tick() * (speed or 1) + (offset or 0)) % 1
    return Color3.fromHSV(hue, 1, 1)
end

-- ===== UI =====
local function createUI()
    if CoreGui:FindFirstChild("MKRA_Hub") then
        CoreGui.MKRA_Hub:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "MKRA_Hub"
    gui.Parent = CoreGui
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 300, 0, 450) -- slightly taller to accommodate credit
    main.Position = UDim2.new(0.5, -150, 0.5, -225)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = gui

    -- Rounded corners for main frame
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = main

    -- ===== Rainbow top bar (gradient) =====
    local topRainbow = Instance.new("Frame")
    topRainbow.Size = UDim2.new(1, 0, 0, 5)
    topRainbow.Position = UDim2.new(0, 0, 0, 0)
    topRainbow.BackgroundTransparency = 1
    topRainbow.Parent = main

    for i = 0, 59 do
        local segment = Instance.new("Frame")
        segment.Size = UDim2.new(1/60, 0, 1, 0)
        segment.Position = UDim2.new(i/60, 0, 0, 0)
        segment.BackgroundColor3 = rainbowColor(0.3, i/60)
        segment.BorderSizePixel = 0
        segment.Parent = topRainbow
    end

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.Position = UDim2.new(0, 0, 0, 5)
    titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main

    -- Rounded top corners only
    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 10)
    tbCorner.Parent = titleBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -30, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "MKRA Hub VIP v4.0"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = titleBar

    -- Minimize button (-)
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 24, 0, 24)
    minimizeBtn.Position = UDim2.new(1, -27, 0, 3)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    minimizeBtn.Text = "−"
    minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
    minimizeBtn.Font = Enum.Font.SourceSansBold
    minimizeBtn.TextSize = 18
    minimizeBtn.Parent = titleBar

    local minBtnCorner = Instance.new("UICorner")
    minBtnCorner.CornerRadius = UDim.new(0, 6)
    minBtnCorner.Parent = minimizeBtn

    -- Tab frame
    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, -10, 0, 25)
    tabFrame.Position = UDim2.new(0, 5, 0, 40)
    tabFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tabFrame.BorderSizePixel = 0
    tabFrame.Parent = main

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 8)
    tabCorner.Parent = tabFrame

    local tabs = {"Move", "Combat", "Farm", "VIP", "Visual", "Util"}
    local tabContainers = {}
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -10, 1, -95) -- adjusted to leave space for credit
    contentFrame.Position = UDim2.new(0, 5, 0, 70)
    contentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = main

    local cfCorner = Instance.new("UICorner")
    cfCorner.CornerRadius = UDim.new(0, 8)
    cfCorner.Parent = contentFrame

    for i, tabName in tabs do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1 / #tabs, 0, 1, 0)
        btn.Position = UDim2.new((i - 1) / #tabs, 0, 0, 0)
        btn.Text = tabName
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.Parent = tabFrame

        local tabBtnCorner = Instance.new("UICorner")
        tabBtnCorner.CornerRadius = UDim.new(0, 6)
        tabBtnCorner.Parent = btn

        local con = Instance.new("Frame")
        con.Size = UDim2.new(1, 0, 1, 0)
        con.BackgroundTransparency = 1
        con.Visible = false
        con.Parent = contentFrame
        tabContainers[tabName] = con

        btn.MouseButton1Click:Connect(function()
            for _, c in pairs(tabContainers) do c.Visible = false end
            con.Visible = true
        end)
    end
    tabContainers["Move"].Visible = true

    -- ===== Helper functions =====
    local function addToggle(container, text, default, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 28)
        btn.Position = UDim2.new(0, 5, 0, #container:GetChildren() * 32 + 5)
        btn.BackgroundColor3 = default and Color3.fromRGB(0, 140, 0) or Color3.fromRGB(70, 70, 70)
        btn.Text = text .. ": " .. (default and "ON" or "OFF")
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.Parent = container

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = text .. ": " .. (state and "ON" or "OFF")
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 140, 0) or Color3.fromRGB(70, 70, 70)
            callback(state)
        end)
    end

    local function addButton(container, text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 28)
        btn.Position = UDim2.new(0, 5, 0, #container:GetChildren() * 32 + 5)
        btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        btn.Text = text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.Parent = container

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(callback)
    end

    local function addTextBox(container, label, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 30)
        frame.Position = UDim2.new(0, 5, 0, #container:GetChildren() * 32 + 5)
        frame.BackgroundTransparency = 1
        frame.Parent = container
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 95, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.Parent = frame
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, -100, 1, 0)
        box.Position = UDim2.new(0, 100, 0, 0)
        box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        box.TextColor3 = Color3.new(1, 1, 1)
        box.Text = default
        box.Font = Enum.Font.Gotham
        box.TextSize = 12
        box.Parent = frame

        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 4)
        boxCorner.Parent = box

        box.FocusLost:Connect(function()
            callback(box.Text)
        end)
    end

    -- ===== Tabs content (same as before) =====
    -- Move Tab
    addToggle(tabContainers["Move"], "Fly (Joystick)", false, function(v)
        Settings.Fly = v
        if v then startFly() else stopFly() end
    end)
    addTextBox(tabContainers["Move"], "Fly Speed", "120", function(v) Settings.FlySpeed = tonumber(v) or 120 end)
    addToggle(tabContainers["Move"], "Boost (x2.5)", false, function(v) Settings.BoostMode = v end)
    addToggle(tabContainers["Move"], "Noclip", false, function(v)
        Settings.Noclip = v
        toggleNoclip()
    end)
    addTextBox(tabContainers["Move"], "WS Mult", "1", function(v)
        Settings.SpeedBoostMultiplier = tonumber(v) or 1
        updateWalkSpeed()
    end)
    addToggle(tabContainers["Move"], "Inf Jump (Orig)", false, function(v) Settings.InfiniteJumpOrig = v end)

    -- Combat Tab
    addToggle(tabContainers["Combat"], "Kill Aura", false, function(v)
        Settings.KillAura = v
        toggleKillAura()
    end)
    addTextBox(tabContainers["Combat"], "KA Range", "30", function(v) Settings.KillAuraRange = tonumber(v) or 30 end)
    addTextBox(tabContainers["Combat"], "KA Damage", "30", function(v) Settings.KillAuraDamage = tonumber(v) or 30 end)
    addToggle(tabContainers["Combat"], "KA NPCs", false, function(v)
        Settings.KillAuraNPC = v
        if Settings.KillAura then toggleKillAura() end
    end)
    addTextBox(tabContainers["Combat"], "Remote Name", "", function(v) Settings.KillAuraRemote = v end)
    addTextBox(tabContainers["Combat"], "Args", "target,damage", function(v) Settings.KillAuraRemoteArgs = v end)
    addToggle(tabContainers["Combat"], "Kill Mobs (99)", false, function(v)
        Settings.KillMobs = v
        toggleKillMobs()
    end)
    addToggle(tabContainers["Combat"], "Hitbox", false, function(v) Settings.HitboxSize = v and 10 or 2 end)
    addToggle(tabContainers["Combat"], "AutoClick", false, function(v)
        Settings.AutoClick = v
        toggleAutoClick()
    end)
    addToggle(tabContainers["Combat"], "ForceField", false, function(v)
        Settings.ForceField = v
        updateForceField()
    end)

    -- Farm Tab
    addToggle(tabContainers["Farm"], "Auto Chop (99)", false, function(v)
        Settings.AutoChop = v
        toggleAutoChop()
    end)
    addTextBox(tabContainers["Farm"], "WalkSpeed (16-500)", "16", function(v)
        Settings.WalkSpeedDirect = math.clamp(tonumber(v) or 16, 16, 500)
        updateWalkSpeed()
    end)
    addToggle(tabContainers["Farm"], "Inf Jump (99)", false, function(v)
        Settings.InfiniteJump99 = v
        enableInfiniteJump99()
    end)

    -- VIP Tab
    addButton(tabContainers["VIP"], "Teleport to Mouse", teleportToMouse)
    addToggle(tabContainers["VIP"], "ESP", false, function(v)
        Settings.ESP = v
        updateESP()
    end)
    addButton(tabContainers["VIP"], "Heal", function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Health = LocalPlayer.Character.Humanoid.MaxHealth
        end
    end)
    addToggle(tabContainers["VIP"], "God Mode", false, function(v)
        Settings.GodMode = v
        toggleGodMode()
    end)
    addToggle(tabContainers["VIP"], "Instant Respawn", false, function(v)
        Settings.InstantRespawn = v
        toggleInstantRespawn()
    end)
    addButton(tabContainers["VIP"], "VIP Speed (100/2500)", function()
        Settings.SpeedBoostMultiplier = 100 / 16
        Settings.FlySpeed = 2500
        updateWalkSpeed()
        notify("Speed", "Walk 100, Fly 2500", 2)
    end)
    addButton(tabContainers["VIP"], "Reset Speed", function()
        Settings.SpeedBoostMultiplier = 1
        Settings.FlySpeed = 120
        updateWalkSpeed()
        notify("Speed", "Reset to default", 2)
    end)
    addButton(tabContainers["VIP"], "Spawn Cash", function()
        if ReplicatedStorage:FindFirstChild("AddMoney") then
            ReplicatedStorage.AddMoney:FireServer(999999)
        end
        notify("Cash", "សាកល្បង", 2)
    end)

    -- Kill Target Box
    local killBox = Instance.new("TextBox")
    killBox.Size = UDim2.new(1, -10, 0, 28)
    killBox.Position = UDim2.new(0, 5, 0, #tabContainers["VIP"]:GetChildren() * 32 + 5)
    killBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    killBox.TextColor3 = Color3.new(1, 1, 1)
    killBox.PlaceholderText = "ឈ្មោះគោលដៅ (Kill)"
    killBox.Text = ""
    killBox.Font = Enum.Font.Gotham
    killBox.TextSize = 12
    killBox.Parent = tabContainers["VIP"]
    local kbCorner = Instance.new("UICorner")
    kbCorner.CornerRadius = UDim.new(0, 4)
    kbCorner.Parent = killBox

    addButton(tabContainers["VIP"], "KILL (FE)", function()
        executeFEKill(killBox.Text)
    end)

    -- Fling Target Box
    local flingBox = Instance.new("TextBox")
    flingBox.Size = UDim2.new(1, -10, 0, 28)
    flingBox.Position = UDim2.new(0, 5, 0, #tabContainers["VIP"]:GetChildren() * 32 + 5)
    flingBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    flingBox.TextColor3 = Color3.new(1, 1, 1)
    flingBox.PlaceholderText = "ឈ្មោះគោលដៅ (Fling)"
    flingBox.Text = ""
    flingBox.Font = Enum.Font.Gotham
    flingBox.TextSize = 12
    flingBox.Parent = tabContainers["VIP"]
    local fbCorner = Instance.new("UICorner")
    fbCorner.CornerRadius = UDim.new(0, 4)
    fbCorner.Parent = flingBox

    addButton(tabContainers["VIP"], "FLING", function()
        executeFling(flingBox.Text)
    end)

    addToggle(tabContainers["VIP"], "Fling All", false, function(v)
        Settings.FlingAll = v
        if v then flingAllPlayers() end
    end)

    -- Visual Tab
    addTextBox(tabContainers["Visual"], "FOV (70-120)", "70", function(v)
        Workspace.CurrentCamera.FieldOfView = math.clamp(tonumber(v) or 70, 70, 120)
    end)
    addToggle(tabContainers["Visual"], "FullBright", false, function(v)
        local lighting = game:GetService("Lighting")
        if v then
            lighting.Brightness = 2
            lighting.ClockTime = 12
            lighting.FogEnd = 100000
        else
            lighting.Brightness = 0.5
            lighting.ClockTime = 0
            lighting.FogEnd = 1000
        end
    end)

    -- Util Tab
    addButton(tabContainers["Util"], "Rejoin", function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
    addButton(tabContainers["Util"], "Server Hop", function()
        local json = game:GetService("HttpService"):JSONDecode(
            game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100")
        )
        local ids = {}
        for _, v in json.data do
            if v.playing and v.id ~= game.JobId then
                table.insert(ids, v.id)
            end
        end
        if #ids > 0 then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, ids[math.random(#ids)], LocalPlayer)
        else
            notify("Hop", "រកមិនឃើញ", 3)
        end
    end)

    -- ===== Credit Label "ធ្វើដោយ Oun ka" =====
    local creditLabel = Instance.new("TextLabel")
    creditLabel.Size = UDim2.new(1, 0, 0, 20)
    creditLabel.Position = UDim2.new(0, 0, 1, -22)
    creditLabel.BackgroundTransparency = 1
    creditLabel.Text = "ធ្វើដោយ Oun ka"
    creditLabel.TextColor3 = Color3.new(1, 1, 1)
    creditLabel.Font = Enum.Font.GothamBold
    creditLabel.TextSize = 13
    creditLabel.Parent = main

    -- ===== Bottom rainbow bar =====
    local bottomRainbow = Instance.new("Frame")
    bottomRainbow.Size = UDim2.new(1, 0, 0, 5)
    bottomRainbow.Position = UDim2.new(0, 0, 1, -5)
    bottomRainbow.BackgroundTransparency = 1
    bottomRainbow.Parent = main

    for i = 0, 59 do
        local segment = Instance.new("Frame")
        segment.Size = UDim2.new(1/60, 0, 1, 0)
        segment.Position = UDim2.new(i/60, 0, 0, 0)
        segment.BackgroundColor3 = rainbowColor(0.3, i/60)
        segment.BorderSizePixel = 0
        segment.Parent = bottomRainbow
    end

    -- ===== Sparkle Particles (twinkling stars) =====
    local sparkles = {}
    for _ = 1, 12 do
        local spark = Instance.new("Frame")
        spark.Size = UDim2.new(0, 6, 0, 6)
        spark.Position = UDim2.new(math.random(), 0, math.random(), 0)
        spark.BackgroundColor3 = Color3.new(1, 1, 1)
        spark.BorderSizePixel = 0
        spark.BackgroundTransparency = 0.7
        spark.Parent = main

        local sparkCorner = Instance.new("UICorner")
        sparkCorner.CornerRadius = UDim.new(1, 0)
        sparkCorner.Parent = spark

        table.insert(sparkles, spark)
    end

    -- Coroutine for rainbow animation and sparkle twinkling
    task.spawn(function()
        while wait() do
            -- Update title, credit, minimize button colors
            local hue = (tick() * 0.5) % 1
            title.TextColor3 = Color3.fromHSV(hue, 1, 1)
            creditLabel.TextColor3 = Color3.fromHSV((hue + 0.3) % 1, 1, 1)
            minimizeBtn.BackgroundColor3 = Color3.fromHSV((hue + 0.6) % 1, 1, 0.8)

            -- Update rainbow bars
            for i, seg in ipairs(topRainbow:GetChildren()) do
                local segHue = (tick() * 0.3 + i/60) % 1
                seg.BackgroundColor3 = Color3.fromHSV(segHue, 1, 1)
            end
            for i, seg in ipairs(bottomRainbow:GetChildren()) do
                local segHue = (tick() * 0.3 + i/60) % 1
                seg.BackgroundColor3 = Color3.fromHSV(segHue, 1, 1)
            end

            -- Twinkle sparkles
            for _, spark in ipairs(sparkles) do
                local twinkle = 0.4 + 0.6 * math.abs(math.sin(tick() * 5 + spark:GetAttribute("Offset") or 0))
                spark.BackgroundTransparency = 1 - twinkle
                if spark:GetAttribute("Offset") == nil then
                    spark:SetAttribute("Offset", math.random() * 10)
                end
            end
        end
    end)

    -- ===== Minimize Functionality =====
    local restoreButton = nil

    local function minimizeUI()
        main.Visible = false
        if not restoreButton then
            restoreButton = Instance.new("TextButton")
            restoreButton.Name = "RestoreBtn"
            restoreButton.Size = UDim2.new(0, 40, 0, 40)
            restoreButton.Position = UDim2.new(main.Position.X.Scale, main.Position.X.Offset, main.Position.Y.Scale, main.Position.Y.Offset)
            restoreButton.BackgroundColor3 = Color3.fromHSV(tick() % 1, 1, 0.8)
            restoreButton.Text = "+"
            restoreButton.TextColor3 = Color3.new(1, 1, 1)
            restoreButton.Font = Enum.Font.SourceSansBold
            restoreButton.TextSize = 24
            restoreButton.Active = true
            restoreButton.Draggable = true
            restoreButton.Parent = gui

            local restCorner = Instance.new("UICorner")
            restCorner.CornerRadius = UDim.new(0, 10)
            restCorner.Parent = restoreButton

            -- Rainbow background for restore button
            task.spawn(function()
                while restoreButton and restoreButton.Parent do
                    restoreButton.BackgroundColor3 = rainbowColor(1, 0)
                    wait(0.05)
                end
            end)

            restoreButton.MouseButton1Click:Connect(function()
                main.Visible = true
                restoreButton:Destroy()
                restoreButton = nil
            end)
        else
            restoreButton.Visible = true
        end
    end

    minimizeBtn.MouseButton1Click:Connect(minimizeUI)
end

-- ===== Character Added =====
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if Settings.Fly then stopFly(); startFly() end
    if Settings.GodMode then toggleGodMode() end
    if Settings.Noclip then toggleNoclip() end
    if Settings.ESP then updateESP() end
    if Settings.KillAura then toggleKillAura() end
    if Settings.KillMobs then toggleKillMobs() end
    if Settings.AutoChop then toggleAutoChop() end
    updateWalkSpeed()
end)

-- ===== Start =====
createUI()
notify("MKRA Hub", "Loaded! ប្រើបានហើយ", 3)
