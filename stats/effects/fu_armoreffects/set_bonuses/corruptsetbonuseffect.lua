require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
require "/scripts/vec2.lua"

armorBonus={
	{stat = "maxHealth", effectiveMultiplier = 1.25},
	{stat = "powerMultiplier", effectiveMultiplier = 1.15}
}

armorEffect={
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1}
}

setName="fu_corruptset"

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	checkArmor()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkArmor()
		fire(dt)
	end
end

function checkArmor()
	if (world.type() == "lightless") or (world.type() == "penumbra") or (world.type() == "aethersea") or (world.type() == "moon_shadow") or (world.type() == "shadow") or (world.type() == "midnight") then
		effect.setStatModifierGroup(
		effectHandlerList.armorBonusHandle,armorBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
	end
end


function fire(dt)
	if not fireDelta or not fireTime then
		fireTime=1.0+(((math.random(100)*0.1)-0.5))
		fireDelta=0
		return
	elseif fireDelta > fireTime then
		fireTime=1.0+(((math.random(100)*0.1)-0.5))
		fireDelta=0
	else
		fireDelta=fireDelta+dt
		return
	end
	
	local buffer=world.entityQuery(entity.position(),20,{includedTypes={"creature"}})
	local buffer2={}
	for _,id in pairs(buffer) do
		local see=entity.entityInSight(id)
		local team=world.entityDamageTeam(id)
		if team.type=="enemy" and see then
			buffer2[id]=world.entityPosition(id)
		end
	end
	buffer=buffer2
	buffer2={}
	for id,pos in pairs(buffer) do
		local quack=math.floor(math.random(100))
		if quack > 40 then
			local aimVector=vec2.sub(pos,entity.position())
			local aimVector={norm=vec2.norm(aimVector),mag=vec2.mag(aimVector)}
			world.spawnProjectile("scouteyecultist",mcontroller.position(),entity.id(),aimVector.norm,false,{power=status.resourceMax("health")*status.stat("powerMultiplier")*0.02,damageKind="shadow",speed=aimVector.mag*2})
		end
	end
end
