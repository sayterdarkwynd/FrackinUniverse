require "/scripts/util.lua"

local oldInit = init
local oldUpdate = update
local oldUnInit = uninit
local baseFireTime

function init()
  oldInit()
  baseFireTime = self.primaryAbility.fireTime
end

function update(dt, fireMode, shiftHeld)

  local scaleFactor = status.resource("energy") / status.resourceMax("energy") + 0.01
  self.primaryAbility.fireTime = baseFireTime * scaleFactor
  oldUpdate(dt, fireMode, shiftHeld)

end

function uninit()
  self.primaryAbility.fireTime = baseFireTime
  oldUnInit()
end
