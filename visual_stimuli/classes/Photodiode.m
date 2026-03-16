classdef Photodiode < handle
    
    properties (SetAccess = private)
        setup
        position
    end
    
    properties
        location = 'top_left'
        colour = 0;
        warp_style = 'Oval';
        size = 200/1.33;
    end
    
    methods
        
        function obj = Photodiode(setup)
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
                        val = [leftPos, topPos, leftPos + obj.size, topPos + obj.size];
                    end
                case 'bottom_left'
                    if obj.setup.ptb.warp_on
                        % Adjust these coordinates to position photodiode correctly
                        % after warping. Start with pre-warp bottom-left area.
                        leftPos = -80; 
                        bottomPos = obj.setup.screen_pixels(2) - 25; % start at bottom
                        sqSize = 100; % 100x100 pixel square
                        val = [leftPos, bottomPos - sqSize, leftPos + sqSize, bottomPos];
                    else
                        leftPos = 0;
                        bottomPos = obj.setup.screen_pixels(2);
                        sqSize = 100;
                        val = [leftPos, bottomPos - sqSize, leftPos + sqSize, bottomPos];
                    end
%                 case 'bottom_right'
%                     val = [1580, 950, 1680, 1050];
%                 case 'top_right'
%                     val = [1580, 0, 1680, 100];
                case 'top_right'
                    if obj.setup.ptb.warp_on
%                         val = [1016, 320;
%                                921, 248;
%                                1023, 340;
%                                1110, 403;
%                                1016, 320];
                         val = [938, 131;
                                933, 76;
                                954, 80;
                                959, 129;
                                938, 131];
                    else
                        leftPos = obj.setup.screen_pixels(1) - obj.size;
                        topPos = 0;
                        val = [leftPos, topPos, leftPos + obj.size, topPos + obj.size];
                    end
                case 'right_goggle_top_right'
                    % Settings to draw a rotated rectangle exactly
                    % underneath the mouse goggles photo diode
                    screen_radius = 200; % px
                    top_right = screen_radius/sqrt(2) * [1 -1] + [200 200];
                    photodiode_mm = [4 2.5];
                    mm_to_px = 400/37;
                    photodiode_px = photodiode_mm * mm_to_px;
                    theta = pi/4; % 45 deg
                    rot_mat = [
                        [cos(theta) -sin(theta)];
                        [sin(theta) cos(theta)];
                        ];
                    center_to_edge_vectors = [
                        [ -photodiode_px(1) -photodiode_px(2)];
                        [  photodiode_px(1) -photodiode_px(2)];
                        [  photodiode_px(1)  photodiode_px(2)];
                        [ -photodiode_px(1)  photodiode_px(2)];
                        ]/2;
                    center_to_edge_rotated = rot_mat * center_to_edge_vectors';

                    photodiode_polygon = top_right + center_to_edge_rotated';
                    val = photodiode_polygon;
            end
        end
        
        
        
        function buffer(obj)
            if strcmp(obj.location, 'right_goggle_top_right')
                % activate right eye window for drawing
                obj.setup.ptb.choose_eye(obj.setup.screen_number, 1);
                % draw the photdiode polygon
                Screen('FillPoly',obj.setup.window, obj.colour, obj.position);
            else
                % Use FillRect for all cases to avoid warp transformation
                Screen('FillRect', obj.setup.window, obj.colour, obj.position);
            end
        end
    end
end
