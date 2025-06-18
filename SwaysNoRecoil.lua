
do -- bypass
	for i, v in next, getgc(true) do
		if type(v) == 'table' then
			if rawget(v, "namecallInstance") and rawget(v, "newindexInstance") and rawget(v, "indexInstance") and rawget(v, "indexEnum") and rawget(v, "namecallEnum") and rawget(v, "eqEnum") then
				rawset(v, "namecallInstance", nil)
				rawset(v, "newindexInstance", nil)
				rawset(v, "indexInstance", nil)
				rawset(v, "indexEnum", nil)
				rawset(v, "namecallEnum", nil)
				rawset(v, "eqEnum", nil)
			end
		end
	end
end

mousemoverel = mousemoverel;
-- Options = Options; (commented out due to readonly issue)
-- Drawing = Drawing; (commented out due to readonly issue)

local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService")
local Players = game:GetService("Players");
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();
local CurrentCamera = workspace.CurrentCamera;

local function NewDrawing(type, info, tbl)
	local drawing = Drawing.new(type);	
	for idx, val in info do
		drawing[idx] = val;
	end
	if (tbl) then
		table.insert(tbl, drawing);
	end
	return drawing;
end

local Framework = {
	Enabled = false;
	Triggerbot = false;
	PredictionFactor = 0.1;
	RecoilPercentage = 1;
	WallCheck = false;
	UseCamera = false;
	ClosestPart = false;
	StickyAim = false;
	Part = "Head";
	AimlockKey = "MouseButton2";
	StickyAimKey = "F";
	Smoothing = .1;
	
	Whitelist = {};
	Target = {
		Character = nil;
		Player = nil;
	};
	Keys = {};
	ESP = {
		Enabled = false;
		Running = {};
		Box = {
			Enabled = false;
			Color = Color3.new(1, 1, 1);
		};
		Name = {
			Enabled = false;
			Color = Color3.new(1, 1, 1);
		};
		Weapon = {
			Enabled = false;
			Color = Color3.new(1, 1, 1);
		};
		Distance = {
			Enabled = false;
			Color = Color3.new(1, 1, 1);
		};
		Health = {
			Enabled = false;
			Color = Color3.new(1, 1, 1);
			Thickness = 3;
		};
	};
	Drawings = {
		Circle = NewDrawing("Circle", {
			Radius = 300
		});
	};
}

local Keys = Framework.Keys;
local function IsKeyDown(str)
	return Keys[str];
end

local function WallCheck(Character, Origin, Position)
	local Params = RaycastParams.new();
	Params.FilterDescendantsInstances = {
		LocalPlayer.Character,
		Character
	};
	return (not workspace:Raycast(Origin, Position - Origin, Params));
end

local function ToViewport(Position)
	local Point, On = CurrentCamera:WorldToViewportPoint(Position);
	return Vector2.new(Point.X, Point.Y), On;
end

local function ClosestPartWithPrediction(Origin, Character, DeltaTime)
	local Distance, Point, Part = math.huge, nil, nil;
	for _, v in pairs(Character:GetChildren()) do
		if not v:IsA("BasePart") then
			continue;
		end
		local Velocity = v.Velocity;
		local ExtrapolatedPosition = v.Position + Velocity * (Framework.PredictionFactor or 0.1);
		local nPoint, On = ToViewport(ExtrapolatedPosition);
		if not On then
			continue;
		end
		local Dist = (Origin - nPoint).Magnitude;
		if Dist > Distance then
			continue;
		end
		Part = v;
		Point = nPoint;
		Distance = Dist;
	end
	return Part, Point;
end

-- This is no longer used because I've made the new function with prediction, feel free to delete it (or keep it if you need it).
local function ClosestPart(Origin, Character)
	local Distance, Point, Part = math.huge, nil, nil;
	for i, v in pairs(Character:GetChildren()) do
		if (not v:IsA("BasePart")) then
			continue;
		end
		local nPoint, On = ToViewport(v.Position);
		if (not On) then
			continue;
		end
		local Dist = (Origin - nPoint).Magnitude;
		if (Dist > Distance) then
			continue;
		end
		Part = v;
		Point = nPoint;
		Distance = Dist;
	end
	return Part, Point;
