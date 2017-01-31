require "/scripts/kheAA/transferUtil.lua"
local deltatime = 0;
local linkRange=1;

function init()
	transferUtil.init()
	storage.receiveItems=true
	inDataNode=0
	outDataNode=0
	storage.inContainers={}
	storage.outContainers={}
	storage.containerId=nil
	storage.containerRect={}
	storage.containerPos={0,0}
	linkRange=20
end

function update(dt)
	deltatime = deltatime + dt;
	if deltatime < 1 then
		return;
	end
	deltatime=0
	findContainer()
	object.setOutputNodeLevel(outDataNode,not storage.containerId==nil)
end

function loadContainer()
	if storage.containerId == nil then return end
	
	if not world.regionActive(transferUtil.containerRect) then
		world.loadRegion(storage.containerRect)
	end
end

--[[function particleBurst()
	if storage.containerId == nil then return
	elseif not world.regionActive(transferUtil.pos2Rect(storage.position,linkRange)) then
		return
	end
	animator.setParticleEmitterOffsetRegion("lightBeam",{-1,-1,-1,-1})
	animator.burstParticleEmitter("lightBeam")
	local posA = storage.position
	local posB = storage.containerPos
	local distance=world.distance(posA,posB)
	local step={distance[1]/0.1,distance[2]/0.1}
	for i=0,9 do
		animator.setParticleEmitterOffsetRegion("lightBeam",transferUtil.pos2Rect({step[1]*i,step[2]*i},1))
		animator.burstParticleEmitter("lightBeam")
	end
end]]--

function findContainer()
	if storage.containerId == nil then
		local tempRect=transferUtil.pos2Rect(storage.position,linkRange)
		if not world.regionActive(temprect) then
			world.loadRegion(tempRect)
		end
	elseif not world.regionActive(storage.containerRect) then
		world.loadRegion(storage.containerRect)
		if not world.entityExists(storage.containerId) then
			storage.containerId=nil
		end
	end

	local objectIds = world.objectQuery(entity.position(), linkRange, { order = "nearest" })
	for _, objectId in pairs(objectIds) do
		if world.containerSize(objectId) then
			storage.containerId=objectId
			storage.containerPos=world.callScriptedEntity(storage.containerId,"entity.position")
			storage.containerRect=transferUtil.spacePos2Rect(world.objectSpaces(storage.containerId),storage.containerPos)
			storage.inContainers[storage.containerId]=storage.containerRect
			storage.outContainers[storage.containerId]=storage.containerRect
			break
		end
	end 
end
