--=================================================================================
-- Addon: DPS_Metrics
-- Filename: CleuDisplay.lua
-- Date: 10 June, 2024
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 June, 2024
--=================================================================================
local ADDON_NAME, DPS_Metrics = ...

------------------------------------------------------------
--                  NAMESPACE LAYOUT
------------------------------------------------------------
DPS_Metrics = DPS_Metrics or {}
DPS_Metrics.Display = {}
local display = DPS_Metrics.Display

local utils     = LibStub:GetLibrary("UtilsLib")
local thread    = LibStub:GetLibrary("WoWThreads")
local L         = DPS_Metrics.Locales.L

------------------------------------------------------------
---                   code begins here                    --
------------------------------------------------------------
--[[ 
GameFontNormal
GameFontNormal
GameFontNormalLarge
GameFontNormalHuge
GameFontHighlight
GameFontHighlightSmall
GameFontHighlightLarge
GameFontHighlightHuge
GameFontDisable
GameFontDisableSmall
GameFontDisableLarge
GameFontDisableHuge
GameFontGreen
GameFontRed
GameFontWhite
GameFontDarkGraySmall
GameFontNormalLeft
GameFontNormalLeftGray
GameFontNormalLeft
GameFontNormalLeftGray
GameFontHighlightLeft
GameFontHighlightSmallLeft
GameFontHighlightSmallRight
GameFontDisableLeft
GameFontHighlightExtraSmall
GameFontHighlightSmallOutline
GameFontHighlightMedium
GameFontNormalMed3
GameFontNormalMed2
GameFontNormalMed1
]]
	-- set the color
	-- f.Text:SetTextColor( 1.0, 1.0, 1.0 )  -- white
	-- f.Text:SetTextColor( 0.0, 1.0, 0.0 )  -- green
	-- f.Text:SetTextColor( 1.0, 1.0, 0.0 )  -- yellow
	-- f.Text:SetTextColor( 0.0, 1.0, 1.0 )  -- turquoise
	-- f.Text:SetTextColor( 0.0, 0.0, 1.0 )  -- blue
	-- f.Text:SetTextColor( 1.0, 0.0, 0.0 )  -- red

	local TICKS_PER_INTERVAL = 4
	
	local framePool = {}
	
	local function createNewFrame()
		local f = CreateFrame("Frame", nil, UIParent)
		f:SetSize(5, 5)
		f:SetPoint("CENTER", 0, 0)
		f.Text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		f.Text:SetPoint("CENTER")
		f.Text:SetJustifyH("LEFT")
		f.Text:SetJustifyV("TOP")
		f.Text:SetText("")
	
		f.IsCrit = false
		f.alpha = 0.03
		f.TotalTicks = 0
		f.TicksPerFrame = TICKS_PER_INTERVAL
		f.TicksRemaining = f.TicksPerFrame
		return f
	end
	
	local function releaseFrame(f) 
		f.Text:SetText("")
		f:Hide()
		table.insert(framePool, f)
	end
	
	local function initFramePool()
		local f = createNewFrame()
		table.insert(framePool, f)
	end
	
	local function acquireFrame()
		local f = table.remove(framePool)
		if f == nil then 
			f = createNewFrame()
		end
		f:Show()
		return f
	end

	local DAMAGE_EVENT 		= 1
	local HEALING_EVENT 	= 2
	
	local DMG_STARTX = 250
	local DMG_XDELTA = 4
	local DMG_STARTY = 25
	local DMG_YDELTA = 4
	
	local HEAL_STARTX = -DMG_STARTX
	local HEAL_XDELTA = -4
	local HEAL_STARTY = DMG_STARTY
	local HEAL_YDELTA = 4
	
	local AURA_STARTX = -600
	local AURA_XDELTA = 0
	local AURA_STARTY = 200
	local AURA_YDELTA = 3
	
	local MISS_STARTX = 0
	local MISS_XDELTA = 0
	local MISS_STARTY = 100
	local MISS_YDELTA = 3
	
	local count = 0
	local function getStartingPositions(combatType)
		if combatType == DAMAGE_EVENT then 
			-- if count == 1 then
			-- 	DMG_STARTX = 70
			-- 	count = 0
			-- else
			-- 	DMG_STARTX = 50
			-- 	count = 1
			-- end
			return DMG_STARTX, DMG_XDELTA, DMG_STARTY, DMG_YDELTA
		end

		if combatType == HEALING_EVENT then
			return HEAL_STARTX, HEAL_XDELTA, HEAL_STARTY, HEAL_YDELTA
		end 
		if combatType == AURA_EVENT then
			return AURA_STARTX, AURA_XDELTA, AURA_STARTY, AURA_YDELTA
		end
		if combatType == MISS_EVENT then
			return MISS_STARTX, MISS_XDELTA, MISS_STARTY, MISS_YDELTA
		end
		return nil, nil, nil, nil
	end
	
	local function scrollText(f, startX, xDelta, startY, yDelta)
		local xPos = startX
		local yPos = startY
	
		f:SetScript("OnUpdate", 
		function(f)
			f.TicksRemaining = f.TicksRemaining - 1
			if f.TicksRemaining > 0 then
				return
			end
			f.TicksRemaining = TICKS_PER_INTERVAL
			f.TotalTicks = f.TotalTicks + 1
	
			if f.TotalTicks == 4 then 
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			elseif f.TotalTicks == 24 then
				xPos = xPos + xDelta
				yPos = yPos + yDelta
			end	
			if f.TotalTicks <= 30 then
				xPos = xPos + xDelta
				yPos = yPos + yDelta
				f:ClearAllPoints()
				f:SetPoint("CENTER", xPos, yPos)
			end
			if f.TotalTicks > 30 then
				f.TotalTicks = 0
				f.Text:SetText("")
				f:ClearAllPoints()
				f:SetPoint("CENTER", 0, 0)
				releaseFrame(f)
			end
		end)
	end
	
	local IN_COMBAT = false

	function display:setCombat( value )
		IN_COMBAT = value
	end
	function display:damageEntry( isCrit, dmgText)
		if IN_COMBAT == false then 
			return 
		end

		local f = acquireFrame()
		if f.IsCrit then
			f.Alpha = 0.9
			f.Text:SetFontObject(GameFontNormalLarge)
			-- yDelta = 6
			-- xDelta = 6
			-- xPos = xPos + 25
		else
			f.Alpha = 0.9
			f.Text:SetFontObject(GameFontNormal)
		end

		f.Text:SetTextColor(1.0, 0.0, 0.0)
		f.Text:SetText(dmgText)
	
		local startX, xDelta, startY, yDelta = getStartingPositions(DAMAGE_EVENT)
		local xPos = startX
		local yPos = startY
	
	
		f:ClearAllPoints()
		f:SetPoint("CENTER", xPos, yPos)
	
		scrollText(f, xPos, xDelta, yPos, yDelta)
	end
	
	function display:healEntry(isCrit, healText)
		if not IN_COMBAT then return end

		local f = acquireFrame()
		f.Text:SetTextColor(0.0, 1.0, 0.0)
		f.Text:SetText(healText)
		f.IsCrit = isCrit
	
		local startX, xDelta, startY, yDelta = getStartingPositions(HEALING_EVENT)
		local xPos = startX
		local yPos = startY
	
		f.Text:SetFontObject(GameFontNormal)
		if f.IsCrit then
			f.Alpha = 0.9
			f.Text:SetFontObject(GameFontNormalHuge)
			yDelta = 6
			xDelta = -6
			xPos = xPos + 25
		end
	
		f:ClearAllPoints()
		f:SetPoint("CENTER", xPos, yPos)
	
		scrollText(f, xPos, xDelta, yPos, yDelta)
	end
	
	function display:auraEntry(auraText)
		if not IN_COMBAT then return end

		local f = acquireFrame()
		f.Text:SetTextColor(1.0, 1.0, 0.0)
		f.Text:SetText(auraText)
	
		local startX, xDelta, startY, yDelta = getStartingPositions(AURA_EVENT)
		local xPos = startX 
		local yPos = startY
	
		f:ClearAllPoints()
		f:SetPoint("CENTER", xPos, 200)
	
		scrollText(f, xPos, xDelta, startY, yDelta)
	end
	
	function display:missEntry(missText)
		if not IN_COMBAT then return end

		local f = acquireFrame()
		f.Text:SetFontObject(GameFontNormal)
		f.Text:SetTextColor(1.0, 1.0, 1.0)
		f.Text:SetText(missText)
	
		local startX, xDelta, startY, yDelta = getStartingPositions(MISS_EVENT)
		local xPos = startX 
		local yPos = startY
	
		f:ClearAllPoints()
		f:SetPoint("CENTER", xPos, yPos)
		scrollText(f, xPos, xDelta, startY, yDelta)
	end

initFramePool()

local fileName = "ScrollText.lua"
if thread:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( string.format("%s loaded.", fileName ), 1.0, 1.0, 0.0 )
end
