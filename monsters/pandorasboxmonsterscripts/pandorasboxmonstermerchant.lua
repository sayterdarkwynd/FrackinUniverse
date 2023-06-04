local originalInit = init

function init()
	originalInit()
	if config.getParameter("wildShopkeeper") or config.getParameter("ownerUuid") then
			monster.setInteractive(true)
	end
end

function interact()
return {config.getParameter("interactAction"), config.getParameter("interactData")}
end
