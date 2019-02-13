classdef Grating < handle
    
    properties (SetAccess = private)
        ptb
        setup
    end
    
    properties
        waveform = 'sine'
        cycles_per_degree
        orientation
        phase
    end
    
    properties (SetAccess = private, Hidden = true, Dependent = true)
        src_rect
    end
    
    properties (SetAccess = private, Hidden = true)
        dst_rect
        noise_texture
        grating_texture
    end
    
    
    
    methods
        
        function obj = Grating(ptb, setup)
            
            obj.ptb = ptb;
            obj.setup = setup;
            obj.dst_rect = CenterRect([0, 0, obj.setup.diagonal, obj.setup.diagonal], [0, 0, obj.setup.screen_pixels]);
        end
        
        
        function initialize(obj)
            mm_per_cycle = obj.setup.degrees_to_mm(1/obj.cycles_per_degree);
            cycles_per_pixel = obj.setup.mm_per_pixel(1) * (1/mm_per_cycle);
            pixels_per_cycle = (1/cycles_per_pixel);
            x = -obj.setup.diagonal/2 : obj.setup.diagonal/2 + pixels_per_cycle;
            grating = 0.5 * cos(2 * pi * cycles_per_pixel * x) + 0.5;
            if strcmp(obj.waveform, 'square')
                grating = round(grating);
            end
            obj.grating_texture = Screen('MakeTexture', obj.ptb.window, grating);
        end
        
        
        function val = get.src_rect(obj)
            mm_per_cycle = obj.setup.degrees_to_mm(1/obj.cycles_per_degree);
            pixels_per_cycle = mm_per_cycle / obj.setup.mm_per_pixel(1);
            xoffset = round(pixels_per_cycle * obj.phase / (2 * pi));
            val =[xoffset, 0, xoffset + obj.setup.diagonal, obj.setup.diagonal];
        end
        
        
        function buffer(obj)
            Screen('DrawTexture', obj.ptb.window, obj.grating_texture, obj.src_rect, obj.dst_rect, obj.orientation);
        end
        
        
        function update(~)
        end
    end
end