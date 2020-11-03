function init()
end

function update(dt)
	script.setUpdateDelta(0)
end

function doShuffle()
	world.sendEntityMessage(pane.containerEntityId(),"doShuffle")
end
