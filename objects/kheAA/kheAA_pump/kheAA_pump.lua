require "/scripts/kheAA/excavatorCommon.lua"

function init()
	excavatorCommon.init();
end


function anims()
	setRunning(storage.running)
	renderPump()
end

function setRunning(running)
	if running then
		--storage.running = true;
		animator.setAnimationState("pumpState", "on")
		animator.setAnimationState("pipeState", "on")
	else
		--storage.running = false;
		animator.setAnimationState("pumpState", "off")
	end
end

function renderPump(step)
	if step==nil then
		step=0
	end
	animator.resetTransformationGroup("pipe")
	local temp=math.min(0,storage.depth-step)
	animator.scaleTransformationGroup("pipe", {1,temp});
	animator.translateTransformationGroup("pipe", {1,1});
end

function update(dt)
	excavatorCommon.cycle(dt)
end

function die()
	liquidLib.die()
end