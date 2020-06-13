--particleList={"blurshadowradiallarge","blurshadowradialmid","blurshadowradial"}
particleList={"/animations/superdark/superdarklarge.png","/animations/superdark/superdarkmid.png","/animations/superdark/superdark.png"}


function init()
	script.setUpdateDelta(1)
	darklevel=config.getParameter("darklevel",1)
	darkpriority=config.getParameter("darkpriority",1)
	setParticleConfig()
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
			particleConfig.position=entity.position()
			world.sendEntityMessage(entity.id(),"fu_specialAnimator.spawnParticle",particleConfig)
		end
	end
end

function setParticleConfig()
	particleConfig={type = "textured",position = {0, 0},velocity = {0, 0},approach = {0, 0},destructionAction = "fade",size = 1,layer = "front",variance = {initialVelocity = {0, 0}}}
	dt=script.updateDt()
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
			dL=darklevel
			status.setStatusProperty("darkpriority",darklevel)
			dP=darkpriority
		end
		if dP<darkpriority then
			status.setStatusProperty("darkpriority",darklevel)
			dP=darkpriority
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