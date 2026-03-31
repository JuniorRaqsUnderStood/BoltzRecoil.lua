if (not game:IsLoaded()) then
    game.Loaded:Wait();
end

local UILibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/JuniorRaqsUnderStood/BoltzRecoil.lua/main/BoltzUI.lua"))();

local PlaceId = game.PlaceId

local Players = game:GetService("Players");
local HttpService = game:GetService("HttpService");
local Workspace = game:GetService("Workspace");
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService");

local CurrentCamera = Workspace.CurrentCamera
local WorldToViewportPoint = CurrentCamera.WorldToViewportPoint
local GetPartsObscuringTarget = CurrentCamera.GetPartsObscuringTarget

local Inset = game:GetService("GuiService"):GetGuiInset().Y

local FindFirstChild = game.FindFirstChild
local FindFirstChildWhichIsA = game.FindFirstChildWhichIsA
local IsA = game.IsA
local Vector2new = Vector2.new
local Vector3new = Vector3.new
local CFramenew = CFrame.new
local Color3new = Color3.new

local Tfind = table.find
local create = table.create
local format = string.format
local floor = math.floor
local gsub = string.gsub
local sub = string.sub
local random = math.random

local DefaultSettings = {
    Esp = {
        NamesEnabled = true,
        DistanceEnabled = true,
        HealthEnabled = true,
        TracersEnabled = false,
        BoxEsp = false,
        TeamColors = true,
        Thickness = 1.5,
        TracerThickness = 1.6,
        Transparency = .9,
        TracerTrancparency = .7,
        Size = 16,
        RenderDistance = 9e9,
        Color = Color3.fromRGB(180, 0, 255), -- Purple
        OutlineColor = Color3new(),
        BlacklistedTeams = {}
    },
    Aimbot = {
        Enabled = false,
        SilentAim = false,
        Wallbang = false,
        ShowFov = false,
        Snaplines = true,
        ThirdPerson = false,
        FirstPerson = true,
        ClosestCursor = true,
        Smoothness = 1,
        SilentAimHitChance = 100,
        FovThickness = 1,
        FovTransparency = 1,
        FovSize = 150,
        FovColor = Color3.fromRGB(180, 0, 255), -- Purple
        Aimlock = "Head",
        BlacklistedTeams = {}
    },
    WindowPosition = UDim2.new(0.5, -200, 0.5, -139);
    Version = 1.3
}

-- Config Encoding/Decoding (kept from original)
local EncodeConfig, DecodeConfig;
do
    local deepsearchset;
    deepsearchset = function(tbl, ret, value)
        if type(tbl) == 'table' then
            local new = {}
            for i, v in next, tbl do
                new[i] = v
                if type(v) == 'table' then
                    new[i] = deepsearchset(v, ret, value);
                end
                if ret(i, v) then
                    new[i] = value(i, v);
                end
            end
            return new
        end
    end

    DecodeConfig = function(Config)
        return deepsearchset(Config, function(i,v) return type(v)=="table" and (v.HSVColor or v.Position) end, function(i,v)
            if v.HSVColor then
                return Color3.fromHSV(v.HSVColor.H, v.HSVColor.S, v.HSVColor.V)
            elseif v.Position then
                return UDim2.new(UDim.new(v.Position.X.Scale, v.Position.X.Offset), UDim.new(v.Position.Y.Scale, v.Position.Y.Offset))
            end
            return DefaultSettings.WindowPosition
        end)
    end

    EncodeConfig = function(Config)
        local ToHSV = Color3new().ToHSV
        return deepsearchset(Config, function(i,v) return typeof(v)=="Color3" or typeof(v)=="UDim2" end, function(i,v)
            if typeof(v)=="Color3" then
                local h,s,val = ToHSV(v)
                return {HSVColor = {H=h,S=s,V=val}}
            elseif typeof(v)=="UDim2" then
                return {Position = {X={Scale=v.X.Scale,Offset=v.X.Offset}, Y={Scale=v.Y.Scale,Offset=v.Y.Offset}}}
            end
        end)
    end
end

local GetConfig = function()
    local success, data = pcall(readfile, "boltzware.json")
    if success then
        local canDecode, config = pcall(HttpService.JSONDecode, HttpService, data)
        if canDecode then
            local decoded = DecodeConfig(config)
            if decoded.Version ~= DefaultSettings.Version then
                writefile("boltzware.json", HttpService:JSONEncode(EncodeConfig(DefaultSettings)))
                return DefaultSettings
            end
            return decoded
        end
    end
    local encoded = HttpService:JSONEncode(EncodeConfig(DefaultSettings))
    writefile("boltzware.json", encoded)
    return DefaultSettings
end

local Settings = GetConfig()
local EspSettings = Settings.Esp
local AimbotSettings = Settings.Aimbot

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local MouseVector = Vector2new(Mouse.X, Mouse.Y)
local Characters = {}

local Drawings = {}

local FOV = Drawing.new("Circle")
FOV.Color = AimbotSettings.FovColor
FOV.Thickness = AimbotSettings.FovThickness
FOV.Transparency = AimbotSettings.FovTransparency
FOV.Filled = false
FOV.Radius = AimbotSettings.FovSize

local Snaplines = Drawing.new("Line")
Snaplines.Color = AimbotSettings.FovColor
Snaplines.Thickness = 0.1
Snaplines.Transparency = 1
Snaplines.Visible = AimbotSettings.Snaplines

table.insert(Drawings, FOV)
table.insert(Drawings, Snaplines)

