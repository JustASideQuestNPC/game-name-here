--[[
The ISC License

Copyright (c) Varun Ramesh

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT,
OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
]]--

Console = {}

-- Utilty functions for manipulating tables.
local function map(tbl, f)
  local t = {}
  for k, v in pairs(tbl) do t[k] = f(v) end
  return t
end
local function filter(tbl, f)
  local t, i = {}, 1
  for _, v in ipairs(tbl) do
    if f(v) then t[i], i = v, i + 1 end
  end
  return t
end
local function push(tbl, ...)
  for _, v in ipairs({...}) do
    table.insert(tbl, v)
  end
end
local function keys(tbl)
  local keys_tbl = {}
  for k, _ in pairs(tbl) do
    table.insert(keys_tbl, k)
  end
  return keys_tbl
end
local function concat(...)
  local tbl = {}
  for _, t in ipairs({...}) do
    for _, v in ipairs(t) do
      table.insert(tbl, v)
    end
  end
  return tbl
end

local function parseArgs(str)
  local args = {}
  local e = 0
  while true do
      local b = e +1 
      b = str:find("%S",b)
      if b == nil then break end
      if str:sub(b, b) == "'" then
          e = str:find("'", b + 1)
          b = b + 1
      elseif str:sub(b,b )== '"' then
          e = str:find('"', b  +1)
          b = b + 1
      else
          e = str:find("%s",b+1)
      end
      if e == nil then e = #str+1 end

      local a = str:sub(b, e-1)
      if tonumber(a) ~= nil then
        a = tonumber(a)
      elseif a == "true" then
        a = true
      elseif  a == "false" then
        a = false
      end
      args[#args+1] = a
  end
  return args
end

Console.HORIZONTAL_MARGIN = 10 -- Horizontal margin between the text and window.
Console.VERTICAL_MARGIN = 10 -- Vertical margins between components.
Console.PROMPT = "> " -- The prompt symbol.

Console.MAX_LINES = 200 -- How many lines to store in the buffer.
Console.HISTORY_SIZE = 100 -- How much of history to store.

-- Color configurations.
Console.BACKGROUND_COLOR = {0, 0, 0, 0.7}
Console.TEXT_COLOR = {1, 1, 1, 1}
Console.COMPLETION_TEXT_COLOR = {1, 1, 1, 0.7}
Console.WARNING_COLOR = {0.89, 0.6, 0.4, 1}
Console.ERROR_COLOR = {0.94, 0.35, 0.44, 1}

Console.FONT_SIZE = 12
Console.FONT = love.graphics.newFont(Console.FONT_SIZE)

-- The scope in which lines in the console are executed.
Console.ENV = setmetatable({}, {__index = _G})

-- The default help text shown.
Console.HELP_TEXT = [[==== Welcome to the In-Game Console ====
- Type any expression or statement to evaluate it.
- Type a built-in command to run it (type `commands` to list all commands).]]

-- Builtin commands.
Console.COMMANDS = {
  clear = function(_) Console.clear() end,
  quit = function(_) love.event.quit(0) end,
  help = function(_) Console.log(Console.HELP_TEXT) end,
  commands = function(_)
    Console.log("=== Available Commands ===")
    for k, _ in pairs(Console.COMMANDS) do
      if Console.COMMAND_HELP[k] then
        Console.log(k .. " - " .. Console.COMMAND_HELP[k])
      else
        Console.log(k)
      end
    end
  end
}

Console.COMMAND_HELP = {
  clear = "Clears the console.",
  quit = "Quits the game.",
  help = "Prints help text.",
  commands = "Lists all commands."
}

function Console.inspect(val)
  if type(val) == "table"  then
    -- If this table has a tostring function, just use that.
    local mt = getmetatable(val)
    if mt and mt.__tostring then return tostring(val) end

    local result = "{ "

    -- First print out array-like keys, keeping track of which keys we've seen.
    local seen = {}
    for k, v in ipairs(val) do
      result = result .. tostring(v) .. ", "
      seen[k] = true
    end

    -- Now print out the reset of the keys.
    for k, v in pairs(val) do
      if seen[k] ~= true then
        result = result .. tostring(k) .. " = " .. tostring(v) .. ", "
      end
    end
    result = result .. "}"
    return result
  else
    return tostring(val)
  end
end

-- Overrideable function that is used for formatting return values.
Console.INSPECT_FUNCTION = function(...)
  local args = {...}
  if #args == 0 then
    return "nil"
  else
    return table.concat(map(args, Console.inspect), "\t")
  end
end

-- Store global state for whether or not the console is enabled / disabled.
local enabled = false
function Console.isEnabled() return enabled end

-- Store the printed lines in a buffer.
local displayedLines = {}
function Console.clear() displayedLines = {} end

local logLines = {}

-- Store previously executed commands in a history buffer.
local history = {}
function Console.addHistory(command)
  table.insert(history, 1, command)
end

-- Print a colored text to the console. Colored text is simply represented
-- as a table of values that alternate between an {r, g, b, a} object and a
-- string value.
function Console.colorprint(coloredtext) table.insert(displayedLines, coloredtext) end

function Console.log(text)
  print(tostring(text))
  table.insert(displayedLines, {Console.TEXT_COLOR, tostring(text)})
  table.insert(logLines, text)
end
function Console.warn(text)
  print("\x1b[33m"..tostring(text).."\x1b[39m")
  table.insert(displayedLines, {Console.WARNING_COLOR, tostring(text)})
  table.insert(logLines, text)
end
function Console.error(text)
  print("\x1b[31m"..tostring(text).."\x1b[39m")
  table.insert(displayedLines, {Console.ERROR_COLOR, tostring(text)})
  table.insert(logLines, text)
end

Console.logToFile = function(filename)
  local file, errorString = love.filesystem.newFile(filename, "w")
  if file == nil then
    print(errorString)
    return
  end

  for _, line in ipairs(logLines) do
    file:write(line.."\r\n")
  end

  file:close()
  Console.log("Logged output to "..filename)
end

-- Helper object that encapuslates operations on the current command.
local command = {
  clear = function(self)
    -- Clear the current command.
    self.text = ""
    self.cursor = 0
    self.history_index = 0
    self.completion = nil
  end,
  insert = function(self, input)
    -- Inert text at the cursor.
    self.text = self.text:sub(0, self.cursor) ..
      input .. self.text:sub(self.cursor + 1)
    self.cursor = self.cursor + 1

    -- Update completion.
    self:update_completion()
  end,
  delete_backward = function(self)
    -- Delete the character before the cursor.
    if self.cursor > 0 then
      self.text = self.text:sub(0, self.cursor - 1) ..
        self.text:sub(self.cursor + 1)
      self.cursor = self.cursor - 1
    end

    -- Update completion.
    self:update_completion()
  end,
  forward_character = function(self)
    if self.completion and self.cursor == self.text:len() then
      self:complete()
    else
      self.cursor = math.min(self.cursor + 1, self.text:len())
    end
  end,
  backward_character = function(self)
    self.cursor = math.max(self.cursor - 1, 0)
  end,
  beginning_of_line = function(self) self.cursor = 0 end,
  end_of_line = function(self) self.cursor = self.text:len() end,
  forward_word = function(self)
    local word = self.text:match('%W*%w*', self.cursor + 1)
    self.cursor = math.min(self.cursor + word:len())
  end,
  backward_word = function(self)
    local word = self.text:reverse():match('%W*%w*', self.text:len() - self.cursor + 1)
    self.cursor = math.max(self.cursor - word:len(), 0)
  end,
  previous = function(self)
    -- If there is no more history, don't do anything.
    if self.history_index + 1 > #history then return end

    -- If this is the first time, then save the command in case the user
    -- navigates back to the present command.
    if self.history_index == 0 then self.saved_command = self.text end

    self.history_index = math.min(self.history_index + 1, #history)
    self.text = history[self.history_index]
    self.cursor = self.text:len()

    -- Update completion.
    self:update_completion()
  end,
  next = function(self)
    -- If there is no more history, don't do anything.
    if self.history_index - 1 < 0 then return end
    self.history_index = math.max(self.history_index - 1, 0)

    if self.history_index == 0 then self.text = self.saved_command
    else self.text = history[self.history_index] end
    self.cursor = self.text:len()

    -- Update completion.
    self:update_completion()
  end,

  update_completion = function(self)
    if self.text:len() > 0 then
      self.completion = Console.completion(self.text)
    else
      self.completion = nil
    end
  end,
  complete = function(self)
    if self.completion then
      self.text = self.completion
      self.cursor = self.text:len()
      self.completion = nil

      -- Update completion.
      self:update_completion()
    end
  end
}
command:clear()

function Console.draw()
  -- Only draw the console if enabled.
  if not enabled then return end

  -- Fill the background color.
  love.graphics.setColor(unpack(Console.BACKGROUND_COLOR))
  love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(),
    love.graphics.getHeight())

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Console.FONT)

  local line_start = love.graphics.getHeight() - Console.VERTICAL_MARGIN*3 - Console.FONT:getHeight()
  local wraplimit = love.graphics.getWidth() - Console.HORIZONTAL_MARGIN*2

  for i = #displayedLines, 1, -1 do
    local textonly = displayedLines[i]
    if type(displayedLines[i]) == "table" then
      textonly = table.concat(filter(displayedLines[i], function(val)
        return type(val) == "string"
      end), "")
    end
    local _, wrapped = Console.FONT:getWrap(textonly, wraplimit)

    love.graphics.printf(
      displayedLines[i], Console.HORIZONTAL_MARGIN,
      line_start - #wrapped * Console.FONT:getHeight(),
      wraplimit, "left")
    line_start = line_start - #wrapped * Console.FONT:getHeight()
  end

  love.graphics.setLineWidth(1)

  love.graphics.line(0,
    love.graphics.getHeight() - Console.VERTICAL_MARGIN
      - Console.FONT:getHeight() - Console.VERTICAL_MARGIN,
    love.graphics.getWidth(),
    love.graphics.getHeight() - Console.VERTICAL_MARGIN
      - Console.FONT:getHeight() - Console.VERTICAL_MARGIN)

  love.graphics.printf(
    Console.PROMPT .. command.text,
    Console.HORIZONTAL_MARGIN,
    love.graphics.getHeight() - Console.VERTICAL_MARGIN - Console.FONT:getHeight(),
    love.graphics.getWidth() - Console.HORIZONTAL_MARGIN*2, "left")

  if love.timer.getTime() % 1 > 0.5 then
    local cursorx = Console.HORIZONTAL_MARGIN +
      Console.FONT:getWidth(Console.PROMPT .. command.text:sub(0, command.cursor))
    love.graphics.line(
      cursorx,
      love.graphics.getHeight() - Console.VERTICAL_MARGIN - Console.FONT:getHeight(),
      cursorx,
      love.graphics.getHeight() - Console.VERTICAL_MARGIN)
  end

  if command.completion ~= nil then
    local suggested = command.completion:sub(command.text:len() + 1, -1)

    love.graphics.setColor(Console.COMPLETION_TEXT_COLOR)
    local autocompletex = Console.FONT:getWidth(Console.PROMPT .. command.text)
    love.graphics.printf(
      suggested,
      Console.HORIZONTAL_MARGIN + autocompletex,
      love.graphics.getHeight() - Console.VERTICAL_MARGIN - Console.FONT:getHeight(),
      love.graphics.getWidth() - Console.HORIZONTAL_MARGIN*2 - autocompletex, "left")
  end
