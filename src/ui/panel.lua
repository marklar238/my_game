local Theme = require("src.ui.theme")
local Panel = {}

function Panel.draw(rect, title, font)
  love.graphics.setColor(Theme.panelBg)
  love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, Theme.r, Theme.r)
  love.graphics.setColor(Theme.panelLn)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, Theme.r, Theme.r)
  if title then
    love.graphics.setFont(font)
    love.graphics.setColor(Theme.fg)
    love.graphics.print(title, rect.x + 10, rect.y + 8)
  end
end

return Panel