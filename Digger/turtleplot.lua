if (turtleplot == nil) then
	turtleplot = {};
	
	(function() 
		local position = { x = 0, y = 0, z = 0, d = 270 };
		
		turtleplot.getPosition = function() return position.x, position.y, position.z; end
		
		turtleplot.resetPosition = function position.x = 0; position.y = 0; position.z = 0; position.d = 270; end 
		
		position.face = function(direction)
			if (direction == position.d) then return true; end
			local leftangle = (position.d + 270) % 360;
			if (leftangle == direction) then
				if (turtle.turnLeft()) then
					position.d = direction;
					return true;
				end
				return false;
			end
			
			while (position.d ~= direction) do
				if (not turtle.turnRight()) then return false; end
				position.d = (position.d + 90) % 360;
			end
			return true;
		end
		
		turtleplot.faceForward = function() return position.face(270); end
		turtleplot.faceLeft = function() return position.face(180); end
		turtleplot.faceRight = function() return position.face(0); end
		turtleplot.faceBackward = function() return position.face(90); end
		
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
				return true;
			end	
			return false;
		end
		
		turtleplot.moveUp = function() return position.move("up"); end
		turtleplot.moveDown = function() return position.move("down"); end
		turtleplot.moveForward = function() return position.move(270); end
		turtleplot.moveLeft = function() return position.move(180); end
		turtleplot.moveRight = function() return position.move(0); end
		turtleplot.moveBackward = function() return position.move(90); end
		
		turtleplot.digUp = function() return position.move("up", "dig"); end
		turtleplot.digDown = function() return position.move("down", "dig"); end
		turtleplot.digForward = function() return position.move(270, "dig"); end
		turtleplot.digLeft = function() return position.move(180, "dig"); end
		turtleplot.digRight = function() return position.move(0, "dig"); end
		turtleplot.digBackward = function() return position.move(90, "dig"); end
		
		turtleplot.excavateUp = function() return position.move("up", "excavate"); end
		turtleplot.excavateDown = function() return position.move("down", "excavate"); end
		turtleplot.excavateForward = function() return position.move(270, "excavate"); end
		turtleplot.excavateLeft = function() return position.move(180, "excavate"); end
		turtleplot.excavateRight = function() return position.move(0, "excavate"); end
		turtleplot.excavateBackward = function() return position.move(90, "excavate"); end

		local function round(number)
			if (number % 1 >= 0.5) then
				return math.ceil(number);
			else
				return math.floor(number);
			end
		end
		
		position.moveTo = function(x, y, z, mode)
			while (round(x) > position.x) do
				position.move(0, mode);
			end
			while (round(x) < position.x) do
				position.move(180, mode);
			end
			while (round(y) > position.y) do
				position.move(270, mode);
			end
			while (round(y) < position.y) do
				position.move(90, mode);
			end
			while (round(z) > position.z) do
				position.move("up", mode);
			end
			while (round(z) < position.z) do
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
				local multiplier = 1 / distance * d;
				local target = {
					x = round(position.x + offset.x * multiplier),
					y = round(position.y + offset.y * multiplier),
					z = round(position.z + offset.z * multiplier)
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
		
		position.calcDistance = function(vector)
			local a = 0;
			for i, v in pairs(vector) do a = a + v * v; end
			return math.sqrt(a);
		end
		
		position.calcAngle2d = function(angle, distance)
			return {
				h = math.cos(math.rad(angle)) * distance,
				v = math.sin(math.rad(angle)) * distance
			};
		end
		
		turtleplot.calcAngleZ = function(angle, distance) 
			local target = position.calcAngle2d(angle, distance);
			return {x = position.x + target.h, y = position.y + target.v, z = position.z};
		end
		turtleplot.calcAngleY = function(angle, distance) 
			local target = position.calcAngle2d(angle, distance);
			return {x = position.x + target.h, y = position.y, z = position.z + target.v};
		end
		turtleplot.calcAngleX = function(angle, distance) 
			local target = position.calcAngle2d(angle, distance);
			return {x = position.x, y = position.y + target.v, z = position.z + target.h};
		end
		
		turtleplot.moveAngleZ = function(angle, distance, action)
			local target = position.calcAngle2d(angle, distance);
			position.plotTo(position.x + target.h, position.y + target.v, position.z, nil, action);
		end
		turtleplot.moveAngleY = function(angle, distance, action)
			local target = position.calcAngle2d(angle, distance);
			position.plotTo(position.x + target.h, position.y, position.z + target.v, nil, action);
		end
		turtleplot.moveAngleX = function(angle, distance, action)
			local target = position.calcAngle2d(angle, distance);
			position.plotTo(position.x, position.y + target.v, position.z + target.h, nil, action);
		end
		
		turtleplot.digAngleZ = function(angle, distance)
			local target = position.calcAngle2d(angle, distance);
			position.plotTo(position.x + target.h, position.y + target.v, position.z, "dig");
		end
		turtleplot.digAngleY = function(angle, distance)
			local target = position.calcAngle2d(angle, distance);
			position.plotTo(position.x + target.h, position.y, position.z + target.v, "dig");
		end
		turtleplot.digAngleX = function(angle, distance)
			local target = position.calcAngle2d(angle, distance);
			position.plotTo(position.x, position.y + target.v, position.z + target.h, "dig");
		end
		
		turtleplot.excavateAngleZ = function(angle, distance)
			local target = position.calcAngle2d(angle, distance);
			position.plotTo(position.x + target.h, position.y + target.v, position.z, "excavate");
		end
		turtleplot.excavateAngleY = function(angle, distance)
			local target = position.calcAngle2d(angle, distance);
			position.plotTo(position.x + target.h, position.y, position.z + target.v, "excavate");
		end
		turtleplot.excavateAngleX = function(angle, distance)
			local target = position.calcAngle2d(angle, distance);
			position.plotTo(position.x, position.y + target.v, position.z + target.h, "excavate");
		end

		position.calcAngle3d = function(frontAngle, sideAngle, distance)
			if (distance == 0) then return {h = 0, v = 0, d = 0}; end
			local front = position.calcAngle2d(frontAngle, 1);
			if (front.h == 0 and front.v == 0 and sideAngle == 0) then
				return { h = 0, v = 0, d = distance };
			end
			if (front.h == 0 and front.v == 0) then
				return { h = 0, v = 0, d = -distance };
			end
			local side = position.calcAngle2d(sideAngle, front.v);
			local normal = {
				h = front.h * side.v / front.v,
				v = side.v,
				d = side.h
			}
			local scale = distance / position.calcDistance(normal);
			return {
				h = normal.h * scale,
				v = normal.v * scale,
				d = normal.d * scale
			}
		end
		
		turtleplot.calcAngleZX = function(angleZ, angleX, distance)
			local target = position.calcAngle3d(angleZ, (angleX + 270) % 360, distance);
			return {x = position.x + target.h, y = position.y + target.d, z = position.z + target.v};
		end
		turtleplot.calcAngleZY = function(angleZ, angleY, distance)
			local target = position.calcAngle3d((angleZ + 270) % 360, angleY, distance);
			return {x = position.x + target.v, y = position.y + target.h, z = position.z + target.d};
		end
		turtleplot.calcAngleXY = function(angleX, angleY, distance)
			local target = position.calcAngle3d(angleY, angleX, distance);
			return {x = position.x + target.h, y = position.y + target.d, z = position.z + target.v};
		end
		
		turtleplot.moveAngleZX = function(angleZ, angleX, distance, action)
			local target = position.calcAngle3d(angleZ, (angleX + 270) % 360, distance);
			position.plotTo(position.x + target.h, position.y + target.v, position.z + target.d, nil, action);
		end
		turtleplot.moveAngleZY = function(angleZ, angleY, distance, action)
			local target = position.calcAngle3d((angleZ + 270) % 360, angleY, distance);
			position.plotTo(position.x + target.v, position.y + target.h, position.z + target.d, nil, action);
		end
		turtleplot.moveAngleXY = function(angleX, angleY, distance, action)
			local target = position.calcAngle3d(angleY, angleX, distance);
			position.plotTo(position.x + target.h, position.y + target.d, position.z + target.v, nil, action);
		end
		
		turtleplot.digAngleZX = function(angleZ, angleX, distance)
			local target = position.calcAngle3d(angleZ, (angleX + 270) % 360, distance);
			position.plotTo(position.x + target.h, position.y + target.v, position.z + target.d, "dig");
		end
		turtleplot.digAngleZY = function(angleZ, angleY, distance)
			local target = position.calcAngle3d((angleZ + 270) % 360, angleY, distance);
			position.plotTo(position.x + target.v, position.y + target.h, position.z + target.d, "dig");
		end
		turtleplot.digAngleXY = function(angleX, angleY, distance)
			local target = position.calcAngle3d(angleY, angleX, distance);
			position.plotTo(position.x + target.h, position.y + target.d, position.z + target.v, "dig");
		end
		
		turtleplot.excavateAngleZX = function(angleZ, angleX, distance)
			local target = position.calcAngle3d(angleZ, (angleX + 270) % 360, distance);
			position.plotTo(position.x + target.h, position.y + target.v, position.z + target.d, "excavate");
		end
		turtleplot.excavateAngleZY = function(angleZ, angleY, distance)
			local target = position.calcAngle3d((angleZ + 270) % 360, angleY, distance);
			position.plotTo(position.x + target.v, position.y + target.h, position.z + target.d, "excavate");
		end
		turtleplot.excavateAngleXY = function(angleX, angleY, distance)
			local target = position.calcAngle3d(angleY, angleX, distance);
			position.plotTo(position.x + target.h, position.y + target.d, position.z + target.v, "excavate");
		end
		
	end)();
end
