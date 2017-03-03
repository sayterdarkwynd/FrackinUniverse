item=nil

function scanButton()
	
end

function printButton()
	if item ~= nil
	world.containerAddItems(pane.containerEntityId(),item)
end


function bye()
	pane.dismiss()
end