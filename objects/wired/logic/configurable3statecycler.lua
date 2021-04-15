--khe was here! No really. dragoncat code work.

function init()
	guiConfig = root.assetJson("/interface/scripted/logicgates/3statecyclerGUI.config")
	message.setHandler("setTimerValues",setValues)
	message.setHandler("sendConfig",sendConfig)
	message.setHandler("resetTimerValues",resetValues)
	handleLoading()
	--doAnim()
	script.setUpdateDelta(1)
	object.setInteractive(true)
end

function handleLoading()
	storage.leftValue=numFix(storage.leftValue or 26)
	storage.midValue=numFix(storage.midValue or 2)
	storage.rightValue=numFix(storage.rightValue or 2)
	storage.state=-1
	runCircuit()
end

function runCircuit()

	if object.isInputNodeConnected(0) and not object.getInputNodeLevel(0) then
		storage.timeup=0
		storage.state=-1
	elseif storage.state==1 then
		storage.timeup=storage.rightValue
		storage.state=2
	elseif storage.state==2 or storage.state==-1 then
		storage.timeup=storage.leftValue
		storage.state=0
	else
		storage.timeup=storage.midValue
		storage.state=1
	end
	object.setOutputNodeLevel(0,storage.state==0)
	object.setOutputNodeLevel(1,storage.state==1)
	object.setOutputNodeLevel(2,storage.state==2)
	storage.timer=0
end

function update(dt)
	storage.timer=storage.timer+dt or 0
	if storage.timer > storage.timeup then
		runCircuit()
	end
end

function setValues(_,_,values)
	for k,v in pairs(values) do
		storage[k]=v
	end
	init()
end

function resetValues()
	storage.state=-2
	storage.leftValue=26
	storage.midValue=2
	storage.rightValue=2
	return {leftValue=storage.leftValue,midValue=storage.midValue,rightValue=storage.rightValue}
end

function doAnim()
	local e=(storage.state >= 0) and "on" or "off"
	if animator.animationState("switchState")~=e then animator.setAnimationState("switchState",e) end
	--animator.setAnimationState("switchState", (storage.state >= 0) and "on" or "off")
end

function onInputNodeChange()
	handleLoading()
end

function onNodeConnectionChange()
	handleLoading()
end

function sendConfig()
	return storage
end

function onInteraction(args)
  return {"ScriptPane", guiConfig}
end

function numFix(v)
	if type(v) ~= "number" then
		v=tonumber(v)
	end
	return(v)
end