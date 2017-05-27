function init()
  self.blockbuster = config.getParameter("blockbuster", {})

  message.setHandler("timetolive", function(_, _, time)
      projectile.setTimeToLive(time)
      projectile.processAction(self.blockbuster)
    end)
end

function update()
  projectile.processAction(self.blockbuster)
end

function uninit()

end
