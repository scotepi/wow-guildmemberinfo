--[[

bool = GuildMemberInfo:Register('AddonName', {
	lines = {
		uniqueLabel = {
			label = 'Label', -- Optional, localized field label, default is uniqueLabel
			default = 'Default Value', -- to be used inside f:SetText();
			height = #, -- Optional, Special height consideration
			callback = function(GetGuildRosterInfo(i)) return newText; end, -- Callback to update the text, no update on false ie. you want to do something custom with your frames
			onload = function(labelF, textF) yourFunc(labelF,textF) end, -- Optional, Function to run when the frame is created
			text = false, -- Optional, disable creating the text frame
		},
	},
});

Parent:
	GMIFrame
	
Your frames will be:
	GMILabelAddonNameLabel
	GMITextAddonNameLabel

]]
local lib, oldMinor = LibStub:NewLibrary("GuildMemberInfo-0.0", 1);

-- already loaded and no upgrade necessary
if not lib then return end

-- Save settings from old instances
lib.callbacks = lib.callbacks or {}
lib.frames = lib.frames or {}
lib.lastLine = lib.lastLine or nil;
lib.selected = lib.selected or nil;

-- Make our frame
if not lib.frame then
  lib.frame = CreateFrame("Frame", "GMIFrame")
end

local function OnEvent(self, event, ...)
	if ( event == 'ADDON_LOADED' ) then
		local addon = ...;
		
		if ( addon == 'Blizzard_GuildUI') then
			
			-- Create the real frame
			lib:CreateGMIFrame();
			
			-- Set our hooks
			GuildRosterContainer:HookScript("OnUpdate", function() lib:GuildFrameUpdated() end);
		end
	end
end

function lib:CreateGMIFrame()
	if (GuildMemberDetailFrame) then
		lib.frame:SetParent(GuildMemberDetailFrame);
		lib.frame:SetWidth(GuildMemberDetailFrame:GetWidth());
		lib.frame:SetHeight(60);
		lib.frame:SetPoint("TOPLEFT", GuildMemberDetailFrame, "BOTTOMLEFT", 0, -3);
		lib.frame:SetBackdrop(GuildMemberDetailFrame:GetBackdrop());
		
		-- Add all of our lines that have been registered so far
		for name,cb in pairs(lib.callbacks) do
			for label,settings in pairs(cb.lines) do
				lib:AddLine(name, label);
			end
		end
	end
end

function lib:GuildFrameUpdated()
	local pname = GetGuildRosterInfo(GetGuildRosterSelection());
	
	-- Make sure we have a new person
	if pname then
		
		-- Break if the person hasn't changed
		if pname == lib.selected then return end
		lib.selected = pname;
		
		-- Loop all callbacks
		for name,cb in pairs(lib.callbacks) do
			for label,settings in pairs(cb.lines) do
				
				if not settings.callback then
					error(name..' '..label..' doesnt have a callback');
					return false;
				end
				
				local value = settings.callback(GetGuildRosterInfo(GetGuildRosterSelection()));
				
				if value then
					lib:UpdateLine(name,label,value);
				end
			end
		end
	end
end

function lib:Register(name, settings)
	if not name then return end
	if not settings then error('No settings for '..name); return end
	if not type(settings) == 'table' then error('Settings arnt a table for '..name); return end
	
	if settings.lines and type(settings.lines) == 'table' then
	
		lib.callbacks[name] = settings;
		
		-- Validate
		for label,line in pairs(lib.callbacks[name].lines) do
			
			-- Break without a callback
			if not line.callback then 
				error(name..' '..label..' has no callback');
				return false;
			end
			
			-- Make sure we have a label
			if not line.label then lib.callbacks[name].lines[label].label = label; end
			if not line.height then lib.callbacks[name].lines[label].height = 10; end
			if not line.default then lib.callbacks[name].lines[label].default = ''; end
			if type(line.text) == 'nil' then lib.callbacks[name].lines[label].text = true; end
			
			-- If we are called after it alredy exists
			if (GuildMemberDetailFrame) then
				lib:AddLine(name, label);
			end
			
			return true;
		end
	else
		error('You must specify lines to add for '..name);
		return false;
	end
end

-- Add all
function lib:AddLines()
	
end

function lib:AddLine(name, label)
	if not name and label then error('AddLine missing information'); return end
	if not GuildMemberDetailFrame and lib.frame then error('Missing frames'); return end
	
	local line = lib.callbacks[name].lines[label];
	local default = line.default;
	local height = line.height or 10;
	
	if not ( name and label and default ) then return end
	if not lib.frames[name] then lib.frames[name] = {}; end
	
	-- Check if we have the frame
	if not lib.frames[name][label] then
		lib.frames[name][label] = {};
		
		
		lib.frames[name][label].label = lib.frame:CreateFontString("GMILabel"..name..label, "ARTWORK", "GameFontNormalSmall");
		lib.frames[name][label].label:SetHeight(height);
		lib.frames[name][label].label:SetText(line.label..':');
		
		-- This is the first line we are adding
		if not lib.lastLine then
			lib.frames[name][label].label:SetPoint("TOPLEFT", lib.frame, "TOPLEFT", 18, -17);
		else
			lib.frames[name][label].label:SetPoint("TOPLEFT", lib.lastLine, "BOTTOMLEFT", 0, 0);
		end
		
		-- Text
		if line.text then
			lib.frames[name][label].text = lib.frame:CreateFontString("GMIText"..name..label, "ARTWORK", "GameFontHighlight");
			lib.frames[name][label].text:SetPoint("LEFT", lib.frames[name][label].label, "RIGHT", 2, 0);
			lib.frames[name][label].text:SetText(default);
		end
		
		-- OnLoad
		
		if line.onload then
			line.onload(lib.frames[name][label].label, lib.frames[name][label].text);
		end
		
		-- Cleanup
		lib.lastLine = lib.frames[name][label].label;
		lib:ResizeFrame()
	end
end

function lib:UpdateLine(name, label, value)
	lib.frames[name][label].text:SetText(value);
end

function lib:ResizeFrame()
	local height = 17;
	for name,labels in pairs(lib.frames) do
		for label,frames in pairs(labels) do
			local h = frames.label:GetHeight();
			height = height + h + 8;
		end
	end
	
	-- Min height is 65 otherwise it looks bad
	if height < 65 then
		lib.frame:SetHeight(65);
	else
		lib.frame:SetHeight(height + 10);
	end
end

function lib:GetLabelFrame(name, label)
	return lib.frames[name][label].text;
end

function lib:GetTextFrame(name, label)
	return lib.frames[name][label].text;
end

lib.frame:SetScript("OnEvent", OnEvent);
lib.frame:RegisterEvent("ADDON_LOADED");