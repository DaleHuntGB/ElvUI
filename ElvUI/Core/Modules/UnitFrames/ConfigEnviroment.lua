local E, L, V, P, G = unpack(ElvUI)
local UF = E:GetModule('UnitFrames')
local ElvUF = E.oUF

local _G = _G
local setmetatable, getfenv, setfenv = setmetatable, getfenv, setfenv
local type, unpack, select, pairs = type, unpack, select, pairs
local min, random, format = min, random, format

local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitName = UnitName
local UnitClass = UnitClass
local InCombatLockdown = InCombatLockdown
local UnregisterUnitWatch = UnregisterUnitWatch
local RegisterUnitWatch = RegisterUnitWatch
local RegisterStateDriver = RegisterStateDriver
local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE
local CLASS_SORT_ORDER = CLASS_SORT_ORDER
local MAX_RAID_MEMBERS = MAX_RAID_MEMBERS

local configEnv
local originalEnvs = {}
local overrideFuncs = {}

local attributeBlacklist = {
	showRaid = true,
	showParty = true,
	showSolo = true
}

local function createConfigEnv()
	if configEnv then return end
	configEnv = setmetatable({
		UnitPower = function (unit, displayType)
			if unit:find('target') or unit:find('focus') then
				return UnitPower(unit, displayType)
			end

			return random(1, UnitPowerMax(unit, displayType) or 1)
		end,
		UnitHealth = function(unit)
			if unit:find('target') or unit:find('focus') then
				return UnitHealth(unit)
			end

			return random(1, UnitHealthMax(unit))
		end,
		UnitName = function(unit)
			if unit:find('target') or unit:find('focus') then
				return UnitName(unit)
			end
			if E.CreditsList then
				local max = #E.CreditsList
				return E.CreditsList[random(1, max)]
			end
			return 'Test Name'
		end,
		UnitClass = function(unit)
			if unit:find('target') or unit:find('focus') then
				return UnitClass(unit)
			end

			local classToken = CLASS_SORT_ORDER[random(1, #(CLASS_SORT_ORDER))]
			return LOCALIZED_CLASS_NAMES_MALE[classToken], classToken
		end,
		Hex = function(r, g, b)
			if type(r) == 'table' then
				if r.r then r, g, b = r.r, r.g, r.b else r, g, b = unpack(r) end
			end
			return format('|cff%02x%02x%02x', r*255, g*255, b*255)
		end,
		ColorGradient = ElvUF.ColorGradient,
		_COLORS = ElvUF.colors
	}, {
		__index = _G,
		__newindex = function(_, key, value) _G[key] = value end,
	})

	overrideFuncs['classcolor'] = ElvUF.Tags.Methods['classcolor']
	overrideFuncs['name:veryshort'] = ElvUF.Tags.Methods['name:veryshort']
	overrideFuncs['name:short'] = ElvUF.Tags.Methods['name:short']
	overrideFuncs['name:medium'] = ElvUF.Tags.Methods['name:medium']
	overrideFuncs['name:long'] = ElvUF.Tags.Methods['name:long']

	overrideFuncs['healthcolor'] = ElvUF.Tags.Methods['healthcolor']
	overrideFuncs['health:current'] = ElvUF.Tags.Methods['health:current']
	overrideFuncs['health:deficit'] = ElvUF.Tags.Methods['health:deficit']
	overrideFuncs['health:current-percent'] = ElvUF.Tags.Methods['health:current-percent']
	overrideFuncs['health:current-max'] = ElvUF.Tags.Methods['health:current-max']
	overrideFuncs['health:current-max-percent'] = ElvUF.Tags.Methods['health:current-max-percent']
	overrideFuncs['health:max'] = ElvUF.Tags.Methods['health:max']
	overrideFuncs['health:percent'] = ElvUF.Tags.Methods['health:percent']

	overrideFuncs['powercolor'] = ElvUF.Tags.Methods['powercolor']
	overrideFuncs['power:current'] = ElvUF.Tags.Methods['power:current']
	overrideFuncs['power:deficit'] = ElvUF.Tags.Methods['power:deficit']
	overrideFuncs['power:current-percent'] = ElvUF.Tags.Methods['power:current-percent']
	overrideFuncs['power:current-max'] = ElvUF.Tags.Methods['power:current-max']
	overrideFuncs['power:current-max-percent'] = ElvUF.Tags.Methods['power:current-max-percent']
	overrideFuncs['power:max'] = ElvUF.Tags.Methods['power:max']
	overrideFuncs['power:percent'] = ElvUF.Tags.Methods['power:percent']
end

function UF:ForceShow(frame)
	if InCombatLockdown() then return end
	if not frame.isForced then
		frame.oldUnit = frame.unit
		frame.unit = 'player'
		frame.isForced = true
		frame.oldOnUpdate = frame:GetScript('OnUpdate')
	end

	frame:SetScript('OnUpdate', nil)
	frame.forceShowAuras = true
	UnregisterUnitWatch(frame)
	RegisterUnitWatch(frame, true)

	frame:EnableMouse(false)

	frame:Show()

	if frame.Update then
		frame:Update()
	end

	if _G[frame:GetName()..'Target'] then
		self:ForceShow(_G[frame:GetName()..'Target'])
	end

	if _G[frame:GetName()..'Pet'] then
		self:ForceShow(_G[frame:GetName()..'Pet'])
	end
end

function UF:UnforceShow(frame)
	if InCombatLockdown() then return end
	if not frame.isForced then
		return
	end
	frame.forceShowAuras = nil
	frame.isForced = nil

	-- Ask the SecureStateDriver to show/hide the frame for us
	UnregisterUnitWatch(frame)
	RegisterUnitWatch(frame)

	frame:EnableMouse(true)

	if frame.oldOnUpdate then
		frame:SetScript('OnUpdate', frame.oldOnUpdate)
		frame.oldOnUpdate = nil
	end

	frame.unit = frame.oldUnit or frame.unit

	if _G[frame:GetName()..'Target'] then
		self:UnforceShow(_G[frame:GetName()..'Target'])
	end

	if _G[frame:GetName()..'Pet'] then
		self:UnforceShow(_G[frame:GetName()..'Pet'])
	end

	if frame.Update then
		frame:Update()
	end
end

function UF:ShowChildUnits(header, ...)
	header.isForced = true

	local length = select('#', ...) -- Limit number of players shown, if Display Player option is disabled
	if not UF.isForcedHidePlayer and not header.db.showPlayer and (header.groupName == 'party' or header.groupName == 'raid') then
		UF.isForcedHidePlayer = true
		length = _G.MAX_PARTY_MEMBERS
	end

	for i=1, length do
		local frame = select(i, ...)
		frame:SetID(i)
		self:ForceShow(frame)
	end
end

function UF:UnshowChildUnits(header, ...)
	header.isForced = nil
	UF.isForcedHidePlayer = nil

	for i=1, select('#', ...) do
		local frame = select(i, ...)
		self:UnforceShow(frame)
	end
end

local function OnAttributeChanged(self)
	if not self:IsShown() or (not self:GetParent().forceShow and not self.forceShow) then return end

	local db = self.db or self:GetParent().db
	local index = not db.raidWideSorting and -4 or -(min((db.numGroups or 1) * ((db.groupsPerRowCol or 1) * 5), MAX_RAID_MEMBERS) + 1)
	if self:GetAttribute('startingIndex') ~= index then
		self:SetAttribute('startingIndex', index)
		UF:ShowChildUnits(self, self:GetChildren())
	end
end

function UF:HeaderConfig(header, configMode)
	if InCombatLockdown() then return end

	createConfigEnv()
	header.forceShow = configMode
	header.forceShowAuras = configMode
	header.isForced = configMode

	if configMode then
		for _, func in pairs(overrideFuncs) do
			if type(func) == 'function' then
				if not originalEnvs[func] then
					originalEnvs[func] = getfenv(func)
					setfenv(func, configEnv)
				end
			end
		end

		RegisterStateDriver(header, 'visibility', 'show')
	else
		for func, env in pairs(originalEnvs) do
			setfenv(func, env)
			originalEnvs[func] = nil
		end

		RegisterStateDriver(header, 'visibility', header.db.visibility)

		if header:GetScript('OnEvent') then
			header:GetScript('OnEvent')(header, 'PLAYER_ENTERING_WORLD')
		end
	end

	for i=1, #header.groups do
		local group = header.groups[i]

		if group:IsShown() then
			group.forceShow = header.forceShow
			group.forceShowAuras = header.forceShowAuras
			group:HookScript('OnAttributeChanged', OnAttributeChanged)
			if configMode then
				for key in pairs(attributeBlacklist) do
					group:SetAttribute(key, nil)
				end

				OnAttributeChanged(group)

				group:Update()
			else
				for key in pairs(attributeBlacklist) do
					group:SetAttribute(key, true)
				end

				UF:UnshowChildUnits(group, group:GetChildren())
				group:SetAttribute('startingIndex', 1)

				group:Update()
			end
		end
	end

	UF.headerFunctions[header.groupName]:AdjustVisibility(header)
end

function UF:PLAYER_REGEN_DISABLED()
	for _, header in pairs(UF.headers) do
		if header.forceShow then
			self:HeaderConfig(header)
		end
	end

	for _, frame in pairs(UF.units) do
		if frame.forceShow then
			self:UnforceShow(frame)
		end
	end

	for i=1, 8 do
		if i < 6 then
			local arena = self['arena'..i]
			if arena and arena.isForced then
				self:UnforceShow(arena)
			end
		end

		local boss = self['boss'..i]
		if boss and boss.isForced then
			self:UnforceShow(boss)
		end
	end
end

UF:RegisterEvent('PLAYER_REGEN_DISABLED')