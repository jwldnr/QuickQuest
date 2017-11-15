local Addon = {}
Addon.name = 'QuickQuest'

local INTERACTION = INTERACTION

function Addon:Initialize()
  self.interaction = INTERACTION

  self:RegisterForEvents()
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

  local function Hook(control, funcName, hookFunc)
    local fn = control[funcName]
    if ((fn ~= nil) and (type(fn) == 'function')) then
      control[funcName] = function(...)
        return hookFunc(fn, ...)
      end
    end
  end

  function Addon:Load()
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
  end

  function Addon:RegisterForEvents()
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
  end

  function Addon:HookPopulateChatterOption()
    local function HookProcedure(fn, self, ...)
      local controlID, optionIndex, optionText, optionType, optionalArg, isImportant, chosenBefore, importantOptions = ...

      local text = controlID .. '. ' .. optionText

      -- call original function
      fn(self, controlID, optionIndex, text, optionType, optionalArg, isImportant, chosenBefore, importantOptions)

      --zo_callLater(function() chatterData.optionIndex() end, 2000)

      --local t = optionIndex()
      -- d(chatterData.optionIndex())
      -- local control = self.optionControls[controlID]
      -- d(control)
      -- d(control.optionIndex)
      -- if (control and control.optionIndex) then
      --   if (control.optionIndex) then
      --     local oiType = type(control.optionIndex)
      --     if (oiType == 'number') then
      --       d('numbeR!')
      --     elseif (oiType == 'function') then
      --       d('function!')
      --       control.optionIndex()
      --     end
      --   end
      -- end
      -- local text = optionIndex() .. '. ' .. optionText
      -- d(text)

      -- override optionText (test)
      -- optionText = function () return 'hooked' end

      -- d(controlID)

      -- call original function
      -- fn(self, ...)
    end

    Hook(self.interaction, 'PopulateChatterOption', HookProcedure)

    -- local function HookFunc(fn, self, ...)
    --   fn(self, ...)
    --
    --   local a, b, c = ...
    --   d(a)
    --   d(b)
    --   d(c)
    --
    --   --local optionCount, backToTOCOption = ...
    --
    --   d('!')
    -- end
    --
    -- Hook(INTERACTION, 'PopulateChatterOptions', HookFunc)
  end
end

Addon:Load()
