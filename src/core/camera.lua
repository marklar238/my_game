-- Stub camera; swap in real pan/zoom later
local Cam = { x = 0, y = 0, zoom = 1 }
function Cam.apply() end
function Cam.screen_to_world(x,y) return x, y end
function Cam.world_to_screen(x,y) return x, y end
return Cam