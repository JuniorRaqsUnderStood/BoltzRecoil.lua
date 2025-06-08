if (not game:IsLoaded()) then
    game.Loaded:Wait();
end

local UILibrary = loadstring(game:HttpGet("loadstring(game:HttpGet("https://raw.githubusercontent.com/JuniorRaqsUnderstood/script/main/BoltzWare.lua"))()"))();

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
local lower = string.lower
local upper = string.upper
local random = math.random

local DefaultSettings = {
    Esp = {
        NamesEnabled = true,
        DisplayNamesEnabled = false,
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
        Color = Color3.fromRGB(19, 130, 226),
        OutlineColor = Color3new(),
        TracerTo = "Head",
        BlacklistedTeams = {}
    },
    Aimbot = {
        Enabled = false,
        SilentAim = false,
        Wallbang = false,
        ShowFov = false,
        Snaplines = true,
        ThirdPerson = false,
        FirstPerson = false,
        ClosestCharacter = false,
        ClosestCursor = true,
        Smoothness = 1,
        SilentAimHitChance = 100,
        FovThickness = 1,
        FovTransparency = 1,
        FovSize = 150,
        FovColor = Color3new(1, 1, 1),
        Aimlock = "Head",
        SilentAimRedirect = "Head",
        BlacklistedTeams = {}
    },
    WindowPosition = UDim2.new(0.5, -200, 0.5, -139);

    Version = 1.2
}

local EncodeConfig, DecodeConfig;
do
    local deepsearchset;
    deepsearchset = function(tbl, ret, value)
        if (type(tbl) == 'table') then
            local new = {}
            for i, v in next, tbl do
                new[i] = v
                if (type(v) == 'table') then
                    new[i] = deepsearchset(v, ret, value);
                end
                if (ret(i, v)) then
                    new[i] = value(i, v);
                end
            end
            return new
        end
    end

    DecodeConfig = function(Config)
        local DecodedConfig = deepsearchset(Config, function(Index, Value)
            return type(Value) == "table" and (Value.HSVColor or Value.Position);
        end, function(Index, Value)
            local Color = Value.HSVColor
            local Position = Value.Position
            if (Color) then
                return Color3.fromHSV(Color.H, Color.S, Color.V);
            end
            if (Position and Position.Y and Position.X) then
                return UDim2.new(UDim.new(Position.X.Scale, Position.X.Offset), UDim.new(Position.Y.Scale, Position.Y.Offset));
            else
                return DefaultSettings.WindowPosition;
            end
        end);
        return DecodedConfig
    end

    EncodeConfig = function(Config)
        local ToHSV = Color3new().ToHSV
        local EncodedConfig = deepsearchset(Config, function(Index, Value)
            return typeof(Value) == "Color3" or typeof(Value) == "UDim2"
        end, function(Index, Value)
            local Color = typeof(Value) == "Color3"
            local Position = typeof(Value) == "UDim2"
            if (Color) then
                local H, S, V = ToHSV(Value);
                return { HSVColor = { H = H, S = S, V = V } };
            end
            if (Position) then
                return { Position = {
                    X = { Scale = Value.X.Scale, Offset = Value.X.Offset };
                    Y = { Scale = Value.Y.Scale, Offset = Value.Y.Offset }
                } };
            end
        end)
        return EncodedConfig
    end
end

local GetConfig = function()
    local read, data = pcall(readfile, "boltzware.json");
    local canDecode, config = pcall(HttpService.JSONDecode, HttpService, data);
    if (read and canDecode) then
        local Decoded = DecodeConfig(config);
        if (Decoded.Version ~= DefaultSettings.Version) then
            local Encoded = HttpService:JSONEncode(EncodeConfig(DefaultSettings));
            writefile("boltzware.json", Encoded);
            return DefaultSettings;
        end
        return Decoded;
    else
        local Encoded = HttpService:JSONEncode(EncodeConfig(DefaultSettings));
        writefile("boltzware.json", Encoded);
        return DefaultSettings
    end
end

local Settings = GetConfig();

local MainUI = UILibrary.new(Color3.fromRGB(255, 79, 87));
local Window = MainUI:LoadWindow('<font color="#ffff00">BoltzWare</font>', UDim2.fromOffset(400, 279));

while wait(5) do
    Settings.WindowPosition = Window.GetPosition();
    local Encoded = HttpService:JSONEncode(EncodeConfig(Settings));
    writefile("boltzware.json", Encoded);
end
