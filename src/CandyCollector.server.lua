--!strict
-- Sunday Charlie: Candy Collector 🍬
-- A cute candy GUI that pings your Discord with an embed every time you collect
-- a candy, and sends a summary embed every 5 minutes.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")

-----------------------------------------------------------------------------
-- CONFIG
-----------------------------------------------------------------------------

-- Change this to match where your player's candy count lives. With MM2-style
-- data this is usually playerdata.Candy.
local CANDY_PATH = "playerdata.Candy"

-- How often (in seconds) the summary embed is sent. 300 = 5 minutes.
local WEBHOOK_INTERVAL = 300

-- How often we poll the candy count to detect "collection" (seconds).
local POLL_INTERVAL = 1

-- Cute pastel colours for the GUI.
local COL_BG = Color3.fromRGB(255, 214, 235)    -- soft pink
local COL_PANEL = Color3.fromRGB(255, 235, 245) -- lighter pink
local COL_ACCENT = Color3.fromRGB(255, 150, 200) -- bubblegum
local COL_TEXT = Color3.fromRGB(90, 50, 80)      -- cocoa
local COL_BUTTON = Color3.fromRGB(255, 170, 220)

local WEBHOOK_STORE = "CandyWebhookStore_v1"

-----------------------------------------------------------------------------
-- SETUP
-----------------------------------------------------------------------------

local DataStore = DataStoreService:GetDataStore(WEBHOOK_STORE)

-- Fetch a nested value from something like playerdata.Candy.
local function getNestedValue(root, path)
    if typeof(root) ~= "table" then
        return 0
    end
    local segment = path:match("^([^.]+)")
    if not segment then
        return root
    end
    local value = root[segment]
    local rest = path:sub(#segment + 2)
    if rest == "" then
        return value
    end
    return getNestedValue(value, rest)
end

-- Convert a numeric candy count to a string, or the raw value if not a number.
local function candyAmount(value)
    if type(value) == "number" then
        return tostring(math.floor(value))
    elseif type(value) == "string" then
        return value
    end
    return "0"
end

-----------------------------------------------------------------------------
-- EMBED HELPERS
-----------------------------------------------------------------------------

local function sendWebhook(url, title, description, color, footerText, extraFields)
    if not url or url == "" then
        return
    end

    local embed = {
        title = title,
        description = description,
        color = color,
        footer = {
            text = footerText,
        },
    }

    if extraFields and #extraFields > 0 then
        embed.fields = extraFields
    end

    local payload = HttpService:JSONEncode({
        username = "Candy Collector 🍭",
        embeds = { embed },
    })

    local success, err = pcall(function()
        HttpService:PostAsync(url, payload, Enum.HttpContentType.ApplicationJson)
    end)

    if not success then
        warn("[CandyCollector] Could not send webhook: " .. tostring(err))
    end
end

-----------------------------------------------------------------------------
-- GUI
-----------------------------------------------------------------------------

local function buildGui(player)
    local gui = Instance.new("ScreenGui")
    gui.Name = "CandyCollectorGui"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Name = "Background"
    frame.BackgroundColor3 = COL_BG
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(0, 320, 0, 260)
    frame.Position = UDim2.new(0.5, -160, 0.5, -130)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Parent = gui

    -- Pretty rounded corners
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 24)
    uiCorner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.Text = "🍬 Candy Collector 🍬"
    title.TextColor3 = COL_TEXT
    title.TextSize = 26
    title.TextStrokeTransparency = 0.7
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    local candyLabel = Instance.new("TextLabel")
    candyLabel.Name = "CandyCount"
    candyLabel.BackgroundColor3 = COL_PANEL
    candyLabel.BackgroundTransparency = 0.2
    candyLabel.Size = UDim2.new(0, 260, 0, 40)
    candyLabel.Position = UDim2.new(0, 30, 0, 70)
    candyLabel.Text = "🍭 Candies: 0"
    candyLabel.TextColor3 = COL_TEXT
    candyLabel.TextSize = 20
    candyLabel.Font = Enum.Font.Gotham
    local candyCorner = Instance.new("UICorner")
    candyCorner.CornerRadius = UDim.new(0, 16)
    candyCorner.Parent = candyLabel
    candyLabel.Parent = frame

    local info = Instance.new("TextLabel")
    info.Name = "Info"
    info.BackgroundTransparency = 1
    info.Size = UDim2.new(1, -40, 0, 40)
    info.Position = UDim2.new(0, 20, 0, 115)
    info.Text = "Your webhook sends an embed to\nDiscord every 5 minutes! 💌"
    info.TextColor3 = COL_TEXT
    info.TextSize = 14
    info.Font = Enum.Font.Gotham
    info.TextWrapped = true
    info.Parent = frame

    local webhookBox = Instance.new("TextBox")
    webhookBox.Name = "WebhookBox"
    webhookBox.BackgroundColor3 = COL_PANEL
    webhookBox.BackgroundTransparency = 0.2
    webhookBox.Size = UDim2.new(0, 260, 0, 36)
    webhookBox.Position = UDim2.new(0, 30, 0, 165)
    webhookBox.PlaceholderText = "Paste your Discord webhook here..."
    webhookBox.Text = ""
    webhookBox.TextColor3 = COL_TEXT
    webhookBox.PlaceholderColor3 = Color3.fromRGB(170, 140, 160)
    webhookBox.TextSize = 13
    webhookBox.Font = Enum.Font.Gotham
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 12)
    boxCorner.Parent = webhookBox
    webhookBox.Parent = frame

    local saveButton = Instance.new("TextButton")
    saveButton.Name = "SaveButton"
    saveButton.BackgroundColor3 = COL_BUTTON
    saveButton.Size = UDim2.new(0, 120, 0, 30)
    saveButton.Position = UDim2.new(0.5, -60, 0, 215)
    saveButton.Text = "Save 💖"
    saveButton.TextColor3 = COL_TEXT
    saveButton.TextSize = 16
    saveButton.Font = Enum.Font.GothamBold
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 14)
    btnCorner.Parent = saveButton
    saveButton.Parent = frame

    return {
        candyLabel = candyLabel,
        webhookBox = webhookBox,
        saveButton = saveButton,
    }
