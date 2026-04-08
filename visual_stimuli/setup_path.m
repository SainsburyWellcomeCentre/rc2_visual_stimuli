% SETUP_PATH - Add visual_stimuli subfolders to MATLAB path
%
% Run this script once at the start of your MATLAB session to add
% all necessary visual_stimuli folders to the MATLAB path.
%
% USAGE:
%   cd('path/to/visual_stimuli/visual_stimuli')
%   setup_path

% Get the directory containing this script
script_dir = fileparts(mfilename('fullpath'));

% Add key subdirectories to path
addpath(fullfile(script_dir, 'classes'));
addpath(fullfile(script_dir, 'daq'));
addpath(fullfile(script_dir, 'aux_'));
addpath(fullfile(script_dir, 'gamma'));
addpath(fullfile(script_dir, 'screen'));
addpath(fullfile(script_dir, 'warp'));

fprintf('Added visual_stimuli folders to MATLAB path:\n');
fprintf('  - classes/\n');
fprintf('  - daq/\n');
fprintf('  - aux_/\n');
fprintf('  - gamma/\n');
fprintf('  - screen/\n');
fprintf('  - warp/\n');
fprintf('\nPath setup complete!\n');

% Optionally save path for future sessions
% Uncomment the line below to permanently save these folders to your MATLAB path
% savepath;
