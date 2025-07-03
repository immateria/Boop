--[[
{
    "api": 1,
    "name": "Lua Capitalize",
    "description": "Capitalizes your text using Lua",
    "author": "Codex",
    "icon": "textformat",
    "tags": "capitalize,lua"
}
]]

function main(state)
  if state.text then
    state.text = string.upper(string.sub(state.text,1,1)) .. string.sub(state.text,2)
  end
end
