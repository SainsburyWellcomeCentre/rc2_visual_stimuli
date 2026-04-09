function config = get_setup_config(setup_name, verbose)
% GET_SETUP_CONFIG Load experimental setup configuration from JSON files
%
% Returns configuration for visual stimulus presentation including screen
% dimensions, pixel resolution, and viewing geometry (eye position and distance).
% Configuration files are stored as JSON in the screen/configs/ directory.
%
% Usage:
%   config = get_setup_config(setup_name)          % Silent mode
%   config = get_setup_config(setup_name, true)    % Verbose with console output
%   config = get_setup_config(setup_name, false)   % Explicitly silent
%   get_setup_config()                             % List available setups
%
% Input:
%   setup_name - String identifier for the setup (e.g., 'mp_300', 'wisecoco')
%   verbose    - (optional) Boolean. If true, prints configuration summary.
%                Default: true when called with single output, false otherwise
%
% Output:
%   config - Structure with fields:
%            .name      - Setup name
%            .w         - Screen width in mm
%            .h         - Screen height in mm
%            .w_pix     - Screen width in pixels
%            .h_pix     - Screen height in pixels
%            .d         - Eye distance from screen in mm
%            .centre_w  - Horizontal eye position in mm
%            .centre_h  - Vertical eye position in mm
%            .has_warp  - Boolean indicating if warp correction is available
%
% Adding new setups:
%   Create a new JSON file in screen/configs/ with the setup name (e.g., my_setup.json)
%   Use the existing files as templates for the required structure.

% Get the directory where this function is located
config_dir = fullfile(fileparts(mfilename('fullpath')), 'configs');

% List available setups if called with no arguments
if nargin == 0
    json_files = dir(fullfile(config_dir, '*.json'));
    
    if isempty(json_files)
        fprintf('No configuration files found in %s\n', config_dir);
        return
    end
    
    fprintf('Available experimental setups:\n');
    for i = 1 : length(json_files)
        [~, setup_name_str, ~] = fileparts(json_files(i).name);
        
        % Try to load and show description
        try
            cfg_file = fullfile(config_dir, json_files(i).name);
            cfg_data = jsondecode(fileread(cfg_file));
            if isfield(cfg_data, 'description')
                fprintf('  %d: %-15s - %s\n', i, setup_name_str, cfg_data.description);
            else
                fprintf('  %d: %s\n', i, setup_name_str);
            end
        catch
            fprintf('  %d: %s (error reading file)\n', i, setup_name_str);
        end
    end
    return
end

% Default verbose behavior: true if user expects printed output
if nargin < 2
    verbose = true;
end

% Find and load the configuration file
config_file = fullfile(config_dir, [setup_name '.json']);

if ~exist(config_file, 'file')
    error('Configuration file not found: %s\nRun get_setup_config() to see available setups.', config_file);
end

% Load and parse JSON configuration
try
    cfg_data = jsondecode(fileread(config_file));
catch ME
    error('Failed to parse configuration file %s: %s', config_file, ME.message);
end

% Build configuration structure with standardized field names
config.name = setup_name;
config.w = cfg_data.screen.width_mm;
config.h = cfg_data.screen.height_mm;
config.w_pix = cfg_data.screen.width_px;
config.h_pix = cfg_data.screen.height_px;
config.d = cfg_data.viewing_geometry.eye_distance_mm;
config.centre_w = cfg_data.viewing_geometry.eye_position_mm.horizontal;
config.centre_h = cfg_data.viewing_geometry.eye_position_mm.vertical;

% Check if warp correction parameters are available
config.has_warp = ~isempty(config.d) && config.d > 0;

% Print configuration summary if verbose mode is enabled
if verbose
    % Calculate visual coverage for display
    [x_angle, y_angle, angles] = calculate_viewing_angles(config);
    
    fprintf('\n');
    fprintf('╔════════════════════════════════════════════════════════════\n');
    fprintf('║  Experimental Setup: %-37s \n', config.name);
    fprintf('╠════════════════════════════════════════════════════════════\n');
    fprintf('║  Screen dimensions: %.1f × %.1f mm                   \n', config.w, config.h);
    fprintf('║  Screen resolution: %d × %d pixels                   \n', config.w_pix, config.h_pix);
    fprintf('║  Eye distance:      %.1f mm                          \n', config.d);
    fprintf('║  Eye position:      (%.1f, %.1f) mm                  \n', config.centre_w, config.centre_h);
    fprintf('║  Visual coverage:   %.1f° × %.1f°                    \n', angles.x_range_deg, angles.y_range_deg);
    
    if config.has_warp
        fprintf('║  Warp correction:   AVAILABLE                              \n');
    else
        fprintf('║  Warp correction:   NOT AVAILABLE                          \n');
    end
    
    fprintf('╚════════════════════════════════════════════════════════════\n');
    fprintf('\n');
end

end
