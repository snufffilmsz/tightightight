local current_camera = game:GetService("Workspace").CurrentCamera
local local_player = game:GetService("Players").LocalPlayer
local run_service = game:GetService("RunService")
local players = game:GetService("Players")
local user_input_service = game:GetService("UserInputService")
local huge = math.huge
local floor = math.floor
local clamp = math.clamp
local rad = math.rad
local cos = math.cos
local sin = math.sin
local atan2 = math.atan2
local deg = math.deg
local abs = math.abs
local max = math.max
local min = math.min
local ceil = math.ceil
local pi = math.pi
local Vector2_new = Vector2.new
local Vector3_new = Vector3.new
local Color3_new = Color3.new
local Color3_fromRGB = Color3.fromRGB
local CFrame_new = CFrame.new

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function bezier(p0, p1, p2, p3, t)
    local t2 = t * t
    local mt = 1 - t
    local mt2 = mt * mt
    return p0 * mt2 * mt + 3 * p1 * mt2 * t + 3 * p2 * mt * t2 + p3 * t2 * t
end

local ESP = {
    Enabled = true,
    BoxType = "Dynamic",-- and static
    BoxEnabled = true,
    BoxColor = Color3_fromRGB(255, 255, 255),
    BoxTransparency = 0,
    HealthBarEnabled = true,
    HealthBarColor = Color3_fromRGB(0, 255, 0),
    HealthBarTransparency = 0,
    HealthBarPosition = "Left", -- left, right
    HealthBarOffset = 5,
    HealthBarBoostEnabled = true, -- ar2
    HealthBarBoostColor = Color3_fromRGB(0, 175, 0), 
    HealthTextEnabled = true,
    SkeletonEnabled = true,
    SkeletonColor = Color3_fromRGB(255, 255, 255),
    SkeletonTransparency = 0,
    NameEnabled = true,
    NameColor = Color3_fromRGB(255, 255, 255),
    NameTransparency = 0,
    DisplayNames = false,
    DistanceEnabled = true,
    DistanceColor = Color3_fromRGB(255, 255, 255),
    DistanceTransparency = 0,
    OOFArrowsEnabled = true, -- offscreen arrows
    OOFArrowsColor = Color3_fromRGB(255, 255, 255),
    OOFArrowsTransparency = 0,
    OOFArrowsRadius = 100,
    ActiveItemEnabled = true,
    ActiveItemColor = Color3_fromRGB(255, 255, 255),
    ActiveItemTransparency = 0,
    InventoryViewerEnabled = true,
    InventoryViewerKey = Enum.KeyCode.V,
    InventoryViewerMaxDistance = 1000,
    InventoryViewerColor = Color3_fromRGB(255, 255, 255),
    MaxDistance = 3300,
    MeasurementType = "Roblox", -- roblox, imperial, and metric
    HighlightVisible = false,
    VisibleColor = Color3_fromRGB(255, 166, 2),
    ChamsEnabled = true,
    ChamsVisibleColor = Color3_fromRGB(255, 0, 0),
    ChamsOccludedColor = Color3_fromRGB(0, 0, 255),
    ChamsOutlineColor = Color3_fromRGB(255, 255, 255),
    ChamsTransparency = 0.55,
    ChamsOutlineTransparency = 0.5,
}

local skeleton_order = { -- r15 oly
    ["LeftFoot"] = "LeftLowerLeg",
    ["LeftLowerLeg"] = "LeftUpperLeg",
    ["LeftUpperLeg"] = "LowerTorso",
    ["RightFoot"] = "RightLowerLeg",
    ["RightLowerLeg"] = "RightUpperLeg",
    ["RightUpperLeg"] = "LowerTorso",
    ["LeftHand"] = "LeftLowerArm",
    ["LeftLowerArm"] = "LeftUpperArm",
    ["LeftUpperArm"] = "UpperTorso",
    ["RightHand"] = "RightLowerArm",
    ["RightLowerArm"] = "RightUpperArm",
    ["RightUpperArm"] = "UpperTorso",
    ["LowerTorso"] = "UpperTorso",
    ["UpperTorso"] = "Head"
}

