print("Updating startup");

local url = "https://raw.github.com/DataDink/ComputerCraft/master/Startup%20Program/startup.lua";
print("Downloading: " .. url);
local stream = http.get(url);
if (stream == nil) then error("Download Not Found"); end
local raw = stream.readAll();
if (raw == nil) then error("Download NIL"); end
print("Download Complete");

print("Saving to 'startup'");
fs.delete("startup");
local file = fs.open("startup", "w");
file.write(raw);
file.close();
print("File saved");
