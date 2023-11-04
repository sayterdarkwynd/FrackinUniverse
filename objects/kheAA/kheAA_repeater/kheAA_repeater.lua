require "/scripts/kheAA/transferUtil.lua"

function init()
	transferUtil.init()
	transferUtil.vars.inContainers={}
	transferUtil.vars.outContainers={}
	transferUtil.vars.upstreamCount=0
	transferUtil.vars.isRelayNode=true
	animator.setAnimationState("repeaterState","off")
end

function update(dt)
	deltatime=(deltatime or 0)+dt
	if deltatime < 1 then
		return
	end
	deltatime=0

	local nodeUpdatePassed=transferUtil.updateNodeLists()
	local hasUpstream=transferUtil.checkUpstreamContainers()

	if nodeUpdatePassed then
		animator.setSoundVolume("alarm",0,0)
		animator.setAnimationState("repeaterState",(hasUpstream and "on") or "off")
	else
		animator.setSoundVolume("alarm",1.0,0)
		animator.playSound("alarm")
		animator.setAnimationState("repeaterState","error")
	end

	object.setOutputNodeLevel(transferUtil.vars.inDataNode,hasUpstream and 1 or 0)
end
