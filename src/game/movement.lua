-- movement.lua
-- Click-to-select + dotted path preview + capped range + step-by-step walking.
-- Uses A* on axial hexes. Also provides a tiny 2-frame idle bob.

local Movement = {}

local H = {
  maxRange = 10,
  selected = nil,        -- entity
  hoverHex = nil,        -- {q,r}
  path = nil,            -- array of {q,r}
  stepTimer = 0,
  stepTime  = 0.12,      -- secs per step when moving
  moving = false,
  camera = nil,
  hexmap = nil,
  entities = nil,
  theme = nil,
}

-- --------- helpers ----------
local function key(q,r) return q.."|"..r end

local function heuristic(a, b)
  local dq = math.abs(a.q - b.q)
  local dr = math.abs(a.r - b.r)
  local ds = math.abs((-a.q-a.r) - (-b.q-b.r))
  return (dq + dr + ds) / 2
end

local function hexDistance(a, b) return heuristic(a,b) end

local function canStandOn(q, r)
  if H.hexmap.isBlocked then return not H.hexmap:isBlocked(q, r) end
  return true
end

-- A* on axial hex grid. Expects:
--   hexmap:neighbors(q,r) -> array of {q,r}
--   canStandOn(q,r) -> bool
local function findPath(start, goal, rangeCap)
  if hexDistance(start, goal) > rangeCap then return nil end
  if not canStandOn(goal.q, goal.r) then return nil end

  local open = { [key(start.q,start.r)] = true }
  local cameFrom, gScore, fScore = {}, {}, {}
  gScore[key(start.q,start.r)] = 0
  fScore[key(start.q,start.r)] = heuristic(start, goal)
  local frontier = { start }

  local function popLowestF()
    local bestIdx, bestNode, bestF = nil, nil, math.huge
    for i, n in ipairs(frontier) do
      local k = key(n.q,n.r)
      local f = fScore[k] or math.huge
      if f < bestF then bestF, bestIdx, bestNode = f, i, n end
    end
    if bestIdx then table.remove(frontier, bestIdx) end
    if bestNode then open[key(bestNode.q,bestNode.r)] = nil end
    return bestNode
  end

  while #frontier > 0 do
    local current = popLowestF()
    if not current then break end
    if current.q == goal.q and current.r == goal.r then
      local out = {}
      local cur = current
      while cur do
        table.insert(out, 1, {q=cur.q, r=cur.r})
        cur = cameFrom[key(cur.q,cur.r)]
      end
      return out
    end
    for _,n in ipairs(H.hexmap:neighbors(current.q, current.r)) do
      if canStandOn(n.q, n.r) then
        local tentative = (gScore[key(current.q,current.r)] or math.huge) + 1
        local nk = key(n.q,n.r)
        if tentative < (gScore[nk] or math.huge) then
          cameFrom[nk] = current
          gScore[nk] = tentative
          fScore[nk] = tentative + heuristic(n, goal)
          if not open[nk] then
            table.insert(frontier, {q=n.q, r=n.r})
            open[nk] = true
          end
        end
      end
    end
  end
  return nil
end

-- ---------- idle bob (two frames flip) ----------
function Movement.setIdleAnimFrames(e, upFrame, downFrame, rate)
  e._idle = e._idle or { t=0, rate=rate or 0.4, up=upFrame, down=downFrame, cur=upFrame }
  e.state = e.state or "idle"
end

local function updateIdle(e, dt)
  if not e._idle or e.state ~= "idle" then return end
  e._idle.t = e._idle.t + dt
  if e._idle.t >= e._idle.rate then
    e._idle.t = e._idle.t - e._idle.rate
    e._idle.cur = (e._idle.cur == e._idle.up) and e._idle.down or e._idle.up
  end
  e._bob = (e._bob or 0) + dt*6.283 -- 2π/s
  e._bobOffset = math.sin(e._bob) * 1
end

-- ---------- public API ----------
function Movement.load(deps)
  H.hexmap   = assert(deps.hexmap, "Movement.load missing hexmap")
  H.entities = assert(deps.entities, "Movement.load missing entities")
  H.camera   = deps.camera
  H.theme    = deps.theme
  H.maxRange = deps.maxRange or H.maxRange
end

function Movement.update(dt, input)
  -- idle anim for all (if entities.each exists)
  if H.entities.each then
    for _,e in H.entities:each() do updateIdle(e, dt) end
  end

  -- live path preview while selected & not currently moving
  if H.selected and not H.moving then
    local mx, my = love.mouse.getPosition()
    if H.camera and H.camera.screenToWorld then
      mx, my = H.camera:screenToWorld(mx, my)
    end
    local q, r = H.hexmap:pixelToAxial(mx, my)
    if q and r then
      H.hoverHex = {q=q, r=r}
      local start = { q=H.selected.q, r=H.selected.r }
      local goal  = { q=q, r=r }
      H.path = findPath(start, goal, H.maxRange)
    end
  end

  -- step along path if moving
  if H.moving and H.path and H.selected then
    H.stepTimer = H.stepTimer + dt
    if H.stepTimer >= H.stepTime then
      H.stepTimer = H.stepTimer - H.stepTime
      if #H.path > 1 then
        table.remove(H.path, 1)
        local nxt = H.path[1]
        -- If you have entities:moveTo, use that instead:
        H.selected.q, H.selected.r = nxt.q, nxt.r
      else
        H.moving = false
        H.path = nil
        H.selected.state = "idle"
      end
    end
  end
end

function Movement.draw()
  if H.path and H.selected then
    local r,g,b,a = 1,1,1,1
    if H.theme and H.theme.colors and H.theme.colors.path then
      local c = H.theme.colors.path
      r,g,b,a = c[1], c[2], c[3], c[4] or 1
    end
    love.graphics.setColor(r,g,b,a)
    local dotRadius = 2
    for i=1,#H.path-1 do
      local aHex, bHex = H.path[i], H.path[i+1]
      local ax, ay = H.hexmap:axialToPixel(aHex.q, aHex.r)
      local bx, by = H.hexmap:axialToPixel(bHex.q, bHex.r)
      local dx, dy = bx-ax, by-ay
      local len = math.sqrt(dx*dx + dy*dy)
      local step = 10
      local n = math.max(1, math.floor(len/step))
      for s=0,n do
        local t = s/n
        love.graphics.circle("fill", ax + dx*t, ay + dy*t, dotRadius)
      end
    end
    love.graphics.setColor(1,1,1,1)
  end
end

function Movement.onMousePressed(x, y, button)
  if button ~= 1 then return end
  if H.camera and H.camera.screenToWorld then
    x, y = H.camera:screenToWorld(x, y)
  end
  local q, r = H.hexmap:pixelToAxial(x, y)
  if not q then return end

  -- 1) first click selects an entity on that hex
  if not H.selected then
    local e = H.entities.getAt and H.entities:getAt(q, r) or nil
    if e then
      H.selected = e
      H.selected.state = "idle"
      return
    end
  end

  -- 2) confirm move if a valid path exists
  if H.selected and H.path and #H.path > 1 then
    if H.entities.canMove and not H.entities:canMove(H.selected, H.path[#H.path].q, H.path[#H.path].r) then
      return
    end
    H.selected.state = "moving"
    H.moving = true
    H.stepTimer = 0
    return
  end

  -- 3) otherwise, clear selection
  H.selected = nil
  H.path = nil
end

return Movement
