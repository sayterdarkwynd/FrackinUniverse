item=nil

function scanButton()
	local temp=world.containerItems(pane.containerEntityId())
	item=temp and temp[1] or nil
end

function printButton()
	if item == nil then return end
	world.containerAddItems(pane.containerEntityId(),item)
end


function bye()
	pane.dismiss()
end