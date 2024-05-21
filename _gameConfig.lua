-- Gameplay configs and anything else I don't want players touching. The filename starts with an
-- underscore so it's always at the top of the list in my editor.

DEBUG_CONFIG = {
  SHOW_HITBOXES = false, -- displays entity hitboxes and ui bounding boxes
  FORCE_RESET_USER_SETTINGS = false -- always resets user settings to default on startup
}

return {
  saveDirectory = "UnnamedLuaShooter",

  defaultUserSettings = {
    graphics = {
      width = 1280,
      height = 720,
      fullscreen = false,
      vsync = 1,
      msaa = 4
    },
    input = {
      swapThumbsticks = false,
      enableGamepadRumble = true, -- rumble is always disabled when the keyboard is being used
      keyboardBinds = {
        ["move up"] = {"w", "up"},
        ["move down"] = {"s", "down"},
        ["move left"] = {"a", "left"},
        ["move right"] = {"d", "right"},
        ["dash"] = {"right mouse"},
        ["melee"] = {"v"},
        ["aim"] = {"left mouse"},
        ["auto fire"] = {"f"},
        ["toggle fullscreen"] = {"f11"},
        ["pause"] = {"escape"},
        ["menu confirm"] = {"left mouse"},
        ["menu back"] = {"escape"},
        ["menu revert"] = {"r"},
        ["menu reset"] = {"delete"}
      },
      gamepadBinds = {
        ["move up"] = {"dpad up"},
        ["move down"] = {"dpad down"},
        ["move left"] = {"dpad left"},
        ["move right"] = {"dpad right"},
        ["dash"] = {"left bumper"},
        ["melee"] = {"x"},
        ["auto fire"] = {"right bumper"},
        ["pause"] = {"options"},
        ["menu up"] = {"dpad up"},
        ["menu down"] = {"dpad down"},
        ["menu left"] = {"dpad left"},
        ["menu right"] = {"dpad right"},
        ["menu confirm"] = {"a"},
        ["menu back"] = {"b"},
        ["menu revert"] = {"x"},
        ["menu reset"] = {"right stick click"}
      }
    }
  },

  input = {
    actions = {
      {name = "move up"},
      {name = "move down"},
      {name = "move left"},
      {name = "move right"},
      {name = "dash", mode = "press"},
      {name = "melee", mode = "press"},
      {name = "aim"},
      {name = "auto fire"},
      {name = "aim release", mode = "release"},
      {name = "toggle fullscreen", mode = "press"},
      {name = "pause", mode = "press"},
      {name = "menu up", mode = "press"},
      {name = "menu down", mode = "press"},
      {name = "menu left", mode = "press"},
      {name = "menu right", mode = "press"},
      {name = "menu confirm", mode = "press"},
      {name = "menu back", mode = "press"},
      {name = "menu revert", mode = "press"},
      {name = "menu reset", mode = "press"}
    },

    -- if true, the left and right thumbsticks are swapped
    swapThumbsticks = false,

    bufferSize = 0.5,   -- size of the input buffer in seconds
    lowDeadzone = 0.1,  -- gamepad analog values lower than this are clamped to 0
    highDeadzone = 0.95 -- gamepad analog values higher than this are clamped to 1
  },

  engine = {
    cameraTightness = 4, -- determines how quickly the camera moves

    -- when the window is this size in pixels, everything is displayed at 1:1 scale
    viewportWidth = 1600,
    viewportHeight = 900
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
      dashSpeed = 1600, -- pixels per second
      dashDuration = 0.075, -- seconds
      maxConsecutiveDashes = 3,
      dashRefreshDuration = 0.25, -- seconds

      meleeComboLength = 4, -- final hit is the spin attack
      meleeJabAngleSize = 120, -- degrees
      meleeSpinEndLag = 0.25, -- after the spin attack, melee is disabled for this many seconds

      initialBulletSpread = 45, -- degrees
      aimSpeed = 45, -- degrees per second
      aimSpeedWhileFiring = 15, -- degrees per second
      unAimSpeed = 30, -- degrees per second
      shotChargeTime = 0.5, -- seconds after fully aiming

      bulletVelocity = 1100, -- pixels per second
      bulletRange = 750, -- pixels
      fireRate = 450, -- rounds per minute
    },
    waveLauncherEnemy = {
      turnSpeed = 240, -- degrees per second
      moveSpeed = 600, -- pixels per second
      acceleration = 900, -- pixels per second squared

      -- determines how far from the player enemies try to stay
      minDistance = 300, -- pixels
      maxDistance = 500, -- pixels

      waveChargeTime = 0.75, -- seconds
      waveCooldown = 2.5, -- seconds
      leadTargets = true, -- if true, the enemy predicts where the player will be when targeting

      projectileMaxVelocity = 1950, -- pixels per second; projectiles spawn with 0 velocity
      projectileAcceleration = 2400, -- pixels per second squared
    },
  }
}