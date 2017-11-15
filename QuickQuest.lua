local Addon = {}
Addon.name = 'QuickQuest'

function Addon:Initialize()
  self:RegisterForEvents()
  self:HookPopulateChatterOption()
end

function Addon:OnAddOnLoaded(name)
  if (name ~= self.name) then return end

  EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)

  self:Initialize()
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
    local function HookFunc(fn, ...)
      -- do work
      d('PopulateChatterOption')

      -- call original function
      fn(...)
    end

    Hook(INTERACTION, 'PopulateChatterOption', HookFunc)
  end
end

Addon:Load()
