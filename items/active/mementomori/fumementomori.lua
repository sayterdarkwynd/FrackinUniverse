require "/scripts/mementomori.lua"

function init()
	activeItem.setScriptedAnimationParameter(mementomori.deathPositionKey,status.statusProperty(mementomori.deathPositionKey))
	script.setUpdateDelta(5)
	promise=world.sendEntityMessage(activeItem.ownerEntityId(),"player.worldId")
end

function update(dt, fireMode, shiftHeld)
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
			local buffer=status.statusProperty(mementomori.deathPositionKey)
			firing=(not not buffer) and (world.magnitude(buffer.position,world.entityPosition(activeItem.ownerEntityId())) > 20)
			
			if firing then
				if not teleportTimer then
					teleportTimer=0
				elseif teleportTimer == 0 then
				  animator.playSound("chime")
				elseif (teleportTimer >= 3-dt) and (teleportTimer<=3) and not playOnce then
					animator.playSound("break")
					playOnce=true
				elseif teleportTimer >= 3 then
					animator.stopAllSounds("chime")
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
				teleportTimer=teleportTimer+dt
			else
				teleportTimer=0
				playOnce=false
				animator.stopAllSounds("error")
				animator.playSound("error")
			end
		else
			playOnce=false
			teleportTimer=0
		end
	end
end