end

-----------------------------------------------------------------------------
-- PLAYER SESSION LOGIC
-----------------------------------------------------------------------------

local function runSession(player)
    local guiElements = buildGui(player)

    -- Load saved webhook for this player.
    local savedWebhook = ""
    pcall(function()
        local loaded = DataStore:GetAsync(tostring(player.UserId))
        if type(loaded) == "string" then
            savedWebhook = loaded
        end
    end)
    guiElements.webhookBox.Text = savedWebhook

    local webhook = savedWebhook

    guiElements.saveButton.Activated:Connect(function()
        webhook = guiElements.webhookBox.Text
        pcall(function()
            DataStore:SetAsync(tostring(player.UserId), webhook)
        end)
    end)

    -- Session-only collected counter.
    local sessionCollected = 0
    local lastKnown = 0

    -- Preload the current candy count once.
    pcall(function()
        lastKnown = tonumber(getNestedValue(player, CANDY_PATH)) or 0
    end)
    guiElements.candyLabel.Text = "🍭 Candies: " .. candyAmount(lastKnown)

    -- Poll for candy collection.
    task.spawn(function()
        while player.Parent ~= nil do
            task.wait(POLL_INTERVAL)

            local current = 0
            pcall(function()
                current = tonumber(getNestedValue(player, CANDY_PATH)) or 0
            end)

            if current > lastKnown then
                local gained = current - lastKnown
                sessionCollected = sessionCollected + gained

                -- Cute instant embed 🍬
                sendWebhook(
                    webhook,
                    "🍭 Candy Collected!",
                    "Yay! You picked up some candies! 🍬\n\n**+ " .. tostring(gained) .. " candies**\nYou now have **"
                        .. tostring(current) .. "** total candies! 🍭",
                    0xFFB6D9,
                    "Candy Collector loves you 💕"
                )

                guiElements.candyLabel.Text = "🍭 Candies: " .. tostring(current)
            end

            lastKnown = current
        end
    end)

    -- Send a summary embed every 5 minutes.
    task.spawn(function()
        while player.Parent ~= nil do
            task.wait(WEBHOOK_INTERVAL)

            local current = 0
            pcall(function()
                current = tonumber(getNestedValue(player, CANDY_PATH)) or 0
            end)

            sendWebhook(
                webhook,
                "🍬 Candy Update (every 5 min)",
                "Here's your little candy report! 💌\n\n**Total candies collected this session:** "
                    .. tostring(sessionCollected) .. "\n**Current candy balance:** " .. tostring(current)
                    .. "\n\nKeep collecting, you're doing amazing! 🌈✨",
                0xB8E0FF,
                "Candy Collector 📅"
            )

            guiElements.candyLabel.Text = "🍭 Candies: " .. tostring(current)
        end
    end)
end

-----------------------------------------------------------------------------
-- CONNECT
-----------------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player)
    task.spawn(runSession, player)
end)

-- Handle players already in the game (e.g. server started with players).
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(runSession, player)
end

print("[CandyCollector] 🍭 Cute candy collector is ready!")
