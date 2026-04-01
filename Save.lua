-- ============ XANBAR CONFIG MANAGER (FULLY FIXED) ============

local SaveManager = {}

do
    SaveManager.Folder = "XanBarConfigs"
    SaveManager.SubFolder = ""
    SaveManager.Ignore = {}
    SaveManager.Library = nil
    SaveManager.AutoloadConfigLabel = nil

    -- Получаем HttpService
    local HttpService = game:GetService("HttpService")
    
    -- Копируем глобальные функции
    local isfolder = isfolder
    local isfile = isfile
    local listfiles = listfiles
    local makefolder = makefolder
    local delfile = delfile
    local readfile = readfile
    local writefile = writefile

    -- Универсальные методы JSON (поддержка разных экзекуторов)
    local function jsonEncode(data)
        if HttpService.JSONEncode then
            return HttpService:JSONEncode(data)
        elseif HttpService.EncodeJson then
            return HttpService:EncodeJson(data)
        elseif HttpService.Encode then
            return HttpService:Encode(data)
        else
            return HttpService:JSONEncode(data)
        end
    end

    local function jsonDecode(data)
        if HttpService.JSONDecode then
            return HttpService:JSONDecode(data)
        elseif HttpService.DecodeJson then
            return HttpService:DecodeJson(data)
        elseif HttpService.Decode then
            return HttpService:Decode(data)
        else
            return HttpService:JSONDecode(data)
        end
    end

    -- Парсер для XanBar элементов
    SaveManager.Parser = {
        Toggle = {
            Save = function(idx, obj)
                return { type = "Toggle", idx = idx, value = obj:Value() }
            end,
            Load = function(idx, data)
                local obj = SaveManager.Library.Toggles[idx]
                if obj and obj:Value() ~= data.value then
                    obj:Set(data.value)
                end
            end,
        },
        Slider = {
            Save = function(idx, obj)
                return { type = "Slider", idx = idx, value = obj:Value() }
            end,
            Load = function(idx, data)
                local obj = SaveManager.Library.Options[idx]
                if obj and obj:Value() ~= data.value then
                    obj:Set(data.value)
                end
            end,
        },
        Dropdown = {
            Save = function(idx, obj)
                return { type = "Dropdown", idx = idx, value = obj:Value() }
            end,
            Load = function(idx, data)
                local obj = SaveManager.Library.Options[idx]
                if obj and obj:Value() ~= data.value then
                    obj:Set(data.value)
                end
            end,
        },
        ColorPicker = {
            Save = function(idx, obj)
                return { type = "ColorPicker", idx = idx, value = obj:Value():ToHex() }
            end,
            Load = function(idx, data)
                local obj = SaveManager.Library.Options[idx]
                if obj then
                    obj:Set(Color3.fromHex(data.value))
                end
            end,
        },
        Keybind = {
            Save = function(idx, obj)
                return { type = "Keybind", idx = idx, key = tostring(obj:Value()) }
            end,
            Load = function(idx, data)
                local obj = SaveManager.Library.Options[idx]
                if obj then
                    local keyName = tostring(data.key):gsub("Enum.KeyCode.", "")
                    local key = Enum.KeyCode[keyName]
                    if key then obj:Set(key) end
                end
            end,
        },
        Input = {
            Save = function(idx, obj)
                return { type = "Input", idx = idx, text = obj:Value() }
            end,
            Load = function(idx, data)
                local obj = SaveManager.Library.Options[idx]
                if obj and obj:Value() ~= data.text then
                    obj:Set(data.text)
                end
            end,
        },
    }

    -- Вспомогательные функции
    local function ensureFolders()
        local folder = SaveManager.Folder
        if not isfolder(folder) then makefolder(folder) end
        
        local settingsFolder = folder .. "/settings"
        if not isfolder(settingsFolder) then makefolder(settingsFolder) end
        
        if SaveManager.SubFolder and SaveManager.SubFolder ~= "" then
            local subFolder = settingsFolder .. "/" .. SaveManager.SubFolder
            if not isfolder(subFolder) then makefolder(subFolder) end
        end
    end

    function SaveManager:SetLibrary(library)
        self.Library = library
        self.Toggles = {}
        self.Options = {}
    end

    function SaveManager:IgnoreThemeSettings()
        self:SetIgnoreIndexes({
            "Theme", "ThemeManager_ThemeList", "ThemeManager_CustomThemeList"
        })
    end

    function SaveManager:SetIgnoreIndexes(list)
        for _, key in pairs(list) do
            self.Ignore[key] = true
        end
    end

    function SaveManager:SetFolder(folder)
        self.Folder = folder
        ensureFolders()
    end

    function SaveManager:SetSubFolder(folder)
        self.SubFolder = folder
        ensureFolders()
    end

    function SaveManager:GetFilePath(name)
        local path = self.Folder .. "/settings/"
        if self.SubFolder and self.SubFolder ~= "" then
            path = path .. self.SubFolder .. "/"
        end
        return path .. name .. ".json"
    end

    function SaveManager:Save(name)
        if not name or name == "" then
            return false, "no config name"
        end
        ensureFolders()

        local data = { objects = {} }
        
        -- Сохраняем флаги через XanBar
        for flag, value in pairs(self.Library.Flags or {}) do
            if not self.Ignore[flag] then
                local obj = { type = "Flag", idx = flag, value = value }
                
                if type(value) == "boolean" then
                    obj.type = "Toggle"
                elseif type(value) == "number" then
                    obj.type = "Slider"
                elseif type(value) == "string" then
                    obj.type = "Input"
                elseif typeof(value) == "Color3" then
                    obj.type = "ColorPicker"
                    obj.value = value:ToHex()
                elseif typeof(value) == "EnumItem" then
                    obj.type = "Keybind"
                    obj.value = tostring(value)
                end
                
                table.insert(data.objects, obj)
            end
        end

        local success, encoded = pcall(jsonEncode, data)
        if not success then
            return false, "encode error: " .. tostring(encoded)
        end

        local filePath = self:GetFilePath(name)
        local writeSuccess, writeErr = pcall(writefile, filePath, encoded)
        if not writeSuccess then
            return false, "write error: " .. tostring(writeErr)
        end
        
        return true
    end

    function SaveManager:Load(name)
        if not name or name == "" then
            return false, "no config name"
        end

        local file = self:GetFilePath(name)
        if not isfile(file) then
            return false, "config not found"
        end

        local content
        local readSuccess, readErr = pcall(function()
            content = readfile(file)
        end)
        
        if not readSuccess then
            return false, "read error: " .. tostring(readErr)
        end

        local success, decoded = pcall(jsonDecode, content)
        if not success then
            return false, "decode error: " .. tostring(decoded)
        end

        for _, obj in pairs(decoded.objects or {}) do
            if not self.Ignore[obj.idx] then
                if obj.type == "Toggle" or obj.type == "Slider" or obj.type == "Input" then
                    self.Library:SetFlag(obj.idx, obj.value)
                elseif obj.type == "ColorPicker" then
                    self.Library:SetFlag(obj.idx, Color3.fromHex(obj.value))
                elseif obj.type == "Keybind" then
                    local keyName = tostring(obj.value):gsub("Enum.KeyCode.", "")
                    local key = Enum.KeyCode[keyName]
                    if key then self.Library:SetFlag(obj.idx, key) end
                end
            end
        end

        return true
    end

    function SaveManager:Delete(name)
        if not name or name == "" then
            return false, "no config name"
        end
        
        local file = self:GetFilePath(name)
        if not isfile(file) then
            return false, "config not found"
        end
        
        local success, err = pcall(delfile, file)
        if not success then
            return false, "delete error: " .. tostring(err)
        end
        
        return true
    end

    function SaveManager:RefreshConfigList()
        ensureFolders()
        local folder = self.Folder .. "/settings/"
        if self.SubFolder and self.SubFolder ~= "" then
            folder = folder .. self.SubFolder .. "/"
        end
        
        local configs = {}
        if listfiles then
            local files = listfiles(folder)
            for _, file in ipairs(files) do
                if file:match("%.json$") then
                    local name = file:match("([^/\\]+)%.json$")
                    if name then table.insert(configs, name) end
                end
            end
        end
        return configs
    end

    function SaveManager:GetAutoloadConfig()
        ensureFolders()
        local path = self.Folder .. "/settings/autoload.txt"
        if self.SubFolder and self.SubFolder ~= "" then
            path = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
        end
        
        if isfile(path) then
            local success, name = pcall(readfile, path)
            if success then
                return name
            end
        end
        return "none"
    end

    function SaveManager:SaveAutoloadConfig(name)
        if not name or name == "" then
            return false, "no config name"
        end
        
        ensureFolders()
        local path = self.Folder .. "/settings/autoload.txt"
        if self.SubFolder and self.SubFolder ~= "" then
            path = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
        end
        
        local success, err = pcall(writefile, path, name)
        if not success then
            return false, "write error: " .. tostring(err)
        end
        return true
    end

    function SaveManager:DeleteAutoLoadConfig()
        local path = self.Folder .. "/settings/autoload.txt"
        if self.SubFolder and self.SubFolder ~= "" then
            path = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
        end
        
        if isfile(path) then
            pcall(delfile, path)
        end
        return true
    end

    function SaveManager:LoadAutoloadConfig()
        local name = self:GetAutoloadConfig()
        if name ~= "none" and name ~= "" then
            local success, err = self:Load(name)
            if success and self.AutoloadConfigLabel then
                self.AutoloadConfigLabel:SetText("Autoload: " .. name)
            end
        end
    end

    -- GUI для XanBar
    function SaveManager:BuildConfigSection(tab)
        assert(self.Library, "Must set SaveManager.Library")

        tab:AddSection("Configuration")

        -- Поле ввода имени
        local nameInput = tab:AddInput("Config Name", "config_name")
        nameInput:Set("my_config")

        -- Кнопка сохранения
        tab:AddButton("Save Config", function()
            local name = nameInput:Value()
            if name == "" then
                self.Library:Notify({ Title = "Error", Content = "Enter config name!", Type = "Error" })
                return
            end
            local success, err = self:Save(name)
            if success then
                self.Library:Notify({ Title = "Saved", Content = "Config '" .. name .. "' saved!", Type = "Success" })
                configList:SetOptions(self:RefreshConfigList())
            else
                self.Library:Notify({ Title = "Error", Content = err, Type = "Error" })
            end
        end)

        tab:AddDivider()

        -- Выпадающий список конфигов
        local configList = tab:AddDropdown("Config List", "config_list", self:RefreshConfigList())

        -- Загрузка
        tab:AddButton("Load Config", function()
            local name = configList:Value()
            if not name then
                self.Library:Notify({ Title = "Error", Content = "Select a config!", Type = "Error" })
                return
            end
            local success, err = self:Load(name)
            if success then
                self.Library:Notify({ Title = "Loaded", Content = "Config '" .. name .. "' loaded!", Type = "Success" })
            else
                self.Library:Notify({ Title = "Error", Content = err, Type = "Error" })
            end
        end)

        -- Перезапись
        tab:AddButton("Overwrite Config", function()
            local name = configList:Value()
            if not name then
                self.Library:Notify({ Title = "Error", Content = "Select a config!", Type = "Error" })
                return
            end
            local success, err = self:Save(name)
            if success then
                self.Library:Notify({ Title = "Saved", Content = "Config '" .. name .. "' overwritten!", Type = "Success" })
            else
                self.Library:Notify({ Title = "Error", Content = err, Type = "Error" })
            end
        end)

        -- Удаление
        tab:AddButton("Delete Config", function()
            local name = configList:Value()
            if not name then
                self.Library:Notify({ Title = "Error", Content = "Select a config!", Type = "Error" })
                return
            end
            local success, err = self:Delete(name)
            if success then
                self.Library:Notify({ Title = "Deleted", Content = "Config '" .. name .. "' deleted!", Type = "Warning" })
                configList:SetOptions(self:RefreshConfigList())
                configList:Set(nil)
            else
                self.Library:Notify({ Title = "Error", Content = err, Type = "Error" })
            end
        end)

        -- Обновить список
        tab:AddButton("Refresh List", function()
            configList:SetOptions(self:RefreshConfigList())
        end)

        tab:AddDivider()

        -- Автозагрузка
        local autoLabel = tab:AddLabel("Autoload: " .. self:GetAutoloadConfig())

        tab:AddButton("Set as Autoload", function()
            local name = configList:Value()
            if not name then
                self.Library:Notify({ Title = "Error", Content = "Select a config!", Type = "Error" })
                return
            end
            local success, err = self:SaveAutoloadConfig(name)
            if success then
                autoLabel:SetText("Autoload: " .. name)
                self.Library:Notify({ Title = "Autoload Set", Content = "Config '" .. name .. "' will load automatically", Type = "Success" })
            else
                self.Library:Notify({ Title = "Error", Content = err, Type = "Error" })
            end
        end)

        tab:AddButton("Clear Autoload", function()
            self:DeleteAutoLoadConfig()
            autoLabel:SetText("Autoload: none")
            self.Library:Notify({ Title = "Autoload Cleared", Content = "No config will auto-load", Type = "Info" })
        end)

        -- Сброс всех настроек
        tab:AddButton("Reset All Settings", function()
            self.Library:ResetAllFlags()
            self.Library:Notify({ Title = "Reset", Content = "All settings reset to defaults!", Type = "Success" })
        end)

        self.AutoloadConfigLabel = autoLabel
        self:SetIgnoreIndexes({ "config_name", "config_list" })
        
        -- Загружаем автоконфиг
        self:LoadAutoloadConfig()
    end

    ensureFolders()
end

return SaveManager
