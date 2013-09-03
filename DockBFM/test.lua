(function()

	local monitor = peripheral.wrap("top");
	
	local useMonitor = function(delegate)
		term.redirect(monitor);
		delegate();
		term.restore();
	end
	
	local screenSize = {};
	useMonitor(function() screenSize.width, screenSize.y = term.getSize(); end);

	for c = 1, 255 do
		local left = screenSize.width % c + 1;
		local top = math.floor(screenSize.height / c) + 1;
		local character = string.char(i);
		useMonitor(function() 
			term.setCursorPos(left, top);
			term.write(character);
		end);
	end
	
end)();
