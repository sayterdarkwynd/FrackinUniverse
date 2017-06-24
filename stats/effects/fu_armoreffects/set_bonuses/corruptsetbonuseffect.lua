require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
require "/scripts/vec2.lua"

armorBonus={
	{stat = "maxHealth", baseMultiplier = 1.25},
	{stat = "powerMultiplier", baseMultiplier = 1.15},
	{stat = "physicalResistance", amount = 1.25}
}

armorEffect={
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1}
}

setName="fu_corruptset"

function init()
	setSEBonusInit(setName)
	armorEffectHandle=effect.addStatModifierGroup(armorEffect)

	armorBonusHandle=effect.addStatModifierGroup({})
	checkArmor()
end

function getLight()
  local position = mcontroller.position()
  position[1] = math.floor(position[1])
  position[2] = math.floor(position[2])
  local lightLevel = world.lightLevel(position)
  self.lightLevel = math.floor(lightLevel * 100)
  return lightLevel
end

-- ***********************************************************************************************************
-- FR SPECIALS  Functions for projectile spawning
-- ***********************************************************************************************************
function firePosition()
   return vec2.add(mcontroller.position(), entity.position())
end

function aimVector()  -- fires straight
  local aimVector = vec2.rotate({1, 0}, mcontroller.facingDirection() )
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function aimVectorRand() -- fires wherever it wants
  local aimVector = vec2.rotate({1, 0},  mcontroller.facingDirection() + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end


function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
	        getLight()
		checkArmor()
		self.randValue = math.random(30)	
		if (self.randValue < 5) then  -- spawn a projectile
		  params = { power = 10, damageKind = "shadow" }			
		  projectileId = world.spawnProjectile("scouteyecultist",mcontroller.position(),entity.id(), aimVectorRand(),false,params)
		end			
	end
end

function checkArmor()
	if (world.type() == "lightless") or (world.type() == "penumbra") or (world.type() == "aethersea") or (world.type() == "moon_shadow") or (world.type() == "shadow") or (world.type() == "midnight") then
		effect.setStatModifierGroup(
		armorBonusHandle,armorBonus)
	else
		effect.setStatModifierGroup(
		armorBonusHandle,{})
	end
end