end
local function ClearESP(Info)
	for idx, connection in Info.Connections do
		connection:Disconnect();
	end
	for idx, drawing in Info.Drawings do
		drawing:Remove();
	end
end
local function GetBounds(Character)
	if (not Character) then
		return;
	end
	local Head = Character.PrimaryPart;
	if (not Head) then
		return;
	end
	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart");
	if (not HumanoidRootPart) then
		return;
	end
	local Top = Head.CFrame * CFrame.new(0, Head.Size.Y / 2, 0);
	local Bottom = HumanoidRootPart.CFrame * CFrame.new(0, -HumanoidRootPart.Size.Y * 1.5, 0);
	local TopPoint, OnP = ToViewport(Top.Position);
	if (not OnP) then
		return;
	end
	local BottomPoint, OnB = ToViewport(Bottom.Position);
	if (not OnB) then
		return;
	end

	local BoundsY = BottomPoint.Y - TopPoint.Y;
	local Bounds = Vector2.new(BoundsY / 2, BoundsY);
	return Bounds, BottomPoint - Vector2.new(Bounds.X / 2, BoundsY), Top.Position;
end
local function ESP(Player)
	local Info = {
		Connections = {},
		Drawings = {}
	};
	local Boxs = {};
	for i = 1, 3 do
		Boxs[i] = NewDrawing("Square", {}, Info.Drawings);
	end
	local Hidden = false;
	local Name = NewDrawing("Text", {
		Text = Player.Name,
		Outline = true,
		Color = Color3.new(1, 1, 1)
	}, Info.Drawings);
	local Weapon = NewDrawing("Text", {
		Outline = true,
		Color = Color3.new(1, 1, 1)
	}, Info.Drawings);
	local Distance = NewDrawing("Text", {
		Outline = true,
		Color = Color3.new(1, 1, 1)
	}, Info.Drawings);
	local Healthbar = NewDrawing("Square", {
		ZIndex = 1,
		Filled = true
	}, Info.Drawings);
	local OutlineHealthbar = NewDrawing("Square", {
		ZIndex = 2,
		Color = Color3.new(0, 0, 0)
	}, Info.Drawings);
	local BackHealthbar = NewDrawing("Square", {
		ZIndex = -1,
		Filled = true,
		Color = Color3.new(0, 0, 0)
	}, Info.Drawings);
	local ESPSettings = Framework.ESP;

	local healthinfo = ESPSettings.Health;
	local nameinfo =  ESPSettings.Name;
	local distanceinfo = ESPSettings.Distance;
	local boxinfo = ESPSettings.Box;
	local weaponinfo = ESPSettings.Weapon;
	Info.Connections[1] = RunService.RenderStepped:Connect(function()
		if (not ESPSettings.Enabled) then
			if (not Hidden) then
				Hidden = true;
				for i, v in Info.Drawings do
					v.Visible = false;
				end
			end
			return;
		end
		local Bounds, Position, TopVector3 = GetBounds(Player.Character);
		if (not Bounds) then
			if (not Hidden) then
				Hidden = true;
				for i, v in Info.Drawings do
					v.Visible = false;
				end
			end
			return;
		end
		Hidden = false;

		if (boxinfo.Enabled) then
			local Box1 = Boxs[1];
			Box1.Position = Position - Vector2.new(1, 1);
			Box1.Size = Bounds + Vector2.new(2, 2);
			Box1.Color = Color3.fromRGB(0, 0, 0);
			Box1.Visible = true;

			local Box2 = Boxs[2];
			Box2.Position = Position - Vector2.new(2, 2);
			Box2.Size = Bounds + Vector2.new(4, 4);
			Box2.Color = boxinfo.Color;
			Box2.Visible = true;

			local Box3 = Boxs[3];
			Box3.Position = Position - Vector2.new(3, 3);
			Box3.Size = Bounds + Vector2.new(6, 6);
			Box3.Color = Color3.fromRGB(0, 0, 0);
			Box3.Visible = true;
		else
			for i, v in Boxs do
				if (not v.Visible) then
					break;
				end
				v.Visible = false;
			end
		end

		if (ESPSettings.Name.Enabled) then
			local TextBounds = Name.TextBounds;
			Name.Position = Position + Vector2.new(Bounds.X / 2 - TextBounds.X / 2, -TextBounds.Y - 4);
			Name.Visible = true;
			Name.Color = nameinfo.Color;
		else
			Name.Visible = false;
		end

		local LocalCharacter = LocalPlayer.Character;
		if (ESPSettings.Distance.Enabled and LocalCharacter) then
			local TextBounds = Distance.TextBounds;
			Distance.Text = math.round((LocalCharacter.PrimaryPart.Position - TopVector3).Magnitude) .. "s"
			Distance.Position = Position + Vector2.new(Bounds.X / 2 - TextBounds.X / 2, Bounds.Y);
			Distance.Visible = true;
			Distance.Color = distanceinfo.Color;
		else
			Distance.Visible = false;
		end

		if (weaponinfo.Enabled) then
			Weapon.Visible = true;
			Weapon.Position = Position + Vector2.new(Bounds.X + 6, -5);
			Weapon.Color = weaponinfo.Color;
			local Tool = Player.Character:FindFirstChildOfClass("Tool");
			if (Tool) then
				Weapon.Text = Tool.Name;
			else
				Weapon.Text = "None";
			end
		else
			Weapon.Visible = false;
		end

		if (healthinfo.Enabled) then
			local HealthbarSize = healthinfo.Thickness;
			local HealthSize = Vector2.new(HealthbarSize, Bounds.Y + 6);
			local HealthPosition = Position - Vector2.new(HealthbarSize + 3, 3);
			local Health = Player.Character.Humanoid.Health;
			local Percent =  math.max(0, math.min(1, Health / 100));
			
			BackHealthbar.Position = HealthPosition;
			BackHealthbar.Size = HealthSize;
			BackHealthbar.Visible = true;

			OutlineHealthbar.Position = HealthPosition;
			OutlineHealthbar.Size = HealthSize;
			OutlineHealthbar.Visible = true;


			local Offset = (Bounds.Y + 6) * (1 - Percent);
			Healthbar.Position = HealthPosition + Vector2.new(0, Offset);
			Healthbar.Color = healthinfo.Color;
			Healthbar.Size = Vector2.new(HealthbarSize, (Bounds.Y + 6) * Percent);
			Healthbar.Visible = true;
		else
			Healthbar.Visible = false;
			BackHealthbar.Visible = false;
			OutlineHealthbar.Visible = false;
		end

	end)
	Framework.ESP.Running[Player] = Info;
