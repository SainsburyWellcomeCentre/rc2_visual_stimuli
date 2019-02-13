classdef Sequence < handle
    
    properties
        period = {}
    end
    
    properties (Dependent = true)
        n_periods
    end
    
    methods
        
        function obj = Sequence()
        end
        
        
        function val = get.n_periods(obj)
            val = length(obj.period);
        end
        
        
        function add_period(obj, stim)
            obj.period{end+1} = stim;
        end
        
        
        function initialize(obj)
            for i = 1 : obj.n_periods
                obj.period{i}.initialize();
            end
        end
    end
end