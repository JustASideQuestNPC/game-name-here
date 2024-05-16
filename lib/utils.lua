-- Various utility functions

---@class Class
---@field inheritsFrom fun(base): Class
---@operator call: Class

---Generates a class.
---@generic C
---@param base C
---@param init fun(instance, ...)
---@return C
---@overload fun(init: fun(instance, ...)): Class
---@overload fun(): Class
local function class(base, init)
  local c = {} -- a new class instance
  if not init and type(base) == 'function' then
    init = base
    base = nil
  elseif type(base) == 'table' then
    -- our new class is a shallow copy of the base class!
    for i,v in pairs(base) do
      c[i] = v
    end
    c._base = base
  end
  -- the class will be the metatable for all its objects,
  -- and they will look up their methods in it.
  c.__index = c

  -- expose a constructor which can be called by <classname>(<args>)
  local mt = {}
  mt.__call = function(class_tbl, ...)
  local obj = {}
  setmetatable(obj, c)
  if init then
    init(obj,...)
  else
    -- make sure that any stuff from the base class is initialized!
    if base and base.init then
    base.init(obj, ...)
    end
  end
  return obj
  end
  c.init = init
  c.inheritsFrom = function(self, _base)
    local m = getmetatable(self)
    while m do 
      if m == _base then return true end
      m = m._base
    end
    return false
  end
  setmetatable(c, mt)
  return c
end

---Returns whether a table is an array.
---@param t table
---@return boolean
local function isArray(t)
  local i = 0
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil then return false end
  end
  return true
end

---Returns whether a predicate function returns true for every item in an array.
---@generic T
---@param arr T[]
---@param predicate fun(item: T): boolean
---@return boolean
---@nodiscard
local function arrayEvery(arr, predicate)
  for _, v in ipairs(arr) do
    if not predicate(v) then
      return false
    end
  end
  return true
end

---Returns whether a predicate function returns true for at least one item in an array.
---@generic T
---@param arr T[]
---@param predicate fun(item: T): boolean
---@return boolean
---@nodiscard
local function arrayAny(arr, predicate)
  for _, v in ipairs(arr) do
    if predicate(v) then
      return true
    end
  end
  return false
end

---Returns the first index of a value in an array, or 0 if the value is not in the array.
---@generic T
---@param arr T[]
---@param value T
---@return integer
local function arrayFind(arr, value)
  for i, v in ipairs(arr) do
    if v == value then
      return i
    end
  end

  return 0
end

---Returns a copy of an array containing only items that a predicate function returns true for.
---@generic T
---@param arr T[]
---@param predicate fun(item: T): boolean
---@return table
local function arrayFilter(arr, predicate)
  local filtered = {}
  for _, v in ipairs(arr) do
    if predicate(v) then
      filtered[#filtered+1] = v
    end
  end
  return filtered
end

---Interpolates between two numbers.
---@param a number
---@param b number
---@param t number The amount to interpolate by. 0 returns a, and 1 returns b.
---@return number
---@nodiscard
local function lerp(a, b, t)
  return t < 0.5 and a + (b - a) * t or b + (a - b) * (1 - t)
end

---Framerate-independent version of `lerp()` using delta time
---@param a number
---@param b number
---@param t number The amount to interpolate by. 0 returns a, and 1 returns b.
---@param dt number The current delta time; makes the result framerate-independent.
---@return number
---@nodiscard
local function damp(a, b, t, dt)
  return lerp(a, b, 1 - math.exp(-t * dt))
end

---Maps a value between two ranges.
---@param value number
---@param inputStart number
---@param inputEnd number
---@param outputStart number
---@param outputEnd number
---@return number
---@nodiscard
local function map(value, inputStart, inputEnd, outputStart, outputEnd)
  return outputStart + ((outputEnd - outputStart) / (inputEnd - inputStart)) * (value - inputStart)
end

---Clamps a value between a minimum and a maximum.
---@param value number
---@param min number
---@param max number
---@return number
---@nodiscard
local function clamp(value, min, max)
  return math.min(math.max(value, min), max)
end

---Returns the *real* arctangent of y/x, because some idiot at Lua headquarters decided that nobody
---actually wanted to aim things at the mouse without writing their own freaking trig functions.
---@param y number
---@param x number
---@return number
---@nodiscard
local function atan2(y, x)
  -- Does anyone know who decided that math.atan was a drop-in replacement for atan2? I'd like to
  -- speak to them using a large blunt object (for legal reasons, this is a joke).
  if x > 0 then
    return math.atan(y / x)
  elseif x < 0 and y >= 0 then
    return math.atan(y / x) + math.pi
  elseif x < 0 and y < 0 then
    return math.atan(y / x) - math.pi
  elseif x == 0 and y > 0 then
    return math.pi / 2
  elseif x == 0 and y < 0 then
    return -math.pi / 2
  else
    return 0
  end
end

---Draws a dotted line.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param dotRadius number
---@param dotSpacing number
local function dottedLine(x1, y1, x2, y2, dotRadius, dotSpacing)
  -- i'd do this with vectors, but that creates an import loop and crashes everything
  local length = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
  local angle = atan2(y2 - y1, x2 - x1)

  love.graphics.push()
  love.graphics.translate(x1, y1)
  love.graphics.rotate(angle)

  for x = 0, length, dotSpacing do
    love.graphics.circle("fill", x, 0, dotRadius)
  end

  love.graphics.pop()
end

---Returns a random floating-point number in the range [min, max).
---@param min number
---@param max number
---@return number
local function randFloat(min, max)
  return (math.random() * (max - min)) + min
end

---Compares a table with a template, and returns a copy of the table that has the same structure
---as the template.
---@param table any
---@param template any
---@return table, boolean
local function verifyTable(table, template)
  local output = {}
  local changeMade = false

  -- catch mismatched types
  if type(table) ~= type(template) then
    return template, true
  elseif type(table) ~= "table" then
    return table, false
  elseif (isArray(table) and not isArray(template)) or
         (not isArray(table) and isArray(template)) then
    return template, true
  elseif isArray(template) then
    for i, templateValue in ipairs(template) do
      local tableValue = table[i]
      output[#output+1], changeMade = verifyTable(tableValue, templateValue)
    end
  else
    for key, templateValue in pairs(template) do
      local tableValue = table[key]
      output[key], changeMade = verifyTable(tableValue, templateValue)
    end
  end

  return output, changeMade
end

local function tableToString(t)
  if type(t) == 'table' then
    if isArray(t) then
      local s = '['
      for i, v in ipairs(t) do
        s = s..tableToString(v)
        if i <= #t - 1 then s = s..', ' end
      end
      return s..']'
    else
      local len = 0
      for _, _ in pairs(t) do len = len + 1 end

      local s = '{'
      local i = 0
      for k,v in pairs(t) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s..k..' = '..tableToString(v)
        if i < len - 1 then s = s..', ' end
        i = i + 1
      end
      return s..'}'
    end
  else
    if type(t) == 'string' then return '"'..t..'"' end
    return tostring(t)
  end
end

return {
  class = class,
  isArray = isArray,
  arrayEvery = arrayEvery,
  arrayAny = arrayAny,
  arrayFind = arrayFind,
  arrayFilter = arrayFilter,
  lerp = lerp,
  damp = damp,
  map = map,
  clamp = clamp,
  atan2 = atan2,
  dottedLine = dottedLine,
  randFloat = randFloat,
  verifyTable = verifyTable,
  tableToString = tableToString
}