end

local function lerp(v0, v1, t) -- wiki
	return (1 - t) * v0 + t * v1;
end;

local function Aimlock(Origin, Point)
	local Smoothing = Framework.Smoothing;
	if (not Framework.UseCamera) then
		local Diff = (Point - Origin);
		mousemoverel(Diff.X * Smoothing, Diff.Y * Smoothing);
		return;
	end
	local Origin = CurrentCamera.CFrame;
	local LookDirect = CFrame.lookAt(Origin.Position, Point);
	CurrentCamera.CFrame = Origin:Lerp(LookDirect, Framework.Smoothing);
end
local Circle = Framework.Drawings.Circle;
local function Targeting()
	local Plrs = Players:GetPlayers();
	local Distance = Circle.Radius;
	local Origin = CurrentCamera.CFrame.Position;
	local Middle = UserInputService:GetMouseLocation();
	local VisibleOnly = Framework.WallCheck;
	local Info = {
		Player = nil,
		Character = nil
	};
	local Whitelist = Framework.Whitelist;
	for i = 2, #Plrs do
		local v = Plrs[i];
		if (Whitelist[v.Name]) then
			continue;
		end
		local Character = v.Character;
		if (not Character) then
			continue;
		end
		local Head = Character.PrimaryPart; -- r6 primary part = head
		if (not Head) then
			continue;
		end
		local HeadPosition = Head.Position;
		local Point, On = ToViewport(HeadPosition);
		if (not On) then
			continue;
		end
		local Dist = (Point - Middle).Magnitude;
		if (Dist > Distance) then
			continue;
		end
		if (VisibleOnly and not WallCheck(Character, Origin, HeadPosition)) then
			continue;
		end
		Distance = Dist;
		Info.Player = v;
		Info.Character = Character;
	end
	Framework.Target = Info;
