-- Gameplay configs and anything else I don't want player's touching. The filename starts with an
-- underscore so it's always at the top of the list in my editor.

DEBUG_CONFIG = {
  SHOW_HITBOXES = false
}

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
        keys = {"w", "up"},
        gamepadButtons = {"dpad up"}
      },
      {
        name = "move down",
        keys = {"s", "down"},
        gamepadButtons = {"dpad down"}
      },
      {
        name = "move left",
        keys = {"a", "left"},
        gamepadButtons = {"dpad left"}
      },
      {
        name = "move right",
        keys = {"d", "right"},
        gamepadButtons = {"dpad right"}
      },
      {
        name = "dash",
        keys = {"right mouse"},
        gamepadButtons = {"left bumper"},
        mode = "press"
      },
      {
        name = "melee",
        keys = {"v"},
        gamepadButtons = {"x"},
        mode = "press"
      },
      {
        name = "aim",
        keys = {"left mouse"},
        gamepadButtons = {},
      },
      {
        name = "auto fire",
        keys = {"f"},
        gamepadButtons = {"right bumper"}
      },
      {
        name = "aim release",
        keys = {"left mouse"},
        gamepadButtons = {},
        mode = "release"
      }
    },

    -- if true, the left and right thumbsticks are swapped
    swapThumbsticks = false,

    bufferSize = 0.5,   -- size of the input buffer in seconds
    lowDeadzone = 0.1,  -- gamepad analog values lower than this are clamped to 0
    highDeadzone = 0.95 -- gamepad analog values higher than this are clamped to 1
  },

  engine = {
    cameraTightness = 4, -- determines how quickly the camera moves
  },

  -- general gameplay configs
  gameplay = {
    roomWidth = 2400, -- width of the playable area in pixels
    roomHeight = 1500, -- height of the playable area in pixels
  },

  -- entity-specific settings
  entities = {
    player = {
      runSpeed = 375, -- pixels per second
      dashSpeed = 1600, -- pixels per second
      dashDuration = 0.075, -- seconds
      maxConsecutiveDashes = 3,
      dashRefreshDuration = 0.25, -- seconds

      meleeComboLength = 4, -- final hit is the spin attack
      meleeJabAngleSize = 120, -- degrees
      meleeSpinEndLag = 0.25, -- seconds

      initialBulletSpread = 45, -- degrees
      aimSpeed = 45, -- degrees per second
      aimSpeedWhileFiring = 15, -- degrees per second
      unAimSpeed = 30, -- degrees per second
      shotChargeTime = 0.5, -- seconds

      bulletVelocity = 1100, -- pixels per second
      bulletRange = 750, -- pixels
      fireRate = 450, -- rounds per minute
    },
    waveLauncherEnemy = {
      turnSpeed = 240, -- degrees per second
      moveSpeed = 600, -- pixels per second
      acceleration = 900, -- pixels per second squared
      minDistance = 300, -- pixels
      maxDistance = 500, -- pixels
    }
  }
}