-- Player Handling (same logic, simplified)
local function HandlePlayer(Player)
    if Player == LocalPlayer then return end

    local Text = Drawing.new("Text")
    Text.Color = EspSettings.Color
    Text.Outline = true
    Text.Size = EspSettings.Size
    Text.Transparency = EspSettings.Transparency
    Text.Center = true

    local Tracer = Drawing.new("Line")
    Tracer.Color = EspSettings.Color
    Tracer.Thickness = EspSettings.TracerThickness
    Tracer.Transparency = EspSettings.TracerTrancparency
    Tracer.From = Vector2new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y)

    local Box = Drawing.new("Quad")
    Box.Thickness = EspSettings.Thickness
    Box.Transparency = EspSettings.Transparency
    Box.Filled = false
    Box.Color = EspSettings.Color

    Drawings[Player] = {Text = Text, Tracer = Tracer, Box = Box}

    Player.CharacterAdded:Connect(function() Characters[Player] = Player.Character end)
    Player.CharacterRemoving:Connect(function()
        Characters[Player] = nil
        local d = Drawings[Player]
        if d then
            d.Text.Visible = false
            d.Box.Visible = false
            d.Tracer.Visible = false
        end
    end)
end

for _, Player in ipairs(Players:GetPlayers()) do
    HandlePlayer(Player)
end
Players.PlayerAdded:Connect(HandlePlayer)

-- Simplified GetClosest (only Closest Cursor + Head)
local function GetClosestPlayerAndRender()
    MouseVector = Vector2new(Mouse.X, Mouse.Y + Inset)
    local Closest = {}
    local ClosestDist = math.huge

    if AimbotSettings.ShowFov then
        FOV.Position = MouseVector
        FOV.Visible = true
    else
        FOV.Visible = false
    end

    local LocalRoot = Characters[LocalPlayer] and Characters[LocalPlayer]:FindFirstChild("HumanoidRootPart")

    for Player, Character in pairs(Characters) do
        if Player == LocalPlayer then continue end

        local PlayerDrawings = Drawings[Player]
        if not PlayerDrawings then continue end

        local Head = Character:FindFirstChild("Head") -- Locked to Head
        if not Head then
            PlayerDrawings.Text.Visible = false
            PlayerDrawings.Box.Visible = false
            PlayerDrawings.Tracer.Visible = false
            continue
        end

        local Pos, OnScreen = WorldToViewportPoint(CurrentCamera, Head.Position)
        local ScreenPos = Vector2new(Pos.X, Pos.Y)
        local Dist = (MouseVector - ScreenPos).Magnitude
        local WorldDist = LocalRoot and (Head.Position - LocalRoot.Position).Magnitude or math.huge

        if WorldDist > EspSettings.RenderDistance then
            PlayerDrawings.Text.Visible = false
            PlayerDrawings.Box.Visible = false
            PlayerDrawings.Tracer.Visible = false
            continue
        end

        -- ESP Rendering
        local Humanoid = Character:FindFirstChildWhichIsA("Humanoid") or {Health=0, MaxHealth=0}

        PlayerDrawings.Text.Text = string.format("%s\n[%d]%s",
            EspSettings.NamesEnabled and Player.Name or "",
            EspSettings.DistanceEnabled and math.floor(WorldDist) or "",
            EspSettings.HealthEnabled and string.format(" [%d/%d]", math.floor(Humanoid.Health), math.floor(Humanoid.MaxHealth)) or ""
        )
        PlayerDrawings.Text.Position = Vector2new(Pos.X, Pos.Y - 40)

        if EspSettings.TracersEnabled then
            PlayerDrawings.Tracer.To = ScreenPos
            PlayerDrawings.Tracer.Visible = true
        else
            PlayerDrawings.Tracer.Visible = false
        end

        PlayerDrawings.Box.Visible = EspSettings.BoxEsp
        PlayerDrawings.Text.Visible = true

        -- Aimbot target (Closest Cursor only)
        if AimbotSettings.ShowFov and Dist <= FOV.Radius and OnScreen and Dist < ClosestDist then
            ClosestDist = Dist
            Closest = {Character, ScreenPos, Player, Head}
            if AimbotSettings.Snaplines then
                Snaplines.Visible = true
                Snaplines.From = MouseVector
                Snaplines.To = ScreenPos
            else
                Snaplines.Visible = false
            end
        end
    end

    return unpack(Closest)
end

-- Aimbot Logic (M2 hold)
local Locked = false
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 and AimbotSettings.Enabled then
        Locked = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Locked = false
    end
end)

local ClosestCharacter, Vector, Player, AimlockPart
RunService.RenderStepped:Connect(function()
    ClosestCharacter, Vector, Player, AimlockPart = GetClosestPlayerAndRender()

    if Locked and AimbotSettings.Enabled and ClosestCharacter and AimlockPart then
        if AimbotSettings.FirstPerson then
            if syn then
                CurrentCamera.CoordinateFrame = CFramenew(CurrentCamera.CFrame.Position, AimlockPart.Position)
            else
                mousemoverel((Vector.X - MouseVector.X) / AimbotSettings.Smoothness, (Vector.Y - MouseVector.Y) / AimbotSettings.Smoothness)
            end
        elseif AimbotSettings.ThirdPerson then
            mousemoveabs(Vector.X, Vector.Y)
        end
    end
end)

-- Silent Aim hooks (kept mostly same, simplified)
-- ... (MetaMethodHooks, Index, Namecall, FindPartOnRay hooks remain similar - omitted for brevity but included in full script if needed)

-- ================ BOLTZWARE UI ================

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