end


RunService.Heartbeat:Connect(function(DeltaTime)
	if not Framework.Enabled then
		return;
	end
	local Origin = UserInputService:GetMouseLocation();
	Circle.Position = Origin;
	if Framework.StickyAim and IsKeyDown(Framework.StickyAimKey) then
		Targeting();
	elseif not Framework.StickyAim then
		Targeting();
	end
	local Character = Framework.Target.Character;
	if not Character or not IsKeyDown(Framework.AimlockKey) then
		return;
	end
	local Part, Point = ClosestPartWithPrediction(Origin, Character, DeltaTime);
	if not Part then
		return;
	end
	if Framework.UseCamera then
		Aimlock(Origin, Part.Position + Part.Velocity * (Framework.PredictionFactor or 0.1));
	else
		Aimlock(Origin, Point);
	end
end)

do -- ESP Setup
	Players.PlayerRemoving:Connect(function(Player)
		ClearESP(Framework.ESP.Running[Player]);
		Framework.ESP.Running[Player] = nil;
	end)
	Players.PlayerAdded:Connect(function(Player)
		ESP(Player);
	end)
	for i, v in pairs(Players:GetChildren()) do
		if (v ~= LocalPlayer) then
			ESP(v);
		end
	end
end
do -- Key Handler
	local Keyboard = Enum.UserInputType.Keyboard;
	UserInputService.InputBegan:Connect(function(Key, Ignore)
		if (Ignore) then
			return;
		end
		local UIT = Key.UserInputType;
		if (UIT == Keyboard) then
			Keys[Key.KeyCode.Name] = true;
			return;
		end 
		Keys[UIT.Name] = true;
	end)
	UserInputService.InputEnded:Connect(function(Key, Ignore)
		if (Ignore) then
			return;
		end
		local UIT = Key.UserInputType;
		if (UIT == Keyboard) then
			Keys[Key.KeyCode.Name] = false;
			return;
		end 
		Keys[UIT.Name] = false;
	end)
end

do -- No Recoil
	local MathUtility = require(game:GetService("ReplicatedStorage").Modules.Utilities.Math)
	local RandomizeHook = MathUtility.Randomize2
	MathUtility.Randomize2 = function(...)
		return (RandomizeHook(...) * Framework.RecoilPercentage);
	end
end

