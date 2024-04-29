-- Filename starts with an underscore so it's always at the top of the list in my editor.

return {
  graphics = {
    width = 1280,
    height = 720,
    fullscreen = false, -- overrides width and height
    vsync = "adaptive", -- true, false, or "adaptive"
    msaaSamples = 8,    -- number of samples for antialiasing
  },

  input = {
    keybinds = {
      {
        name = "move up",
        keys = {"up", "w"},
        gamepadButtons = {"dpad up"}
      },
      {
        name = "move down",
        keys = {"down", "s"},
        gamepadButtons = {"dpad down"}
      },
      {
        name = "move left",
        keys = {"left", "a"},
        gamepadButtons = {"dpad left"}
      },
      {
        name = "move right",
        keys = {"right", "d"},
        gamepadButtons = {"dpad right"}
      },
      {
        name = "dash",
        keys = {"space"},
        gamepadButtons = {"left bumper"},
        mode = "press"
      }
    },

    -- if true, the left and right thumbsticks are swapped
    invertThumbsticks = false,

    bufferSize = 0.5,   -- size of the input buffer in seconds
    lowDeadzone = 0.1,  -- gamepad analog values lower than this are clamped to 0
    highDeadzone = 0.95 -- gamepad analog values higher than this are clamped to 1
  },

  engine = {
    cameraTightness = 2.5, -- determines how quickly the camera moves
  },

  -- general gameplay configs
  gameplay = {
    roomWidth = 2400, -- width of the playable area in pixels
    roomHeight = 1500, -- height of the playable area in pixels
  },

  -- entity-specific settings
  entities = {
    player = {
      runSpeed = 450, -- pixels per second
      dashSpeed = 1500, -- pixels per second
      dashDuration = 0.075, -- seconds
      maxConsecutiveDashes = 2,
      dashRefreshDuration = 0.2 -- seconds
    }
  }
}
