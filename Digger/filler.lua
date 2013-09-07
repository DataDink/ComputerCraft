if (filler == nil) then
	filler = {};
	
	(function() 
	
		local inventory = {};
		inventory.selectItem = function() 
			for i = 2, 16 do
				if (turtle.getItemCount(i) > 0) then
					turtle.select(i);
					return true;
				end
			end
			return false;
		end
		inventory.placeItem = function(placeDelegate) 
			if (not inventory.selectItem()) then
				print("Awaiting Inventory Refill");
				while (not inventory.selectItem()) do
					sleep(5);
				end
				print("Resuming in 15 seconds");
				sleep(15);
			end
			placeDelegate();
			turtle.place();
		end
		inventory.isFull = function()
			for i = 2, 16 do
				if (turtle.getItemSpace(i) > 0) then return false; end
			end
			return true;
		end
		
		local fuel = {};
		fuel.manage = function()
			if (turtle.getFuelLevel() > 0) then return true; end
			turtle.select(1);
			if (not turtle.refuel(1)) then
				print("Awaiting Refuel");
				while (not turtle.refuel(1)) do
					sleep(5);
					turtle.select(1);
				end
				print("Resuming");
			end
		end
		
		local movement = {};
		movement.fillRow = function(placeDelegate)
			repeat
				inventory.placeItem(placeDelegate);
				fuel.manage();
			until (not turtle.back());
		end
		movement.direction = true;
		movement.nextRow = function()
			local turn = turtle.turnLeft;
			if (movement.direction) then 
				turn = turtle.turnRight;
			end
			movement.direction = not movement.direction;
			turn();
			if (turtle.back()) then
				turn();
				return true;
			end
			turn();
			return false;
		end
		movement.fill = function(levelDelegate, placeDelegate)
			repeat
				repeat
					movement.fillRow(placeDelegate);
					fuel.manage();
				until (not movement.nextRow());
				turtle.turnLeft();
				fuel.manage();
			until (not levelDelegate());
		end
		movement.dig = function(move, dig)
			dig();
			local count = 0;
			while (not move()) do
				count = count + 1;
				if (count > 60) then return false; end
				sleep(.25);
				dig();
			end
			return true;
		end
		movement.eat = function()
			if (inventory.isFull()) then
				print("Inventory is full");
				return false;
			end
			
			if (turtle.getItemCount(2) == 0) then
				print("Place the type of block to eat in slot 2");
				return false;
			end

			for searchCount = 0, 10 do
				fuel.manage();
				turtle.select(2);
				if (turtle.compareUp()) then return movement.dig(turtle.up, turtle.digUp); end
				turtle.turnRight();
				if (turtle.compare()) then return movement.dig(turtle.forward, turtle.dig); end
				turtle.turnLeft();
				if (turtle.compare()) then return movement.dig(turtle.forward, turtle.dig); end
				turtle.turnLeft();
				if (turtle.compare()) then return movement.dig(turtle.forward, turtle.dig); end
				turtle.turnLeft();
				if (turtle.compare()) then return movement.dig(turtle.forward, turtle.dig); end
				if (turtle.compareDown()) then return movement.dig(turtle.down, turtle.digDown); end
				
				for turns = 1, 4 do
					turtle.turnLeft();
					if (not turtle.detect()) then
						movement.dig(turtle.forward, function() return true; end);
						break;
					end
				end
			end
			return false;
		end
		movement.unfill = function()
			while (movement.eat()) do
				sleep(.01);
			end
			print("Turtle is full, blocked, or completed.");
		end
		
		filler.fillUp = function()
			movement.fill(turtle.up, turtle.placeDown);
		end
		
		filler.fillDown = function()
			movement.fill(turtle.down, turtle.placeUp);
		end
		
		filler.unfill = function()
			movement.unfill();
		end
		
	end)();
end