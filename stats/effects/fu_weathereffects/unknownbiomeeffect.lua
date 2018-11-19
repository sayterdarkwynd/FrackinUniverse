function init()
  self.value = math.random(10)
  self.activated = 0
end

function update(dt)
  if self.activated==0 then
        if self.value > 1 then
	  self.activated = 1
	end
	if self.value==1
		status.addEphemeralEffect( "ffextremecold" )
	elseif self.value==2
		status.addEphemeralEffect( "ffextremeradiation" )
	elseif self.value==3
		status.addEphemeralEffect( "biomecold" )
	elseif self.value==4
		status.addEphemeralEffect( "biomeheat" )
	elseif self.value==5
		status.addEphemeralEffect( "biomeradiation" )
	elseif self.value==6
		status.addEphemeralEffect( "ffextremesulphuric" )
	elseif self.value==7
		status.addEphemeralEffect( "gasworld" )
	elseif self.value==8
		status.addEphemeralEffect( "metallichydrogengas" )
	elseif self.value==9
		status.addEphemeralEffect( "poisongas" )
	elseif self.value==10
		status.addEphemeralEffect( "weakenweather" )
	elseif self.value==11
		status.addEphemeralEffect( "aetherweathernew" )
	elseif self.value==12
		status.addEphemeralEffect( "aetherweathernew2" )
	elseif self.value==13
		status.addEphemeralEffect( "aetherweathernew3" )
	elseif self.value==14
		status.addEphemeralEffect( "ffbiomecold0" )
	elseif self.value==15
		status.addEphemeralEffect( "ffbiomecold1" )
	elseif self.value==16
		status.addEphemeralEffect( "ffbiomecold2" )
	elseif self.value==17
		status.addEphemeralEffect( "ffbiomecold3" )
	elseif self.value==18
		status.addEphemeralEffect( "desertweathernew" )
	elseif self.value==19
		status.addEphemeralEffect( "ffbiomeheat1" )
	elseif self.value==20
		status.addEphemeralEffect( "ffbiomeheat2" )		
	elseif self.value==21
		status.addEphemeralEffect( "ffbiomeheat3" )
	elseif self.value==22
		status.addEphemeralEffect( "insanitynew" )
	elseif self.value==23
		status.addEphemeralEffect( "insanitynew2" )
	elseif self.value==24
		status.addEphemeralEffect( "biomepoison1" )
	elseif self.value==25
		status.addEphemeralEffect( "biomepoison2" )
	elseif self.value==26
		status.addEphemeralEffect( "biomepoison3" )
	elseif self.value==27
		status.addEphemeralEffect( "biomepoisongas" )
	elseif self.value==28
		status.addEphemeralEffect( "poisonweathernew" )
	elseif self.value==29
		status.addEphemeralEffect( "protoweather" )
	elseif self.value==30
		status.addEphemeralEffect( "protoweather2" )
	elseif self.value==31
		status.addEphemeralEffect( "radioactiveweathernew" )
	elseif self.value==32
		status.addEphemeralEffect( "radioactiveweathernew2" )
	elseif self.value==33
		status.addEphemeralEffect( "radioactiveweathernew3" )
	elseif self.value==34
		status.addEphemeralEffect( "sulphuricweathernew" )
	elseif self.value==35
		status.addEphemeralEffect( "sulphuricweathernew2" )
	elseif self.value==36
		status.addEphemeralEffect( "jungleheatweather" )
	elseif self.value==37
		status.addEphemeralEffect( "darkstalker" )
	elseif self.value==38
		status.addEphemeralEffect( "darkwaterpoison" )
	elseif self.value==39
		status.addEphemeralEffect( "helium3" )
	elseif self.value==40
		status.addEphemeralEffect( "shadowgasfx" )
	elseif self.value==41 then
		status.addEphemeralEffect( "ffextremeheat" )	
	elseif self.value==42
		status.addEphemeralEffect( "ffbiomecold4" )		
	end  
  else
    effect.expire()
  end

end

function uninit()
status.removeEphemeralEffect( "glowpurple" )
end
