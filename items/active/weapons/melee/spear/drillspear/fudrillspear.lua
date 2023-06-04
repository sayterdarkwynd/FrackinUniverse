require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

function init()
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))
  animator.setGlobalTag("directives", "")
  animator.setGlobalTag("bladeDirectives", "")

  self.weapon = Weapon:new()

  self.weapon:addTransformationGroup("weapon", {0,0}, util.toRadians(config.getParameter("baseWeaponRotation", 0)))
  self.weapon:addTransformationGroup("swoosh", {0,0}, math.pi/2)

  local primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(primaryAbility)

  local secondaryAttack = getAltAbility()
  if secondaryAttack then
    self.weapon:addAbility(secondaryAttack)
  end

  self.weapon:init()

  self.activeTime = config.getParameter("activeTime", 2.0)
  self.activeTimer = 0

  animator.setAnimationState("blade", "inactive")
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)

  local nowActive = self.weapon.currentAbility ~= nil
  if nowActive then
    if self.activeTimer == 0 then
      animator.setAnimationState("blade", "active")
      animator.playSound("fire2", -1)
    end
    self.activeTimer = self.activeTime
  elseif self.activeTimer > 0 then
    self.activeTimer = math.max(0, self.activeTimer - dt)
    if self.activeTimer == 0 then
      animator.setAnimationState("blade", "inactive")
      animator.stopAllSounds("fire2")
      animator.playSound("winddown")
    end
  end
end

function uninit()
  self.weapon:uninit()
end
