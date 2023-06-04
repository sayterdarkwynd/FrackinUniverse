require "/scripts/effectUtil.lua"

local oldUpdate=update
local oldInit=init


function init()
	if oldInit then oldInit() end
	ghostLostPetData=config.getParameter("ghostLostPetData",{ghostGiftPool="fulostghostgeneric",ghostGiftChance=10,ghostDuration=30})
end

function update(dt)
	if oldUpdate then oldUpdate(dt) end

	if ghostLostPetData.ghostDuration then
		status.modifyResourcePercentage("health",-dt*(1/(ghostLostPetData.ghostDuration)))
	end

	if not ghostLostPetDelta or ghostLostPetDelta > 1.0 then
		status.addEphemeralEffects({{effect="ghostlyglow",duration=60},{effect="invisible",duration=60},{effect="cultistshieldAlwaysHidden",duration=60},{effect="nodamagedummy",duration=60},{effect="nofalldamage",duration=60},{effect="invulnerable",duration=60}})

		if ghostLostPetData then
			if ghostLostPetData.ghostAuraFriendly then
				for _,effect in pairs(ghostLostPetData.ghostAuraFriendly) do
					effectUtil.effectAllFriendliesInRange(effect,ghostLostPetData.ghostAuraRange or 5,ghostLostPetDelta)
				end
			end
			if ghostLostPetData.ghostAuraEnemy then
				for _,effect in pairs(ghostLostPetData.ghostAuraEnemy) do
					effectUtil.effectAllEnemiesInRange(effect,ghostLostPetData.ghostAuraRange or 5,ghostLostPetDelta)
				end
			end

			if status.isResource("hunger") and status.resourcePercentage("hunger")<=0.4 then

				if math.random(100) < (ghostLostPetData.ghostGiftChance or 10) then
					world.spawnTreasure(entity.position(),(ghostLostPetData.ghostGiftPool) or "fulostghostgeneric",1,os.time())
				else
					world.spawnItem("endomorphicjelly",entity.position())
				end
				status.setResourcePercentage("hunger",1)
			end
		end

		ghostLostPetDelta=0.0
	else
		ghostLostPetDelta=ghostLostPetDelta+dt
	end
end

