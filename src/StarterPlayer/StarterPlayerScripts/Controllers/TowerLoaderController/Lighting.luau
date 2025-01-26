local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

type LightingChangeType = "Lighting" | "ColorCorrectionEffect" | "BlurEffect" | "BloomEffect" | "DepthOfFieldEffect"
type LightingChangeConfig = { [string]: any } | "Default"
type LightingChangeInfo = {
	Type: LightingChangeType,
	Configuration: LightingChangeConfig,
	TweenInfo: TweenInfo,
}

local ConfigManifest: { [string]: { string } } = {
	["Lighting"] = {
		"Ambient",
		"OutdoorAmbient",
		"FogEnd",
		"FogStart",
		"FogColor",
		"ClockTime",
		"Brightness",

		"ColorShift_Bottom",
		"ColorShift_Top",
	},

	["ColorCorrectionEffect"] = {
		"Brightness",
		"Contrast",
		"Saturation",
		"TintColor",
	},
	["BlurEffect"] = {
		"Size",
	},
	["BloomEffect"] = {
		"Intensity",
		"Size",
		"Threshold",
	},
	["DepthOfFieldEffect"] = {
		"FarIntensity",
		"FocusDistance",
		"InFocusRadius",
		"NearIntensity",
	},
}

local defaultTweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local defaultLightingProperties: { [string]: { [string]: any } } = {}

local Shared = {}

function Shared.OnStart()
	_G.SetLighting = Shared.LegacyChangeLighting

	for effectName, effectProperties in ConfigManifest do
		if effectName == "Lighting" then
			continue
		end

		local effect = Lighting:FindFirstChild(`MTK{effectName}`)
		if not effect then
			local newEffect = Instance.new(effectName)
			newEffect.Name = `MTK{effectName}`
			newEffect.Parent = Lighting

			if newEffect:IsA("BlurEffect") then
				newEffect.Size = 0
			elseif newEffect:IsA("DepthOfFieldEffect") then
				newEffect.NearIntensity = 0
				newEffect.FarIntensity = 0
			elseif newEffect:IsA("BloomEffect") then
				newEffect.Intensity = 1
				newEffect.Size = 24
				newEffect.Threshold = 2
			end

			effect = newEffect
		end

		if effect and effect:IsA("PostEffect") then
			local defaultEffectProperties: { [string]: any } = {}

			for _, propertyName in effectProperties do
				defaultEffectProperties[propertyName] = effect[propertyName]
			end

			defaultLightingProperties[effectName] = defaultEffectProperties
		end

		defaultLightingProperties.Lighting = {}

		for _, lightingEffect in ConfigManifest.Lighting do
			defaultLightingProperties.Lighting[lightingEffect] = Lighting[lightingEffect]
		end

		ReplicatedStorage.ChangeLighting.Event:Connect(function(config)
			Shared:ChangeLighting(config)
		end)
	end
end

function Shared:ChangeLighting(info: LightingChangeInfo)
	local target = Lighting:FindFirstChild(`MTK{info.Type}`)
	if info.Type == "Lighting" or not target then
		target = Lighting
	end

	local tweenDictionary: { [string]: any } = (
		(info.Configuration == "Default") and defaultLightingProperties[info.Type]
		or info.Configuration :: { [string]: any }
	)

	local tween = TweenService:Create(target, info.TweenInfo, tweenDictionary)
	tween:Play()
end

function Shared:LegacyChangeLighting(config: LightingChangeConfig)
	local info: LightingChangeInfo = {
		Type = "Lighting",
		Configuration = config,
		TweenInfo = defaultTweenInfo,
	}

	Shared:ChangeLighting(info)
end

return Shared
