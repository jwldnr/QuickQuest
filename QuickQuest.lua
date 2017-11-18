local Addon = {}
Addon.name = 'QuickQuest'

local EVENT_MANAGER = EVENT_MANAGER
local EVENT_ADD_ON_LOADED = EVENT_ADD_ON_LOADED
local EVENT_PLAYER_ACTIVATED = EVENT_PLAYER_ACTIVATED
local INTERACTION = INTERACTION
local CHAT_SYSTEM = CHAT_SYSTEM
local CHATTER_GOODBYE = CHATTER_GOODBYE
local CHATTER_START_SHOP = CHATTER_START_SHOP

local SELECT_OPTION_DELAY = 250
local TEXT_ALIGN_LEFT = TEXT_ALIGN_LEFT

local zo_callLater = zo_callLater
local ZO_ColorDef = ZO_ColorDef

local type = type

function Addon:Initialize()
  self.interaction = INTERACTION

  self:RegisterForEvents()
  self:HookResetInteraction()
  self:HookPopulateChatterOption()
  self:HookFinalizeChatterOptions()
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

function Addon:SelectChatterOption(optionIndex)
  local optionIndexType = type(optionIndex)

  if ('number' == optionIndexType) then
    zo_callLater(function()
      self.interaction:SelectChatterOptionByIndex(optionIndex)
    end, SELECT_OPTION_DELAY)
  elseif ('function' == optionIndexType) then
    zo_callLater(function()
      optionIndex()
    end, SELECT_OPTION_DELAY)
  end
end

do
  local function OnAddOnLoaded(event, ...)
    Addon:OnAddOnLoaded(...)
  end

  local function OnPlayerActivated(event, ...)
    Addon:OnPlayerActivated(...)
  end

  local function SelectChatterOption(...)
    Addon:SelectChatterOption(...)
  end

  local function SetHook(control, fnName, HookFn)
    local fn = control[fnName]
    if (nil ~= fn and 'function' == type(fn)) then
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
      if (CHATTER_GOODBYE == optionType) then
        chosenBefore = true
      end

      -- call original function with modified values
      fn(self, controlID, optionIndex, optionText, optionType, optionalArg, isImportant, chosenBefore, importantOptions)
    end

    SetHook(self.interaction, 'PopulateChatterOption', HookFn)
  end

  function Addon:HookFinalizeChatterOptions()
    local function HookFn(fn, self, ...)
      -- call original function
      fn(self, ...)

      local optionCount = ...

      -- select if there is only one option, should be safe right?
      if (1 == optionCount) then
        SelectChatterOption(optionCount)
      end

      -- check for important options
      local hasImportantOptions = false

      for i = 1, optionCount do
        local optionControl = self.optionControls[i]

        if (optionControl and optionControl.isImportant) then
          hasImportantOptions = true
          break
        end
      end

      -- dialog has important options
      if (hasImportantOptions) then
        d('there are important options to choose from')
        return
      end

      -- dialog has no important options
      local numberChosenBefore = 0

      for i = 1, optionCount do
        local optionControl = self.optionControls[i]

        -- guard: not a valid option
        if (not optionControl or not optionControl.optionIndex) then
          return
        end

        -- select if vendor
        if (CHATTER_START_SHOP == optionControl.optionType) then
          SelectChatterOption(optionControl.optionIndex)
          break
        end

        -- select if option not chosen before
        if (not optionControl.chosenBefore) then
          SelectChatterOption(optionControl.optionIndex)
          break
        end

        -- check if chosen before
        if (optionControl.chosenBefore) then
          numberChosenBefore = numberChosenBefore + 1

          -- say goodbye if all options have been chosen before
          if (optionCount == numberChosenBefore) then
            SelectChatterOption(optionControl.optionIndex)
            break
          end
        end
      end

    end

    SetHook(self.interaction, 'FinalizeChatterOptions', HookFn)
  end
end

Addon:Load()
