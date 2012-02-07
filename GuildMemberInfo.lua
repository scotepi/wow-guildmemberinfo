--[[

bool = GuildMemberInfo:Register('AddonName', {
	lines = {
		uniqueLabel = {
				-- Required
			callback = function(GetGuildRosterInfo(i)) return newText; end,
			
				-- Optional
			label = 'Label', -- localized field label, default is uniqueLabel
			default = 'Default Value',
			height = ##, -- Special height consideration, default is 10, this requires testing
			onload = function(labelF, textF) yourFunc(labelF,textF) end, -- Function to run when the frame is created
			text = false, -- Disable creating the text frame, works well with onload
		},
	},
});

Parent:
	GMIFrame
	
Your frames will be:
	GMILabelAddonNameLabel
	GMITextAddonNameLabel

]]

local AuroraF, AuroraC = unpack(Aurora)

-- Start the Addon
GMI = {};
GMI.callbacks = {};
GMI.frames = {};
GMI.lastLine = nil;
GMI.selected = nil;

-- Make our frame
GMI.frame = CreateFrame("Frame", "GMIFrame")

local function OnEvent(self, event, ...)
	if event == 'ADDON_LOADED' then
		local addon = ...;
		
		if addon == 'Blizzard_GuildUI' then
			
			-- Create the real frame
			GMI:CreateGMIFrame();
			
			-- Set our hooks
			GuildRosterContainer:HookScript("OnUpdate", function() GMI:GuildFrameUpdated() end);
		end
	end
end

function GMI:CreateGMIFrame()
	if (GuildMemberDetailFrame) then
		GMI.frame:SetParent(GuildMemberDetailFrame);
		GMI.frame:SetWidth(GuildMemberDetailFrame:GetWidth());
		GMI.frame:SetHeight(60);
		GMI.frame:SetPoint("TOPLEFT", GuildMemberDetailFrame, "BOTTOMLEFT", 0, -3);
		GMI.frame:SetBackdrop(GuildMemberDetailFrame:GetBackdrop());
		
        if AuroraF then
            AuroraF.CreateBD(GMI.frame);
        end
        
		-- Add all of our lines that have been registered so far
		for name,cb in pairs(GMI.callbacks) do
			for label,settings in pairs(cb.lines) do
				GMI:AddLine(name, label);
			end
		end
	end
end

function GMI:GuildFrameUpdated()
	local pname = GetGuildRosterInfo(GetGuildRosterSelection());
	
	-- Make sure we have a new person
	if pname then
		
		-- Break if the person hasn't changed
		if pname == GMI.selected then return end
		GMI.selected = pname;
		
		-- Loop all callbacks
		for name,cb in pairs(GMI.callbacks) do
			for label,settings in pairs(cb.lines) do
				
				if not settings.callback then
					error(name..' '..label..' doesnt have a callback');
					return false;
				end
				
				local value = settings.callback(GetGuildRosterInfo(GetGuildRosterSelection()));
				
				if value then
					GMI:UpdateLine(name,label,value);
				end
			end
		end
	end
end

function GMI:Register(name, settings)
	if not name then return end
	if not settings then error('No settings for '..name); return end
	if not type(settings) == 'table' then error('Settings arnt a table for '..name); return end
	
	if settings.lines and type(settings.lines) == 'table' then
	
		GMI.callbacks[name] = settings;
		
		-- Validate
		for label,line in pairs(GMI.callbacks[name].lines) do
			
			-- Break without a callback
			if not line.callback then 
				error(name..' '..label..' has no callback');
				return false;
			end
			
			-- Make sure we have a label
			if not line.label then GMI.callbacks[name].lines[label].label = label; end
			if not line.height then GMI.callbacks[name].lines[label].height = 12; end
			if not line.default then GMI.callbacks[name].lines[label].default = ''; end
			if type(line.text) == 'nil' then GMI.callbacks[name].lines[label].text = true; end
			
			-- If we are called after it alredy exists
			if (GuildMemberDetailFrame) then
				GMI:AddLine(name, label);
			end
			
			return true;
		end
	else
		error('You must specify lines to add for '..name);
		return false;
	end
end

-- Add all
function GMI:AddLines()
	
end

function GMI:AddLine(name, label)
	if not name and label then error('AddLine missing information'); return end
	if not GuildMemberDetailFrame and GMI.frame then error('Missing frames'); return end
	
	local line = GMI.callbacks[name].lines[label];
	local default = line.default;
	local height = line.height or 12;
	
	if not ( name and label and default ) then return end
	if not GMI.frames[name] then GMI.frames[name] = {}; end
	
	-- Check if we have the frame
	if not GMI.frames[name][label] then
		GMI.frames[name][label] = {};
		
		
		GMI.frames[name][label].label = GMI.frame:CreateFontString("GMILabel"..name..label, "ARTWORK", "GameFontNormalSmall");
		GMI.frames[name][label].label:SetHeight(height);
		GMI.frames[name][label].label:SetText(line.label..':');
		
		-- This is the first line we are adding
		if not GMI.lastLine then
			GMI.frames[name][label].label:SetPoint("TOPLEFT", GMI.frame, "TOPLEFT", 18, -17);
		else
			GMI.frames[name][label].label:SetPoint("TOPLEFT", GMI.lastLine, "BOTTOMLEFT", 0, 0);
		end
		
		-- Text
		if line.text then
			GMI.frames[name][label].text = GMI.frame:CreateFontString("GMIText"..name..label, "ARTWORK", "GameFontHighlight");
			GMI.frames[name][label].text:SetPoint("LEFT", GMI.frames[name][label].label, "RIGHT", 2, 0);
			GMI.frames[name][label].text:SetText(default);
		end
		
		-- OnLoad
		
		if line.onload then
			line.onload(GMI.frames[name][label].label, GMI.frames[name][label].text);
		end
		
		-- Cleanup
		GMI.lastLine = GMI.frames[name][label].label;
		GMI:ResizeFrame()
	end
end

function GMI:UpdateLine(name, label, value)
	GMI.frames[name][label].text:SetText(value);
end

function GMI:ResizeFrame()
	local height = 17;
	for name,labels in pairs(GMI.frames) do
		for label,frames in pairs(labels) do
			local h = frames.label:GetHeight();
			height = height + h + 8;
		end
	end
	
	-- Min height is 65 otherwise it looks bad
	if height < 65 then
		GMI.frame:SetHeight(65);
	else
		GMI.frame:SetHeight(height + 10);
	end
end

function GMI:GetLabelFrame(name, label)
	return GMI.frames[name][label].text;
end

function GMI:GetTextFrame(name, label)
	return GMI.frames[name][label].text;
end

-- Set Events
GMI.frame:SetScript("OnEvent", OnEvent);
GMI.frame:RegisterEvent("ADDON_LOADED");