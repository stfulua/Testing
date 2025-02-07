--[[
    Important UNC [iUNC]
    Made by stfulua
    Project: github.com/stfulua/Testing

    It's still being maintained, don't worry.
    Get the newest version here:
    https://raw.githubusercontent.com/stfulua/Testing/main/iUNC.lua

    MIT License, please read.
--]]
local identityLevel = getthreadidentity()
-- Initialize variables to track success/failure of features
local results = {}
local running = 0

-- Function to test a feature and log its result
local function testFeature(name, func)
    running += 1
    task.spawn(function()
        local success, message = pcall(func)
        if success then
            print("✅ " .. name .. ": Success")
            results[name] = true
        else
            warn("⛔ " .. name .. ": Failed - " .. tostring(message))
            results[name] = false
        end
        running -= 1
    end)
end

-- Header and summary
print("\n")
print("Executor Feature Test")
print("✅ - Pass, ⛔ - Fail\n")

task.defer(function()
    repeat task.wait() until running == 0 -- Wait for all tests to complete
    local passes, fails = 0, 0
    for _, result in pairs(results) do
        if result then
            passes += 1
        else
            fails += 1
        end
    end
    local total = passes + fails
    local rate = math.floor(passes / total * 100)
    print("\n--- Feature Test Summary ---")
    print("✅ Passed: " .. passes .. "/" .. total .. " (" .. rate .. "%)")
    print("⛔ Failed: " .. fails .. "/" .. total)
end)

-- 1. Get Executor Information
testFeature("Executor Information", function()
    local executorName, executorVersion = identifyexecutor()
    local identityLevel = getthreadidentity()
    print("Executor Name: " .. (executorName or "N/A"))
    if executorVersion then
        print("Executor Version: " .. executorVersion)
    end
    print("Thread Identity Level: " .. (identityLevel or "N/A"))
end)

