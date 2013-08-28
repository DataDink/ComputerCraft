-- WARNING: Normal turtle movement and facing commands are not compatible with TurtlePlot. Use one or the other - do not use both.
--			TurtlePlot provides a positional coordinate system relative to the turtle's start point.
--			This allows you to make plots based on x,y,z coordinates and handles calculating facing and movement.
--
-- turtleplot.getPosition()			returns the x, y, z coordinate relative to the turtles initial position
--
-- turtleplot.faceForward()
-- turtleplot.faceLeft()
-- turtleplot.faceRight()
-- turtleplot.faceBackward()		Faces the turtle the specified direction relative to the turtles initial facing on turtleplot startup.
--
-- turtleplot.moveUp()
-- turtleplot.moveDown()
-- turtleplot.moveForward()
-- turtleplot.moveLeft()
-- turtleplot.moveRight()
-- turtleplot.moveBackward()		Face the turtle and moves one space in the specified direction. Will attempt to burn fuel from slot 1 when needed and will wait if no fuel is available.
--
-- turtleplot.digUp()
-- turtleplot.digDown()
-- turtleplot.digForward()
-- turtleplot.digLeft()
-- turtleplot.digRight()
-- turtleplot.digBackward()			Face the turtle, digs the block in front of it, and moves one space in the specified direction. Will attempt to burn fuel from slot 1 when needed and will wait if no fuel is available.
--
-- turtleplot.excavateUp()
-- turtleplot.excavateDown()
-- turtleplot.excavateForward()
-- turtleplot.excavateLeft()
-- turtleplot.excavateRight()
-- turtleplot.excavateBackward()	Face the turtle, digs the block in front, above, and below it, and moves one space in the specified direction. Will attempt to burn fuel from slot 1 when needed and will wait if no fuel is available.


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
		
		position.moveTo = function(direction, x, y, z, mode)
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
		
		
	end)();
	
end