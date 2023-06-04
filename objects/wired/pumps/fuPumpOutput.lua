function receivedLiquidPumpInput()
	storage.currentState=true
	storage.timer=1
end

function init()
	storage.currentState=storage.currentState or false
	animator.setAnimationState("outputState",stateCurrent and "on" or "off")
	--message.setHandler("sentLiquid",function () storage.timer=1 end)
end

function update(dt)
	if not storage.timer or storage.timer <= 0 then
		storage.currentState=false
	else
		storage.timer=storage.timer-dt
	end

	animator.setAnimationState("outputState",stateCurrent and "on" or "off")
	object.setAllOutputNodes(storage.currentState)
end