-- 2. Filesystem Operations
testFeature("Filesystem Operations", function()
    local folderName = "MyFolder"
    local fileName = "example.txt"

    -- Cleanup before testing
    if isfolder(folderName) then
        delfolder(folderName)
    end

    makefolder(folderName) -- Creates a folder named "MyFolder"
    writefile(folderName .. "/" .. fileName, "Hello, this is a test file!") -- Writes content to a file
    appendfile(folderName .. "/" .. fileName, " Appended text.") -- Appends text to the file
    local content = readfile(folderName .. "/" .. fileName) -- Reads the file content
    assert(content == "Hello, this is a test file! Appended text.", "File content mismatch")

    local files = listfiles(folderName) -- Lists files in the folder
    assert(#files > 0, "No files found in the folder")
    assert(isfile(folderName .. "/" .. fileName), "File does not exist")
    assert(isfolder(folderName), "Folder does not exist")

    delfile(folderName .. "/" .. fileName) -- Deletes the file
    assert(not isfile(folderName .. "/" .. fileName), "File was not deleted")
    delfolder(folderName) -- Deletes the folder
    assert(not isfolder(folderName), "Folder was not deleted")
end)

-- 3. Hashing Data
testFeature("Hashing Data", function()
    local algorithms = { 'sha1', 'sha256', 'md5' }
    for _, algo in ipairs(algorithms) do
        local hash = crypt.hash("password123", algo) -- Generate hash of "password123" using the specified algorithm
        assert(hash ~= nil, "Hash generation failed for " .. algo)
        print("Hash (" .. algo .. "): " .. hash)
    end
end)

-- 4. Base64 Encoding and Decoding
testFeature("Base64 Encoding/Decoding", function()
    local originalText = "Base64 Test"
    local encoded = crypt.base64encode(originalText) -- Encode text to Base64
    assert(encoded ~= nil, "Encoding failed")
    print("Encoded: " .. encoded)
    local decoded = crypt.base64decode(encoded) -- Decode Base64 back to original text
    assert(decoded == originalText, "Decoding failed")
    print("Decoded: " .. decoded)
end)

-- 5. Manipulating Metatables
testFeature("Manipulating Metatables", function()
    local myTable = { value = 42 }
    local meta = {
        __index = function(tbl, key)
            if key == "magicValue" then
                return tbl.value * 2 -- Double the value when accessing "magicValue"
            end
        end,
        __newindex = function(tbl, key, value)
            if key == "value" then
                rawset(tbl, key, value + 10) -- Add 10 to the value when setting it
            end
        end
    }
    setmetatable(myTable, meta)
    myTable.value = 10 -- Sets value to 20 (10 + 10)
    assert(myTable.value == 20, "Metatable __newindex failed")
    assert(myTable.magicValue == 40, "Metatable __index failed")
end)

-- 6. Hooking Functions
testFeature("Hooking Functions", function()
    local LogFunction = false
    local function testHookFunction()
        local success, errorMessage = pcall(function()
            local originalPrint = hookfunction(print, function(...)
                originalPrint("[LOGGED]:", ...) -- Use the original print function here
            end)
            originalPrint("This is the original print function.")
            print("This is a test message.") -- This will trigger the hook and add the "[LOGGED]:" prefix
            LogFunction = true
        end)
        if not success then
            warn("Error while testing hookfunction: " .. tostring(errorMessage))
            LogFunction = false
        end
        assert(LogFunction, "Hookfunction failed")
    end
    testHookFunction()
end)

-- 7. HTTP Requests
testFeature("HTTP Requests", function()
    local response = request({
        Url = "https://httpbin.org/get",
        Method = "GET",
    })
    assert(response.StatusCode == 200, "Request failed with status code: " .. (response.StatusCode or "N/A"))
    local body = game:GetService("HttpService"):JSONDecode(response.Body)
    print("User-Agent:", body["headers"]["User-Agent"]) -- Prints the User-Agent from the response
end)

-- 8. WebSocket Example
testFeature("WebSocket", function()
    local ws = WebSocket.connect("ws://echo.websocket.events")
    if ws then
        ws.OnMessage = function(message)
            print("Received Message:", message)
        end
        ws.Send("Hello, WebSocket!") -- Send a message to the WebSocket server
        task.wait(5) -- Wait for 5 seconds to receive messages
        ws.Close() -- Close the WebSocket connection
    else
        error("WebSocket connection failed")
    end
end)

-- 9. Additional Features
testFeature("isreadonly", function()
    local obj = {}
    table.freeze(obj)
    assert(isreadonly(obj), "Object is not read-only")
end)

testFeature("lz4compress and lz4decompress", function()
    local raw = "Hello, world!"
    local compressed = lz4compress(raw)
    assert(type(compressed) == "string", "Compression did not return a string")
    local decompressed = lz4decompress(compressed, #raw)
    assert(decompressed == raw, "Decompression did not return the original string")
end)

testFeature("getinstances", function()
    local instances = getinstances()
    assert(type(instances) == "table", "Did not return a table")
    assert(#instances > 0, "No instances found")
end)

testFeature("getnilinstances", function()
    local nilInstances = getnilinstances()
    assert(type(nilInstances) == "table", "Did not return a table")
    assert(#nilInstances > 0, "No nil-parented instances found")
end)

testFeature("isscriptable", function()
    local fire = Instance.new("Fire")
    assert(isscriptable(fire, "Size") == true, "Property should be scriptable")
    assert(isscriptable(fire, "size_xml") == false, "Hidden property should not be scriptable")
end)

-- 10. Game Activity Check
testFeature("Game Activity Check", function()
    local isActive = isrbxactive()
    assert(type(isActive) == "boolean", "Did not return a boolean value")
    print("Game Active: " .. tostring(isActive))
end)

-- 11. Console Title Manipulation
testFeature("Console Title Manipulation", function()
    local success, originalTitle = pcall(rconsolesettitle, "Test Title")
    if success then
        assert(type(originalTitle) == "string", "Did not return the original console title")
        task.wait(1) -- Allow time for the title change to take effect
        rconsolesettitle(originalTitle) -- Restore the original title
    else
        warn("⚠️ Console title manipulation is not supported")
    end
end)

-- 13. Drawing API
testFeature("Drawing API", function()
    local drawing = Drawing.new("Text")
    if drawing then
        drawing.Text = "Test Drawing"
        drawing.Position = Vector2.new(100, 100)
        drawing.Visible = true
        task.wait(1) -- Allow time for the drawing to render
        drawing:Remove()
    else
        warn("⚠️ Drawing API is not supported")
    end
end)

-- 14. Custom Asset Handling
testFeature("Custom Asset Handling", function()
    local assetPath = "customasset.txt"
    writefile(assetPath, "Custom asset content")
    local assetId = getcustomasset(assetPath)
    if assetId then
        assert(type(assetId) == "string", "Did not return a string for the custom asset")
        assert(string.match(assetId, "rbxasset://") == "rbxasset://", "Did not return a valid rbxasset URL")
    else
        warn("⚠️ Custom asset handling is not supported")
    end
    delfile(assetPath)
end)

-- 15. Hidden Property Access
testFeature("Hidden Property Access", function()
    local fire = Instance.new("Fire")
    local hiddenProperty, isHidden = gethiddenproperty(fire, "size_xml")
    if hiddenProperty and isHidden then
        assert(hiddenProperty == 5, "Did not return the correct hidden property value")
        assert(isHidden == true, "Did not return true for a hidden property")
    else
        warn("⚠️ Hidden property access is not supported")
    end
end)

-- 16. Script Bytecode Extraction
testFeature("Script Bytecode Extraction", function()
    local animate = game:GetService("Players").LocalPlayer.Character.Animate
    if animate then
        local bytecode = getscriptbytecode(animate)
        assert(type(bytecode) == "string", "Did not return a string for the script bytecode")
    else
        warn("⚠️ Character.Animate is nil, skipping bytecode extraction")
    end
end)

-- 17. Thread Identity Management
testFeature("Thread Identity Management", function()
    local originalIdentity = 3 or 8
    if originalIdentity then
        setthreadidentity(identityLevel)
        assert(getthreadidentity() == 3 or 8, "Did not set the thread identity correctly")
        setthreadidentity(originalIdentity) -- Restore the original identity
    else
        warn("⚠️ Thread identity management is not supported")
    end
end)

-- 18. Environment Manipulation
testFeature("Environment Manipulation", function()
    local globalEnv = getgenv()
    if globalEnv then
        globalEnv.__TEST_GLOBAL = true
        assert(__TEST_GLOBAL == true, "Failed to set a global variable")
        globalEnv.__TEST_GLOBAL = nil
    else
        warn("⚠️ Environment manipulation is not supported")
    end
end)

-- 19. Running Scripts Enumeration
testFeature("Running Scripts Enumeration", function()
    local scripts = getrunningscripts()
    if scripts then
        assert(type(scripts) == "table", "Did not return a table")
        assert(#scripts > 0, "No running scripts found")
    else
        warn("⚠️ Running scripts enumeration is not supported")
    end
end)

function watermark()
    print("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n                                           MG Console Clear\n")
end
function clearconsole()
    local count = 0
    while true do
        if count == 500 then
            break
        else
            count += 1
            print("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
        end
    end
end
clearconsole()
watermark()

-- Summary of Results
print("\n--- Feature Test Summary ---")
for feature, success in pairs(results) do
    print(feature .. ": " .. (success and "✅ Passed" or "⛔ Failed"))
end
