classdef VisualStimulusController < handle
    %% VisualStimulusController()
    %       this is the main object which controls which visual
    %       stimuli are run, and some general configuration parameters.
    %   Properties:
    %       n_triggers:     read-only property giving the total number of
    %                       triggers this script will expect to receive
    %       stimulus:       object containing the visual stimulus to
    %                       present. can be set using the .set_stimulus(option) 
    %                       method where options are: 'drifting_gratings',
    %                       'retinotopy', 'flash', or 'sparse_noise'.
    %       save_enabled:   true (default) or false. whether or not to save
    %                       stimulus_info.mat, AI.bin and AI_info.mat files
    %                       containing information about the stimulus, and
    %                       the analog input data.
    %       distance_from_screen:   in mm
    %       screen_number:  which screen to present the stimulus on
    %       screen_size:    size in [X, Y], in mm, of the screen
    %       screen_pixels:  size in [X, Y], in pixels, of the screen
    %       base_directory: main directory where current controller will setup
    %                       subdirectories in which data and info files
    %                       will be saved
    %       save_directory: subdirectory where the next run of the visual
    %                       stimulus (using v.start()) will save data and
    %                       info files
    %       filename:       full path to where stimulus_info.mat will be
    %                       saved
    %   Methods (see 'help VisualStimulusController.<method>' for help):
    %       set_stimulus
    %       set_directory
    %       start
    
    
    properties (Dependent = true)
        n_triggers
    end
    
    properties (SetAccess = private)
        stimulus
    end
    
    properties (Hidden = true)
        socket_enabled = false
    end
    
    properties
        save_enabled = true
        distance_from_screen = 200  % mm
        screen_number
        screen_size
    end
    
    properties (SetAccess = private)
        screen_pixels
        base_directory
        save_directory
    end
    
    properties (Dependent = true)
        filename
    end
    
    properties (Hidden = true)
        daq
    end
    
    properties (Hidden = true, SetAccess = private)
        tcpip
        screens
    end
    
    
    
    methods
        
        function obj = VisualStimulusController()
            
            obj.tcpip = StimulusTCPIP(25001, 25000);
            obj.stimulus = DriftingGratings(obj);
            
            obj.screens = Screen('Screens');
            obj.screen_number = max(obj.screens);
            [obj.screen_pixels(1), obj.screen_pixels(2)] = Screen('WindowSize', obj.screen_number);
            % https://www.dell.com/ed/business/p/dell-u2415/pd
            obj.screen_size = [518.4, 324.0]; % [473.8, 296.1];  % mm, [X, Y]
            
            obj.daq = VisualStimulusDAQ();
            
            % prompt user for directory in which to save
            obj.base_directory = uigetdir('\\Nn7908796\d', 'Choose data path...');
            if obj.base_directory == 0
                obj.base_directory = 'C:\data';
            end
        end
        
        
        function delete(obj)
            
            delete(obj.daq)
        end
        
        
        function val = get.filename(obj)
            
            val = fullfile(obj.save_directory, 'stimulus_info.mat');
        end
        
        
        function set_directory(obj, namestr)
            
            obj.save_directory = fullfile(obj.base_directory, namestr);
            mkdir(obj.save_directory);
        end
        
        
        function val = get.n_triggers(obj)
            
            val = obj.stimulus.total_n_triggers;
        end
        
        
        function set_stimulus(obj, type)
            %% SET_STIMULUS(type)
            %       set the visual stimulus to be presented to one of:
            %       type: 'drifting_gratings', 'retinotopy', 'flash',
            %       'sparse_noise'
            
            if strcmp(type, 'drifting_gratings')
                obj.stimulus = DriftingGratings(obj);
            elseif strcmp(type, 'retinotopy')
                obj.stimulus = Retinotopy(obj);
            elseif strcmp(type, 'testing')
                obj.stimulus = Testing(obj);
            elseif strcmp(type, 'flash')
                obj.stimulus = Flash(obj);
            elseif strcmp(type, 'sparse_noise')
                obj.stimulus = SparseNoise(obj);
            end
        end
        
        
        function save(obj)
            
            stimulus.type = class(obj.stimulus); %#ok<*PROP>
            stimulus.stimulus = obj.stimulus.to_save();
            stimulus.distance_from_screen = obj.distance_from_screen;
            stimulus.n_triggers = obj.n_triggers;
            stimulus.screens = obj.screens;
            stimulus.screen_number = obj.screen_number;
            stimulus.screen_size = obj.screen_size;
            stimulus.daq.ai.device = obj.daq.ai_device;
            stimulus.daq.ai.channels = obj.daq.channels;
            stimulus.daq.ai.sample_rate = obj.daq.sample_rate;
            stimulus.daq.ai.save_every_n_samples = obj.daq.save_every_n_samples;
            stimulus.daq.ai.save_directory = obj.daq.save_directory;
            stimulus.daq.ctr.device = obj.daq.counter_device;
            stimulus.daq.ctr.channels = obj.daq.counter_channel;
            stimulus.daq.ai_min_voltage = obj.daq.ai_min_voltage;
            stimulus.daq.ai_max_voltage = obj.daq.ai_max_voltage; %#ok<STRNU>
            
            save(obj.filename, 'stimulus');
        end
        
        
        function start(obj)
            %% START()
            %       starts the visual stimulus running, expecting an
            %       incoming trigger.
            
            if obj.socket_enabled
                obj.tcpip.open_connection(); pause(1)
                if obj.save_enabled
                    obj.filename = obj.tcpip.receive_message();
                    if isempty(obj.filename)
                        [~, new_dir] = fileparts(tempname);
                        mkdir(tempdir, new_dir);
                        obj.filename = fullfile(tempdir, new_dir);
                    end
                else
                    [~, new_dir] = fileparts(tempname);
                    mkdir(tempdir, new_dir);
                    obj.filename = fullfile(tempdir, new_dir);
                end
            end
            
            obj.daq.save_directory = obj.save_directory;
            
            % Must prepare the stimulus before saving the stimulus
            % information (as there are random numbers to generate).
            obj.stimulus.prepare();
            
            obj.daq.save_ai = obj.save_enabled;
            if obj.save_enabled
                if exist(obj.filename, 'file') == 2
                    error('%s already exists.', obj.filename);
                end
                obj.save()
            end
            obj.daq.start()
            
            try    
                obj.stimulus.run();
                obj.stop();
            catch
                if obj.socket_enabled
                    obj.tcpip.send_ready()
                end
                obj.stop();
            end
        end
        
        
        function stop(obj)
            
            if obj.socket_enabled
                obj.tcpip.close_connection();
            end
            
            pause(1)
            obj.daq.stop()
        end
    end
end