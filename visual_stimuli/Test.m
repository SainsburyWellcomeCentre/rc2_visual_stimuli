classdef Test < StimulusAbstract
    
    properties
       
        n_repetitions = 20
    end
    
    
    properties (Hidden = true, SetAccess = private)
        
        controller
    end
    
    
    
    methods
        
        function obj = Testing(controller)
            
            obj.controller = controller;
        end

            
        function prepare(obj)
        end
        
        function to_save(obj)
        end
        
        function run(obj)
            
            do = daq.createSession('ni');
            addDigitalChannel(do, 'Dev2', 'Port0/Line0', 'OutputOnly')
            
            fprintf('Ready to start.\n')
            
            % Setup and ready to go
            if obj.controller.socket_enabled
                obj.controller.tcpip.send_ready();
            end

            triggerCount = 1;
            
            for repIdx = 1 : obj.n_repetitions-1
                while inputSingleScan(obj.controller.daq.ctr) < (triggerCount + 1)
                    do.outputSingleScan(mod(triggerCount, 2))
                end
                triggerCount = triggerCount + 1;
            end
        end
    end
end


