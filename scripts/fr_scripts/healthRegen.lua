--[[
    Simple HP regeneration effect.
	Restores the given % of HP every second this is active.
    Arguments:

	"args" : {
		"healingRate" = 0.015,
		"label" = <string> --this is used for unique regen handling. absent, the string is "default". there should never be more than one default running at a time.
	}
]]

function FRHelper:call(args, main, dt, ...)
	--special handling for NPCs, to prevent immortality
	if not dt then dt = script.updateDt() end
	local label=(args.label or "default").."_healthRegen"
	if not (world.isNpc(entity.id()) and status.resource("health") < 1) then
		--status.modifyResourcePercentage("health", args.healingRate * dt * math.max(0,1+status.stat("healingBonus")))
		if not self[label.."_timer"] or self[label.."_timer"]>=0.5 then
			world.sendEntityMessage(entity.id(),"recordFUPersistentEffect",label)
			--sb.logInfo("args %s, maxHp %s, healingBonus %s, actualRegen %s",args,status.stat("maxHealth"),status.stat("healingBonus"),status.stat("maxHealth")*(args.healingRate or 0)*math.max(0,1+status.stat("healingBonus")))
			status.setPersistentEffects(label,{{stat="healthRegen",amount=status.stat("maxHealth")*(args.healingRate or 0)*math.max(0,1+status.stat("healingBonus"))}})
			self[label.."_timer"]=0.0
		else
			self[label.."_timer"]=self[label.."_timer"]+dt
		end
	else
		status.setResource("health",0)
	end
end
