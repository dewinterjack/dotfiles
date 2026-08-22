--- === FirefoxDisplayScale ===
---
--- Changes Firefox's UI scale when a configured monitor is connected or
--- disconnected. Firefox is restarted after its preference changes.

local obj = {}
obj.__index = obj

obj.name = "FirefoxDisplayScale"
obj.version = "1.0"
obj.author = "Jack Dewinter <jackdewinter1@gmail.com>"
obj.homepage = "https://github.com/dewinterjack/dotfiles"
obj.license = "MIT"

--- FirefoxDisplayScale.monitorName
--- Variable
--- The name of the monitor that should use `connectedScale`.
obj.monitorName = nil

--- FirefoxDisplayScale.connectedScale
--- Variable
--- The Firefox UI scale to use when `monitorName` is connected.
obj.connectedScale = "1.2"

--- FirefoxDisplayScale.disconnectedScale
--- Variable
--- The Firefox UI scale to use when `monitorName` is disconnected.
obj.disconnectedScale = "-1.0"

--- FirefoxDisplayScale.debounceSeconds
--- Variable
--- How long to wait for screen changes to settle before updating Firefox.
obj.debounceSeconds = 1

obj._firefoxBundleId = "org.mozilla.firefox"
obj._firefoxApplicationName = "Firefox"
obj._screenWatcher = nil
obj._applicationWatcher = nil
obj._debounceTimer = nil
obj._restartTimer = nil
obj._waitingForRestart = false

local function readFile(path)
    local file = io.open(path, "r")

    if not file then
        return nil
    end

    local contents = file:read("*a")
    file:close()

    return contents
end

local function writeFile(path, contents)
    local file, err = io.open(path, "w")

    if not file then
        error("Could not write " .. path .. ": " .. tostring(err))
    end

    file:write(contents)
    file:close()
end

local function trim(value)
    return value:match("^%s*(.-)%s*$")
end

local function parseIni(contents)
    local sections = {}
    local currentSection = nil

    for line in contents:gmatch("[^\r\n]+") do
        local sectionName = line:match("^%s*%[([^%]]+)%]%s*$")

        if sectionName then
            currentSection = {
                name = sectionName,
                values = {},
            }
            table.insert(sections, currentSection)
        elseif currentSection and not line:match("^%s*[#;]") then
            local key, value = line:match("^%s*([^=]+)=(.-)%s*$")

            if key then
                currentSection.values[trim(key)] = trim(value)
            end
        end
    end

    return sections
end

local function firefoxRoot()
    local home = os.getenv("HOME")

    if not home then
        error("Could not determine the home directory")
    end

    return home .. "/Library/Application Support/Firefox"
end

local function resolveProfilePath(root, path, relative)
    if not relative or path:sub(1, 1) == "/" then
        return path
    end

    return root .. "/" .. path
end

local function findFirefoxProfile()
    local root = firefoxRoot()
    local profilesIni = root .. "/profiles.ini"
    local contents = readFile(profilesIni)

    if not contents then
        error("Could not find Firefox profiles.ini at " .. profilesIni)
    end

    local sections = parseIni(contents)

    for _, section in ipairs(sections) do
        local path = section.values.Default

        if section.name:match("^Install") and path then
            return resolveProfilePath(root, path, true)
        end
    end

    for _, section in ipairs(sections) do
        local values = section.values

        if
            section.name:match("^Profile%d+$")
            and values.Default == "1"
            and values.Path
        then
            return resolveProfilePath(
                root,
                values.Path,
                values.IsRelative ~= "0"
            )
        end
    end

    error("Could not determine the default Firefox profile")
end

local function desiredPreference(scale)
    return 'user_pref("layout.css.devPixelsPerPx", "' .. scale .. '");'
end

local function updateUserJs(profile, scale)
    local userJs = profile .. "/user.js"
    local contents = readFile(userJs) or ""
    local existingScale = contents:match(
        'user_pref%("layout%.css%.devPixelsPerPx",%s*"([^"]+)"%s*%);'
    )

    if existingScale == scale then
        return false
    end

    local preference = desiredPreference(scale)
    local pattern =
        'user_pref%("layout%.css%.devPixelsPerPx",%s*"[^"]+"%s*%);'

    if contents:match(pattern) then
        contents = contents:gsub(pattern, preference)
    else
        if #contents > 0 and contents:sub(-1) ~= "\n" then
            contents = contents .. "\n"
        end

        contents = contents .. preference .. "\n"
    end

    writeFile(userJs, contents)

    return true
end

function obj:_targetMonitorConnected()
    for _, screen in ipairs(hs.screen.allScreens()) do
        if screen:name() == self.monitorName then
            return true
        end
    end

    return false
end

function obj:_setScale(scale)
    local profile = findFirefoxProfile()

    if not updateUserJs(profile, scale) then
        return
    end

    hs.alert.show("Firefox scale → " .. scale)

    local firefox = hs.application.get(self._firefoxBundleId)

    if not firefox then
        return
    end

    self._waitingForRestart = true
    firefox:kill()
end

function obj:_updateScale()
    local scale = self.disconnectedScale

    if self:_targetMonitorConnected() then
        scale = self.connectedScale
    end

    self:_setScale(scale)
end

function obj:_scheduleUpdate()
    if self._debounceTimer then
        self._debounceTimer:stop()
    end

    self._debounceTimer = hs.timer.doAfter(self.debounceSeconds, function()
        self._debounceTimer = nil
        self:_updateScale()
    end)
end

function obj:_handleApplicationEvent(appName, eventType, app)
    if not self._waitingForRestart then
        return
    end

    local isFirefox = appName == self._firefoxApplicationName
        or (app and app:bundleID() == self._firefoxBundleId)

    if eventType ~= hs.application.watcher.terminated or not isFirefox then
        return
    end

    self._waitingForRestart = false
    self._restartTimer = hs.timer.doAfter(0.5, function()
        self._restartTimer = nil
        hs.application.launchOrFocus(self._firefoxApplicationName)
    end)
end

--- FirefoxDisplayScale:start()
--- Method
--- Starts watching for monitor changes and applies the current scale.
---
--- Returns:
---  * The `FirefoxDisplayScale` Spoon object.
function obj:start()
    if self._screenWatcher then
        return self
    end

    if not self.monitorName or self.monitorName == "" then
        error("FirefoxDisplayScale.monitorName must be configured before start")
    end

    self._applicationWatcher = hs.application.watcher.new(
        function(appName, eventType, app)
            self:_handleApplicationEvent(appName, eventType, app)
        end
    )
    self._applicationWatcher:start()

    self._screenWatcher = hs.screen.watcher.new(function()
        self:_scheduleUpdate()
    end)
    self._screenWatcher:start()

    local started, err = pcall(function()
        self:_updateScale()
    end)

    if not started then
        self:stop()
        error(err)
    end

    return self
end

--- FirefoxDisplayScale:stop()
--- Method
--- Stops all watchers and pending timers owned by the Spoon.
---
--- Returns:
---  * The `FirefoxDisplayScale` Spoon object.
function obj:stop()
    if self._screenWatcher then
        self._screenWatcher:stop()
        self._screenWatcher = nil
    end

    if self._applicationWatcher then
        self._applicationWatcher:stop()
        self._applicationWatcher = nil
    end

    if self._debounceTimer then
        self._debounceTimer:stop()
        self._debounceTimer = nil
    end

    if self._restartTimer then
        self._restartTimer:stop()
        self._restartTimer = nil
    end

    self._waitingForRestart = false

    return self
end

return obj
