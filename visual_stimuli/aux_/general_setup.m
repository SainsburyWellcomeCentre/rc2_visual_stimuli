function [ptb, setup, schedule] = general_setup(options)
%%[psychtoolbox, setup, schedule] = GENERAL_SETUP(options)
%    internal function used to setup the presentation environment

% Interface to psychtoolbox
ptb                     = PsychoToolbox();
ptb.calibration_on      = options.calibration_on;

% Load the gamma calibration file.
if ptb.calibration_on
    load(options.calibration_file, 'gamma_table');
    ptb.gamma_table 	= gamma_table;
end

% Information about the setup.
setup                   = SetupInfo(ptb);
setup.set_screen_number(options.screen_number);

% Load the pre-compiled schedule information
load(options.schedule_path, 'schedule')