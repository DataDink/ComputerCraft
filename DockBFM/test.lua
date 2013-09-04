(function()

	local monitor = peripheral.wrap("top");
	
	local useMonitor = function(delegate)
		term.redirect(monitor);
		delegate();
		term.restore();
	end
	
	local screenSize = {};
	useMonitor(function() screenSize.width, screenSize.height = term.getSize(); end);

	for c = 1, 255 do
		local left = c % screenSize.width + 1;
		local top = math.floor(c / screenSize.width) + 1;
		local character = string.char(c);
		useMonitor(function() 
			term.setCursorPos(left, top);
			term.write(character);
		end);
	end
	
end)();
