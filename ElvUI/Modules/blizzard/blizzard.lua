local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local B = E:NewModule('Blizzard', 'AceEvent-3.0', 'AceHook-3.0');
local S = E:GetModule('Skins')
E.Blizzard = B;

--No point caching anything here, but list them here for mikk's FindGlobals script
-- GLOBALS: IsAddOnLoaded, LossOfControlFrame, CreateFrame, LFRBrowseFrame, TalentMicroButtonAlert

function B:Initialize()
	self:EnhanceColorPicker()
	self:KillBlizzard()
	self:AlertMovers()
	self:PositionCaptureBar()
	self:PositionDurabilityFrame()
	self:PositionGMFrames()
	self:SkinBlizzTimers()
	self:PositionVehicleFrame()
	self:PositionTalkingHead()
	self:Handle_LevelUpDisplay_BossBanner()

	if not IsAddOnLoaded("DugisGuideViewerZ") then
		self:MoveObjectiveFrame()
	end

	if not IsAddOnLoaded("SimplePowerBar") then
		self:PositionAltPowerBar()
	end

	E:CreateMover(LossOfControlFrame, 'LossControlMover', L["Loss Control Icon"])

	CreateFrame("Frame"):SetScript("OnUpdate", function(self)
		if LFRBrowseFrame.timeToClear then
			LFRBrowseFrame.timeToClear = nil
		end
	end)
end

local function InitializeCallback()
	B:Initialize()
end

E:RegisterModule(B:GetName(), InitializeCallback)