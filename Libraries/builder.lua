if (builder == nil) then
	builder = {};
	
	local function round(number)
		if (number % 1 >= 0.5) then
			return math.ceil(number);
		else
			return math.floor(number);
		end
	end

	local calcPlot = function(angle, distance) 
		return {
			h = math.cos(math.rad(angle)) * distance,
			v = math.sin(math.rad(angle)) * distance
		};
	end
	
	local measure = function(x, y, z)
		if (x == nil) then x = 0; end
		if (y == nil) then y = 0; end
		if (z == nil) then z = 0; end
		return math.sqrt(x*x + y*y + z*z);
	end
	
	local extractNearestVector = function(vectors, vector)
		if (vectors == nill or vector == nil or vectors[1] == nil) then return nil; end
		local index = 0;
		local distance = nil;
		
		for i, compare in ipairs(vectors) do
			local dist = measure(compare.x - vector.x, compare.y - vector.y, compare.z - vector.z);
			if (distance == nil or dist < distance) then
				distance = dist;
				index = i;
			end
		end
		
		return table.remove(vectors, index);
	end
	
	local groupBy = function(objects, indexer)
		local results = {};
		local indexed = {};
		
		for i, object in ipairs(objects) do
			local key = indexer(object);
			if (indexed[key] == nil) then indexed[key] = {}; end
			table.insert(indexed[key], object);
		end
		
		local indexes = {};
		for key in pairs(indexed) do
			table.insert(indexes, key);
		end
		table.sort(indexes);
		
		for i, key in ipairs(indexes) do
			table.insert(results, indexed[key]);
		end
		return results;
	end
	
	local sortVectors = function(vectors)
		local results = {};
		
		local layers = groupBy(vectors, function(v) return v.z; end);
		for il, layer in ipairs(layers) do
			local plots = {};
			local rows = groupBy(layer, function(v) return v.y; end);
			for ir, row in ipairs(rows) do
				local columns = groupBy(row, function(v) return v.x; end);
				for ic, column in ipairs(columns) do
					table.insert(plots, column[1]);
				end
			end
			if (plots[1] ~= nil) then
				local plot = table.remove(plots, 1);
				table.insert(results, plot);
				
				while (plots[1] ~= nil) do
					plot = extractNearestVector(plots, plot);
					table.insert(results, plot);
				end
			end
		end
			
		return results;
	end
	
	local rotateVector = function(vector, xaxis, yaxis, zaxis)
		if (xaxis == nil) then xaxis = 0; end
		if (yaxis == nil) then yaxis = 0; end
		if (zaxis == nil) then zaxis = 0; end
		
		if (xaxis == 0 and yaxis == 0 and zaxis == 0) then return; end

		local xcos = math.cos(math.rad(xaxis));
		local xsin = math.sin(math.rad(xaxis));
		local xz = xcos * vector.z - xsin * vector.y;
		local xy = xsin * vector.z + xcos * vector.y;
		vector.z = xz;
		vector.y = xy;
		
		local ycos = math.cos(math.rad(yaxis));
		local ysin = math.sin(math.rad(yaxis));
		local yx = ycos * vector.x - ysin * vector.z;
		local yz = ysin * vector.x + ycos * vector.z;
		vector.x = yx;
		vector.z = yz;
		
		local zcos = math.cos(math.rad(zaxis));
		local zsin = math.sin(math.rad(zaxis));
		local zx = zcos * vector.x - zsin * vector.y;
		local zy = zsin * vector.x + zcos * vector.y;
		vector.x = zx;
		vector.y = zy;
	end
	
	local scaleVector = function(vector, xscale, yscale, zscale)
		if (xscale == nil) then xscale = 1; end
		if (yscale == nil) then yscale = 1; end
		if (zscale == nil) then zscale = 1; end
		if (xscale == 1 and yscale == 1 and zscale == 1) then return; end
		vector.x = vector.x * xscale;
		vector.y = vector.y * yscale;
		vector.z = vector.z * zscale;
	end
	
	local roundVector = function(vector)
		vector.x = round(vector.x);
		vector.y = round(vector.y);
		vector.z = round(vector.z);
	end
	
	local ajustVectors = function(vectors, xscale, yscale, zscale, xaxis, yaxis, zaxis)
		for i, vector in ipairs(vectors) do
			scaleVector(vector, xscale, yscale, zscale);
			rotateVector(vector, xaxis, yaxis, zaxis);
			roundVector(vector);
		end
		return sortVectors(vectors);
	end
	
	builder.circle = function(radius, xscale, yscale, xaxis, yaxis, zaxis)
		local plots = {};
		local step = 45 / radius;
		if (angleX == nil) then angleX = 0; end
		if (angleZ == nil) then angleZ = 0; end
		for angle = 0, 360, step do
			local plot = calcPlot(angle, radius);
			table.insert(plots, {x = plot.h, y = plot.h, z = 0});
		end
		return ajustVectors(plots, xscale, yscale, nil, xaxis, yaxis, zaxis);
	end
	
	builder.sphere = function(radius, xscale, yscale, zscale, xaxis, yaxis, zaxis)
		local plots = {};
		local step = 45 / radius;
		
		for z = 0, 180, step do
			local zplot = calcPlot(z, radius);
			local xradius = zplot.v;
			for x = 0, 360, step do
				local xplot = calcPlot(x, xradius);
				table.insert(plots, { x = zplot.h, y = xplot.h, z = xplot.v });
			end
		end
		return ajustVectors(plots, xscale, yscale, zscale, xaxis, yaxis, zaxis);
	end
	
	builder.square = function(radius, xscale, yscale, xaxis, yaxis, zaxis)
		local plots = {};
		for v = -radius, radius do
			table.insert(plots, {x = v, y = -radius, z = 0});
			table.insert(plots, {x = v, y = radius, z = 0});
			table.insert(plots, {x = -radius, y = v, z = 0});
			table.insert(plots, {x = radius, y = v, z = 0});
		end
		return ajustVectors(plots, xscale, yscale, nil, xaxis, yaxis, zaxis);
	end
	
	builder.cube = function(radius, xscale, yscale, zscale, xaxis, yaxis, zaxis)
		local plots = {};
		for h = -radius, radius, 0.5 do
			for v = -radius, radius, 0.5 do
				table.insert(plots, {x = h, y = v, z = -radius});
				table.insert(plots, {x = h, y = v, z = radius});
				table.insert(plots, {x = h, y = -radius, z = v});
				table.insert(plots, {x = h, y = radius, z = v});
				table.insert(plots, {x = -radius, y = h, z = v});
				table.insert(plots, {x = radius, y = h, z = v});
			end
		end
		return ajustVectors(plots, xscale, yscale, zscale, xaxis, yaxis, zaxis);
	end
	
	builder.cone = function(radius, xscale, yscale, zscale, xaxis, yaxis, zaxis)
		local plots = {};
		for r = 1, radius, 0.5 do
			for a = 0, 360, (45 / r) do
				local plot = calcPlot(a, r);
				table.insert(plots, {x = plot.h, y = plot.v, z = r - radius / 2});
			end
		end
		return ajustVectors(plots, xscale, yscale, zscale, xaxis, yaxis, zaxis);
	end
	
	builder.polygon = function(radius, sides, xscale, yscale, xaxis, yaxis, zaxis)
		if (sides < 3) then return nil; end
		local plots = {};
		local step = 360 / sides;
		-- NYI
	end
		
	builder.findInventory = function()
		for i = 2, 16 do
			if (turtle.getItemCount(i) > 0) then
				return i;
			end
		end
		return nil;
	end
	
	builder.placeDown = function()
		if (builder.findInventory() == nil) then
			print("Waiting for inventory");
			while (builder.findInventory() == nil) do
				sleep(1);
			end
			print("Continuing in 15 seconds");
			sleep(15);
		end
		turtle.select(builder.findInventory());
		turtle.placeDown();
	end
end

