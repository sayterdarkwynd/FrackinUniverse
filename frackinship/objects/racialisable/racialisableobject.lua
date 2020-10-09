local origInit = init or function() end

function init()
	origInit()
	
	message.setHandler("racialise", function(_, _, newImage)
		local animationParts = config.getParameter("animationParts")
		animationParts.door = newImage
		object.setConfigParameter("animationParts", animationParts)
		animator.setPartTag("door", "partImage", newImage)
	end)
end