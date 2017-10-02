--khe was here! No really. dragoncat code work.

function init()
	message.setHandler("setTimerValues",setValues)
	message.setHandler("resetTimerValues",function() storage.state=-2 end)
	if storage.state and storage.state==-2 then
		storage.leftValue=26
		storage.midValue=2
		storage.rightValue=2
	else
		storage.leftValue=storage.leftValue or 26
		storage.midValue=storage.midValue or 2
		storage.rightValue=storage.rightValue or 2
	end
	storage.state=-1
	runCircuit()
	--doAnim()
	script.setUpdateDelta(1)
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
	storage.leftValue=values[0]
	storage.midValue=values[1]
	storage.rightValue=values[2]
	init()
end

function doAnim()
	animator.setAnimationState("switchState", (storage.state >= 0) and "on" or "off")
end

function onInputNodeChange()
	init()
end

function onNodeConnectionChange()
	init()
end
