local Input = { down = {} }

function Input.keypressed(k)  Input.down[k] = true  end
function Input.keyreleased(k) Input.down[k] = false end
function Input.isDown(k)      return Input.down[k]  end

-- Optional: map hotkeys to actions later
-- Input.bind = { ["1"]="ability1", ["2"]="ability2" }
return Input
