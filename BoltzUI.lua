local MainUI = UILibrary.new(Color3.fromRGB(180, 0, 255)) -- Purple theme
local Window = MainUI:LoadWindow("BoltzWare", UDim2.fromOffset(420, 300))

local ESPPage = Window.NewPage("ESP")
local AimbotPage = Window.NewPage("Aimbot")

local EspSec = ESPPage.NewSection("ESP Settings")
local TracerSec = ESPPage.NewSection("Tracers")

local SilentSec = AimbotPage.NewSection("Silent Aim")
local AimSec = AimbotPage.NewSection("Aimbot")

-- ESP Toggles
EspSec.Toggle("Names", EspSettings.NamesEnabled, function(v) EspSettings.NamesEnabled = v end)
EspSec.Toggle("Health", EspSettings.HealthEnabled, function(v) EspSettings.HealthEnabled = v end)
EspSec.Toggle("Distance", EspSettings.DistanceEnabled, function(v) EspSettings.DistanceEnabled = v end)
EspSec.Toggle("Box", EspSettings.BoxEsp, function(v) EspSettings.BoxEsp = v end)
EspSec.Toggle("Team Colors", EspSettings.TeamColors, function(v) EspSettings.TeamColors = v end)
EspSec.Slider("Render Distance", {Min=0, Max=50000, Default=EspSettings.RenderDistance, Step=100}, function(v) EspSettings.RenderDistance = v end)
EspSec.Slider("Text Size", {Min=8, Max=30, Default=EspSettings.Size, Step=1}, function(v) EspSettings.Size = v end)
EspSec.ColorPicker("ESP Color", EspSettings.Color, function(v) 
    EspSettings.Color = v 
    -- Apply to all drawings if not using team colors
end)

-- Tracers
TracerSec.Toggle("Tracers", EspSettings.TracersEnabled, function(v) EspSettings.TracersEnabled = v end)
TracerSec.Slider("Tracer Thickness", {Min=0.5, Max=5, Default=EspSettings.TracerThickness, Step=0.1}, function(v) EspSettings.TracerThickness = v end)

-- Silent Aim
SilentSec.Toggle("Silent Aim", AimbotSettings.SilentAim, function(v) AimbotSettings.SilentAim = v end)
SilentSec.Toggle("Wallbang", AimbotSettings.Wallbang, function(v) AimbotSettings.Wallbang = v end)
SilentSec.Slider("Hit Chance", {Min=0, Max=100, Default=AimbotSettings.SilentAimHitChance, Step=5}, function(v) AimbotSettings.SilentAimHitChance = v end)

-- Aimbot
AimSec.Toggle("Aimbot (Hold M2)", AimbotSettings.Enabled, function(v) AimbotSettings.Enabled = v end)
AimSec.Slider("Smoothness", {Min=1, Max=10, Default=AimbotSettings.Smoothness, Step=0.5}, function(v) AimbotSettings.Smoothness = v end)
AimSec.Toggle("Show FOV", AimbotSettings.ShowFov, function(v) AimbotSettings.ShowFov = v; FOV.Visible = v end)
AimSec.Slider("FOV Size", {Min=0, Max=800, Default=AimbotSettings.FovSize, Step=5}, function(v) -- Now goes below 75
    AimbotSettings.FovSize = v
    FOV.Radius = v
end)
AimSec.ColorPicker("FOV Color", AimbotSettings.FovColor, function(v)
    AimbotSettings.FovColor = v
    FOV.Color = v
    Snaplines.Color = v
end)
AimSec.Toggle("Snaplines", AimbotSettings.Snaplines, function(v) AimbotSettings.Snaplines = v end)

-- Save config every 5s
Window.SetPosition(Settings.WindowPosition)

while wait(5) do
    Settings.WindowPosition = Window.GetPosition()
    writefile("boltzware.json", HttpService:JSONEncode(EncodeConfig(Settings)))
end
