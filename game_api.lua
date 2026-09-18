local class = require("class")

---@class game.GameAPI
---@operator call: game.GameAPI
local GameAPI = class()

---@param game sphere.GameController
function GameAPI:new(game)
	self.game = game
end

---@return {id: string, name: string}[]
function GameAPI:getThemes()
	local themes = {
		{id = "Default", name = "Default"},
	}
	local packages = self.game.packageManager:getPackagesByType("ui")

	for _, package in ipairs(packages) do
		table.insert(themes, {
			id = package.name,
			name = package:getDisplayName(),
		})
	end

	return themes
end

---@param theme_id string
function GameAPI:setTheme(theme_id)
	local themes = self:getThemes()
	local found = false

	for _, theme in ipairs(themes) do
		if theme.id == theme_id then
			found = true
			break
		end
	end

	if not found then
		error("Unknown UI theme: " .. tostring(theme_id))
	end

	self.game.configModel.configs.settings.graphics.userInterface = theme_id
	self.game.previewModel:stop()
	self.game.uiModel:switchTheme()
end

return GameAPI
