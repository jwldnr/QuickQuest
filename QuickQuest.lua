local Addon = {}
Addon.name = 'QuickQuest'

local EVENT_MANAGER = EVENT_MANAGER
local EVENT_ADD_ON_LOADED = EVENT_ADD_ON_LOADED
local EVENT_PLAYER_ACTIVATED = EVENT_PLAYER_ACTIVATED
local CHAT_SYSTEM = CHAT_SYSTEM
local INTERACTION = INTERACTION
local CHATTER_GOODBYE = CHATTER_GOODBYE

local ZO_ColorDef = ZO_ColorDef

function Addon:Initialize()
  self.interaction = INTERACTION

  self:RegisterForEvents()
  self:HookResetInteraction()
  self:HookPopulateChatterOption()
end

function Addon:OnAddOnLoaded(name)
  if (name ~= self.name) then return end

  EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)

  self:Initialize()
end

function Addon:OnPlayerActivated()
  EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_PLAYER_ACTIVATED)

  local color = ZO_ColorDef:New(1, .7, 1)
  CHAT_SYSTEM:AddMessage(color:Colorize(self.name .. ' loaded'))
end

do
  local function OnAddOnLoaded(event, ...)
    Addon:OnAddOnLoaded(...)
  end

  local function OnPlayerActivated(event, ...)
    Addon:OnPlayerActivated(...)
  end

  local function SetHook(control, fnName, HookFn)
    local fn = control[fnName]
    if ((fn ~= nil) and (type(fn) == 'function')) then
      control[fnName] = function(...)
        return HookFn(fn, ...)
      end
    end
  end

  function Addon:Load()
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
  end

  function Addon:RegisterForEvents()
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
  end

  function Addon:HookResetInteraction()
    local function HookFn(fn, self, ...)
      -- call original function
      fn(self, ...)

      -- override title values
      self.titleControl:SetText(GetUnitName('interact'))
      self.titleControl:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
      self.titleControl:SetFont('ZoFontCallout')
    end

    SetHook(self.interaction, 'ResetInteraction', HookFn)
  end

  function Addon:HookPopulateChatterOption()
    local function HookFn(fn, self, ...)
      local controlID, optionIndex, optionText, optionType, optionalArg, isImportant, chosenBefore, importantOptions = ...

      -- override option text
      optionText = controlID .. '. ' .. optionText

      -- override goodbye color
      if (optionType == CHATTER_GOODBYE) then
        chosenBefore = true
      end

      -- call original function with modified values
      fn(self, controlID, optionIndex, optionText, optionType, optionalArg, isImportant, chosenBefore, importantOptions)
    end

    SetHook(self.interaction, 'PopulateChatterOption', HookFn)
  end
end

Addon:Load()
