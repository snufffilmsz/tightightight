task.spawn(function()
    local ScriptContext = game:GetService("ScriptContext")
    local function DisableErrorConnections()
        for _, V in pairs(getconnections(ScriptContext.Error)) do
            V:Disable()
        end
    end
    DisableErrorConnections()
    while task.wait(0.1) do
        DisableErrorConnections()
    end
end)

local Framework = require(game:GetService("ReplicatedFirst"):WaitForChild("Framework"))
Framework:WaitForLoaded()

local Libraries = {
    Bullets = Framework.require("Libraries", "Bullets"),
    Raycasting = Framework.require("Libraries", "Raycasting"),
    Cameras = Framework.require("Libraries", "Cameras"),
    Network = Framework.require("Libraries", "Network"),
}
local Classes = {
    Players = Framework.require("Classes", "Players"),
}

local Repo = 'https://raw.githubusercontent.com/snufffilmsz/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(Repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(Repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(Repo .. 'addons/SaveManager.lua'))()

ThemeManager.BuiltInThemes.Default = { 1, game:GetService("HttpService"):JSONDecode('{"FontColor":"ffffff","MainColor":"1c1c1c","AccentColor":"c90808","BackgroundColor":"141414","OutlineColor":"010000"}') }
Library.AccentColor = Color3.fromHex("c90808")

local Window = Library:CreateWindow({
    Title = 'stealth.rip',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2,
})

local Tabs = {
    Combat = Window:AddTab('Combat'),
    UI_Settings = Window:AddTab('UI Settings'),
}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local Configuration = {
    Combat = {
        SilentAim = {
            SilentAim = false,
            BulletTracers = false,
            BulletTracersColor = Color3.fromRGB(255, 255, 255),
            UseFOV = false,
            FOVColor = Color3.fromRGB(255, 0, 0),
            FOVRadius = 100,
            UsePrediction = false,
            Accuracy = 1,
        },
        Gunmods = {
            ChangeRecoil = false,
            Dampener = 0,
            UnlockFiremodes = false,
            ForceSuppress = false,
            CanEquipInVehicle = false,
            ChangeFireRate = false,
            FireRate = 1,
        },
        HitboxExpander = {
            Enabled = false,
            Size = 1.15,
            Transparency = 0,
        },
        InstantBullet = {
            InstantBullet = false,
        },
    },
}

local PlayerClass = Classes.Players.get()
local Globals = Framework.Configs.Globals
local ProjectileGravity = Globals.ProjectileGravity
local ProjectileSpeed = 1000

local OriginalRecoil = {}
local OriginalFireModes = {}

local Functions = {}

function Functions:HookCharacter(Character) -- [skidded rewrite this niggaa]
    local OldEquip = Character.Equip
    Character.Equip = function(Self, Item, ...)
        if Item.FireConfig and Item.FireConfig.MuzzleVelocity then
            ProjectileSpeed = Item.FireConfig.MuzzleVelocity * Globals.MuzzleVelocityMod
        end
        return OldEquip(Self, Item, ...)
    end
end

if PlayerClass.Character then
    Functions:HookCharacter(PlayerClass.Character)
end

PlayerClass.CharacterAdded:Connect(function(Character)
    Functions:HookCharacter(Character)
end)

local LastPositions = {}
local LastTimes = {}

function Functions:Trajectory(pp, pv, pa, tp, tv, ta, s)
    local rp = tp - pp
    local rv = tv - pv
    local ra = ta - pa
    local t0, t1, t2, t3 = solve(
        dot(ra, ra) / 4,
        dot(ra, rv),
        dot(ra, rp) + dot(rv, rv) - s * s,
        2 * dot(rp, rv),
        dot(rp, rp)
    )
    if t0 and t0 > 0 then
        return ra * t0 / 2 + tv + rp / t0, t0
    elseif t1 and t1 > 0 then
        return ra * t1 / 2 + tv + rp / t1, t1
    elseif t2 and t2 > 0 then
        return ra * t2 / 2 + tv + rp / t2, t2
    elseif t3 and t3 > 0 then
        return ra * t3 / 2 + tv + rp / t3, t3
    end
end

