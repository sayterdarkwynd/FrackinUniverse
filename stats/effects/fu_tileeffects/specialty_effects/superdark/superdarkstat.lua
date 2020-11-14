--particleList={"blurshadowradiallarge","blurshadowradialmid","blurshadowradial"}
particleList={"/animations/superdark/superdarksuperlarge.png","/animations/superdark/superdarklarge.png","/animations/superdark/superdarkmid.png","/animations/superdark/superdark.png"}


function init()
	script.setUpdateDelta(1)
	darklevel=config.getParameter("darklevel",1)
	darkpriority=config.getParameter("darkpriority",1)
	setParticleConfig(0)
	tryRun(0)
end

function update(dt)
	tryRun(dt)
end

function tryRun(dt)
	handleDarkStats()
	if world.entityType(entity.id()) == "player" then
		--animator.setParticleEmitterActive("smoke", thisCanRun())
		if thisCanRun() then
			setParticleConfig(dt)
			world.sendEntityMessage(entity.id(),"fu_specialAnimator.spawnParticle",particleConfig)
		end
	end
end

function setParticleConfig(dt)
	if not particleConfig then
		particleConfig={type = "textured",position = {0, 0},velocity = {0, 0},approach = {0, 0},destructionAction = "fade",size = 1,layer = "front",variance = {initialVelocity = {0, 0}}}
	end
	particleConfig.position=entity.position()
	particleConfig.timeToLive = dt*10.0
	particleConfig.destructionTime = dt*1.0
	particleConfig.image=particleList[darklevel]
end

function uninit()
	if world.entityType(entity.id()) == "player" then
		--animator.setParticleEmitterActive("smoke", false)
		handleDarkStats(true)
	end
end

function handleDarkStats(terminate)
	if not terminate then
		local dP=status.statusProperty("darkpriority") or 0
		local dL=status.statusProperty("darklevel") or 0
		if dL<darklevel then
			status.setStatusProperty("darklevel",darklevel)
			status.setStatusProperty("darkpriority",darkpriority)
		elseif dL==darklevel then
			if dP<darkpriority then
				status.setStatusProperty("darkpriority",darkpriority)
			end
		end
	else
		status.setStatusProperty("darkpriority",0)
		status.setStatusProperty("darklevel",0)
	end
end

function thisCanRun()
	local dP=status.statusProperty("darkpriority") or 0
	local dL=status.statusProperty("darklevel") or 0
	return ((dP==darkpriority) and (dL==darklevel))
end
