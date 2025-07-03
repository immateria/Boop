#!/usr/bin/env lua
local state_json = os.getenv('BOOP_STATE') or '{}'
local state = {}
local ok, res = pcall(function() return assert(load('return '..state_json))() end)
if ok then state = res else state = {} end

local MODULE_EXT = os.getenv('BOOP_MODULE_EXT') or '.lua'
local SCRIPT_DIR = os.getenv('BOOP_SCRIPT_DIR') or ''
local LIB_DIR = os.getenv('BOOP_LIB_DIR') or ''
local REQUIRE_NAME = os.getenv('BOOP_REQUIRE_NAME') or 'boop_require'

local loaded = {}
local function _boop_require(path)
  local p = path
  if p:sub(-#MODULE_EXT) ~= MODULE_EXT then p = p .. MODULE_EXT end
  local file
  if p:sub(1,6) == '@boop/' then
    file = LIB_DIR .. '/' .. p:sub(7)
  else
    file = SCRIPT_DIR .. '/' .. p
  end
  if loaded[file] then return loaded[file] end
  local f = loadfile(file)
  if not f then return nil end
  local mod = f() or {}
  loaded[file] = mod
  return mod
end

_G[REQUIRE_NAME] = _boop_require
if REQUIRE_NAME ~= 'boop_require' then
  _G['boop_require'] = _boop_require
end

local State = {}
State.__index = State
function State:new(data)
  local obj = setmetatable({}, self)
  obj.text = data.text
  obj.fullText = data.fullText
  obj.selection = data.selection
  obj.network = data.network
  obj.inserts = {}
  obj.messages = {}
  return obj
end
function State:post_info(msg) table.insert(self.messages, {type='info', message=msg}) end
function State:post_error(msg) table.insert(self.messages, {type='error', message=msg}) end
function State:insert(val) table.insert(self.inserts, val) end
function State:fetch(url, method, body)
  if not self.network then self:post_error('Network permission required'); return nil end
  local cmd = 'curl -sL '
  if method and method ~= 'GET' then cmd = cmd .. '-X '..method..' ' end
  if body then cmd = cmd .. '--data '..string.format('%q', body)..' ' end
  cmd = cmd .. url
  local f = io.popen(cmd, 'r')
  local data = f:read('*a')
  local ok2 = f:close()
  if ok2 then return data else self:post_error('Failed to fetch'); return nil end
end
local function escape(s) return s:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n') end
function State:to_json()
  local parts = {
    '"text":"'..escape(self.text or '')..'"',
    '"fullText":"'..escape(self.fullText or '')..'"',
    '"selection":"'..escape(self.selection or '')..'"',
    '"inserts":['..table.concat((function()
      local arr={} for i,v in ipairs(self.inserts) do arr[i]='"'..escape(v)..'"' end return arr end)(),',')..']',
    '"messages":['..table.concat((function()
      local arr={} for i,v in ipairs(self.messages) do arr[i]='{"type":"'..escape(v.type)..'","message":"'..escape(v.message)..'"}' end return arr end)(),',')..']'
  }
  return '{'..table.concat(parts, ',')..'}'
end

local script = arg[1]
local stateObj = State:new(state)
local user = assert(loadfile(script))
if user then user()(stateObj) end
print(stateObj:to_json())

