require "/scripts/util.lua"

local oldInit = init
local oldUpdate = update
local oldUnInit = uninit
local baseFireTime
local baseInaccuracy

function init()
  oldInit()
  baseFireTime = self.primaryAbility.fireTime
  baseInaccuracy = self.primaryAbility.inaccuracy
  baseDamageMultiplier = self.primaryAbility.baseDamageMultiplier or 1.0
end

function update(dt, fireMode, shiftHeld)

  local scaleFactor = status.resource("energy") / status.resourceMax("energy") + 0.005
  local scaleFactor2 = status.resource("energy") / status.resourceMax("energy") + 0.03
  self.primaryAbility.fireTime = baseFireTime * scaleFactor
  self.primaryAbility.inaccuracy = baseInaccuracy * scaleFactor
  self.primaryAbility.baseDamageMultiplier = baseDamageMultiplier / scaleFactor
  oldUpdate(dt, fireMode, shiftHeld)

end

function uninit()
  self.primaryAbility.fireTime = baseFireTime
  self.primaryAbility.fireTime = baseInaccuracy
  self.primaryAbility.baseDamageMultiplier = baseDamageMultiplier
  oldUnInit()
end
