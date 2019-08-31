require "/scripts/mementomori.lua"

function init()
	activeItem.setScriptedAnimationParameter(mementomori.deathPositionKey,status.statusProperty(mementomori.deathPositionKey))
	script.setUpdateDelta(5)
	promise=world.sendEntityMessage(activeItem.ownerEntityId(),"player.worldId")
	--doesnt work...
	--animator.setSoundPool("chime",{"/sfx/weapons/elderchime1.ogg"})
	--animator.setSoundPool("break",{"/sfx/objects/vase_break_large1.ogg"})
end

function update(dt, fireMode, shiftHeld)
	if not firing then
		if not located then
			if promise then
				if promise:finished() then
					if promise:succeeded() then
						activeItem.setScriptedAnimationParameter(mementomori.worldId,promise:result())
						located=true
					else
						promise=world.sendEntityMessage(activeItem.ownerEntityId(),"player.worldId")
					end
				end
			end
		else
			if fireMode=="primary" then
				if teleportTimer == 0 then
					 --[[if animator.hasSound("chime") then
						animator.playSound("chime")
					--else
						--sb.logInfo("Chime missing")
					end]]
				end
				teleportTimer=teleportTimer and teleportTimer+dt or dt
				if teleportTimer >= 3 then
					--[[if animator.hasSound("chime") then
						animator.stopAllSounds("chime")
					end]]
					local buffer=status.statusProperty(mementomori.deathPositionKey)
					firing=(not not buffer) and (world.magnitude(buffer.position,world.entityPosition(activeItem.ownerEntityId())) > 20)
					if firing then
						--[[if animator.hasSound("break") then
							animator.playSound("break")
						end]]
						status.addEphemeralEffect("blink")
						status.addEphemeralEffect("cultistshieldAlwaysHidden",2.5)
						status.addEphemeralEffect("nofalldamage",2.5)
						status.addEphemeralEffect("breathprotectionvehicle",2.5)
						status.addEphemeralEffect("dontstarve",2.5)
						status.addEphemeralEffect("ghostlyglow",2.5)
						status.addEphemeralEffect("nodamagedummy",2.5)
						status.addEphemeralEffect("noenergyregendummy",2.5)
						status.addEphemeralEffect("ghostlyglow",2.5)
						status.addEphemeralEffect("nude",2.5)
						status.addEphemeralEffect("energy_negative_100_hidden",2.5)
						mcontroller.setPosition(buffer.position)
						item.consume(1)
					end
				end
			else
				--[[if animator.hasSound("chime") then
					animator.stopAllSounds("chime")
				end]]
				teleportTimer=0
			end
		end
	else
		
	end
end