end

function Console.completion(partial)
  -- Generate a list of all possible completions.
  local possible_completions = concat(keys(Console.ENV), keys(Console.COMMANDS), history)

  -- Filter out completions that don't match the currently typed text.
  possible_completions = filter(possible_completions, function(possible_completion)
    return possible_completion:len() > partial:len()
      and partial == possible_completion:sub(1, partial:len())
  end)

  -- Sort completions by length.
  table.sort(possible_completions, function(a, b)
    return a:len() < b:len()
  end)

  -- If we have at least one valid completion, return it.
  if #possible_completions > 0 then
    return possible_completions[1]
  end
end

function Console.textinput(input)
  -- Use the "~" key to enable / disable the console.
  if input == "~" then
    enabled = not enabled
    return
  end

  -- If disabled, ignore the input, otherwise insert at the cursor.
  if not enabled then return end
  command:insert(input)
end

function Console.execute(command)
  Console.log("> "..command)
  local args = parseArgs(command)

  -- If this is a builtin command, execute it and return immediately.
  if Console.COMMANDS[args[1]] then
    Console.COMMANDS[args[1]]({unpack(args, 2)})
    return
  end

  -- Reprint the command + the prompt string.
  Console.log(Console.PROMPT .. command)

  local chunk, error = load("return " .. command)
  if not chunk then
    chunk, error = load(command)
  end

  if chunk then
    setfenv(chunk, Console.ENV)
    local values = { pcall(chunk) }
    if values[1] then
      table.remove(values, 1)
      Console.log(Console.INSPECT_FUNCTION(unpack(values)))

      -- Bind '_' to the first returned value, and bind 'last' to a list
      -- of returned values.
      Console.ENV._ = values[1]
      Console.ENV.last = values
    else
      Console.error(values[2])
    end
  else
    Console.error(command.." is not a command")
  end
