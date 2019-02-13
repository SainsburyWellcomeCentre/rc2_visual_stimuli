function op = general_options(stim_type)
%%options = GENERAL_OPTIONS(stimulus_type)
%   function which returns options for running an experimental session.
%       INPUTS:     stimulus_type: 'sparse_noise', 'retinotopy', 'sf_tf'
%       OUTPUTS:    structure containing options


%% SAVING
% where to save information for each session (i.e. animal_id\date directory)
animal_id               = 'CX_00_0';
date_today              = '19700101';
data_directory          = 'C:\data';  % this will save in e.g. 'C:\data\CX_00_0\19700101'
op.save_dir             = fullfile(data_directory, animal_id, date_today);

% whether to save information at all
op.save_enabled         = true;

%% SCREEN
% the screen on which to present stimuli (psychtoolbox uses this)
op.screen_number        = 1;

% state whether to apply gamma correction and set path to a .mat file with
% a gamma table to apply
op.calibration_on       = true;
op.calibration_file     = 'C:\Users\Carol\Documents\Work\ctsitou\margrielab\visual_stimuli\gamma\gamma_correction.mat';


%% SCHEDULE FILE PATH
if strcmp(stim_type, 'sparse_noise')
    
    % location of the experimental plan for sparse noise
    op.schedule_path  = 'C:\Users\Carol\Documents\Work\ctsitou\margrielab\visual_stimuli\schedule\sparse_noise_schedule_20190205.mat';

elseif strcmp(stim_type, 'retinotopy')
    
    % location of the experimental plan for sparse noise
    op.schedule_path  = 'C:\Users\Carol\Documents\Work\ctsitou\margrielab\visual_stimuli\schedule\retinotopy_schedule_20190205.mat';

elseif strcmp(stim_type, 'sf_tf')
    
    % location of the experimental plan for SF/TF experiments
    op.schedule_path  = 'C:\Users\Carol\Documents\Work\ctsitou\margrielab\visual_stimuli\schedule\sf_tf_schedule_20190205.mat';
end