local weapon_ammo = { -- ar2 only
    ["M1903"] = ".30-06 Springfield",
    ["Model 788"] = ".44 Magnum",
    ["Model 788 Carbine"] = "7.62mm NATO",
    ["PSG-1"] = "7.62mm NATO",
    ["M14 DMR"] = "7.62mm NATO",
    ["M14"] = "7.62mm NATO",
    ["Dragunov SVD"] = "7.62mm Rimmed",
    ["Mosin PU"] = "7.62mm Rimmed",
    ["L96A1"] = "7.62mm NATO",
    ["M40A1"] = "7.62mm NATO",
    ["Auto-5"] = "12 Gauge Buckshot",
    ["Coach Gun"] = "12 Gauge Buckshot",
    ["Maverick 88"] = "12 Gauge Buckshot",
    ["Maverick 88 Tactical"] = "12 Gauge Buckshot",
    ["SPAS-12"] = "12 Gauge Buckshot",
    ["Boomstick Coach Gun"] = "12 Gauge Buckshot",
    ["M1 Thompson"] = ".45 ACP",
    ["M3A1"] = ".45 ACP",
    ["MP5"] = "9mm Parabellum",
    ["MP 40"] = "9mm Parabellum",
    ["Bootleg Type 37"] = "9mm Parabellum",
    ["Camp Carbine"] = "9mm Parabellum",
    ["M1 Carbine"] = ".30 Carbine",
    ["Mosin-Nagant M44"] = "7.62 Rimmed",
    ["XM177"] = "5.56mm NATO",
    ["AKS-74U"] = "5.45mm Soviet",
    ["Filtered AKS-74U"] = "5.45mm Soviet",
    ["Spetsnaz AKS-74U"] = "5.45mm Soviet",
    ["Patriot"] = "5.56mm NATO",
    ["XM177Mod1"] = "5.56mm NATO",
    ["AC-556"] = "5.56mm NATO",
    ["AK-47"] = "7.62mm Soviet",
    ["AKM"] = "7.62mm Soviet",
    ["AUG"] = "5.56mm NATO",
    ["M16A1"] = "5.56mm NATO",
    ["M16A2"] = "5.56mm NATO",
    ["AK-74"] = "5.45mm Soviet",
    ["FAL"] = "7.62mm NATO",
    ["G3"] = "7.62mm NATO",
    ["M1 Garand"] = ".30-06 Springfield",
    ["SKS"] = "7.62mm Soviet",
    ["SVT-40"] = "7.62mm Rimmed",
    ["M1918A2 BAR"] = ".30-06 Springfield",
    ["M1919A6"] = ".30-06 Springfield",
    ["M249"] = "5.56mm NATO",
    ["M60"] = "7.62mm NATO",
    ["M249 Paratrooper"] = "5.56mm NATO",
    ["PKM"] = "7.62mm Rimmed",
    ["Trooper M1919A6"] = ".30-06 Springfield",
    ["Model 29"] = ".44 Magnum",
    ["M1909 Snubnose"] = ".45 ACP",
    ["Python"] = ".357 Magnum",
    ["Desert Eagle"] = ".44 Magnum",
    ["Hi-Power"] = "9mm Parabellum",
    ["M9"] = "9mm Parabellum",
    ["M1911"] = ".45 ACP",
    ["Model 459"] = "9mm Parabellum",
    ["P38"] = "9mm Parabellum",
    ["Makarov"] = "9mm Soviet",
    ["Admiral's M9"] = "9mm Parabellum",
    ["Silent Partner M1911"] = ".45 ACP",
    ["MAC-10"] = ".45 ACP",
    ["TEC-9"] = "9mm Parabellum",
    ["Sweeper Desert Eagle"] = ".44 Magnum",
    ["Mac-10Mod1"] = ".45 ACP",
    ["MP5K"] = "9mm Parabellum",
    ["Uzi"] = "9mm Parabellum",
    ["AO-46"] = "5.45mm Soviet",
    ["Rogue UZI"] = "9mm Parabellum",
    ["Lupara"] = "12 Gauge Buckshot",
    ["Broadside Lupara"] = "12 Gauge Buckshot",
    ["Vagrant Lupara"] = "12 Gauge Buckshot",
    ["Stunted AK-47"] = "7.62mm Soviet",
    ["Obrez Mosin-Nagant"] = "7.62mm Rimmed",
    ["Winchester 1894"] = ".44 Magnum",
    ["Mini-14"] = "5.56mm NATO",
    ["Walther P38"] = "9mm Parabellum",
}

