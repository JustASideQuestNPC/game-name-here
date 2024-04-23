-- Game settings.
-- PS: The only reason the filename starts with an underscore is so that it's always at the top
-- when I sort the folder alphabetically.

return {
  graphics = {
    width = 1280,
    height = 720,
    fullscreen = false, -- overrides width and height
    vsync = "adaptive", -- true, false, or "adaptive"
    msaaSamples = 8,    -- number of samples for antialiasing
  },

  keybinds = {
    {
      name = "continuous action",
      keys = {"space"},
      gamepadButtons = {"a"}
    },
    {
      name = "press action",
      keys = {"space"},
      gamepadButtons = {"a"},
      mode = "press"
    },
    {
      name = "release action",
      keys = {"space"},
      gamepadButtons = {"a"},
      mode = "release"
    },
    {
      name = "multiple keys",
      keys = {"lshift", "left mouse"},
      gamepadButtons = {"left trigger", "right trigger"},
    },
    {
      name = "chord action",
      keys = {"lshift", "left mouse"},
      gamepadButtons = {"left trigger", "right trigger"},
      chord = true
    }
  },

  -- gamepad analog values lower than this are clamped to 0
  gamepadLowDeadzone = 0.1,
  -- gamepad analog values higher than this are clamped to 1
  gamepadHighDeadzone = 0.95,
  -- size of the input buffer in seconds
  inputBufferSize = 0.5
}
