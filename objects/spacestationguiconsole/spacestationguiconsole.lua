function init()
	message.setHandler('getStorage', getStorage)
	message.setHandler('setStorage', setStorage)
	message.setHandler('setInteractable', setInteractable)
	
	object.setInteractive(true)
end

function setInteractable(_,_,bool)
	object.setInteractive(bool)
end

function setStorage(_,_,data)
	storage.objectData = data
end

function getStorage()
	return storage.objectData
end

function update() end
function uninit() end