require "/scripts/effectUtil.lua"

function init()
	--sourceVal=effect.sourceEntity()
	durVal=effect.duration()
	--sb.logInfo("Dur:%s",durVal)
	effect.addStatModifierGroup({{stat="physicalResistance",effectiveMultiplier=0}})
end

function update(dt)
	if status.stat("maxHealth") and entity.id() then
	--applySelfDamageRequest does not work for this either. again, we cant use scripted methods. blame CF
	--[[status.applySelfDamageRequest({
		damageType = "Damage",
		damage = status.stat("maxHealth"),
		damageSourceKind = "bow",
		sourceEntityId = entity.id()
	})]]
	--sb.logInfo("hunterdamage sourceval: %s",sourceVal)
	effectUtil.projectileSelf("fuhunterdamagegimmick",{damageTeam={type="indiscriminate"},power=durVal or 1})
	effect.expire()
	end
end