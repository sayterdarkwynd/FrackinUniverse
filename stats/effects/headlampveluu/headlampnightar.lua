function init()
	script.setUpdateDelta(1)
	if not world.entityExists(entity.id()) then return end
	setParticleConfig(0)
end

function update(dt)
	if not pParams then
		init()
	end
	setParticleConfig(dt)
	world.sendEntityMessage(entity.id(),"fu_specialAnimator.spawnParticle",particleConfig)
end

function uninit()
end

function setParticleConfig(dt)
	if not particleConfig then
		particleConfig={
			light = {130,130,130},--might need tweaking. {0-255,same,same,<alpha? only in animated>}
			type = "textured",--for the below.
			image = "/projectiles/invisibleprojectile/invisibleprojectile.png",--invisible!
			--destructionAction = "fade",
			--size = 1,--does not matter
			layer = "back"--doesnt seem to matter
			--variance = {rotation=360,initialVelocity = {0.0, 0.0}}--pointless
		}
	end
	local lightval=math.min(0.5*(status.stat("maxHealth")+status.stat("maxEnergy"))*status.resourcePercentage("health"),255)
	particleConfig.light={lightval,lightval,lightval}
	particleConfig.position=entity.position()
	particleConfig.timeToLive = dt--*0.5--*6.0
	--particleConfig.destructionTime = dt*0.5--*3.0
end

