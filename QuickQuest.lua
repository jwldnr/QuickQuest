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

local ENABLE_DEBUG = true

function Addon:Initialize()
  self.interaction = INTERACTION

  self:RegisterForEvents()
  self:HookResetInteraction()
  self:HookPopulateChatterOption()
  self:HookFinalizeChatterOptions()
end

function Addon:OnAddOnLoaded(name)
  if (name ~= self.name) then
    return
  end

  EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)

  self:Initialize()
end

function Addon:OnPlayerActivated()
  EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_PLAYER_ACTIVATED)

  local color = ZO_ColorDef:New(1, .7, 1)
  CHAT_SYSTEM:AddMessage(color:Colorize(self.name .. ' loaded'))
end

function Addon:OnResetInteraction(fn, ...)
  -- call original function
  fn(...)

  -- override title values
  self.interaction.titleControl:SetText(GetUnitName('interact'))
  self.interaction.titleControl:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
  self.interaction.titleControl:SetFont('ZoFontCallout')
end

function Addon:OnPopulateChatterOption(fn, ...)
  local control, controlID, optionIndex, optionText, optionType, optionalArg, isImportant, chosenBefore, importantOptions = ...

  -- override option text
  optionText = controlID .. '. ' .. optionText

  -- override goodbye color
  if (CHATTER_GOODBYE == optionType) then
    chosenBefore = true
  end

  -- call original function with modified values
  fn(control, controlID, optionIndex, optionText, optionType, optionalArg, isImportant, chosenBefore, importantOptions)
end

function Addon:OnFinalizeChatterOptions(fn, ...)
  -- call original function
  fn(...)

  if (IsShiftKeyDown()) then
    self:WriteLineDebug('shift key is down', 0)

    return
  end

  local control, optionCount = ...
  local debugCount = 0

  -- select if there is only one option, should be safe right?
  if (1 == optionCount) then
    local optionControl = control.optionControls[optionCount]

    if (optionControl and optionControl.optionIndex) then
      debugCount = debugCount + 1
      self:WriteLineDebug('there is only one option', debugCount)
      self:SelectChatterOption(optionControl.optionIndex)

      return
    end
  end

  -- check for important options
  for i = 1, optionCount do
    local optionControl = control.optionControls[i]

    -- skip invalid option
    if (not optionControl) then
      debugCount = debugCount + 1
      self:WriteLineDebug('[1] option is invalid', debugCount)

      break
    end

    -- option is important
    if (optionControl.isImportant) then
      debugCount = debugCount + 1
      self:WriteLineDebug('option is important', debugCount)

      return
    end

    -- option cost gold
    if (nil ~= COST_OPTIONS[optionControl.optionType]) then
      debugCount = debugCount + 1
      self:WriteLineDebug('option cost gold', debugCount)

      return
    end
  end

  -- check for start shop option
  for i = 1, optionCount do
    local optionControl = control.optionControls[i]

    -- skip invalid option
    if (not optionControl) then
      debugCount = debugCount + 1
      self:WriteLineDebug('[2] option is invalid', debugCount)

      break
    end

    -- start shop available
    if (CHATTER_START_SHOP == optionControl.optionType) then
      debugCount = debugCount + 1
      self:WriteLineDebug('start shop is available', debugCount)
      self:SelectChatterOption(optionControl.optionIndex)

      return
    end
  end

  local chosenOptionCount = 0

  for i = 1, optionCount do
    local optionControl = control.optionControls[i]

    -- skip invalid/not usable option
    if (not optionControl or nil ~= DISABLED_OPTIONS[optionControl.optionType]) then
      debugCount = debugCount + 1
      self:WriteLineDebug('option is invalid/not usable', debugCount)

      break
    end

    -- select if option not chosen before
    if (not optionControl.chosenBefore) then
      debugCount = debugCount + 1
      self:WriteLineDebug('option has not been chosen before- select', debugCount)
      self:SelectChatterOption(optionControl.optionIndex)

      return
    end

    -- check if chosen before
    if (optionControl.chosenBefore) then
      chosenOptionCount = chosenOptionCount + 1

      -- say goodbye if all options have been chosen before
      if (optionCount == chosenOptionCount) then
        debugCount = debugCount + 1
        self:WriteLineDebug('all options have been chosen before- goodbye', debugCount)
        self:SelectChatterOption(optionControl.optionIndex) -- goodbye

        return
      end
    end
  end
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

function Addon:WriteLineDebug(message, count)
  if (not ENABLE_DEBUG) then
    return
  end

  if (1 < count) then
    d('error! count should never be greater than 1')
  end

  d(message .. ', count: ' .. count)
end

do
  local function OnAddOnLoaded(event, ...)
    Addon:OnAddOnLoaded(...)
  end

  local function OnPlayerActivated(event, ...)
    Addon:OnPlayerActivated(...)
  end

  local function OnResetInteraction(...)
    Addon:OnResetInteraction(...)
  end

  local function OnPopulateChatterOption(...)
    Addon:OnPopulateChatterOption(...)
  end

  local function OnFinalizeChatterOptions(...)
    Addon:OnFinalizeChatterOptions(...)
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
    SetHook(self.interaction, 'ResetInteraction', OnResetInteraction)
  end

  function Addon:HookPopulateChatterOption()
    SetHook(self.interaction, 'PopulateChatterOption', OnPopulateChatterOption)
  end

  function Addon:HookFinalizeChatterOptions()
    SetHook(self.interaction, 'FinalizeChatterOptions', OnFinalizeChatterOptions)
  end
end

Addon:Load()
