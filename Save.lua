-- ============ XANBAR CONFIG MANAGER ============

local SaveManager = {}

do
    SaveManager.Folder = "XanBarConfigs"
    SaveManager.SubFolder = ""
    SaveManager.Ignore = {}
    SaveManager.Library = nil
    SaveManager.AutoloadConfigLabel = nil

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
                local val = obj:Value()
                return { type = "Dropdown", idx = idx, value = val }
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
                local key = obj:Value()
                return { type = "Keybind", idx = idx, key = tostring(key) }
            end,
            Load = function(idx, data)
                local obj = SaveManager.Library.Options[idx]
                if obj then
                    local key = Enum.KeyCode[data.key:gsub("Enum.KeyCode.", "")]
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
        
        -- Собираем все элементы из окон
        for _, win in ipairs(library.Windows or {}) do
            for _, tab in ipairs(win.Tabs or {}) do
                -- Проходим по элементам в скролле
                local scroll = tab.Scroll
                if scroll then
                    for _, child in ipairs(scroll:GetChildren()) do
                        if child:IsA("Frame") then
                            local toggle = child:FindFirstChild("ToggleBg")
                            local slider = child:FindFirstChild("Track")
                            local input = child:FindFirstChild("Input")
                            local color = child:FindFirstChild("Picker")
                            
                            if toggle then
                                local label = child:FindFirstChild("Label")
                                if label then
                                    local name = label.Text
                                    self.Toggles[name] = {
                                        Type = "Toggle",
                                        Value = function() return child.ToggleBg.BackgroundColor3 == library.CurrentTheme.ToggleEnabled end,
                                        Set = function(v)
                                            local btn = child:FindFirstChild("Hitbox")
                                            if btn then btn.MouseButton1Click:Fire() end
                                        end
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
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
                local typeName = type(value)
                local obj = { type = "Flag", idx = flag, value = value }
                
                if typeName == "boolean" then
                    obj.type = "Toggle"
                elseif typeName == "number" then
                    obj.type = "Slider"
                elseif typeName == "string" then
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

        local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
        if not success then
            return false, "encode error"
        end

        writefile(self:GetFilePath(name), encoded)
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

        local success, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(file))
        if not success then
            return false, "decode error"
        end

        for _, obj in pairs(decoded.objects or {}) do
            if not self.Ignore[obj.idx] then
                if obj.type == "Flag" or obj.type == "Toggle" or obj.type == "Slider" or obj.type == "Input" then
                    self.Library:SetFlag(obj.idx, obj.value)
                elseif obj.type == "ColorPicker" then
                    self.Library:SetFlag(obj.idx, Color3.fromHex(obj.value))
                elseif obj.type == "Keybind" then
                    local key = Enum.KeyCode[obj.value:gsub("Enum.KeyCode.", "")]
                    if key then self.Library:SetFlag(obj.idx, key) end
                end
            end
        end

        return true
    end

    function SaveManager:Delete(name)
        local file = self:GetFilePath(name)
        if not isfile(file) then
            return false, "config not found"
        end
        delfile(file)
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
            return readfile(path)
        end
        return "none"
    end

    function SaveManager:SaveAutoloadConfig(name)
        ensureFolders()
        local path = self.Folder .. "/settings/autoload.txt"
        if self.SubFolder and self.SubFolder ~= "" then
            path = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
        end
        writefile(path, name)
        return true
    end

    function SaveManager:DeleteAutoLoadConfig()
        local path = self.Folder .. "/settings/autoload.txt"
        if self.SubFolder and self.SubFolder ~= "" then
            path = self.Folder .. "/settings/" .. self.SubFolder .. "/autoload.txt"
        end
        if isfile(path) then delfile(path) end
        return true
    end

    function SaveManager:LoadAutoloadConfig()
        local name = self:GetAutoloadConfig()
        if name ~= "none" then
            self:Load(name)
            if self.AutoloadConfigLabel then
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
            self:Delete(name)
            self.Library:Notify({ Title = "Deleted", Content = "Config '" .. name .. "' deleted!", Type = "Warning" })
            configList:SetOptions(self:RefreshConfigList())
            configList:Set(nil)
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
            self:SaveAutoloadConfig(name)
            autoLabel:SetText("Autoload: " .. name)
            self.Library:Notify({ Title = "Autoload Set", Content = "Config '" .. name .. "' will load automatically", Type = "Success" })
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
