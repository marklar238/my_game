-- src/gfx/sprite.lua
local Sprite = {}
Sprite.__index = Sprite

function Sprite.new(path, frameW, frameH, speed)
  local self = setmetatable({}, Sprite)
  self.image = love.graphics.newImage(path)
  self.frameW = frameW
  self.frameH = frameH
  self.speed = speed or 0.15
  self.timer = 0
  self.current = 1
  self.quads = {}

  local imgW, imgH = self.image:getDimensions()
  for x = 0, imgW - frameW, frameW do
    table.insert(self.quads, love.graphics.newQuad(x, 0, frameW, frameH, imgW, imgH))
  end

  return self
end

function Sprite:update(dt)
  self.timer = self.timer + dt
  if self.timer >= self.speed then
    self.timer = self.timer - self.speed
    self.current = (self.current % #self.quads) + 1
  end
end

function Sprite:draw(x, y)
  -- Save current color, draw sprite in pure white (no tint), then restore.
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self.image, self.quads[self.current], x, y, 0, 1, 1, self.frameW/2, self.frameH/2)
  love.graphics.setColor(r, g, b, a)
end

return Sprite
