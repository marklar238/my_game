local Theme = require("src.ui.theme")
local Panel = require("src.ui.panel")

local M = { rects = {} }

local function pointInRect(x, y, r)
  return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

function M.draw(rect, cards, selectedIndex, fontSmall, fontMedium)
  Panel.draw(rect, "Hand", fontMedium)
  M.rects = {}

  local pad = 12
  local gap = 10
  local count = #cards
  local card_w = math.max(120, (rect.w - pad*2 - gap*(count-1)) / count)
  local card_h = rect.h - pad*2 - 26
  local mx, my = love.mouse.getPosition()

  for i = 1, count do
    local x = rect.x + pad + (i-1) * (card_w + gap)
    local y = rect.y + pad + 26
    local r = { x = x, y = y, w = card_w, h = card_h }
    local hover = pointInRect(mx, my, r)
    local isSel = (selectedIndex == i)

    love.graphics.setColor( (hover and 0.22 or (isSel and 0.20 or 0.18)), 0.2, (hover and 0.26 or (isSel and 0.25 or 0.23)), 0.95)
    love.graphics.rectangle("fill", x, y, card_w, card_h, Theme.r, Theme.r)
    love.graphics.setColor(0.55, 0.6, 0.7, 0.9)
    love.graphics.setLineWidth(isSel and 3 or 2)
    love.graphics.rectangle("line", x, y, card_w, card_h, Theme.r, Theme.r)

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(Theme.fg)
    love.graphics.printf(cards[i].title, x + 10, y + 10, card_w - 20, "left")
    love.graphics.setColor(0.8, 0.85, 0.95, 0.9)
    love.graphics.printf(cards[i].subtitle, x + 10, y + 28, card_w - 20, "left")

    M.rects[i] = r
  end
end

function M.hit(x, y)
  for i, r in ipairs(M.rects) do if pointInRect(x,y,r) then return i end end
end

return M