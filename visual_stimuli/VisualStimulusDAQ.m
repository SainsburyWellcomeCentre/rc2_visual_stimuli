classdef VisualStimulusDAQ < handle
    
    properties (SetAccess = private)
        
        ai
        ctr
    end
    
    properties
        
        channels = [0, 1]
        channel_description = {'frame_clock', 'photodiode'}
        sample_rate = 20000
        save_every_n_samples = 10000
        save_directory
        save_ai = true
    end
    
    properties (Dependent = true)
        
        ai_file
        metadata_file
    end
    
    properties (SetAccess = private, Hidden = true)
        
        fid
        ai_device = 'Dev1'
        counter_device = 'Dev1'
        samples_written = 0;
        counter_channel = 0
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
        
        
        function val = get.ai_file(obj)
            
            val = fullfile(obj.save_directory, 'AI.bin');
        end
        
        
        function val = get.metadata_file(obj)
            
            val = fullfile(obj.save_directory, 'AI_info.mat');
        end
        
        
        function refresh_daq(obj)
            
            obj.samples_written = 0;
            obj.delete_daq()
            obj.setup_daq()
        end
        
        
        function set_sample_rate(obj, val)
            
            obj.sample_rate = val;
            obj.ai.Rate = val;
        end
        
        
        function start(obj)
            
            if obj.save_ai
                assert(length(obj.channels) == length(obj.channel_description), ...
                    'number of channels not equal to length of channel description')
                obj.fid = fopen(obj.ai_file, 'w');
                if obj.fid > 0
                    fprintf('AI is recording to %s...\n', obj.ai_file);
                else
                    fprintf('Could not open file: %s\n', obj.ai_file);
                end
                obj.save_metadata();
            end
            
            obj.refresh_daq()
            obj.ai.startBackground();
        end
        
        
        function save_metadata(obj)
            
            ai.n_channels = length(obj.channels);
            ai.n_samples = NaN;
            ai.channel_description = obj.channel_description;
            ai.sample_rate = obj.sample_rate;
            ai.ai_device = obj.ai_device;
            ai.ai_channels = obj.channels;
            ai.counter_device = obj.counter_device;
            ai.counter_channel = obj.counter_channel; %#ok<STRNU>
            save(obj.metadata_file, 'ai');
        end
        
        
        function stop(obj)
            
            obj.ai.stop();
            obj.ctr.resetCounters();
            if obj.fid > 0
                fclose(obj.fid);
                obj.fid = [];
            end
            if obj.save_ai
                load(obj.metadata_file, 'ai');
                ai.n_samples = obj.samples_written; %#ok<STRNU>
                save(obj.metadata_file, 'ai');
            end
        end
        
        
        function log_data(obj, ~, evt)
            
            if ~obj.save_ai; return
            end
            
            % Data is voltage between -10 and 10V
            % We will do 16-bit conversion - resolution 0.31mV
            data = evt.Data';
            data = int16(-2^15+((data-obj.ai_min_voltage)/(obj.ai_max_voltage-obj.ai_min_voltage))*2^16);
            
            obj.samples_written = obj.samples_written + obj.save_every_n_samples;
            
            fwrite(obj.fid, data(:), 'int16');
        end
    end
end