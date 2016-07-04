local oldtileMaterials = tileMaterials

function tileMaterials()
  oldtileMaterials()
  sb.logInfo("fu_tilematerials has loaded")
  -- ["materialName"] = {{EphemeralEffects to apply},
  --  groundMovementModifier, runModifier, jumpModifier,      <-- mcontroller.controlModifiers
  --  normalGroundFriction, groundForce, slopeSlidingFactor,  <-- mcontroller.controlParameters 
  --  groundSoftness}
  						 --effect      Move  Run  Jump  Fric   Force Slide  Bounce  Softness
              		
  self.matCheck["mud"] = 	     		{{"fumudslow"},  0.8, 1,   1,   14,   101, 0.25,    0,  1.75}
  self.matCheck["clay"] = 	    		{{"fuclayslow"}, 1,   1,   1,   14,   101,    0,    0,  1.75}
  self.matCheck["sand"] = 	    		{{"jungleslow"}, 1,   1,   1,   14,   101,    0.5,  0,  1.9}
  self.matCheck["rainbowsand"] = 		{{"jungleslow"}, 1,   1,   1,   14,   101,    0.5,  0,  1.2}
  self.matCheck["glowingsand"] = 		{{"glow"},       1,   1,   1,   14,   101,    0.5,  0,  1.2} 
  self.matCheck["crystalsand"] = 		{{"jungleslow"}, 1,   1,   1,   14,   101,    0.5,  0,  1.9}
  self.matCheck["glasssand"] = 		        {{"jungleslow"}, 1,   1,   1,   14,   101,  0.5,    0,  1.9}
  self.matCheck["redsand"] = 		        {{"jungleslow"}, 1,   1,   1,   14,   101,  0.5,    0,  1.9}
  self.matCheck["jungledirt2"] = 		{{"jungleslow"}, 1,   1,   1,   14,   100,  0.0,    0,  1}
  self.matCheck["swampdirtff"] = 		{{"jungleslow"}, 1,   1,   1,   14,   100,  0.0,    0,  1}
  self.matCheck["springvines"] = 		{{"jungleslow"}, 1,   1,   1,   14,   100,  0.0,    0,  1}
  self.matCheck["frozenwater"] = 		{{"iceslip"},    1,   1,   1,   14,   100,  0.0,    0,  1}
  self.matCheck["ice"] = 			{{"iceslip"},    1,   1,   1,   14,   100,  0.0,    0,  1}
  self.matCheck["iceblock1"] = 		        {{"iceslip"},    1,   1,   1,   14,   100,  0.0,    0,  1}
  self.matCheck["iceblock2"] = 		        {{"iceslip"},    1,   1,   1,   14,   100,  0.0,    0,  1}
  self.matCheck["iceblock3"] = 		        {{"iceslip3"},   1,   1,   1,   14,   101,  1.0,    0,  1.2}
  self.matCheck["iceblock4"] = 		        {{"iceslip2"},   1,   1,   1,   14,   101,  1.0,    0,  1.2}
  self.matCheck["snow"] = 			{{"snowslow"},   1,   1,   1,   14,   100,  0.0,    0,  1}
  self.matCheck["slush"] = 			{{"slushslow"},  1,   1,   1,   14,   100,  0.0,    0,  1}
  self.matCheck["slime"] = 			{{"slimestick"}, 1,   1,   1,   14,   101,  1.0,    1,  1.75}
  self.matCheck["slime2"] = 			{{"slimestick"}, 1,   1,   1,   14,   101,  1.0,    1,  1.75}
  self.matCheck["jellyblock"] = 		{{"slimestick"}, 1,   1,   1,   14,   101,  1.0,    1,  1.75}
  self.matCheck["jellystone"] = 		{{"jumpboost15"},1,   1,   1,   14,   100,  0.0,    1,  1}
  self.matCheck["blackslime"] =    {{"slimestick","weakpoison"}, 1,   1,   1,   14,   101,  1.5,    0,  1.65}
  self.matCheck["spidersilkblock"] = 	        {{"webstick"},   1,   1,   1,   14,   101,  0.0,    0,  1.32}
  self.matCheck["irradiatedtile"] = 	      {{"radiationburn"},1,   1,   1,   14,   100,  0.0,    0,  1}
  self.matCheck["irradiatedtile2"] =          {{"radiationburn"},1,   1,   1,   14,   100,  0.0,    0,  1}
  self.matCheck["irradiatedtile3"] =          {{"radiationburn"},1,   1,   1,   14,   100,  0.0,    0,  1}
  self.matCheck["protorock"] = 	         {{"ffextremeradiation"},1,   1,   1,   14,   100,  0.0,    0,  1.3}
  self.matCheck["bioblock"] = 	          {{"regenerationblock"},1,   1,   1,   14,   100,  0.0,    0,  1.1}
  self.matCheck["bioblock2"] = 	          {{"regenerationblock"},1,   1,   1,   14,   100,  0.0,    0,  1.2}
  self.matCheck["biodirt"] = 	          {{"regenerationblock"},1,   1,   1,   14,   101,  1.0,    0,  1.85}
  self.matCheck["metallic"] = 	                 {{"metalspeed"},1,   1,   1,   14,   100,  0.0,    0,  1.3}
  self.matCheck["asphalt"] = 	                 {{"metalspeed"},1,   1,   1,   14,   100,  0.0,    0,  1.4}
  self.matCheck["cloudblock"] = 	            {{"lowgrav"},1,   1,   1,   14,   101,  1.0,    0,  1.2}
  self.matCheck["raincloud"] = 	                    {{"lowgrav"},1,   1,   1,   14,   101,  1.0,    0,  1.2}
  self.matCheck["honeycombmaterial"] =            {{"honeyslow"},1,   1,   1,   14,   101,  0.0,    0,  1.7}  
  self.matCheck["speedblock"] = 		 {{"runboost35"},1,   1,   1,   14,   101,  0.0,    0,  1.75} 
  self.matCheck["jumpblock"] = 		        {{"jumpboost35"},1,   1,   1,   14,   101,  0.0,    0,  1.75} 
  self.matCheck["moltensteel"] = 		    {{"burning"},1,   1,   1,   14,   101,  0.0,    0,  1.75} 
  self.matCheck["moltentile"] = 		    {{"burning"},1,   1,   1,   14,   101,  0.0,    0,  1.75} 
  self.matCheck["moltensand"] = 		    {{"burning"},1,   1,   1,   14,   101,  0.0,    0,  1.75} 
  self.matCheck["moltenmetal"] = 		    {{"burning"},1,   1,   1,   14,   101,  0.0,    0,  1.75} 
  self.matCheck["magmatile"] = 		            {{"burning"},1,   1,   1,   14,   100,  0.0,    0,  1}
  self.matCheck["magmatile2"] = 		    {{"burning"},1,   1,   1,   14,   100,  0.0,    0,  1}
  self.matCheck["redhotcobblestone"] = 	            {{"burning"},1,   1,   1,   14,   100,  0.0,    0,  1}  
  self.matCheck["fublueslimedirt"] =   {{"regenerationblock","slimestick"},1,1,1,14,100,0.0,1,1.1}
  self.matCheck["fublueslime"] = 	{{"regenerationblock","slimestick"},1,1,1,14,100,0.0,1,1.1}
 self.matCheck["fublueslimestone"] = {{"regenerationblock","slimestick"},1,1,1,14,100,0.0,0.5,1.1}

end

