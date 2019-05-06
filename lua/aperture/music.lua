--[[

APERTURE API MAIN

]]
AddCSLuaFile()

LIB_LASERMUSIC = {}

function LIB_LASERMUSIC:PlaySong(ent, music)
     if music == "none" or music == nil or music == "" then
          return
     end

     if music == "wheatley" then
          ent:EmitSound("TA:wheatleymusic1")

          return
     end

     if music == "triple laser 1" then
          ent:EmitSound("TA:trimusic1")

          return
     end
     if music == "triple laser 2" then
          ent:EmitSound("TA:trimusic2")

          return
     end
     if music == "triple laser 3" then
          ent:EmitSound("TA:trimusic3")

          return
     end

     if music == "radio" then
          ent:EmitSound("TA:radio_laser")

          return
     end
     if music == "portal 1" then
          ent:EmitSound("TA:portal1music")

          return
     end
end
function LIB_LASERMUSIC:StopSong(ent, music)
     if music == "none" or music == nil or music == "" then
          return
     end

     if music == "wheatley" then
          ent:StopSound("TA:wheatleymusic1")

          return
     end

     if music == "triple laser 1" then
          ent:StopSound("TA:trimusic1")
          return
     end
     if music == "triple laser 2" then
          ent:StopSound("TA:trimusic2")
          return
     end
     if music == "triple laser 3" then
          ent:StopSound("TA:trimusic3")
          return
     end
     if music == "radio" then
          ent:StopSound("TA:radio_laser")
          return
     end
     if music == "portal 1" then
          ent:StopSound("TA:portal1music")
          return
     end
end
