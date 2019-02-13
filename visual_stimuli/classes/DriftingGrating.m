classdef DriftingGrating < Grating

    properties
        cycles_per_second
    end
    
    properties (Hidden = true, SetAccess = private)
        n
        start_phase
        shift_per_frame
    end
    
    
    
    methods
        
        function obj = DriftingGrating(ptb, setup)
            
            obj = obj@Grating(ptb, setup);
        end
        
        
        function initialize(obj)
            
            obj.n = 0;
            obj.start_phase = obj.phase;
            obj.shift_per_frame = 2*pi * obj.ptb.ifi * obj.cycles_per_second;
            
            initialize@Grating(obj);
        end
        
        
        function update(obj)
            obj.n = obj.n + 1;
            obj.phase = mod(obj.start_phase + obj.n * obj.shift_per_frame, 2*pi);
        end
    end
end
