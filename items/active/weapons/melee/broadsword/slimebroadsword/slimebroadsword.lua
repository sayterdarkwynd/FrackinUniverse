require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"
require "/scripts/slimepersonglobalfunctions.lua"

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
  getSkinColorOnce = 0
  self.weapon:init()

  self.activeTime = config.getParameter("activeTime", 2.0)
  self.activeTimer = 0
  animator.setAnimationState("blade", "inactive")
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)


  if getSkinColorOnce == 0 then
        getSkinColorOnce = 1
        local result = world.entityPortrait(activeItem.ownerEntityId(),"full")
        local i = 1
        local done = 0
        while i < 12 do

                if string.find(sb.printJson(result[i].image), "head") ~= nil then
                    local bodyColor = sb.printJson(result[i].image)
                    bodyColor = bodyColor:sub(2,-2)
                    local splited = bodyColor:split("?")
                    animator.setGlobalTag("skinColor", "?" .. splited[2])
					activeItem.setInventoryIcon("/items/active/weapons/melee/broadsword/slimebroadsword/slimebroadswordicon.png".."?" .. splited[2])

                    done = done + 1
                end

                if string.find(sb.printJson(result[i].image), "hair") ~= nil then
                    local hairColor = sb.printJson(result[i].image)
                    hairColor = hairColor:sub(2,-2)
                    local splited = hairColor:split("?")
                    animator.setGlobalTag("hairColor", "?" .. splited[2])

                    done = done + 1
                end

                if done == 2 then
                    i = 13
                end
            i = i + 1
        end
    end



  local nowActive = self.weapon.currentAbility ~= nil
  if nowActive then
    if self.activeTimer == 0 then
      animator.setAnimationState("blade", "extend")
    end
    self.activeTimer = self.activeTime
  elseif self.activeTimer > 0 then
    self.activeTimer = math.max(0, self.activeTimer - dt)
    if self.activeTimer == 0 then
      animator.setAnimationState("blade", "retract")
    end
  end
end

function uninit()
  getSkinColorOnce = 0
  self.weapon:uninit()
end