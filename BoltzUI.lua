
-- BoltzUI.lua
return function(UILibrary, Settings, SetProperties, FOV, Snaplines, CurrentCamera, Vector2new, LocalPlayer, Teams)
    local Window = UILibrary.new(Color3.fromRGB(67, 7, 241)):LoadWindow('<font color="#4307f1">boltz</font> ware', UDim2.fromOffset(400, 279))
    local ESP = Window.NewPage("esp")
    local Aimbot = Window.NewPage("aimbot")

    local EspSettings = Settings.Esp
    local AimbotSettings = Settings.Aimbot

    local EspSettingsUI = ESP.NewSection("Esp")
    local TracerSettingsUI = ESP.NewSection("Tracers")
    local SilentAim = Aimbot.NewSection("Silent Aim")
    local AimbotSec = Aimbot.NewSection("Aimbot")

    EspSettingsUI.Toggle("Show Names", EspSettings.NamesEnabled, function(cb) EspSettings.NamesEnabled = cb end)
    EspSettingsUI.Toggle("Show Health", EspSettings.HealthEnabled, function(cb) EspSettings.HealthEnabled = cb end)
    EspSettingsUI.Toggle("Show Distance", EspSettings.DistanceEnabled, function(cb) EspSettings.DistanceEnabled = cb end)
    EspSettingsUI.Toggle("Box Esp", EspSettings.BoxEsp, function(cb)
        EspSettings.BoxEsp = cb
        SetProperties({ Box = { Visible = cb } })
    end)

    EspSettingsUI.Slider("Render Distance", { Min = 0, Max = 50000, Default = math.clamp(EspSettings.RenderDistance, 0, 50000), Step = 10 }, function(cb)
        EspSettings.RenderDistance = cb
    end)

    EspSettingsUI.Slider("Esp Size", { Min = 0, Max = 30, Default = EspSettings.Size, Step = 1 }, function(cb)
        EspSettings.Size = cb
        SetProperties({ Text = { Size = cb } })
    end)

    EspSettingsUI.ColorPicker("Esp Color", EspSettings.Color, function(cb)
        EspSettings.TeamColors = false
        EspSettings.Color = cb
        SetProperties({ Box = { Color = cb }, Text = { Color = cb }, Tracer = { Color = cb } })
    end)

    EspSettingsUI.Toggle("Team Colors", EspSettings.TeamColors, function(cb)
        EspSettings.TeamColors = cb
        if not cb then
            SetProperties({ Tracer = { Color = EspSettings.Color }, Box = { Color = EspSettings.Color }, Text = { Color = EspSettings.Color } })
        end
    end)

    EspSettingsUI.Dropdown("Teams", {"Allies", "Enemies", "All"}, function(cb)
        table.clear(EspSettings.BlacklistedTeams)
        if cb == "Enemies" then
            table.insert(EspSettings.BlacklistedTeams, LocalPlayer.Team)
        elseif cb == "Allies" then
            local all = Teams:GetTeams()
            table.remove(all, table.find(all, LocalPlayer.Team))
            EspSettings.BlacklistedTeams = all
        end
    end)

    TracerSettingsUI.Toggle("Enable Tracers", EspSettings.TracersEnabled, function(cb)
        EspSettings.TracersEnabled = cb
        SetProperties({ Tracer = { Visible = cb } })
    end)

    TracerSettingsUI.Dropdown("To", {"Head", "Torso"}, function(cb)
        AimbotSettings.Aimlock = cb == "Torso" and "HumanoidRootPart" or cb
    end)

    TracerSettingsUI.Dropdown("From", {"Top", "Bottom", "Left", "Right"}, function(cb)
        local size = CurrentCamera.ViewportSize
        local pos = cb == "Top" and Vector2new(size.X / 2, 0)
                  or cb == "Bottom" and Vector2new(size.X / 2, size.Y)
                  or cb == "Left" and Vector2new(0, size.Y / 2)
                  or Vector2new(size.X, size.Y / 2)
        EspSettings.TracerFrom = pos
        SetProperties({ Tracer = { From = pos } })
    end)

    TracerSettingsUI.Slider("Tracer Transparency", {Min = 0, Max = 1, Default = EspSettings.TracerTrancparency, Step = .1}, function(cb)
        EspSettings.TracerTrancparency = cb
        SetProperties({ Tracer = { Transparency = cb } })
    end)

    TracerSettingsUI.Slider("Tracer Thickness", {Min = 0, Max = 5, Default = EspSettings.TracerThickness, Step = .1}, function(cb)
        EspSettings.TracerThickness = cb
        SetProperties({ Tracer = { Thickness = cb } })
    end)

    SilentAim.Toggle("Silent Aim", AimbotSettings.SilentAim, function(cb) AimbotSettings.SilentAim = cb end)
    SilentAim.Toggle("Wallbang", AimbotSettings.Wallbang, function(cb) AimbotSettings.Wallbang = cb end)
    SilentAim.Dropdown("Redirect", {"Head", "Torso"}, function(cb) AimbotSettings.SilentAimRedirect = cb end)
    SilentAim.Slider("Hit Chance", {Min = 0, Max = 100, Default = AimbotSettings.SilentAimHitChance, Step = 1}, function(cb)
        AimbotSettings.SilentAimHitChance = cb
    end)

    SilentAim.Dropdown("Lock Type", {"Closest Cursor"}, function(cb)
        AimbotSettings.ClosestCharacter = false
        AimbotSettings.ClosestCursor = true
    end)

    AimbotSec.Toggle("Aimbot (M2)", AimbotSettings.Enabled, function(cb)
        AimbotSettings.Enabled = cb
        if not AimbotSettings.FirstPerson and not AimbotSettings.ThirdPerson then
            AimbotSettings.FirstPerson = true
        end
    end)

    AimbotSec.Slider("Aimbot Smoothness", {Min = 1, Max = 10, Default = AimbotSettings.Smoothness, Step = .5}, function(cb)
        AimbotSettings.Smoothness = cb
    end)

    local function sortTeams(cb)
        table.clear(AimbotSettings.BlacklistedTeams)
        if cb == "Enemies" then
            table.insert(AimbotSettings.BlacklistedTeams, LocalPlayer.Team)
        elseif cb == "Allies" then
            local all = Teams:GetTeams()
            table.remove(all, table.find(all, LocalPlayer.Team))
            AimbotSettings.BlacklistedTeams = all
        end
    end

    AimbotSec.Dropdown("Team Target", {"All"}, sortTeams)
    sortTeams("Enemies")

    AimbotSec.Dropdown("Aimlock Type", {"First Person"}, function(cb)
        AimbotSettings.ThirdPerson = false
        AimbotSettings.FirstPerson = true
    end)

    AimbotSec.Toggle("Show Fov", AimbotSettings.ShowFov, function(cb)
        AimbotSettings.ShowFov = cb
        FOV.Visible = cb
    end)

    AimbotSec.ColorPicker("Fov Color", AimbotSettings.FovColor, function(cb)
        AimbotSettings.FovColor = cb
        FOV.Color = cb
        Snaplines.Color = cb
    end)

    AimbotSec.Slider("Fov Size", {Min = 0, Max = 500, Default = AimbotSettings.FovSize, Step = 5}, function(cb)
        AimbotSettings.FovSize = cb
        FOV.Radius = cb
    end)

    AimbotSec.Toggle("Enable Snaplines", AimbotSettings.Snaplines, function(cb)
        AimbotSettings.Snaplines = cb
    end)

    return Window
end