function Functions:CalculateTrajectory(Origin, Target)
    if not Target then return Origin end

    local CurrentTime = tick()
    
    if not LastPositions[Target] then
        LastPositions[Target] = Target.Position
        LastTimes[Target] = CurrentTime
        return Target.Position
    end

    local TimeDelta = CurrentTime - LastTimes[Target]
    local TargetVelocity = (Target.Position - LastPositions[Target]) / TimeDelta
    
    local Distance = (Target.Position - Origin).Magnitude
    local TimeToHit = Distance / ProjectileSpeed
    local PredictedPos = Origin + (TargetVelocity * TimeToHit)

    local DeltaDistance = (PredictedPos - Origin).Magnitude
    local FinalSpeed = (ProjectileSpeed ^ 2.005) * TimeToHit + (ProjectileSpeed ^ 1.5) * math.log(DeltaDistance + 1)
    local FinalTime = TimeToHit + (DeltaDistance / (FinalSpeed + 0.005))
    
    local PredictedPosition = Target.Position + (TargetVelocity * FinalTime)

    local curve = Functions:Trajectory(Origin, Vector3.new(), Vector3.new(0, -(game:GetService("Workspace").Gravity / 2), 0), PredictedPosition, TargetVelocity, Vector3.new(), ProjectileSpeed)
    if curve then
        PredictedPosition = Origin + curve
    end

    if Configuration.Combat.SilentAim.UsePrediction then
        local Accuracy = Configuration.Combat.SilentAim.Accuracy or 1
        PredictedPosition = Origin:Lerp(PredictedPosition, Accuracy)
    end

    LastPositions[Target] = Target.Position
    LastTimes[Target] = CurrentTime

    return PredictedPosition
end

function Functions:Beam(startPos, endPos)
    if not Configuration.Combat.SilentAim.BulletTracers then return end

    local attachment0 = Instance.new("Attachment")
    attachment0.Position = startPos
    attachment0.Parent = workspace.Terrain

    local attachment1 = Instance.new("Attachment")
    attachment1.Position = endPos
    attachment1.Parent = workspace.Terrain

    local beam = Instance.new("Beam")
    beam.Attachment0 = attachment0
    beam.Attachment1 = attachment1
    beam.FaceCamera = true
    beam.Width0 = 1.007
    beam.Width1 = 0.7
    beam.Color = ColorSequence.new(Configuration.Combat.SilentAim.BulletTracersColor)
    beam.Texture = "rbxassetid://446111271"
    beam.TextureMode = Enum.TextureMode.Wrap
    beam.TextureLength = 3
    beam.TextureSpeed = 3.05
    beam.LightEmission = 1
    beam.LightInfluence = 1
    beam.Parent = workspace.Terrain

    game:GetService("Debris"):AddItem(attachment0, 2.5)
    game:GetService("Debris"):AddItem(attachment1, 2.5)
    game:GetService("Debris"):AddItem(beam, 2.5)
end


