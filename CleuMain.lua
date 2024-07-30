--=================================================================================
-- Addon: DPS_Metrics
-- Filename: CleuMain.lua
-- Date: 10 June, 2024
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 June, 2024
--=================================================================================
local ADDON_NAME, DPS_Metrics = ...

------------------------------------------------------------
--                  NAMESPACE LAYOUT
------------------------------------------------------------
DPS_Metrics = DPS_Metrics or {}
DPS_Metrics.Main = {}

local utils     = LibStub:GetLibrary("UtilsLib")
local thread    = LibStub:GetLibrary("WoWThreads")
local core      = DPS_Metrics.Core
local L         = DPS_Metrics.Locales.L
local event 	= DPS_Metrics.Event
local display   = DPS_Metrics.Display
local main      = DPS_Metrics.Main

-------------------------------------------------------------------------
--                          CODE BEGINS HERE
-------------------------------------------------------------------------

-- Thread symbols
local SIG_ALERT         = thread.SIG_ALERT
local SIG_GET_DATA      = thread.SIG_GET_DATA
local SIG_SEND_DATA     = thread.SIG_SEND_DATA
local SIG_BEGIN         = thread.SIG_BEGIN
local SIG_HALT          = thread.SIG_HALT
local SIG_TERMINATE     = thread.SIG_TERMINATE
local SIG_IS_COMPLETE   = thread.SIG_IS_COMPLETE
local SIG_SUCCESS       = thread.SIG_SUCCESS
local SIG_FAILURE       = thread.SIG_FAILURE  
local SIG_READY         = thread.SIG_READY 
local SIG_WAKEUP        = thread.SIG_WAKEUP 
local SIG_CALLBACK      = thread.SIG_CALLBACK
local SIG_NONE_PENDING  = thread.SIG_NONE_PENDING

-- DPS_Metrics-specific symbols
local EMPTY_STR = ""

------ INDICES FOR THE CLEU subEvent TABLE----
local CLEU_TIMESTAMP		= 1		
local CLEU_SUBEVENT			= 2
local CLEU_HIDECASTER		= 3
local CLEU_SOURCEGUID 		= 4	
local CLEU_SOURCENAME		= 5 	
local CLEU_SOURCEFLAGS		= 6 	
local CLEU_SOURCERAIDFLAGS	= 7	
local CLEU_TARGETGUID		= 8 	
local CLEU_TARGETNAME		= 9 	
local CLEU_TARGETFLAGS		= 10 	
local CLEU_TARGETRAIDFLAGS	= 11
local CLEU_SPELLID			= 12
local CLEU_SPELLNAME		= 13
local CLEU_SPELLSCHOOL		= 14
local CLEU_DMG_AMOUNT		= 15
local CLEU_HEAL_AMOUNT		= CLEU_DMG_AMOUNT
local CLEU_MISS_TYPE		= CLEU_DMG_AMOUNT
local CLEU_AURA_TYPE		= CLEU_DMG_AMOUNT
local CLEU_DMG_OVERKILL		= 16
local CLEU_OVERHEAL			= CLEU_DMG_OVERKILL
local CLEU_MISS_OFFHAND		= CLEU_DMG_OVERKILL	
local CLEU_AURA_AMOUNT		= CLEU_DMG_OVERKILL
local CLEU_DMG_SCHOOL		= 17
local CLEU_MISS_AMOUNT		= CLEU_DMG_SCHOOL
local CLEU_HEAL_ABSORBED	= CLEU_DMG_SCHOOL
local CLEU_DMG_RESISTED		= 18
local CLEU_MISS_CRITICAL	= CLEU_DMG_RESISTED
local CLEU_HEAL_IS_CRIT	    = CLEU_DMG_RESISTED
local CLEU_DMG_BLOCKED		= 19
local CLEU_DMG_ABSORBED		= 20
local CLEU_DMG_IS_CRIT		= 21 -- boolean
local CLEU_DMG_GLANCING		= 22 -- boolean
local CLEU_DMG_CRUSHING		= 23 -- boolean
local CLEU_DMG_IS_OFFHAND 	= 24 -- boolean

local cleuDB = {}

main.TYPE_DAMAGE    = 1
main.TYPE_HEALS     = 2
main.TYPE_AURA      = 3
main.TYPE_MISS      = 4

local TYPE_DAMAGE   = main.TYPE_DAMAGE
local TYPE_HEALS    = main.TYPE_HEALS
local TYPE_AURA     = main.TYPE_AURA
local TYPE_MISS     = main.TYPE_MISS

