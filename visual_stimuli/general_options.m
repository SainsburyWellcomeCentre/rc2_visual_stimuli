function op = general_options(stim_type)
%%options = GENERAL_OPTIONS(stimulus_type)
%   function which returns options for running an experimental session.
%       INPUTS:     stimulus_type: 'sparse_noise', 'retinotopy', 'sf_tf'
%       OUTPUTS:    structure containing options


%% SAVING
% where to save information for each session (i.e. animal_id\date directory)
op.save_dir             = 'C:\data\ctsitou\CX_79_2'; % this will save in e.g. 'C:\data\CX_00_0\19700101'

% whether to save information at all
op.save_enabled         = true;

%% SCREEN
% the screen on which to present stimuli (psychtoolbox uses this)
op.screen_number        = 2;

% state whether to apply gamma correction and set path to a .mat file with
% a gamma table to apply
op.calibration_on       = true;
op.calibration_file     = 'C:\Users\Analysis-NN7570699\Documents\MATLAB\margrielab\visual_stimuli\gamma\gamma_correction.mat';


%% SCHEDULE FILE PATH
if strcmp(stim_type, 'sparse_noise')
    
    % location of the experimental plan for sparse noise
    op.schedule_file  = 'C:\data\ctsitou\CX_79_2\sparse_noise_schedule_20190218.mat';

elseif strcmp(stim_type, 'retinotopy')
    
    % location of the experimental plan for retinotopy
    op.schedule_file  = 'C:\data\ctsitou\CX_79_2\retinotopy_schedule_20190218.mat';

elseif strcmp(stim_type, 'sf_tf')
    
    % location of the experimental plan for SF/TF experiments
    op.schedule_file  = 'C:\data\ctsitou\CX_79_2\sf_tf_schedule_20190218.mat';
end
