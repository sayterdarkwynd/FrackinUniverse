require "/scripts/kheAA/excavatorCommon.lua"

function init()
	excavatorCommon.init();
end

function anims()
	animHorizontal({storage.width,1})
	if storage.drillPos==nil then
		drillReset()
	end
	renderDrill(storage.drillPos)
end

function renderDrill(pos)
	animator.resetTransformationGroup("vertical")
	animator.scaleTransformationGroup("vertical", {1,math.min(0,pos[2] + 2)});
	animator.translateTransformationGroup("vertical", {pos[1],1}); 
	animator.resetTransformationGroup("drill")
	animator.translateTransformationGroup("drill", {pos[1] - 0.5, pos[2] + 1}); 
	animator.resetTransformationGroup("connector")
	animator.translateTransformationGroup("connector", {pos[1], 1}); 
end

function animHorizontal()
	animator.resetTransformationGroup("horizontal")
	animator.scaleTransformationGroup("horizontal", {storage.width + step,1});
	animator.setAnimationState("horizontalState", "on");
	animator.resetTransformationGroup("horizontal")
	animator.scaleTransformationGroup("horizontal", {storage.width,1});
	animator.translateTransformationGroup("horizontal", {2,1});
end

function drillReset()
	storage.drillPos = {1,-1};
	storage.drillTarget = {0,0};
	storage.drillDir = {0,0};
end

function setRunning(running)
	if running then
		storage.running = true;
		animator.setAnimationState("quarryState", "on")
		animator.setAnimationState("drillState", "on")
	else
		storage.running = false;
		animator.setAnimationState("drillState", "idle")
		animator.setAnimationState("quarryState", "off")
	end
end

function update(dt)
	excavatorCommon.cycle(dt)
end
