local Player = {}
local Movement = require("src.game.movement")
Movement.setIdleAnimFrames(player, /*upFrame=*/2, /*downFrame=*/3, /*rate=*/0.35)

Player.__index = Player

function Player.new(x, y)
  return setmetatable({
    x = x, y = y,
    speed = 200,
    w = 16, h = 16
  }, Player)
end

function Player:update(dt)
  local dx, dy = 0, 0
  if love.keyboard.isDown("left","a")  then dx = dx - 1 end
  if love.keyboard.isDown("right","d") then dx = dx + 1 end
  if love.keyboard.isDown("up","w")    then dy = dy - 1 end
  if love.keyboard.isDown("down","s")  then dy = dy + 1 end

  if dx ~= 0 or dy ~= 0 then
    local len = math.sqrt(dx*dx + dy*dy)
    dx, dy = dx/len, dy/len
  end

  self.x = self.x + dx * self.speed * dt
  self.y = self.y + dy * self.speed * dt
end

function Player:draw()
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

return Player
