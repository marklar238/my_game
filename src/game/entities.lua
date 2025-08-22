local Entities = { list = {}, by_cell = {} }

local function key(q, r) return tostring(q) .. "|" .. tostring(r) end

function Entities.reset()
  Entities.list = {}
  Entities.by_cell = {}
end

function Entities.spawn(t)
  local e = {
    type = t.type or "enemy",
    q = t.q, r = t.r,
    name = t.name,
  }
  e.id = #Entities.list + 1
  Entities.list[e.id] = e
  Entities.by_cell[key(e.q, e.r)] = e.id
  return e.id
end

function Entities.get(id)
  return Entities.list[id]
end

function Entities.at(q, r)
  local id = Entities.by_cell[key(q, r)]
  if id then return Entities.list[id], id end
end

function Entities.occupied(q, r)
  return Entities.by_cell[key(q, r)] ~= nil
end

function Entities.move(id, q, r)
  local e = Entities.list[id]
  if not e then return false end
  if Entities.occupied(q, r) then return false end
  Entities.by_cell[key(e.q, e.r)] = nil
  e.q, e.r = q, r
  Entities.by_cell[key(q, r)] = id
  return true
end

function Entities.remove_at(q, r)
  local id = Entities.by_cell[key(q, r)]
  if not id then return false end
  Entities.by_cell[key(q, r)] = nil
  Entities.list[id] = nil
  return true
end

function Entities.all()
  return Entities.list
end

return Entities