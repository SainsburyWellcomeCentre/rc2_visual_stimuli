classdef ReadAI < handle
    
    properties
        
        fid
        data
        
        clock_channel = 1
        pd_channel = 2
        n_channels = 2
        sample_rate = 1000
    end
    
    
    methods
        
        function obj = ReadAI(filename)
            
            obj.fid = fopen(filename, 'r');
        end
        
        
        function load(obj)
            
            obj.data = fread(obj.fid, Inf, 'int16');
            obj.data = reshape(obj.data, obj.n_channels, [])';
        end
        
        
        function plot(obj)
            
            t = (0:size(obj.data, 1)-1)*(1/obj.sample_rate);
            figure();
            plot(t, -10 + 20*(double(obj.data)+2^15)/2^16)
            xlabel('Time (s)')
            ylabel('Voltage (V)')
            box off, axis square
        end
        
        function idx = find_ups(obj)
            
            fc = obj.data(:, 1);
            idx = diff(fc > 2) == 1;
        end
    end
end