function Functions:GetTarget()
    if not Configuration.Combat.SilentAim.SilentAim then
        return nil
    end

    local CurrentTarget = nil
    local MaximumDistance = 2000

    for _, V in pairs(Players:GetPlayers()) do
        if V ~= LocalPlayer then
            if V.Character and V.Character:FindFirstChild("Head") then
                local Position, OnScreen = Camera:WorldToScreenPoint(V.Character:FindFirstChild("Head").Position)
                if OnScreen then
                    local Distance = (Vector2.new(Position.X, Position.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                    if Configuration.Combat.SilentAim.UseFOV and Distance > Configuration.Combat.SilentAim.FOVRadius then
                        return
                    end
                    if Distance < MaximumDistance then
                        CurrentTarget = V.Character:FindFirstChild("Head")
                        MaximumDistance = Distance
                    end
                end
            end
        end
    end
    return CurrentTarget
end

function Functions:GunHook(OldFire, Self, ...)
    local Args = { ... }
    local Target = Functions:GetTarget()
    
    if Target then
        local StartPos = Args[4]
        local AimPoint
        if Configuration.Combat.SilentAim.UsePrediction then
            AimPoint = Functions:CalculateTrajectory(StartPos, Target)
        else
            AimPoint = Target.Position
        end
        Args[5] = (AimPoint - StartPos).Unit
        Functions:Beam(StartPos, AimPoint)
    else
        local DefaultPosition = Args[4] + Args[5] * 100
        Functions:Beam(Args[4], DefaultPosition)
    end
    
    return OldFire(Self, unpack(Args))
end

local OldFire; OldFire = hookfunction(Libraries.Bullets.Fire, function(Self, ...)
    return Functions:GunHook(OldFire, Self, ...)
end)

function Functions:StoreOriginalRecoil()
    local Guns = game:GetService("ReplicatedStorage").ItemData["Firearms\013"]
    for i, V in pairs(Guns:GetChildren()) do
        local Gun = require(V)
        local Recoil = require(V["Recoil Data\013"])

        OriginalRecoil[V.Name] = {
            KickUpForce = Recoil.KickUpForce,
            KickUpBounce = Recoil.KickUpBounce,
            KickUpSpeed = Recoil.KickUpSpeed,
            KickUpGunInfluence = Recoil.KickUpGunInfluence,
            KickUpCameraInfluence = Recoil.KickUpCameraInfluence,
            RaiseInfluence = Recoil.RaiseInfluence,
            RaiseBounce = Recoil.RaiseBounce,
            RaiseSpeed = Recoil.RaiseSpeed,
            RaiseForce = Recoil.RaiseForce,
            ShiftGunInfluence = Recoil.ShiftGunInfluence,
            ShiftBounce = Recoil.ShiftBounce,
            ShiftCameraInfluence = Recoil.ShiftCameraInfluence,
            ShiftForce = Recoil.ShiftForce,
        }
    end
end

function Functions:StoreOriginalFireModes()
    local Guns = game:GetService("ReplicatedStorage").ItemData["Firearms\013"]
    for i, V in pairs(Guns:GetChildren()) do
        local Gun = require(V)

        OriginalFireModes[V.Name] = Gun.FireModes
    end
end

function Functions:UpdateRecoil()
    local Guns = game:GetService("ReplicatedStorage").ItemData["Firearms\013"]
    for i, V in pairs(Guns:GetChildren()) do
        local Gun = require(V)
        local Recoil = require(V["Recoil Data\013"])
        setreadonly(Recoil, false)

        local Dampener = Configuration.Combat.Gunmods.Dampener / 100
        Recoil.KickUpForce = OriginalRecoil[V.Name].KickUpForce * (1 - Dampener)
        Recoil.KickUpBounce = OriginalRecoil[V.Name].KickUpBounce * (1 - Dampener)
        Recoil.KickUpSpeed = OriginalRecoil[V.Name].KickUpSpeed * (1 - Dampener)
        Recoil.KickUpGunInfluence = OriginalRecoil[V.Name].KickUpGunInfluence * (1 - Dampener)
        Recoil.KickUpCameraInfluence = OriginalRecoil[V.Name].KickUpCameraInfluence * (1 - Dampener)
        Recoil.RaiseInfluence = OriginalRecoil[V.Name].RaiseInfluence * (1 - Dampener)
        Recoil.RaiseBounce = OriginalRecoil[V.Name].RaiseBounce * (1 - Dampener)
        Recoil.RaiseSpeed = OriginalRecoil[V.Name].RaiseSpeed * (1 - Dampener)
        Recoil.RaiseForce = OriginalRecoil[V.Name].RaiseForce * (1 - Dampener)
        Recoil.ShiftGunInfluence = OriginalRecoil[V.Name].ShiftGunInfluence * (1 - Dampener)
        Recoil.ShiftBounce = OriginalRecoil[V.Name].ShiftBounce * (1 - Dampener)
        Recoil.ShiftCameraInfluence = OriginalRecoil[V.Name].ShiftCameraInfluence * (1 - Dampener)
        Recoil.ShiftForce = OriginalRecoil[V.Name].ShiftForce * (1 - Dampener)
        
        setreadonly(Recoil, true)
    end
end

function Functions:RevertRecoil()
    local Guns = game:GetService("ReplicatedStorage").ItemData["Firearms\013"]
    for i, V in pairs(Guns:GetChildren()) do
        local Recoil = require(V["Recoil Data\013"])
        setreadonly(Recoil, false)

        Recoil.KickUpForce = OriginalRecoil[V.Name].KickUpForce
        Recoil.KickUpBounce = OriginalRecoil[V.Name].KickUpBounce
        Recoil.KickUpSpeed = OriginalRecoil[V.Name].KickUpSpeed
        Recoil.KickUpGunInfluence = OriginalRecoil[V.Name].KickUpGunInfluence
        Recoil.KickUpCameraInfluence = OriginalRecoil[V.Name].KickUpCameraInfluence
        Recoil.RaiseInfluence = OriginalRecoil[V.Name].RaiseInfluence
        Recoil.RaiseBounce = OriginalRecoil[V.Name].RaiseBounce
        Recoil.RaiseSpeed = OriginalRecoil[V.Name].RaiseSpeed
        Recoil.RaiseForce = OriginalRecoil[V.Name].RaiseForce
        Recoil.ShiftGunInfluence = OriginalRecoil[V.Name].ShiftGunInfluence
        Recoil.ShiftBounce = OriginalRecoil[V.Name].ShiftBounce
        Recoil.ShiftCameraInfluence = OriginalRecoil[V.Name].ShiftCameraInfluence
        Recoil.ShiftForce = OriginalRecoil[V.Name].ShiftForce
        
        setreadonly(Recoil, true)
    end
end

function Functions:ForceSuppressGuns()
    local guns = game:GetService("ReplicatedStorage").ItemData["Firearms\013"]
    for i, v in pairs(guns:GetChildren()) do
        local gun = require(v)
        setreadonly(gun, false)
        gun.SuppressedByDefault = true
        setreadonly(gun, true)
    end
    print("modded")
end

function Functions:RevertSuppressGuns()
    local guns = game:GetService("ReplicatedStorage").ItemData["Firearms\013"]
    for i, v in pairs(guns:GetChildren()) do
        local gun = require(v)
        setreadonly(gun, false)
        gun.SuppressedByDefault = false
        setreadonly(gun, true)
    end
    print("reverted")
end

function Functions:UnlockFiremodes()
    local Guns = game:GetService("ReplicatedStorage").ItemData["Firearms\013"]
    local Modes = {"Semiautomatic", "Burst", "Automatic"}
    
    for i, V in pairs(Guns:GetChildren()) do
        local Gun = require(V)
        setreadonly(Gun, false)
        Gun.FireModes = Modes
        setreadonly(Gun, true)
    end
end

function Functions:RevertFiremodes()
    local Guns = game:GetService("ReplicatedStorage").ItemData["Firearms\013"]
    
    for i, V in pairs(Guns:GetChildren()) do
        local Gun = require(V)
        setreadonly(Gun, false)
        Gun.FireModes = OriginalFireModes[V.Name]
        setreadonly(Gun, true)
    end
end

function Functions:HeadCheat()
    local function SetHeadSize(head, size, transparency)
        pcall(function()
            head.Size = Vector3.new(size, size, size)
            head.Transparency = transparency
            head.CanCollide = true
        end)
    end

    local function ResetHeadSize(head)
        pcall(function()
            head.Size = Vector3.new(1.15, 1.15, 1.15)
            head.Transparency = 0
            head.CanCollide = false
        end)
    end

    local function UpdateHitboxes()
        for _, player in pairs(game:GetService('Players'):GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
                if Configuration.Combat.HitboxExpander.Enabled then
                    SetHeadSize(player.Character.Head, Configuration.Combat.HitboxExpander.Size, Configuration.Combat.HitboxExpander.Transparency / 100)
                else
                    ResetHeadSize(player.Character.Head)
                end
            end
        end
    end

    local function OnPlayerAdded(player)
        player.CharacterAdded:Connect(function(character)
            character:WaitForChild("Head")
            UpdateHitboxes()
        end)
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            OnPlayerAdded(player)
        end
    end

    Players.PlayerAdded:Connect(OnPlayerAdded)

    local oldIndex = nil
    oldIndex = hookmetamethod(game, "__index", function(self, index)
        if Configuration.Combat.HitboxExpander.Enabled and tostring(self) == "Head" and index == "Size" then
            return Vector3.new(1.15, 1.15, 1.15)
        end
        return oldIndex(self, index)
    end)

    RunService.RenderStepped:Connect(UpdateHitboxes)

    Workspace.ChildAdded:Connect(function(child)
        if child:IsA("Model") and child:FindFirstChild("Head") and Players:GetPlayerFromCharacter(child) ~= LocalPlayer then
            SetHeadSize(child:FindFirstChild("Head"), Configuration.Combat.HitboxExpander.Size, Configuration.Combat.HitboxExpander.Transparency / 100)
        end
    end)

    local mt = getrawmetatable(game)
    local old_index = mt.__index
    local old_newindex = mt.__newindex

    setreadonly(mt, false)

    mt.__index = newcclosure(function(self, key)
        if not checkcaller() then
            if key == "Scale" and self:IsA("SpecialMesh") and self.Parent and self.Parent.Name == "Head" then
                return Vector3.new(1, 1, 1)
            elseif key == "Size" and self.Name == "Head" then
                local character = self.Parent
                if character and character:IsA("Model") and Players:GetPlayerFromCharacter(character) ~= LocalPlayer then
                    return Vector3.new(1.15, 1.15, 1.15)
                end
            end
        end
        return old_index(self, key)
    end)

    mt.__newindex = newcclosure(function(self, key, value)
        if not checkcaller() then
            if key == "Scale" and self:IsA("SpecialMesh") and self.Parent and self.Parent.Name == "Head" then
                return
            elseif key == "Size" and self.Name == "Head" then
                local character = self.Parent
                if character and character:IsA("Model") and Players:GetPlayerFromCharacter(character) ~= LocalPlayer then
                    return
                end
            end
        end
        return old_newindex(self, key, value)
    end)

    setreadonly(mt, true)
end

function Functions:InstantBullet(Value)
    local Framework = require(game:GetService("ReplicatedFirst").Framework)
    local Remote = getupvalue(Framework.Libraries.Network.Send, 2)

    setupvalue(Framework.Libraries.Network.Send, 1, function(a, ...)
        local args = {...}
        if args[1] == "Bullet Impact" then
            wait(0.2)
        end
        Remote:FireServer(unpack(args))
    end)

    local BulletClone = table.clone(Framework.Libraries.Bullets)
    local OldFire = Framework.Libraries.Bullets.Fire

    local RunService = game:GetService("RunService")
    local originalWait = RunService.Heartbeat.Wait

    local function newWait(self, ...)
        return 0.016666666666666667
    end

    setupvalue(getupvalues(OldFire)[4], 8, {Heartbeat={Wait=newWait}})
end

local FOVCircle = Drawing.new("Circle")
function Functions:UpdateFOVCircle()
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = Configuration.Combat.SilentAim.FOVRadius
    FOVCircle.Color = Configuration.Combat.SilentAim.FOVColor
    FOVCircle.Visible = Configuration.Combat.SilentAim.UseFOV
    FOVCircle.Filled = false
    FOVCircle.Transparency = 1
    FOVCircle.NumSides = 64
    FOVCircle.Thickness = 1
end

RunService.RenderStepped:Connect(function()
    Functions:UpdateFOVCircle()
end)

do
    local SilentAim = Tabs.Combat:AddLeftGroupbox('silent aim')
    SilentAim:AddToggle('SilentAim', {
        Text = 'enabled',
        Default = false,
        Callback = function(Value)
            Configuration.Combat.SilentAim.SilentAim = Value
        end
    }):AddKeyPicker('SilentAimKeybind', {
        Default = 'nil',
        NoUI = false,
        Text = 'silent aim',
        Mode = 'Toggle',
        Callback = function(Value)
            Configuration.Combat.SilentAim.SilentAim = not Configuration.Combat.SilentAim.SilentAim
            Toggles.SilentAim:SetValue(Configuration.Combat.SilentAim.SilentAim)
        end
    })
    SilentAim:AddToggle('InstantBullet', {
        Text = 'instant bullet',
        Default = false,
        Callback = function(Value)
            Configuration.Combat.InstantBullet.Enabled = Value
            Functions:InstantBullet(Value)
        end
    })
    SilentAim:AddToggle('BulletTracers', {
        Text = 'bullet tracers',
        Default = false,
        Callback = function(Value)
            Configuration.Combat.SilentAim.BulletTracers = Value
        end
    }):AddColorPicker('BulletTracersColor', {
        Default = Color3.fromRGB(255, 255, 255),
        Title = 'bullet tracers color',
        Callback = function(Value)
            Configuration.Combat.SilentAim.BulletTracersColor = Value
        end
    })
    
    SilentAim:AddToggle('UseFOV', {
        Text = 'use fov',
        Default = false,
        Callback = function(Value)
            Configuration.Combat.SilentAim.UseFOV = Value
        end
    }):AddColorPicker('FOVColor', {
        Default = Color3.fromRGB(255, 0, 0),
        Title = 'fov color',
        Callback = function(Value)
            Configuration.Combat.SilentAim.FOVColor = Value
        end
    })
    SilentAim:AddSlider('FOVRadius', {
        Text = 'fov radius',
        Default = 0,
        Min = 1,
        Max = 300,
        Rounding = 0,
        Callback = function(Value)
            Configuration.Combat.SilentAim.FOVRadius = Value
        end
    })

    SilentAim:AddToggle('UsePrediction', {
        Text = 'prediction',
        Default = false,
        Callback = function(Value)
            Configuration.Combat.SilentAim.UsePrediction = Value
        end
    })
    SilentAim:AddSlider('Accuracy', {
        Text = 'accuracy %',
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,
        Callback = function(Value)
            Configuration.Combat.SilentAim.Accuracy = Value / 100
        end
    })

    local Gunmods = Tabs.Combat:AddRightGroupbox('gun mods')
    Gunmods:AddToggle('UnlockFiremodes', {
        Text = 'unlock firemodes',
        Default = false,
        Callback = function(Value)
            Configuration.Combat.Gunmods.UnlockFiremodes = Value
            if Value then
                Functions:StoreOriginalFireModes()
                Functions:UnlockFiremodes()
            else
                Functions:RevertFiremodes()
            end
        end
    })
    Gunmods:AddToggle('ForceSuppress', {
        Text = 'force suppress',
        Default = false,
        Callback = function(Value)
            Configuration.Combat.Gunmods.ForceSuppress = Value
            if Value then
                Functions:ForceSuppressGuns()
            else
                Functions:RevertSuppressGuns()
            end
        end
    })
    Gunmods:AddToggle('NoSpread', {
        Text = 'no spread',
        Default = false,
        Callback = function(Value)
            Configuration.Combat.Gunmods.NoSpread = Value
            Functions:ToggleNoSpread(Value)
        end
    })
    Gunmods:AddToggle('ChangeRecoil', {
        Text = 'custom recoil',
        Default = false,
        Callback = function(Value)
            Configuration.Combat.Gunmods.ChangeRecoil = Value
            if Value then
                Functions:StoreOriginalRecoil()
                Functions:UpdateRecoil()
            else
                Functions:RevertRecoil()
            end
        end
    })
    Gunmods:AddSlider('Dampener', {
        Text = 'recoil dampener %',
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,
        Callback = function(Value)
            Configuration.Combat.Gunmods.Dampener = Value
            if Configuration.Combat.Gunmods.ChangeRecoil then
                Functions:UpdateRecoil()
            end
        end
    })
    local HitboxExpander = Tabs.Combat:AddRightGroupbox('hitbox expander')
    HitboxExpander:AddToggle('Enabled', {
        Text = 'enabled',
        Default = false,
        Callback = function(Value)
            Configuration.Combat.HitboxExpander.Enabled = Value
        end
    })
    HitboxExpander:AddSlider('Size', {
        Text = 'size %',
        Default = 1,
        Min = 1,
        Max = 40,
        Rounding = 0,
        Callback = function(Value)
            Configuration.Combat.HitboxExpander.Size = Value
        end
    })
    HitboxExpander:AddSlider('Transparency', {
        Text = 'transparency %',
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,
        Callback = function(Value)
            Configuration.Combat.HitboxExpander.Transparency = Value
        end
    })
end

Library.KeybindFrame.Visible = true
Library:OnUnload(function()
    print('unloaded')
    Library.Unloaded = true
end)

local MenuGroup = Tabs.UI_Settings:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })
Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('MyScriptHub')
SaveManager:SetFolder('MyScriptHub/specific-game')
SaveManager:BuildConfigSection(Tabs.UI_Settings)
ThemeManager:ApplyToTab(Tabs.UI_Settings)
SaveManager:LoadAutoloadConfig()
