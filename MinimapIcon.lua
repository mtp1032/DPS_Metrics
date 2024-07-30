--=================================================================================
-- Addon: DPS_Metrics
-- Filename: MinimapIcon.lua
-- Date: 10 June, 2024
-- AUTHOR: Michael Peterson
-- ORIGINAL DATE: 10 June, 2024
--=================================================================================
local ADDON_NAME, DPS_Metrics = ...

------------------------------------------------------------
--                  NAMESPACE LAYOUT
------------------------------------------------------------
DPS_Metrics = DPS_Metrics or {}
DPS_Metrics.MinimapIcon = {}

local utils     = LibStub:GetLibrary("UtilsLib")
local thread    = LibStub:GetLibrary("WoWThreads")
local core      = DPS_Metrics.Core  -- Local reference to the core table
local L         = DPS_Metrics.Locales.L  -- Local reference to the core table
local event 	= DPS_Metrics.Event  -- Local reference to the core table
local display   = DPS_Metrics.Display  -- Local reference to the core table
local main      = DPS_Metrics.Main  -- Local reference to the core table
local mm        = DPS_Metrics.MinimapIcon

------------------------------------------------------------
--                   code begins here                    --
------------------------------------------------------------


local fileName = "MinimapIcon.lua"
if thread:debuggingIsEnabled() then
    DEFAULT_CHAT_FRAME:AddMessage( fileName .. " " .. "loaded.", 0.0, 1.0, 1.0 )
end

