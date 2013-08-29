if (configuration == nil) then
	configuration = {
		Username = "DataDink", -- Your username on github
		Repository = "ComputerCraft" -- The repository to load files from
	};
end

if (json == nil) then
	json = {};
	(function()
		
		local parse = {};
		
		parse.trim = function(s)
			s = string.gsub(s, "^%s+", "");
			s = string.gsub(s, "%s+$", "");
			return s;
		end
		
		parse.unescape = function(s)
			s = string.gsub(s, "\\\\", "\\");
			s = string.gsub(s, "\\\"", "\"");
			s = string.gsub(s, "\\/", "/");
			s = string.gsub(s, "\\b", "\b");
			s = string.gsub(s, "\\f", "\f");
			s = string.gsub(s, "\\n", "\n");
			s = string.gsub(s, "\\r", "\r");
			s = string.gsub(s, "\\t", "\t");
			while (string.find(s, "\\u%x%x%x%x") ~= nil) do -- is there a better way to do this?
				local code = string.match(s, "\\u%x%x%x%x"); 
				local number = tonumber(string.sub(code, 3), 16);
				local character = loadstring("return \"\\" .. number .. "\"")();
				s = string.gsub(s, code, character);
			end
			return s;
		end
		
		parse.string = function(s)
			local index = 2;
			while index < string.len(s) do
				local position = string.find(s, "\\*\"", index);
				local text = string.match(s, "\\*\"", index);
				if (position == nil) then error("Invalid JSON format"); end
				if ((string.len(text) % 2) == 1) then
					index = position + string.len(text) - 1;
					break;
				end
				index = position + string.len(text);
			end
			local remainder = string.sub(s, index + 1);
			local result = string.sub(s, 2, index - 1);
			return parse.unescape(result), remainder;
		end
		
		parse.number = function(s)
			local numeric = string.match(s, "^-?%d+%.?%d*");
			if (numeric == nil) then error("Invalid JSON format"); end
			local value = tonumber(numeric);
			s = string.sub(s, string.len(numeric) + 1);
			local exponent = string.match(s, "^[eE][+-]?%d+");
			if (exponent ~= nil) then
				local multiplier = tonumber(string.match(exponent, "-?%d+$"));
				value = value * math.pow(10, multiplier);
				s = string.sub(s, string.len(exponent) + 1);
			end
			return value, s;
		end
		
		parse.array = function(s)
			local array = {};
			local index = 1;
			s = string.sub(s, 2);
			s = parse.trim(s);
			
			while (string.sub(s, 1, 1) ~= "]") do
				local value, remainder = parse.select(s);
				array[index] = value;
				index = index + 1;
				s = parse.trim(remainder);
				if (string.sub(s, 1, 1) == ",") then 
					s = string.sub(s, 2);
					s = parse.trim(s);
				end
			end
			s = string.sub(s, 2);
			s = parse.trim(s);
			return array, s;
		end
		
		parse.object = function(s)
			local object = {};
			s = string.sub(s, 2);
			s = parse.trim(s);
			
			while (string.sub(s, 1, 1) ~= "}") do
				local key, remainder = parse.string(s);
				s = parse.trim(remainder);
				s = string.sub(s, 2);
				s = parse.trim(s);
				local value, remainder = parse.select(s);
				object[key] = value;
				s = parse.trim(remainder);
				if (string.sub(s, 1, 1) == ",") then
					s = string.sub(s, 2);
					s = parse.trim(s);
				end
			end
			s = string.sub(s, 2);
			s = parse.trim(s);
			return object, s;
		end
		
		parse.select = function(s)
			s = parse.trim(s);
			local switch = string.sub(s,1,1);
			if (switch == "{") then return parse.object(s); 
			elseif (switch == "[") then return parse.array(s); 
			elseif (switch == "\"") then return parse.string(s); 
			elseif (string.match(s, "^true") ~= nil) then return true, string.sub(s, 5); 
			elseif (string.match(s, "^false") ~= nil) then return false, string.sub(s, 6); 
			elseif (string.match(s, "^null") ~= nil) then return nil, string.sub(s, 5); 
			else return parse.number(s); end
		end
		
		json.parse = function(s)
			s = parse.trim(s);
			local object = parse.select(s);
			return object;
		end
		
	end)();
end


(function() 
	local rawUrlRoot = "https://raw.github.com/" .. configuration.Username .. "/" .. configuration.Repository;
	local blobUrlRoot = "https://github.com/" .. configuration.Username .. "/" .. configuration.Repository .. "/blob";
	
	local getRaw = function(fileInfo) 
		return string.gsub(fileInfo["html_url"], blobUrlRoot, rawUrlRoot);
	end

	local rootUrl = "https://api.github.com/repos/" .. configuration.Username .. "/" .. configuration.Repository .. "/contents/";
	local rootDir = json.parse(http.get(rootUrl).readAll());
	
	local loadDirectory = function(directory)
		for index, fileInfo in pairs(directory) do
			if (fileInfo.type == "file" and string.find(fileInfo.name, "%.lua$") ~= nil) then
				local fileUrl = getRaw(fileInfo);
				local fileRaw = http.get(fileUrl).readAll();
				local loader = loadstring(fileRaw);
				if (loader ~- nil) then loader();
				else print("Could not parse " .. fileInfo.name); end
			end
		end
	end
	
	loadDirectory(rootDir);
	
	local label = os.getComputerLabel();
	if (label == nil) then return; end
	local labelUrl = rootUrl .. label .. "/";
	local labelData = http.get(labelUrl);
	if (labelData == nil) then return; end
	local labelDir = json.parse(labelData.readAll());
	if (labelDir.message == "Not Found") then return; end
	loadDirectory(labelDir);
	
end)();