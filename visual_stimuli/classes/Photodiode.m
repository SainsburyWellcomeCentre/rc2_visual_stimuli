classdef Photodiode < handle
    
    properties (SetAccess = private)
        ptb
        position
    end
    
    properties
        location = 'top_left'
        colour = 0;
        warp_style = 'Oval'
    end
    
    methods
        
        function obj = Photodiode(ptb)
            obj.ptb = ptb;
        end
        
        
        
        function val = get.position(obj)
            switch obj.location
                case 'top_left'
                    if obj.ptb.warp_on
                        % the PD 
                        val = [70, 150, 170, 250];
                    else
                        val = [0, 0, 100, 100];
                    end
%                 case 'bottom_left'
%                     val = [0, 950, 100, 1050];
%                 case 'bottom_right'
%                     val = [1580, 950, 1680, 1050];
%                 case 'top_right'
%                     val = [1580, 0, 1680, 100];
                case 'top_right'
                    if obj.ptb.warp_on
                        val = [1016, 320;
                               921, 248;
                               1023, 340;
                               1110, 403;
                               1016, 320];
                    else
                        val = [980, 0, 1280, 300];
                    end
            end
        end
        
        
        
        function buffer(obj)
            if obj.ptb.warp_on
                if strcmp(obj.warp_style, 'Oval')
                    Screen('FillOval', obj.ptb.window, obj.colour, obj.position);
                elseif strcmp(obj.warp_style, 'Poly')
                    Screen('FillPoly', obj.ptb.window, obj.colour, obj.position);
                end
            else
                Screen('FillRect', obj.ptb.window, obj.colour, obj.position);
            end
        end
    end
end
