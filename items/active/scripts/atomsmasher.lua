require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"



-- update which image we're using and keep the weapon visually in front of the hand
function updateHand()
  local isFrontHand = self.weapon:isFrontHand()
  local isBackHand = self.weapon:isBackHand()
  animator.setGlobalTag("hand", isFrontHand and "front" or "back")
  animator.resetTransformationGroup("swoosh")
  animator.scaleTransformationGroup("swoosh", isBackHand and {1, 1} or {1, -1})
  --activeItem.setOutsideOfHand(isFrontHand)
  --activeItem.setOutsideOfHand(isBackHand)

  if isFrontHand then
    animator.setGlobalTag("hand", isBackHand and "front" or "back")
    animator.resetTransformationGroup("muzzle")
    animator.scaleTransformationGroup("muzzle", isBackHand and {1, 1} or {1, -1})
  end

end

function init()
  self.weapon = Weapon:new()
  updateHand()
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)
end

function uninit()
  self.weapon:uninit()
end


