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

local CHATTER_TALK_CHOICE_INTIMIDATE_DISABLED = CHATTER_TALK_CHOICE_INTIMIDATE_DISABLED
local CHATTER_TALK_CHOICE_PERSUADE_DISABLED = CHATTER_TALK_CHOICE_PERSUADE_DISABLED
local CHATTER_TALK_CHOICE_CLEMENCY_DISABLED = CHATTER_TALK_CHOICE_CLEMENCY_DISABLED
local CHATTER_GUILDKIOSK_IN_TRANSITION = CHATTER_GUILDKIOSK_IN_TRANSITION

local DISABLED_OPTIONS = {
  CHATTER_TALK_CHOICE_INTIMIDATE_DISABLED,
  CHATTER_TALK_CHOICE_PERSUADE_DISABLED,
  CHATTER_TALK_CHOICE_CLEMENCY_DISABLED,
  CHATTER_GUILDKIOSK_IN_TRANSITION
}

local CHATTER_TALK_CHOICE_MONEY = CHATTER_TALK_CHOICE_MONEY
local CHATTER_TALK_CHOICE_PAY_BOUNTY = CHATTER_TALK_CHOICE_PAY_BOUNTY

local COST_OPTIONS = {
  CHATTER_TALK_CHOICE_MONEY,
  CHATTER_TALK_CHOICE_PAY_BOUNTY
}

local IsShiftKeyDown = IsShiftKeyDown

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
    local function OnResetInteraction(fn, self, ...)
      -- call original function
      fn(self, ...)

      -- override title values
      self.titleControl:SetText(GetUnitName('interact'))
      self.titleControl:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
      self.titleControl:SetFont('ZoFontCallout')
    end

    SetHook(self.interaction, 'ResetInteraction', OnResetInteraction)
  end

  function Addon:HookPopulateChatterOption()
    local function OnPopulateChatterOption(fn, self, ...)
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

    SetHook(self.interaction, 'PopulateChatterOption', OnPopulateChatterOption)
  end

  function Addon:HookFinalizeChatterOptions()
    local function OnFinalizeChatterOptions(fn, self, ...)
      -- call original function
      fn(self, ...)

      if (IsShiftKeyDown()) then
        return
      end

      local optionCount = ...
      local debug = 0 -- test

      -- select if there is only one option, should be safe right?
      if (1 == optionCount) then
        local optionControl = self.optionControls[optionCount]

        if (optionControl and optionControl.optionIndex) then
          debug = debug + 1
          d('only one option, select: ' .. debug)

          SelectChatterOption(optionControl.optionIndex)
          return
        end
      end

      -- check for important options
      for i = 1, optionCount do
        local optionControl = self.optionControls[i]

        -- skip invalid option
        if (not optionControl) then
          break
        end

        -- option is important
        if (optionControl.isImportant) then
          debug = debug + 1
          d('option is important: ' .. debug)

          return
        end

        -- option cost gold
        if (nil ~= COST_OPTIONS[optionControl.optionType]) then
          debug = debug + 1
          d('option cost gold: ' .. debug)

          return
        end
      end

      -- check for start shop option
      for i = 1, optionCount do
        local optionControl = self.optionControls[i]

        -- skip invalid option
        if (not optionControl) then
          d('not optionControl')
          break
        end

        -- start shop available
        if (CHATTER_START_SHOP == optionControl.optionType) then
          debug = debug + 1
          d('start shop available: ' .. debug)

          SelectChatterOption(optionControl.optionIndex)
          return
        end
      end

      local numberChosenBefore = 0

      for i = 1, optionCount do
        local optionControl = self.optionControls[i]

        -- skip invalid/not usable option
        if (not optionControl or nil ~= DISABLED_OPTIONS[optionControl.optionType]) then
          break
        end

        -- select if option not chosen before
        if (not optionControl.chosenBefore) then
          debug = debug + 1
          d('select if option not chosen before: ' .. debug)

          SelectChatterOption(optionControl.optionIndex)
          return
        end

        -- check if chosen before
        if (optionControl.chosenBefore) then
          numberChosenBefore = numberChosenBefore + 1

          -- say goodbye if all options have been chosen before
          if (optionCount == numberChosenBefore) then
            debug = debug + 1
            d('say goodbye if all options have been chosen before: ' .. debug)

            SelectChatterOption(optionControl.optionIndex)
            return
          end
        end
      end

    end

    SetHook(self.interaction, 'FinalizeChatterOptions', OnFinalizeChatterOptions)
  end
end

Addon:Load()
