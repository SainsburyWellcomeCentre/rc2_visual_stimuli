classdef Blank_bino < handle
    
    properties (SetAccess = private)
        setup
        position
    end
    
    properties
        location = 'top_left'
        colour = 0;
        warp_style = 'Oval';
        size = 500;
    end
    
    methods
        
        function obj = Blank_bino(setup)
            obj.setup = setup;
        end
        
        
        
        function val = get.position(obj)
            switch obj.location
                case 'top_left'
                    if obj.setup.ptb.warp_on
                        % the PD 
                        val = [70, 150, 170, 250];
                    else
                        leftPos = 0;
                        topPos = 0;
                        botPos = obj.setup.screen_pixels(2);
                        val = [leftPos, topPos, leftPos + obj.size, botPos];
                    end
%                 case 'bottom_left'
%                     val = [0, 950, 100, 1050];
%                 case 'bottom_right'
%                     val = [1580, 950, 1680, 1050];
%                 case 'top_right'
%                     val = [1580, 0, 1680, 100];
                case 'top_right'
                    if obj.setup.ptb.warp_on
                        val = [1016, 320;
                               921, 248;
                               1023, 340;
                               1110, 403;
                               1016, 320];
                    else

                        leftPos = obj.setup.screen_pixels(1) - obj.size;
                        topPos = 0;
                        botPos = obj.setup.screen_pixels(2);
                        val = [leftPos, topPos, leftPos + obj.size, botPos];
                
                    end
            end
        end
        
  
        
        function buffer(obj)
            if obj.setup.ptb.warp_on
                if strcmp(obj.warp_style, 'Oval')
                    Screen('FillOval', obj.setup.window, obj.colour, obj.position);
                elseif strcmp(obj.warp_style, 'Polygon')
                    Screen('FillPoly', obj.setup.window, obj.colour, obj.position);
                end
            else
                Screen('FillRect', obj.setup.window, obj.colour, obj.position);
            end
        end
    end
end