end

function Console.keypressed(key, scancode, isrepeat)
  -- Ignore if the console isn't enabled.
  if not enabled then return end

  local ctrl = love.keyboard.isDown("lctrl", "lgui")
  local shift = love.keyboard.isDown("lshift", "rshift")
  local alt = love.keyboard.isDown("lalt", "ralt")

  if key == 'backspace' then command:delete_backward()

  elseif key == "up" then command:previous()
  elseif key == "down" then command:next()

  elseif alt and key == "left" then command:backward_word()
  elseif alt and key == "right" then command:forward_word()

  elseif ctrl and key == "left" then command:beginning_of_line()
  elseif ctrl and key == "right" then command:end_of_line()

  elseif key == "left" then command:backward_character()
  elseif key == "right" then command:forward_character()

  elseif key == "c" and ctrl then command:clear()

  elseif key == "=" and shift and ctrl then
      Console.FONT_SIZE = Console.FONT_SIZE + 1
      Console.FONT = love.graphics.newFont(Console.FONT_SIZE)
  elseif key == "-" and ctrl then
      Console.FONT_SIZE = math.max(Console.FONT_SIZE - 1, 1)
      Console.FONT = love.graphics.newFont(Console.FONT_SIZE)

  elseif key == "return" then
    Console.addHistory(command.text)
    Console.execute(command.text)
    command:clear()

  elseif key == "tab" then
    command:complete()
  end
end

function Console.setEnabled(enable)
	enabled = enable
end

Console = Console
