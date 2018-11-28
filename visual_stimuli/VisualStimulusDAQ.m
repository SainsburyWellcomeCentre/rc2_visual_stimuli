classdef VisualStimulusDAQ < handle
    
    properties (SetAccess = private)
        
        ai
        ctr
    end
    
    properties
        
        channels = [0, 1, 2]
        sample_rate = 20000
        save_every_n_samples = 10000
        file_to_write
        save_ai = true
    end
    
    properties (SetAccess = private, Hidden = true)
        
        fid
        ai_device = 'Dev1'
        counter_device = 'Dev2'
        counter_channel = 3
        ai_min_voltage = -10
        ai_max_voltage = 10
    end
    
    
    
    methods
        
        function obj = VisualStimulusDAQ()
            
            obj.setup_daq();
        end
        
        
        function delete(obj)
            
            delete(obj.ai);
            if obj.fid > 0
                fclose(obj.fid);
            end
        end
        
        
        function setup_daq(obj)
            
            % Required for the PXI for some reason: see
            % https://uk.mathworks.com/matlabcentral/answers/37134-data-acquisition-from-ni-pxie-1062q
            daq.reset %#ok<*PROP>
            daq.HardwareInfo.getInstance('DisableReferenceClockSynchronization', true);
            
            % Create analog input session.
            obj.ai = daq.createSession('ni');
            addAnalogInputChannel(obj.ai, obj.ai_device, obj.channels, 'Voltage');
            obj.ai.Rate = obj.sample_rate;
            obj.ai.IsContinuous = true;
            obj.ai.NotifyWhenDataAvailableExceeds = obj.save_every_n_samples;
            addlistener(obj.ai, 'DataAvailable', @(src, event)obj.log_data(src, event));
            
            % Setup hardware object
            obj.ctr = daq.createSession('ni');
            addCounterInputChannel(obj.ctr, obj.counter_device, obj.counter_channel, 'EdgeCount');
        end
        
        
        function delete_daq(obj)
            
            obj.ai.stop();
            delete(obj.ai);
            delete(obj.ctr);
        end
        
        
        function refresh_daq(obj)
            
            obj.delete_daq()
            obj.setup_daq()
        end
        
        
        function set_sample_rate(obj, val)
            
            obj.sample_rate = val;
            obj.ai.Rate = val;
        end
        
        
        function start(obj)
            
            if obj.save_ai
                obj.fid = fopen(obj.file_to_write, 'w');
                if obj.fid > 0
                    fprintf('AI is recording to %s...\n', obj.file_to_write);
                else
                    fprintf('Could not open file: %s\n', obj.file_to_write);
                end
            end
            
            obj.refresh_daq()
            obj.ai.startBackground();
        end
        
        
        function stop(obj)
            
            obj.ai.stop();
            obj.ctr.resetCounters();
            if obj.fid > 0
                fclose(obj.fid);
                obj.fid = [];
            end
        end
        
        
        function log_data(obj, ~, evt)
            
            if ~obj.save_ai; return
            end
            
            % Data is voltage between -10 and 10V
            % We will do 16-bit conversion - resolution 0.31mV
            data = evt.Data';
            data = int16(-2^15+((data-obj.ai_min_voltage)/(obj.ai_max_voltage-obj.ai_min_voltage))*2^16);
            
            fwrite(obj.fid, data(:), 'int16');
        end
    end
end