if (turtleplot == nil) then
	turtleplot = {};
	
	(function() 
		if (not fs.exists("turtle_data")) then fs.makeDir("turtle_data"); end
		local position = { x = 0, y = 0, z = 0, d = 0 };
		
		position.save = function()
			local file = fs.open("turtle_data/position", "w");
			file.write("return " .. position.x .. ", " .. position.y .. ", " .. position.z .. ", " .. position.d .. ";");
			file.close();
		end
		position.load = function()
			if (not fs.exists("turtle_data/position")) then return; end
			local file = fs.open("turtle_data/position", "r");
			local raw = file.readAll();
			file.close();
			position.x, position.y, position.z, position.d = loadstring(raw)();
		end
		position.load();
		
		turtleplot.getPosition = function() return position.x, position.y, position.z; end
		
		position.face = function(direction)
			if (direction == position.d) then return; end
			local leftangle = (position.d + 270) % 360;
			if (leftangle == direction) then
				if (turtle.turnLeft()) then
					position.d = direction;
					position.save();
					return true;
				end
				return false;
			end
			
			while (position.d ~= direction) do
				if (not turtle.turnRight()) then return false; end
				position.d = (position.d + 90) % 360;
				position.save();
			end
		end
		
		turtleplot.faceForward = function() return position.face(270); end
		turtleplot.faceLeft = function() return position.face(0); end
		turtleplot.faceRight = function() return position.face(90); end
		turtleplot.faceBackward = function() return position.face(180); end
		
		position.move = function(direction, mode)
			sleep(0.01);
			local move = turtle.forward;
			local dig = turtle.dig;
			
			if (direction == "up") then
				move = turtle.up;
				dig = turtle.digUp;
			elseif (direction == "down") then
				move = turtle.down;
				dig = turtle.digDown;
			else
				if (not position.face(direction)) then return false; end
			end
			
			if (turtle.getFuelLevel() == 0) then
				turtle.select(1);
				if (not turtle.refuel(1)) then
					print("Waiting for more fuel...");
					while (not turtle.refuel(1)) do
						sleep(1);
					end
				end
			end
			if (mode == "dig") then
				dig();
			elseif (mode == "excavate") then
				turtle.dig();
				turtle.digUp();
				turtle.digDown();
			end
			if (move()) then
				if (direction == 270) then
					position.y = position.y + 1;
				elseif (direction == 0) then
					position.x = position.x + 1;
				elseif (direction == 90) then 
					position.y = position.y - 1;
				elseif (direction == 180) then
					position.x = position.x - 1;
				elseif (direction == "up") then
					position.z = position.z + 1;
				elseif (direction == "down") then
					position.z = position.z - 1;
				else
					error("invalid movement direction");
				end
				position.save();
				return true;
			end	
			return false;
		end
		
		turtleplot.moveUp = function() return position.move("up"); end
		turtleplot.moveDown = function() return position.move("down"); end
		turtleplot.moveForward = function() return position.move(270); end
		turtleplot.moveLeft = function() return position.move(0); end
		turtleplot.moveRight = function() return position.move(90); end
		turtleplot.moveBackward = function() return position.move(180); end
		
		turtleplot.digUp = function() return position.move("up", "dig"); end
		turtleplot.digDown = function() return position.move("down", "dig"); end
		turtleplot.digForward = function() return position.move(270, "dig"); end
		turtleplot.digLeft = function() return position.move(0, "dig"); end
		turtleplot.digRight = function() return position.move(90, "dig"); end
		turtleplot.digBackward = function() return position.move(180, "dig"); end
		
		turtleplot.excavateUp = function() return position.move("up", "excavate"); end
		turtleplot.excavateDown = function() return position.move("down", "excavate"); end
		turtleplot.excavateForward = function() return position.move(270, "excavate"); end
		turtleplot.excavateLeft = function() return position.move(0, "excavate"); end
		turtleplot.excavateRight = function() return position.move(90, "excavate"); end
		turtleplot.excavateBackward = function() return position.move(180, "excavate"); end
		
		position.moveTo = function(x, y, z, mode)
			while (x > position.x) do
				position.move(0, mode);
			end
			while (x < position.x) do
				position.move(180, mode);
			end
			while (y > position.y) do
				position.move(270, mode);
			end
			while (y < position.y) do
				position.move(90, mode);
			end
			while (z > position.z) do
				position.move("up", mode);
			end
			while (z < position.z) do
				position.move("down", mode);
			end
		end
		
		position.getPlot = function(x, y, z)
			local offset = {
				x = x - position.x,
				y = y - position.y,
				z = z - position.z
			};
			local distance = math.sqrt(offset.x*offset.x + offset.y*offset.y + offset.z*offset.z);
			local plot = {{
				x = position.x,
				y = position.y,
				z = position.z
			}};
			local index = 1;
			for d = 0, distance do
				local target = {
					x = position.x + offset.x * d,
					y = position.y + offset.y * d,
					z = position.z + offset.z * d
				};
				if not (plot[index].x == target.x and plot[index].y == target.y and plot[index].z == target.z) then
					index = index + 1;
					plot[index] = target;
				end
			end
			return plot;
		end
		
		turtleplot.calcPlotTo = function(x, y, z) return position.getPlot(x, y, z); end
		
		position.plotTo = function(x, y, z, mode, action)
			local plot = position.getPlot(x, y, z);
			for i, coords in ipairs(plot) do
				position.moveTo(coords.x, coords.y, coords.z, mode);
				if (action ~= nil) then action(); end
			end
		end
		
		turtleplot.moveTo = function(x, y, z, action) return position.plotTo(x, y, z, nil, action); end
		turtleplot.digTo = function(x, y, z) return position.plotTo(x, y, z, "dig"); end
		turtleplot.excavateTo = function(x, y, z) return position.plotTo(x, y, z, "excavate"); end
		
	end)();
end
