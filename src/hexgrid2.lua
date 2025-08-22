local HexGrid = {}


-- Pointy-top hex math (axial coords)
-- size: radius in pixels from center to corner
HexGrid.size = 28


local sqrt3 = math.sqrt(3)


local function axial_to_pixel(q, r, size)
    local x = size * sqrt3 * (q + r/2)
    local y = size * (3/2) * r
    return x, y
end


local function hex_corners(cx, cy, size)
    local pts = {}
    for i = 0, 5 do
        local angle = (math.pi / 180) * (60 * i - 30) -- pointy top
        pts[#pts+1] = cx + size * math.cos(angle)
        pts[#pts+1] = cy + size * math.sin(angle)
    end
    return pts
end


-- Draw a rectangular patch of axial coords covering the given area
function HexGrid.draw(area)
    local s = HexGrid.size
    local col_w = sqrt3 * s
    local row_h = 1.5 * s


    -- We center the grid in the area
    local cols = math.floor(area.w / col_w) + 2
    local rows = math.floor(area.h / row_h) + 2


    local origin_x = area.x + area.w * 0.5
    local origin_y = area.y + area.h * 0.45 -- slight bias upward to leave room for UI overlay


    love.graphics.push()
    love.graphics.translate(origin_x, origin_y)


    love.graphics.setLineWidth(1)
    for r = -math.floor(rows/2), math.floor(rows/2) do
        for q = -math.floor(cols/2), math.floor(cols/2) do
            local x, y = axial_to_pixel(q, r, s)
            -- faint fill + outline
            love.graphics.setColor(0.25, 0.28, 0.32, 0.35)
            love.graphics.polygon("fill", hex_corners(x, y, s-1))
            love.graphics.setColor(0.75, 0.8, 0.86, 0.25)
            love.graphics.polygon("line", hex_corners(x, y, s-1))
        end
    end


love.graphics.pop()
end


return HexGrid