local function calculate_box(player)
    local character = player.Character
    if not character then return end
    if ESP.BoxType == "Dynamic" then
        local position, size = character:GetBoundingBox()
        local half_size = size * 0.5
        local points = {
            position * CFrame_new(half_size.X, half_size.Y, half_size.Z),
            position * CFrame_new(half_size.X, half_size.Y, -half_size.Z),
            position * CFrame_new(half_size.X, -half_size.Y, half_size.Z),
            position * CFrame_new(half_size.X, -half_size.Y, -half_size.Z),
            position * CFrame_new(-half_size.X, half_size.Y, half_size.Z),
            position * CFrame_new(-half_size.X, half_size.Y, -half_size.Z),
            position * CFrame_new(-half_size.X, -half_size.Y, half_size.Z),
            position * CFrame_new(-half_size.X, -half_size.Y, -half_size.Z)
        }
        local min_x, min_y = huge, huge
        local max_x, max_y = -huge, -huge
        local on_screen_count = 0
        for _, point in ipairs(points) do
            local screen_pos, on_screen = current_camera:WorldToViewportPoint(point.Position)
            if on_screen then
                on_screen_count = on_screen_count + 1
                min_x = min(min_x, screen_pos.X)
                min_y = min(min_y, screen_pos.Y)
                max_x = max(max_x, screen_pos.X)
                max_y = max(max_y, screen_pos.Y)
            end
        end
        if on_screen_count == 0 then return end
        local width = max_x - min_x
        local height = max_y - min_y
        return { X = floor(min_x), Y = floor(min_y), W = floor(width), H = floor(height) }
    else -- static
        local torso_cframe = character.HumanoidRootPart.CFrame
        local matrix_top = (torso_cframe.Position + Vector3_new(0, 0.3, 0)) + (torso_cframe.UpVector * 1.5) + current_camera.CFrame.UpVector
        local matrix_bottom = (torso_cframe.Position + Vector3_new(0, 0.4, 0)) - (torso_cframe.UpVector * 3)
        local top, top_is_visible = current_camera:WorldToViewportPoint(matrix_top)
        local bottom, bottom_is_visible = current_camera:WorldToViewportPoint(matrix_bottom)
        if not top_is_visible and not bottom_is_visible then return end
        local width = floor(abs(top.X - bottom.X))
        local height = floor(max(abs(bottom.Y - top.Y), width * 0.6))
        local box_size = Vector2_new(floor(max(height / 1.7, width * 1.8)), height)
        local box_position = Vector2_new(floor(top.X * 0.5 + bottom.X * 0.5 - box_size.X * 0.5), floor(min(top.Y, bottom.Y)))
        return { X = box_position.X, Y = box_position.Y, W = box_size.X, H = box_size.Y }
    end
end

local function draw(class, properties)
    local object = Drawing.new(class)
    for property, value in pairs(properties) do
        if property == "Font" and typeof(value) == "EnumItem" then
            object[property] = value.Value
        else
            object[property] = value
        end
    end
    return object
end

local function is_visible(player)
    local character = player.Character
    if not character then return false end
    local visibility_parts = {"Head", "HumanoidRootPart", "LeftFoot", "RightFoot", "LeftHand", "RightHand"}
    local ray_params = RaycastParams.new()
    ray_params.FilterType = Enum.RaycastFilterType.Blacklist
    ray_params.FilterDescendantsInstances = {local_player.Character}
    for _, part_name in ipairs(visibility_parts) do
        local part = character:FindFirstChild(part_name)
        if part then
            local raycast_result = workspace:Raycast(current_camera.CFrame.p, (part.Position - current_camera.CFrame.p).Unit * 10000, ray_params)
            if raycast_result and raycast_result.Instance:IsDescendantOf(character) then
                return true
            end
        end
    end
    return false
end

