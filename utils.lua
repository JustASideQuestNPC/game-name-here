-- Various utility functions

---Interpolates values in args into a string. To interpolate a value, surround its name in curly
---brackets and give it an entry in `args`.
---@param str string
---@param args table
---@return string
---@nodiscard
local function stringFormat(str, args)
  local formatted = {} -- table because it makes building the string *way* faster

  local parsingName = false
  local nameBuffer = {} -- for parsing value names

  for char in str:gmatch(".") do
    if parsingName then
      if char == '}' then
        local key = table.concat(nameBuffer)
        table.insert(formatted, args[key])
        nameBuffer = {}
        parsingName = false
      else
        table.insert(nameBuffer, char)
      end
    else
      if char == '{' then
        parsingName = true
      else
        table.insert(formatted, char)
      end
    end
  end

  return table.concat(formatted)
end

---Returns whether a predicate function returns true for every item in an array.
---@param arr table
---@param predicate function
---@return boolean
---@nodiscard
local function arrayEvery(arr, predicate)
  for _, item in ipairs(arr) do
    if not predicate(item) then
      return false
    end
  end
  return true
end

---Returns whether a predicate function returns true for at least one item in an array.
---@param arr table
---@param predicate function
---@return boolean
---@nodiscard
local function arrayAny(arr, predicate)
  for _, item in ipairs(arr) do
    if predicate(item) then
      return true
    end
  end
  return false
end

return {
  stringFormat = stringFormat,
  arrayEvery = arrayEvery,
  arrayAny = arrayAny
}