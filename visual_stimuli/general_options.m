function op = general_options(stim_type)
%%options = GENERAL_OPTIONS(stimulus_type)
%   function which returns options for running an experimental session.
%       INPUTS:     stimulus_type: 'sparse_noise', 'retinotopy', 'sf_tf'
%       OUTPUTS:    structure containing options


%% GENERAL
% location of the git directory
op.git_dir              = fullfile(pwd, '.git');


%% SAVING
% where to save information for each session (i.e. animal_id\date directory)
op.save_dir             = 'C:\data\ctsitou\BY_317_2_hemisphere_left_monitor_left'; % this will save in e.g. 'C:\data\CX_00_0\19700101'

% whether to save information at all
op.save_enabled         = true;

%% SCREEN
% the screen on which to present stimuli (psychtoolbox uses this)
op.screen_name          = 'samsung_cfg73';
op.screen_number        = 2;

% state whether to apply gamma correction and set path to a .mat file with
% a gamma table to apply
op.calibration_on       = true;
op.calibration_file     = 'C:\Users\Analysis-NN7570699\Documents\MATLAB\margrielab\visual_stimuli\gamma\gamma_correction.mat';

% whether to apply warp and mat file for warping parameters
op.warp_on              = false;
op.warp_file            = 'C:\Users\Analysis-NN7570699\Documents\MATLAB\margrielab\visual_stimuli\warp\warp_samsung_cfg73.mat';


%% SCHEDULE FILE PATH
if strcmp(stim_type, 'sparse_noise')
    
    % location of the experimental plan for sparse noise
    op.schedule_file  = 'C:\data\ctsitou\BY_317_2_hemisphere_right_monitor_left\sparse_noise_schedule_20200129.mat';

elseif strcmp(stim_type, 'sparse_noise_allen')
    
    op.schedule_file = '';
    
elseif strcmp(stim_type, 'retinotopy')
    
    % location of the experimental plan for retinotopy
    op.schedule_file  = 'C:\data\ctsitou\BY_317_2_hemisphere_left_monitor_left\retinotopy_schedule_20200129.mat';

elseif strcmp(stim_type, 'sf_tf')
    
    % location of the experimental plan for SF/TF experiments
    op.schedule_file  = 'C:\data\ctsitou\BY_317_2_hemisphere_right_monitor_left\sf_tf_schedule_20200129.mat';%'C:\data\ctsitou\CX_79_4\sf_tf_schedule_20190306.mat';
end