do -- UI!
	local repo = 'https://raw.githubusercontent.com/smi9/LinoriaLib/main/'
	local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
	local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
	local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
	
	local Window = Library:CreateWindow({
		Title = 'Boltz Recoil',
		Center = true,
		AutoShow = true,
		TabPadding = 8,
		MenuFadeTime = 0.2
	})
	
	local Tabs = {
		Main = Window:AddTab('Main'),
		['UI Settings'] = Window:AddTab('UI Settings'),
	}
	
	local LeftGroupBox = Tabs.Main:AddLeftGroupbox('Combat');
	local RightGroupBox = Tabs.Main:AddRightGroupbox('ESP');
	
	do -- Combat
		LeftGroupBox:AddToggle('C_Aimlock', {
			Text = 'Aimlock',
			Default = false,
			Tooltip = 'Locks Onto Target',

			Callback = function(Value)
				Framework.Enabled = Value;
			end
		}):AddKeyPicker('C_AimKey', {
			Default = 'MB2',
			Mode = 'Hold',
			Text =  '', 
			NoUI = true, 
			ChangedCallback = function(Key)
				Framework.AimlockKey = Key.Name;
			end
		})
		LeftGroupBox:AddToggle('C_Triggerbot', {
			Text = 'Triggerbot',
			Default = false,
			Tooltip = 'Automatically Shoots',

			Callback = function(Value)
				Framework.Triggerbot = Value;
			end
		}):AddKeyPicker('C_TriggerKey', {
			Default = 'MB2',
			Mode = 'Hold',
			Text =  '', 
			NoUI = true, 
		})
		LeftGroupBox:AddSlider('C_RecoilSlider', {
			Text = 'Recoil Multiplier',
			Default = 1,
			Min = 0,
			Max = 1,
			Rounding = 1,
			Callback = function(Value)
				Framework.RecoilPercentage = Value
			end
		});
		LeftGroupBox:AddToggle('C_WallCheck', {
			Text = 'WallCheck',
			Default = false,
			Tooltip = 'Visible Only',

			Callback = function(Value)
				Framework.WallCheck = Value;
			end
		});
		LeftGroupBox:AddToggle('C_StickyAim', {
			Text = 'Sticky Aim',
			Default = false,
			Tooltip = 'Keeps A Target',

			Callback = function(Value)
				Framework.StickyAim = Value;
			end
		}):AddKeyPicker('C_StickAimKey', {
			Default = 'F',
			Mode = 'Hold',
			Text =  '', 
			NoUI = true, 
			ChangedCallback = function(Key)
				Framework.StickyAimKey = Key.Name;
			end
		});
		LeftGroupBox:AddToggle('C_UseCamera', {
			Text = 'Use Camera',
			Default = false,
			Tooltip = 'Uses Camera/Mouse',

			Callback = function(Value)
				Framework.UseCamera = Value;
			end
		});
		LeftGroupBox:AddToggle('C_ClosestPart', {
			Text = 'Closest Part',
			Default = false,
			Tooltip = 'Locks To Closest Part',
			Callback = function(Value)
				Framework.ClosestPart = Value;
			end
		});
		LeftGroupBox:AddToggle('C_ShowCircle', {
			Text = 'Show Circle',
			Default = false,
			Tooltip = 'Hides/Shows Circle',

			Callback = function(Value)
				Circle.Visible = Value;
			end
		});
		LeftGroupBox:AddSlider('C_CircleRadius', {
			Text = 'Radius',
			Default = 300,
			Min = 10,
			Max = 2000,
			Rounding = 0,
			Compact = false,
			Callback = function(Value)
				Circle.Radius = Value;
			end
		});
		LeftGroupBox:AddSlider('C_Smoothness', {
			Text = 'Smoothing',
			Default = .5,
			Min = 0.01,
			Max = 1,
			Rounding = 2,
			Compact = false,
			Callback = function(Value)
				Framework.Smoothing = Value;
			end
		});

		LeftGroupBox:AddDropdown('C_Part', {
			Values = {
				"Torso",
				"Head",
				"Left Leg",
				"Right Leg",
				"HumanoidRootPart",
				"Left Arm",
				"Right Arm"
			},
			Default = 2, -- number index of the value / string
			Multi = false, -- true / false, allows multiple choices to be selected

			Text = 'Body Part',
			Tooltip = 'Aim Part', -- Information shown when you hover over the dropdown

			Callback = function(Value)
				Framework.Part = Value;
			end
		})
		LeftGroupBox:AddDropdown('C_Whitelist', {
			SpecialType = 'Player',
			Text = 'Whitelist',
			Tooltip = 'Cant Target Player', -- Information shown when you hover over the dropdown
			Multi = true,
			Callback = function(Value)
				table.foreach(Value, function(i, v)
					print(i, typeof(i), v, typeof(v));
				end);
				Framework.Whitelist = Value;
			end
		})
	end

	do -- ESP
		RightGroupBox:AddToggle('E_Enabled', {
			Text = 'Enabled',
			Default = false,
			Tooltip = 'On/Off',
			Callback = function(Value)
				Framework.ESP.Enabled = Value;
			end
		})
		RightGroupBox:AddToggle('E_Box', {
			Text = 'Box',
			Default = false,
			Tooltip = 'On/Off',
			Callback = function(Value)
				Framework.ESP.Box.Enabled = Value;
			end
		}):AddColorPicker('E_BoxColor', {
			Default = Color3.new(1, 1, 1),
			Title = 'Box Color', 
			Transparency = 0,
			Callback = function(Value)
				Framework.ESP.Box.Color = Value;
			end
		})
		RightGroupBox:AddToggle('E_Name', {
			Text = 'Name',
			Default = false,
			Tooltip = 'On/Off',
			Callback = function(Value)
				Framework.ESP.Name.Enabled = Value;
			end
		}):AddColorPicker('E_NamePicker', {
			Default = Color3.new(1, 1, 1),
			Title = 'Name Color', 
			Transparency = 0,
			Callback = function(Value)
				Framework.ESP.Name.Color = Value;
			end
		})
		RightGroupBox:AddToggle('E_Distance', {
			Text = 'Distance',
			Default = false,
			Tooltip = 'On/Off',
			Callback = function(Value)
				Framework.ESP.Distance.Enabled = Value;
			end
		}):AddColorPicker('E_DistancePicker', {
			Default = Color3.new(1, 1, 1),
			Title = 'Distance Color', 
			Transparency = 0,
			Callback = function(Value)
				Framework.ESP.Distance.Color = Value;
			end
		})
		RightGroupBox:AddToggle('E_Weapon', {
			Text = 'Weapon',
			Default = false,
			Tooltip = 'On/Off',
			Callback = function(Value)
				Framework.ESP.Weapon.Enabled = Value;
			end
		}):AddColorPicker('E_WeaponPicker', {
			Default = Color3.new(1, 1, 1),
			Title = 'Distance Color', 
			Transparency = 0,
			Callback = function(Value)
				Framework.ESP.Weapon.Color = Value;
			end
		})
		RightGroupBox:AddToggle('E_Health', {
			Text = 'Health',
			Default = false,
			Tooltip = 'On/Off',
			Callback = function(Value)
				Framework.ESP.Health.Enabled = Value;
			end
		}):AddColorPicker('E_HealthPicker', {
			Default = Color3.new(1, 1, 1),
			Title = 'Distance Color', 
			Transparency = 0,
			Callback = function(Value)
				Framework.ESP.Health.Color = Value;
			end
		})
		RightGroupBox:AddSlider('E_HealthThickness', {
			Text = 'Health Thickness',
			Default = 3,
			Min = 3,
			Max = 20,
			Rounding = 1,
			Compact = false,
			Callback = function(Value)
				Framework.ESP.Health.Thickness = Value;
			end
		})
	end

	
	Library:SetWatermarkVisibility(false);

	local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

	MenuGroup:AddButton('Unload', function()
		Library:Unload()
	end);
	MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
		Default = 'End',
		NoUI = true,
		Text = 'Menu keybind'
	});

	Library.ToggleKeybind = Options.MenuKeybind;

	ThemeManager:SetLibrary(Library)
	SaveManager:SetLibrary(Library)

	SaveManager:IgnoreThemeSettings()

	SaveManager:SetIgnoreIndexes({
		'MenuKeybind'
	})

	ThemeManager:SetFolder('Boltz')
	SaveManager:SetFolder('Boltz/Recoil')

	SaveManager:BuildConfigSection(Tabs['UI Settings'])
	ThemeManager:ApplyToTab(Tabs['UI Settings'])
	SaveManager:LoadAutoloadConfig()
end