local function create_highlight(character) -- lazy i know
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillTransparency = ESP.ChamsTransparency
    highlight.Adornee = character
    highlight.Enabled = false
    highlight.Parent = character
    return highlight
end

local function update_highlight(highlight, is_visible)
    highlight.Enabled = ESP.ChamsEnabled and ESP.Enabled
    highlight.FillColor = is_visible and ESP.ChamsVisibleColor or ESP.ChamsOccludedColor
    if ESP.HighlightVisible then
        highlight.Enabled = highlight.Enabled and is_visible
    end
    highlight.OutlineColor = ESP.ChamsOutlineColor
    highlight.OutlineTransparency = ESP.ChamsOutlineTransparency
end

local highlight_instances = {}
local esp_objects = {}

run_service.RenderStepped:Connect(function()
    if not ESP.Enabled then
        for _, objects in pairs(esp_objects) do
            for _, object in pairs(objects) do
                object.Visible = false
            end
        end
        return
    end

    local viewport_size = current_camera.ViewportSize
    local viewport_center = viewport_size / 2

    for _, player in pairs(players:GetPlayers()) do
        if player == local_player then continue end
        if not player.Character or not player.Character:FindFirstChild("Humanoid") or not player.Character:FindFirstChild("HumanoidRootPart") then
            if esp_objects[player.Name] then
                for _, object in pairs(esp_objects[player.Name]) do
                    object.Visible = false
                end
            end
            continue
        end
        local distance = (player.Character.HumanoidRootPart.Position - local_player.Character.HumanoidRootPart.Position).Magnitude
        if distance > ESP.MaxDistance then
            if esp_objects[player.Name] then
                for _, object in pairs(esp_objects[player.Name]) do
                    object.Visible = false
                end
            end
            continue
        end
        local box = calculate_box(player)
        if not esp_objects[player.Name] then
            esp_objects[player.Name] = {
                box_outside = draw("Square", { Color = Color3_new(0, 0, 0), Thickness = 1, Transparency = 0.5, Filled = false }),
                box = draw("Square", { Thickness = 1, Filled = false }),
                box_inside = draw("Square", { Color = Color3_new(0, 0, 0), Thickness = 1, Transparency = 0.5, Filled = false }),
                name = draw("Text", { Center = true, Outline = true, Size = 13, Font = 2 }),
                health_bar_outside = draw("Square", { Color = Color3_new(0, 0, 0), Thickness = 1, Transparency = 0.5, Filled = true }),
                health_bar = draw("Square", { Thickness = 1, Filled = true }),
                health_bar_boost = draw("Square", { Thickness = 1, Filled = true }),
                health_text = draw("Text", { Center = true, Outline = true, Size = 13, Font = 2 }),
                distance = draw("Text", { Center = true, Outline = true, Size = 13, Font = 2 }),
                oof_arrow = draw("Triangle", { Thickness = 1, Filled = true }),
                oof_arrow_outline = draw("Triangle", { Color = Color3_new(0, 0, 0), Thickness = 1, Filled = false }),
                active_item = draw("Text", { Center = true, Outline = true, Size = 13, Font = 2 }),
                inventory_viewer = draw("Text", { Center = false, Outline = true, Size = 20, Font = Enum.Font.SourceSans, Visible = false, Position = Vector2_new(10, 350), Color = Color3_new(0, 0, 0) })
            }
            for i = 1, 6 do
                esp_objects[player.Name]["skeleton_head_" .. i] = draw("Line", { Color = ESP.SkeletonColor, Thickness = 1, Transparency = 1 - ESP.SkeletonTransparency, Visible = false })
            end
            for required, _ in next, skeleton_order do
                esp_objects[player.Name]["skeleton_".. required] = draw("Line", { Color = ESP.SkeletonColor, Transparency = 1 - ESP.SkeletonTransparency, Visible = false })
            end
        end
        if ESP.ChamsEnabled and not highlight_instances[player.Name] then
            highlight_instances[player.Name] = create_highlight(player.Character)
        end
        local objects = esp_objects[player.Name]
        if box then
            local visible = is_visible(player)
            local color = visible and ESP.VisibleColor or ESP.BoxColor
            if highlight_instances[player.Name] then
                update_highlight(highlight_instances[player.Name], visible)
            end
            if ESP.BoxEnabled then
                objects.box_outside.Position = Vector2_new(box.X - 1, box.Y - 1)
                objects.box_outside.Size = Vector2_new(box.W + 2, box.H + 2)
                objects.box_outside.Transparency = 0.5
                objects.box_outside.Visible = true
                objects.box.Position = Vector2_new(box.X, box.Y)
                objects.box.Size = Vector2_new(box.W, box.H)
                objects.box.Color = ESP.HighlightVisible and color or ESP.BoxColor
                objects.box.Transparency = 1 - ESP.BoxTransparency
                objects.box.Visible = true
                objects.box_inside.Position = Vector2_new(box.X + 1, box.Y + 1)
                objects.box_inside.Size = Vector2_new(box.W - 2, box.H - 2)
                objects.box_inside.Transparency = 0.5
                objects.box_inside.Visible = true
            else
                objects.box_outside.Visible = false
                objects.box.Visible = false
                objects.box_inside.Visible = false
            end
            if ESP.HealthBarEnabled then
                local health = game.PlaceId == 863266079 and floor(player.Stats.Health.Value) or player.Character.Humanoid.Health
                local max_health = game.PlaceId == 863266079 and 100 or player.Character.Humanoid.MaxHealth
                local health_percent = clamp(health / max_health, 0, 1)
                local bar_position = Vector2_new(box.X - (ESP.HealthBarPosition == "Left" and ESP.HealthBarOffset or -box.W - ESP.HealthBarOffset), box.Y)
                objects.health_bar_outside.Position = Vector2_new(bar_position.X - 1, bar_position.Y - 1)
                objects.health_bar_outside.Size = Vector2_new(4, box.H + 2)
                objects.health_bar_outside.Transparency = 0.5
                objects.health_bar_outside.Visible = true
                local filled_height = bezier(0, box.H * health_percent, box.H * health_percent, box.H * health_percent, health_percent)
                objects.health_bar.Position = Vector2_new(bar_position.X, bar_position.Y + box.H - filled_height)
                objects.health_bar.Size = Vector2_new(2, filled_height)
                objects.health_bar.Color = ESP.HighlightVisible and ESP.HealthBarColor:Lerp(Color3_fromRGB(255, 0, 0), 1 - health_percent) or ESP.HealthBarColor
                objects.health_bar.Transparency = 1 - ESP.HealthBarTransparency
                objects.health_bar.Visible = true
                if ESP.HealthTextEnabled and health < 90 then
                    local text_offset = ESP.HealthBarPosition == "Left" and -7 - objects.health_text.TextBounds.X or 7
                    objects.health_text.Position = Vector2_new(bar_position.X + text_offset, bar_position.Y + (box.H * (1 - health_percent)) - (objects.health_text.TextBounds.Y / 2))
                    objects.health_text.Color = ESP.HighlightVisible and ESP.HealthBarColor:Lerp(Color3_fromRGB(255, 0, 0), 1 - health_percent) or ESP.HealthBarColor
                    objects.health_text.Text = tostring(ceil(health))
                    objects.health_text.Visible = true
                else
                    objects.health_text.Visible = false
                end
                if ESP.HealthBarBoostEnabled then -- ar2
                    local boost = clamp(health - max_health, 0, 100)
                    local boost_percent = boost / max_health
                    objects.health_bar_boost.Position = Vector2_new(bar_position.X, bar_position.Y)
                    objects.health_bar_boost.Size = Vector2_new(2, box.H * boost_percent)
                    objects.health_bar_boost.Color = ESP.HighlightVisible and ESP.HealthBarBoostColor or ESP.HealthBarBoostColor
                    objects.health_bar_boost.Visible = boost > 0
                end
            end
            if ESP.InventoryViewerEnabled and game.PlaceId == 863266079 and user_input_service:IsKeyDown(ESP.InventoryViewerKey) then
                local mouse_pos = user_input_service:GetMouseLocation()
                local closest_player, closest_dist = nil, math.huge
            
                -- Find the closest player
                for _, p in pairs(players:GetPlayers()) do
                    if p ~= local_player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local pos = current_camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                        local dist = (Vector2_new(pos.X, pos.Y) - mouse_pos).Magnitude
                        if dist < closest_dist then
                            closest_player = p
                            closest_dist = dist
                        end
                    end
                end
            
                if closest_player and closest_dist <= ESP.InventoryViewerMaxDistance then
                    -- Gather player stats
                    local stats = closest_player:FindFirstChild("Stats")
                    local primary = stats and stats:FindFirstChild("Primary") and stats.Primary.Value or "None"
                    local secondary = stats and stats:FindFirstChild("Secondary") and stats.Secondary.Value or "None"
                    local primary_ammo = weapon_ammo[primary] or "nil"
                    local secondary_ammo = weapon_ammo[secondary] or "nil"
                    local health = stats and stats:FindFirstChild("Health") and stats.Health.Value or 0
                    local account_age = closest_player.AccountAge
                    local equipment = {}
                    local equipment_folder = closest_player.Character:FindFirstChild("Equipment")
                    if equipment_folder then
                        for _, item in pairs(equipment_folder:GetChildren()) do
                            table.insert(equipment, item.Name)
                        end
                    end
                    local humanoid_state = "Idle"
                    local is_cheating = "No"
                    if closest_player.Character and closest_player.Character:FindFirstChild("Humanoid") then
                        local humanoid = closest_player.Character.Humanoid
                        humanoid_state = humanoid:GetState().Name
                        if humanoid_state ~= "Seated" then
                            local velocity = closest_player.Character.HumanoidRootPart.Velocity
                            local speed = velocity.Magnitude
                            if speed > 30 then
                                is_cheating = "Yes"
                            end
                        end
                    end
                    local ping = stats and stats:FindFirstChild("Ping") and stats.Ping.Value or "nil"
            
                    -- Create and display the UI
                    local main_frame = Instance.new("Frame", core_gui)
                    main_frame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
                    main_frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    main_frame.BorderSizePixel = 0
                    main_frame.Position = UDim2.new(0.3, 0, 0.3, 0)
                    main_frame.Size = UDim2.new(0.4, 0, 0.4, 0)
                    main_frame.Visible = true -- Ensure visibility
            
                    local title = Instance.new("TextLabel", main_frame)
                    title.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
                    title.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    title.BorderSizePixel = 0
                    title.Position = UDim2.new(0.05, 0, 0.05, 0)
                    title.Size = UDim2.new(0.9, 0, 0.1, 0)
                    title.Font = Enum.Font.RobotoMono
                    title.Text = closest_player.Name .. "'s Inventory"
                    title.TextColor3 = Color3.fromRGB(255, 255, 255)
                    title.TextSize = 18
                    title.Visible = true
            
                    local info = Instance.new("TextLabel", main_frame)
                    info.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
                    info.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    info.BorderSizePixel = 0
                    info.Position = UDim2.new(0.05, 0, 0.2, 0)
                    info.Size = UDim2.new(0.9, 0, 0.7, 0)
                    info.Font = Enum.Font.RobotoMono
                    info.Text = string.format(
                        "Primary: %s\nAmmo: %s\n\nSecondary: %s\nAmmo: %s\n\nEquipment:\n%s\n\nHP: %d%%\nHP Boost: %s\nCharacter State: %s\nAccount Age: %d days\nPing: %s\nCheating: %s",
                        primary,
                        primary_ammo,
                        secondary,
                        secondary_ammo,
                        table.concat(equipment, "\n"),
                        health,
                        health > 100 and "Yes" or "No",
                        humanoid_state,
                        account_age,
                        ping,
                        is_cheating
                    )
                    info.TextColor3 = Color3.fromRGB(255, 255, 255)
                    info.TextSize = 14
                    info.TextWrapped = true
                    info.TextYAlignment = Enum.TextYAlignment.Top
                    info.Visible = true
                else
                    print("No player found within range.")
                end
            else
                objects.inventory_viewer.Visible = false
            end        
            if ESP.NameEnabled then
                objects.name.Position = Vector2_new(box.X + (box.W / 2), box.Y - 5 - objects.name.TextBounds.Y)
                objects.name.Color = ESP.HighlightVisible and color or ESP.NameColor
                objects.name.Transparency = 1 - ESP.NameTransparency
                objects.name.Text = ESP.DisplayNames and player.DisplayName or player.Name
                objects.name.Visible = true
            else
                objects.name.Visible = false
            end
            if ESP.DistanceEnabled then
                local measurement = {
                    Roblox = {div = 1, suffix = "s"},
                    Imperial = {div = 3.265, suffix = "y"},
                    Metric = {div = 3.333, suffix = "m"}
                }
                local current = measurement[ESP.MeasurementType]
                local display_distance = floor(distance / current.div)
                objects.distance.Position = Vector2_new(box.X + (box.W / 2), box.Y + box.H + 3)
                objects.distance.Color = ESP.HighlightVisible and color or ESP.DistanceColor
                objects.distance.Transparency = 1 - ESP.DistanceTransparency
                objects.distance.Text = string.format("[%d%s]", display_distance, current.suffix)
                objects.distance.Visible = true
            else
                objects.distance.Visible = false
            end
            if ESP.SkeletonEnabled then
                local head = player.Character:FindFirstChild("Head")
                if head then
                    local radius = head.Size.X / 2
                    local center_pos = head.Position
                    local camera_pos = current_camera.CFrame.Position
                    local camera_look = (camera_pos - center_pos).Unit
                    local right = Vector3_new(0, 1, 0):Cross(camera_look).Unit
                    local up = camera_look:Cross(right).Unit
                    local points = {}
                    for i = 1, 6 do
                        local angle = rad((i-1) * 60)
                        local x = cos(angle) * radius
                        local y = sin(angle) * radius
                        local point = center_pos + (right * x) + (up * y)
                        local screen_pos = current_camera:WorldToViewportPoint(point)
                        points[i] = Vector2_new(screen_pos.X, screen_pos.Y)
                    end
                    for i = 1, 6 do
                        local next_i = i % 6 + 1
                        local line = esp_objects[player.Name]["skeleton_head_" .. i]
                        line.From = points[i]
                        line.To = points[next_i]
                        line.Visible = true
                    end
                end
                for required, _ in next, skeleton_order do
                    local current = player.Character:FindFirstChild(required)
                    local next = player.Character:FindFirstChild(skeleton_order[required])
                    if current and next then
                        local current_pos = current_camera:WorldToViewportPoint(current.Position)
                        local next_pos = current_camera:WorldToViewportPoint(next.Position)
                        local line = esp_objects[player.Name]["skeleton_".. required]
                        line.From = Vector2_new(current_pos.X, current_pos.Y)
                        line.To = Vector2_new(next_pos.X, next_pos.Y)
                        line.Visible = true
                    end
                end
            end
            if ESP.ActiveItemEnabled then
                local active_items = {}
                if game.PlaceId == 863266079 then -- ar2
                    if player:FindFirstChild("Stats") then
                        local primary = player.Stats:FindFirstChild("Primary") and player.Stats.Primary.Value or ""
                        local secondary = player.Stats:FindFirstChild("Secondary") and player.Stats.Secondary.Value or ""
                        if primary ~= "" then
                            table.insert(active_items, primary)
                        end
                        if secondary ~= "" then
                            table.insert(active_items, secondary)
                        end
                    end
                elseif game.PlaceId == 286090429 then -- arsenal
                    local tool = player.Character and player.Character:FindFirstChild("Gun")
                    if tool then
                        table.insert(active_items, tostring(tool:GetAttribute("Real")))
                    end
                elseif game.PlaceId == 17625359962 then -- rivals
                    local view_models = workspace:FindFirstChild("ViewModels")
                    if view_models then
                        for _, model in ipairs(view_models:GetChildren()) do
                            if model:IsA("Model") then
                                local name_parts = string.split(model.Name, " - ")
                                if #name_parts == 3 and name_parts[1] == player.Name then
                                    table.insert(active_items, name_parts[2])
                                    break
                                end
                            end
                        end
                    end
                elseif game.PlaceId == 301549746 then -- counter blox
                    local tool = player.Character and player.Character:FindFirstChild("EquippedTool")
                    if tool and tool.Value then
                        table.insert(active_items, tostring(tool.Value))
                    end
                else -- universal
                    if player.Character then
                        local Tool = player.Character:FindFirstChildOfClass("Tool")
                        if Tool and Tool.Name then
                            table.insert(active_items, Tool.Name)
                        end
                    end
                end
            
                if #active_items > 0 then
                    for i, item in ipairs(active_items) do
                        objects["active_item_" .. i] = objects["active_item_" .. i] or draw("Text", { Center = true, Outline = true, Size = 13, Font = 2 })
                        local active_item_object = objects["active_item_" .. i]
                        active_item_object.Position = Vector2_new(box.X + (box.W / 2), box.Y + box.H + 3 + (i - 1) * (active_item_object.TextBounds.Y + 2))
                        active_item_object.Color = ESP.HighlightVisible and color or ESP.ActiveItemColor
                        active_item_object.Transparency = 1 - ESP.ActiveItemTransparency
                        active_item_object.Text = "[" .. item .. "]"
                        active_item_object.Visible = true
                    end
                    if ESP.DistanceEnabled then
                        objects.distance.Position = Vector2_new(box.X + (box.W / 2), box.Y + box.H + 3 + #active_items * (objects.active_item.TextBounds.Y + 2))
                    end
                else
                    for i = 1, #active_items do
                        if objects["active_item_" .. i] then
                            objects["active_item_" .. i].Visible = false
                        end
                    end
                    if ESP.DistanceEnabled then
                        objects.distance.Position = Vector2_new(box.X + (box.W / 2), box.Y + box.H + 3)
                    end
                end
            else
                for i = 1, #active_items do
                    if objects["active_item_" .. i] then
                        objects["active_item_" .. i].Visible = false
                    end
                end
                if ESP.DistanceEnabled then
                    objects.distance.Position = Vector2_new(box.X + (box.W / 2), box.Y + box.H + 3)
                end
            end
            objects.oof_arrow.Visible = false
            objects.oof_arrow_outline.Visible = false
            else
                if ESP.OOFArrowsEnabled then
                    local fix_ratio = 450 / ESP.OOFArrowsRadius
                    local relative = current_camera.CFrame:PointToObjectSpace(player.Character.HumanoidRootPart.Position)
                    local middle = current_camera.ViewportSize / 2
                    local degree = deg(atan2(-relative.Y, relative.X)) * pi / 180
                    local end_pos = middle + (Vector2_new(cos(degree), sin(degree))) * ESP.OOFArrowsRadius
                    local end_pos_a = middle + (Vector2_new(cos(degree + rad(2 * fix_ratio)), sin(degree + rad(2 * fix_ratio)))) * ESP.OOFArrowsRadius -- 2 * f / 3
                    local end_pos_c = middle + (Vector2_new(cos(degree - rad(2 * fix_ratio)), sin(degree - rad(2 * fix_ratio)))) * ESP.OOFArrowsRadius
                    local difference = middle - end_pos
                    objects.oof_arrow.PointA = end_pos_a
                    objects.oof_arrow.PointB = end_pos + (-difference.Unit * 15)
                    objects.oof_arrow.PointC = end_pos_c
                    objects.oof_arrow.Color = ESP.HighlightVisible and ESP.OOFArrowsColor or ESP.OOFArrowsColor
                    objects.oof_arrow.Transparency = 1 - ESP.OOFArrowsTransparency
                    objects.oof_arrow.Visible = true
                    objects.oof_arrow_outline.PointA = end_pos_a
                    objects.oof_arrow_outline.PointB = end_pos + (-difference.Unit * 15)
                    objects.oof_arrow_outline.PointC = end_pos_c
                    objects.oof_arrow_outline.Transparency = 1 - ESP.OOFArrowsTransparency
                    objects.oof_arrow_outline.Visible = true
                else
                    objects.oof_arrow.Visible = false
                    objects.oof_arrow_outline.Visible = false
                end
                for _, object in pairs(objects) do
                    if object ~= objects.oof_arrow and object ~= objects.oof_arrow_outline then
                        object.Visible = false
                    end
                end
            end
        end
        for player_name, objects in pairs(esp_objects) do
            if not players:FindFirstChild(player_name) then
                for _, object in pairs(objects) do
                    object:Remove()
                end
                esp_objects[player_name] = nil
            end
        end    
    end)
return ESP
