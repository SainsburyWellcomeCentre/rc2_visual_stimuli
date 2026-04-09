classdef Grid < handle
    
    properties (SetAccess = private)
        shape
        bounds
    end
    
    properties (SetAccess = private, Dependent = true)
        square_size
    end
    
    
    
    methods
        
        function obj = Grid(shape, bounds)
            obj.shape = shape;  %[x, y]
            obj.bounds = bounds;  %[left, top, right, bottom]
        end
        
        
        function val = get.square_size(obj)
            val = (obj.bounds([3, 4])-obj.bounds([1, 2])) ./ obj.shape;
        end
        
        
        function center = get_center(obj, idx)
            [sub(2), sub(1)] = ind2sub(obj.shape([2, 1]), idx);
            center = obj.square_size/2 + (sub - 1) .* obj.square_size;
        end
        
        
        function position = get_position(obj, idx)
            center = obj.get_center(idx);
            base_rect = [0, 0, obj.square_size];
            position = CenterRectOnPointd(base_rect, center(1), center(2));
        end
    end
end