local function dbgDumpSubEvent( subEvent ) -- DUMPS A SUB EVENT IN A COMMA DELIMITED FORMAT.
	local dataType = nil
	
	for i = 1, 24 do
		if subEvent[i] ~= nil then
			local value = nil
			dataType = type(subEvent[i])

			if type(subEvent[i]) == "number" or type(subEvent[i] == "boolean") then
				value = tostring( subEvent[i] )
			end
			if i == 1 then
				utils:postMsg( string.format("arg[%d] %s, ", i, value ))
			else
				utils:postMsg( string.format(" arg[%d] %s, ", i, value ))
			end
		elseif subEvent[i] == EMPTY_STR then
			utils:postMsg( string.format(" arg[%d] EMPTY, ", i))
		else
			utils:postMsg( string.format(" arg[%d] NIL, ", i))
		end
	end
	utils:postMsg( string.format("\n\n"))
end	
local function isDamageSubEvent( subEventName )
	local isValid = false
	local str = string.sub( subEventName, -7 )
	if str == "_DAMAGE" then 
		isValid = true
	end	
	return isValid
end
local function isHealSubEvent( subEventName )
	local isValid = false
	local str = string.sub( subEventName, -5 )
	if str == "_HEAL" then 
		isValid = true
	end
	return isValid
end
local function isAuraSubEvent( subEventName )
	local isValid = false	
	local str = string.sub( subEventName, 1,11 )
	if str == "SPELL_AURA_" then 
		isValid = true
	end
	return isValid
end
local function isMissSubEvent( subEventName )
	local isValid = false
	local str = string.sub( subEventName, -7 )
	if str == "_MISSED" then
		isValid = true 
	end
	return isValid
end
local function insertInDB( subEvent )
    table.insert( cleuDB, subEvent )
end
local function getEventInfo( subEvent )
    insertInDB( subEvent )

    local eventType = nil
    local amount = nil
    local spell  = nil
    local isCrit = nil
    local infoStr = nil
    local sourceName = subEvent[CLEU_SOURCENAME]
    local targetName = subEvent[CLEU_TARGETNAME]
    local targetGUID = subEvent[CLEU_TARGETGUID]

    local subEventName = subEvent[CLEU_SUBEVENT]

    if isDamageSubEvent( subEventName) then
        eventType   = TYPE_DAMAGE
        if subEventName == "SWING_DAMAGE" then
            amount = subEvent[CLEU_DMG_AMOUNT - 3]
            spell  = "Melee Swing"
        else
            amount = subEvent[CLEU_DMG_AMOUNT]
            spell  = subEvent[CLEU_SPELLNAME]
        end
        isCrit      = subEvent[CLEU_DMG_IS_CRIT - 3]
        if isCrit then
            infoStr     = string.format("%s's %s CRITICALLY hit %s for %d\n", sourceName, spell, targetName, amount )
        else
            infoStr     = string.format("%s's %s hit %s for %d\n", sourceName, spell, targetName, amount )
        end
    end
    if isHealSubEvent( subEventName ) then
        eventType   = TYPE_HEALS
        amount      = subEvent[CLEU_HEAL_AMOUNT]
        spell       = subEvent[CLEU_SPELLNAME] 
        isCrit      = subEvent[CLEU_HEAL_IS_CRIT]  
        if isCrit then
            infoStr     = string.format("%s's %s CRITICALLY healed %s for %d\n", sourceName, spell, targetName, amount )
        else
            infoStr     =string.format("%s's %s healed %s for %d\n", sourceName, spell, targetName, amount )
        end
    end

    return eventType, isCrit, infoStr
end
local OUT_OF_COMBAT = true

local function processSubevent()
    local fname = "processSubevent()"
    local DONE = false
    local sigEvent = nil
    local result = nil
    local numSignals = 0
    local inCombat = false

    while not DONE do
        thread:yield()

        sigEvent, result = thread:getSignal()
        assert( sigEvent ~= nil)
        assert( result == nil )
        
        if sigEvent[1] == SIG_ALERT then
            local subEvent = sigEvent[3]
            local eventType, isCrit, combatText = getEventInfo( subEvent )
            if eventType == TYPE_DAMAGE then
                display:damageEntry( isCrit, combatText )
            end
            if eventType == TYPE_HEALS then
                display:healEntry( isCrit, combatText)
            end
            thread:delay(3)
        end
        
        if signal == SIG_TERMINATE then
            DONE = true
        end
    end
end

local display_h, result = thread:create( 10, processSubevent )
if not display_h then
    utils:postMsg( result[1] .. ", " .. result[2])
    return
end
event:setDisplayThread( display_h )


local fileName = "CleuMain.lua"
if thread:debuggingIsEnabled() then
    DEFAULT_CHAT_FRAME:AddMessage( fileName .. " " .. "loaded.", 0.0, 1.0, 1.0 )
end

