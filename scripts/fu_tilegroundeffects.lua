local oldtileMaterials = tileMaterials

function tileMaterials()
  oldtileMaterials()
  -- sb.logInfo("fu_tilematerials has loaded")
  -- ["materialName"] = {{EphemeralEffects to apply},
  --  groundMovementModifier, runModifier, jumpModifier,      <-- mcontroller.controlModifiers
  --  normalGroundFriction, groundForce, slopeSlidingFactor,  <-- mcontroller.controlParameters 
  --  groundSoftness}
  						 --effect      Move  Run  Jump  Fric   Force Slide  Bounce  Softness  (softness / dmg / sound)
              		
  self.matCheck["mud"] = 	     		{{"fumudslow"},  0.8, 1,   1,   14,   101, 0.25,    0,  1.75,1,3,"/sfx/blocks/footstep_ash.ogg"}
  self.matCheck["clay"] = 	    		{{"fuclayslow"}, 1,   1,   1,   14,   101,    0,    0,  1.75,1,3,"/sfx/blocks/footstep_ash.ogg"}
  self.matCheck["sand"] = 	    		{{"jungleslow"}, 1,   1,   1,   14,   101,    0.5,  0,  1.9, 2,3,"/sfx/blocks/footstep_ash.ogg"}
  self.matCheck["rainbowsand"] = 		{{"jungleslow"}, 1,   1,   1,   14,   101,    0.5,  0,  1.2, 2,3,"/sfx/blocks/footstep_ash.ogg"}
  self.matCheck["glowingsand"] = 		{{"glow"},       1,   1,   1,   14,   101,    0.5,  0,  1.2, 2,3,"/sfx/blocks/footstep_ash.ogg"} 
  self.matCheck["crystalsand"] = 		{{"jungleslow"}, 1,   1,   1,   14,   101,    0.5,  0,  1.9, 0}
  self.matCheck["glasssand"] = 		        {{"jungleslow"}, 1,   1,   1,   14,   101,  0.5,    0,  1.9, 5,5,"/sfx/blocks/footstep_ash.ogg"}
  self.matCheck["redsand"] = 		        {{"jungleslow"}, 1,   1,   1,   14,   101,  0.5,    0,  1.9, 0}
  self.matCheck["jungledirt1"] = 	        {{"jungleslow"}, 1,   1,   1,   14,   100,  0.0,    0,  1,   0} 
  self.matCheck["jungledirt2"] = 		{{"jungleslow"}, 1,   1,   1,   14,   100,  0.0,    0,  1,   0}
  self.matCheck["swampdirtff"] = 		{{"jungleslow"}, 1,   1,   1,   14,   100,  0.0,    0,  1,   0}
  self.matCheck["springvines"] = 		{{"jungleslow"}, 1,   1,   1,   14,   100,  0.0,    0,  1,   0}
  self.matCheck["frozenwater"] = 		{{"iceslip"},    1,   1,   1,   14,   100,  0.0,    0,  1,   10, 3, "/sfx/objects/ice_break1.ogg"}
  self.matCheck["glass"] =                      {{         },    1,   1,   1,   14,   101,  0.0,    0,  1,   10, 5, "/sfx/objects/prism_break_large2.ogg"}
  self.matCheck["ice"] = 			{{"iceslip"},    1,   1,   1,   14,   100,  0.0,    0,  1,   10, 3, "/sfx/objects/ice_break1.ogg"}
  self.matCheck["iceblock1"] = 		        {{"iceslip"},    1,   1,   1,   14,   100,  0.0,    0,  1,   3,3, "/sfx/objects/ice_break1.ogg"}
  self.matCheck["iceblock2"] = 		        {{"iceslip"},    1,   1,   1,   14,   100,  0.0,    0,  1,   3,3, "/sfx/objects/ice_break1.ogg"}
  self.matCheck["iceblock3"] = 		        {{"iceslip3"},   1,   1,   1,   14,   101,  1.0,    0,  1.2, 3,3, "/sfx/objects/ice_break1.ogg"}
  self.matCheck["iceblock4"] = 		        {{"iceslip2"},   1,   1,   1,   14,   101,  1.0,    0,  1.2, 3,3, "/sfx/objects/ice_break1.ogg"}
  self.matCheck["snow"] = 			{{"snowslow"},   1,   1,   1,   14,   100,  0.0,    0,  1,   8, 3, "/sfx/blocks/footstep_ash.ogg"}
  self.matCheck["slush"] = 			{{"slushslow"},  1,   1,   1,   14,   100,  0.0,    0,  1,    8, 3, "/sfx/blocks/footstep_ash.ogg"}
  self.matCheck["slime"] = 			{{"slimestick"}, 1,   1,   1,   14,   101,  1.0,    1,  1.75, 0}
  self.matCheck["slime2"] = 			{{"slimestick"}, 1,   1,   1,   14,   101,  1.0,    1,  1.75, 0}
  self.matCheck["jellyblock"] = 		{{"slimestick"}, 1,   1,   1,   14,   101,  1.0,    1,  1.75, 0}
  self.matCheck["fujellyblock"] = 		{{"slimestick"}, 1,   1,   1,   14,   101,  1.0,    1,  1.75, 0}
  self.matCheck["jellystone"] = 		{{"jumpboost15"},1,   1,   1,   14,   100,  0.0,    1,  1, 0}
  self.matCheck["blackslime"] =    {{"slimestick","weakpoison"}, 1,   1,   1,   14,   101,  1.5,    0,  1.65, 0}
  self.matCheck["spidersilkblock"] = 	        {{"webstick"},   1,   1,   1,   14,   101,  0.0,    0,  1.32, 0}
  self.matCheck["irradiatedtile"] =  {{"negativehealthirradiated"},1,   1,   1,   14,   100,  0.0,    0,  1, 0}
  self.matCheck["irradiatedtile2"]= {{"percentarmorboostnegproto"},1,   1,   1,   14,   100,  0.0,    0,  1, 0}
  self.matCheck["irradiatedtile3"] =            {{"radiationburn"},1,   1,   1,   14,   100,  0.0,    0,  1, 0}
  self.matCheck["protorock"] = 	         {{"ffextremeradiation"},1,   1,   1,   14,   100,  0.0,    0,  1.3, 0}
  self.matCheck["bioblock"] = 	                  {{"fumudslow"},1,   1,   1,   14,   100,  0.0,    0,  1.1, 0}
  self.matCheck["bioblock2"] = 	  {{"percentarmorboostnegproto"},1,   1,   1,   14,   100,  0.0,    0,  1.2, 0}
  self.matCheck["metallic"] = 	                 {{"metalspeed"},1,   1,   1,   14,   100,  0.0,    0,  1.3, 0}
  self.matCheck["asphalt"] = 	                 {{"metalspeed"},1,   1,   1,   14,   100,  0.0,    0,  1.4, 0}
  self.matCheck["cloudblock"] = 	            {{"lowgrav"},1,   1,   1,   14,   101,  1.0,    0,  1.2, 10,10,"/sfx/blocks/footstep_ash.ogg"}
  self.matCheck["raincloud"] = 	          {{"lowgrav_fallspeed"},1,   1,   1,   14,   101,  1.0,    0,  1.2, 10,10,"/sfx/blocks/footstep_ash.ogg"}
  self.matCheck["honeycombmaterial"] =            {{"honeyslow"},1,   1,   1,   14,   101,  0.0,    0,  1.7, 0}  
  self.matCheck["speedblock"] = 		 {{"runboost35"},1,   1,   1,   14,   101,  0.0,    0,  1.75, 0} 
  self.matCheck["jumpblock"] = 		        {{"jumpboost35"},1,   1,   1,   14,   101,  0.0,    0,  1.75, 0} 
  self.matCheck["moltensteel"] = 		    {{"burning"},1,   1,   1,   14,   101,  0.0,    0,  1.75, 0} 
  self.matCheck["moltentile"] = 		    {{"burning"},1,   1,   1,   14,   101,  0.0,    0,  1.75, 0} 
  self.matCheck["moltensand"] = 		    {{"burning"},1,   1,   1,   14,   101,  0.0,    0,  1.75, 0} 
  self.matCheck["moltenmetal"] = 		    {{"burning"},1,   1,   1,   14,   101,  0.0,    0,  1.75, 0} 
  self.matCheck["magmatile"] = 		            {{"burning"},1,   1,   1,   14,   100,  0.0,    0,  1, 0, 0}
  self.matCheck["magmatile2"] = 		    {{"burning"},1,   1,   1,   14,   100,  0.0,    0,  1, 0, 0}
  self.matCheck["redhotcobblestone"] = 	            {{"burning"},1,   1,   1,   14,   100,  0.0,    0,  1, 0, 0}  
  self.matCheck["fublueslimedirt"] =   {{"regenerationblock","slimestick"},1,1,1,14,100,0.0,1,1.1, 2,"/sfx/blocks/footstep_ash.ogg"}
  self.matCheck["fublueslime"] = 	{{"regenerationblock","slimestick"},1,1,1,14,100,0.0,1,1.1, 2,"/sfx/blocks/footstep_ash.ogg"}
 self.matCheck["fublueslimestone"] = {{"regenerationblock","slimestick"},1,1,1,14,100,0.0,0.5,1.1, 0}

end

