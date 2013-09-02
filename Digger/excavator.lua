if (excavator == nil) then 
	excavator = {};
	
	(function() 
		local directions = {
			forward = 270, front = 270,
			rear = 90, back = 90, backward = 90,
			left = 180, 
			right = 0,
			up = "up",
			down = "down"
		};
	
		local position = {
			marker = { x = 0, y = 0, z = 0 },
			current = { x = 0, y = 0, z = 0, d = directions.forward }
		};
		position.mark = function() 
			position.marker.x = position.current.x; 
			position.marker.y = position.current.y; 
			position.marker.z = position.current.z; 
		end
		position.reset = function() 
			position.current.x = 0; 
			position.current.y = 0; 
			position.current.z = 0; 
			position.current.d = directions.forward; 
		end
		
		local fuel = {};
		local move = {};
		local inventory = {};
		
		-- Fuel
		fuel.movesPerFuel = 0;
		fuel.calcRemainingFuel = function() return turtle.getItemCount(1) * fuel.movesPerFuel + turtle.getFuelLevel(); end
		fuel.needsRefuel = function() return move.calcReturnDist() >= fuel.calcRemainingFuel(); end
		fuel.initialize = function()
			local before = turtle.getFuelLevel();
			turtle.select(inventory.fuelSlot);
			turtle.refuel(1);
			local after = turtle.getFuelLevel();
			fuel.movesPerFuel = after - before;
		end
		fuel.refuel = function()
			if (turtle.getFuelLevel() > 0) then return; end
			fuel.initialize();
		end
		
		-- Inventory
		inventory.fuelSlot = 1;
		inventory.calcRemainingSlots = function() 
			local count = 0;
			for i = 2, 16 do
				if (turtle.getItemCount(i) == 0) then count = count + 1; end
			end
			return count;
		end
		inventory.needsUnload = function() return inventory.calcRemainingSlots() == 0; end
		inventory.unload = function()
			move.face(directions.backward);
			for i = 2, 16 do
				if (turtle.getItemCount(i) > 0) then
					turtle.select(i);
					if (not turtle.drop()) then
						error("Aborting: Can't unload inventory.");
					end
				end				
			end
			move.face(directions.forward);
		end
		
		-- Movement
		move.calcReturnDist = function() return math.abs(position.current.x) + math.abs(position.current.y) + math.abs(position.current.z) + 4; end
		move.face = function(direction)
			if (direction == directions.up or direction == directions.down or direction == position.current.d) then return; end
			if (direction == (position.current.d + 270) % 360) then 
				turtle.turnLeft();
				position.current.d = direction;
			else
				while (direction ~= position.current.d) do
					turtle.turnRight();
					position.current.d = (position.current.d + 90) % 360;
				end
			end
		end
		move.dig = function(direction)
			if (turtle.detectUp() and (not turtle.digUp()) and direction == directions.up) then return false; end
			if (turtle.detectDown() and (not turtle.digDown()) and direction == directions.down) then return false; end
			if (turtle.detect() and (not turtle.dig()) and direction ~= directions.up and direction ~= directions.down) then return false; end
			return true;
		end
		move.direction = function(direction)
			move.face(direction);
			if (not move.dig(direction)) then return false; end
			fuel.refuel();
						
			local method = turtle.forward;
			if (direction == directions.up) then method = turtle.up end
			if (direction == directions.down) then  method = turtle.down end
			
			while (not method()) do
				sleep(0.01);
				if (not move.dig(direction)) then return false; end
			end

			if (direction == directions.up) then position.current.z = position.current.z + 1; 
			elseif (direction == directions.down) then position.current.z = position.current.z - 1; 
			elseif (direction == directions.front) then position.current.y = position.current.y + 1; 
			elseif (direction == directions.back) then position.current.y = position.current.y - 1; 
			elseif (direction == directions.left) then position.current.x = position.current.x - 1; 
			elseif (direction == directions.right) then position.current.x = position.current.x + 1; end
			return true;
		end
		move.to = function(x, y, z)
			while (position.current.z < z) do if (not move.direction(directions.up)) then return false; end end
			while (position.current.z > z) do if (not move.direction(directions.down)) then return false; end end
			while (position.current.x < x) do if (not move.direction(directions.right)) then return false; end end
			while (position.current.x > x) do if (not move.direction(directions.left)) then return false; end end
			while (position.current.y < y) do if (not move.direction(directions.forward)) then return false; end end
			while (position.current.y > y) do if (not move.direction(directions.backward)) then return false; end end
			return true;
		end
		move.home = function(callback)
			position.mark();
			move.to(0, 0, 0);
			callback();
			move.face(directions.forward);
			move.to(position.marker.x, position.marker.y, position.marker.z);
		end
		move.finish = function()
			move.to(0, 0, 0);
			move.face(directions.backward);
			inventory.unload();
			turtle.select(1);
			turtle.drop();
		end
		move.excavate = function(x, y, z)
			position.reset();
			fuel.initialize();
			if (fuel.calcRemainingFuel() < 4) then
				error("Aborting: Insufficient fuel.");
			end
			
			local ystep = 1;
			if (y < 0) then ystep = -1; end
			local row = 0;
			
			local xstep = 1;
			if (x < 0) then xstep = -1; end
			local column = 0;
			
			local startz = math.min(2, math.abs(z));
			if (z < 0) then startz = -startz; end
			local zstep = startz / 2 * 3;
			
			for layer = startz, z, zstep do
				if (not move.to(position.current.x, position.current.y, layer)) then
					print("Returning: Reached unbreakable blocks");
					move.finish();
					return;
				end
				
				while (y > 0 and row <= y and row >= 0 or y < 0 and row <= 0 and row >= y) do
					while (x > 0 and column <= x and column >= 0 or x < 0 and column <= 0 and column >= x) do
						
						if (fuel.needsRefuel()) then
							print("Returning for refuel...");
							move.home(function() 
								print("Waiting for more fuel in slot 1.");
								turtle.refuel();
								while (not turtle.refuel(1)) do
									sleep(3);
									turtle.select(1);
								end
								fuel.initialize();
								print("Continuing");
							end);
						end
						
						if (inventory.needsUnload()) then
							print("Returning for unload...");
							move.home(function() 
								inventory.unload();
								print("Continuing");
							end);
						end
						
						if (not move.to(column, row, layer)) then
							print("Returning: Reached unbreakable blocks");
							return move.finish();
						end
						
						column = column + xstep;
					end
					if (x > 0 and column > x) then column = x; end
					if (x < 0 and column > 0) then column = 0; end
					if (x > 0 and column < 0) then column = 0; end
					if (x < 0 and column < x) then column = x; end
					xstep = -xstep;
					row = row + ystep;
				end
				if (y > 0 and row > y) then row = y; end
				if (y < 0 and row > 0) then row = 0; end
				if (y > 0 and row < 0) then row = 0; end
				if (y < 0 and row < y) then row = y; end
				ystep = -ystep;				
			end
			
			print("Returning: Mission complete");
			move.finish();
		end
	
		excavator.start = function(x, y, z)
			move.excavate(x, y, z);
		end
	end)();	
end