% PLAY_VIDEO_GOGGLES - Video playback on mouse goggles with frame tracking
%
% DESCRIPTION:
%   This script plays back an MP4 video file on the wisecoco mouse goggles
%   (screen 2) using Psychtoolbox's hardware-accelerated video playback.
%   The video is displayed on the LEFT EYE ONLY while the right eye shows
%   a grey background. A photodiode box is displayed in the top-right corner
%   of the right goggle and toggles at a configurable rate for synchronization.
%
% VIDEO PLAYBACK:
%   - Uses Screen('OpenMovie') and Screen('GetMovieImage') for low-latency playback
%   - Automatically handles frame rate mismatches (e.g., 90 Hz video on 60 Hz display)
%   - Psychtoolbox skips video frames as needed to maintain temporal synchronization
%   - Each displayed frame is logged with its video timestamp (PTS) for later analysis
%
% STEREO DISPLAY:
%   - Left eye (goggle):  Video content
%   - Right eye (goggle): Grey background with photodiode box
%   - Both goggles are rotated 90° and 270° respectively
%
% PHOTODIODE SYNCHRONIZATION:
%   - Photodiode box toggles between white and black every N frames (configurable)
%
% NI-DAQ SYNCHRONIZATION:
%   The script uses dual DAQ acquisition:
%   
%   1. Digital Input (port0/line0): Trigger detection only
%      - On-demand polling for experiment start signal
%      - Optional: set wait_for_start_trigger = true to wait for HIGH->LOW
%   
%   2. Analog Inputs (AI1, AI5, AI6): Continuous recording at 10 kHz
%      - AI1: Master clock signal (0-5V digital)
%      - AI5: Eye camera 0 trigger (0-5V digital)
%      - AI6: Eye camera 1 trigger (0-5V digital)
%      - Hardware-timed acquisition with minimal CPU overhead
%      - Data saved to AI_YYYYMMDD_HHMMSS.bin in same directory
%   
%   Why analog inputs for digital signals?
%   - USB DAQ digital I/O doesn't support hardware timing
%   - Analog inputs can sample 0-5V signals with precise 10 kHz timing
%   - Use read_ai_data.m to load and threshold data for event reconstruction
%
% FRAME TRACKING:
%   For each displayed frame, the script logs:
%   - display_frame: Sequential frame number (1, 2, 3, ...)
%   - video_pts:     Video Presentation Time Stamp in seconds (from MP4)
%   - display_time:  When frame was shown (seconds relative to playback start)
%   
%   This allows precise reconstruction of which video frames were displayed
%   and when, accounting for dropped frames due to refresh rate mismatch.
%
% TIMELINE:
%   1. Grey screen baseline (baseline_duration)
%   2. One "bookend" frame: photodiode visible, analog output = GREY
%   3. Video playback: photodiode toggles every N frames, analog matches
%   4. One "bookend" frame: photodiode visible, analog output = GREY
%   5. Baseline period (baseline_duration)
%
% SAVED DATA STRUCTURE:
%   The script saves a .mat file: 'video_playback_log_YYYYMMDD_HHMMSS.mat'
%   
%   Contents (frame_log_data struct):
%     .frame_log             - Array of structs with fields:
%         .display_frame     - Sequential display frame number (1 to N)
%         .video_pts         - Video timestamp in seconds (e.g., 0.000, 0.011, 0.033...)
%         .display_time      - Display time in seconds (relative to playback start)
%     
%     .video_filename        - Full path to video file played
%     .video_fps             - Video frame rate (e.g., 90.0 Hz)
%     .video_frame_count     - Total frames in video file
%     .display_frame_count   - Number of frames actually displayed
%     .start_time            - Absolute timestamp when playback started (GetSecs)
%
%   USAGE EXAMPLE:
%     load('video_playback_log_20260318_143052.mat');
%     pts_values = [frame_log_data.frame_log.video_pts];
%     plot(pts_values);  % Visualize which video frames were displayed
%     plot(diff(pts_values));  % See dropped frames (gaps > 1/fps)
%
% PARAMETERS (modify in code):
%   video_filename          - Video file to play (in same directory as script)
%   screen_number           - Screen ID (2 for wisecoco goggles)
%   baseline_duration       - Duration of pre/post baseline periods (seconds)
%   show_diagnostics        - Display frame rate diagnostics at end (true/false)
%   photodiode_toggle_every - Toggle photodiode every N frames (1 = every frame)
%   wait_for_start_trigger  - Wait for NI-DAQ trigger before starting (true/false)


Screen('Preference', 'SkipSyncTests', 1);

% file where protocol is saved
video_filename = 'ZebraNoise_400x400_90Hz_scale0.4_seed16.mp4';

% Convert to absolute path (required by Screen('OpenMovie'))
[script_dir, ~, ~] = fileparts(mfilename('fullpath'));
video_filename = fullfile(script_dir, video_filename);

% variables
screen_number           = 2;        % Psychtoolbox sees both goggles as one 800 x 400 screen with id 2
baseline_duration       = 2;        % s
show_diagnostics        = true;     % show frame rate diagnostics at end
photodiode_toggle_every = 5;        % toggle photodiode every N frames (1 = every frame)

% distance_from_screen is now loaded automatically from setup config
screen_name             = 'wisecoco';
gamma_correction_file   = 'gamma_correction_mp_300.mat';
wait_for_start_trigger  = true;  % wait for start trigger, true or false

% NI-DAQ info
nidaq_dev               = 'Dev1';
% Digital input (on-demand polling for trigger only)
di_experiment_started   = 'port0/line0';

% startup psychtoolbox
ptb                     = PsychoToolbox();
ptb.calibration_on      = false;

% warp info
ptb.warp_on             = false;
ptb.warp_file           = '';

% load a gamma table for gamma correction
load(gamma_correction_file, 'gamma_table');
ptb.gamma_table 	= gamma_table;


% SetupInfo now automatically loads distance_from_screen from config
setup                       = SetupInfo(ptb, screen_name, screen_number);

%% setup DAQ


% Create DataAcquisition for digital input (trigger)
if wait_for_start_trigger
    dq_digital = daq("ni");
    addinput(dq_digital, nidaq_dev, di_experiment_started, "Digital");
    
    % Check that trigger is high to start
    initial_data = read(dq_digital);
    if initial_data{1, 1} ~= 1
        error('Digital input on channel 1 (experiment_started) should start high')
    end
end

%% 
% create an object controlling the background
bck                 = Background(setup);
bck.colour          = ptb.mid_grey_index(screen_number);

% create object controlling photodiode box
pd                  = Photodiode(setup);
pd.location         = 'right_goggle_top_right';

%%
try
    
    % Startup psychtoolbox
    ptb.start_stereo(screen_number, 90, 270);
    
    % Open the video file
    % Returns: [moviePtr, duration, fps, width, height, frameCount]
    [movie, duration, fps, width, height, frameCount] = Screen('OpenMovie', ptb.window(screen_number == ptb.screens), video_filename);
    fprintf('Video loaded: %s\n', video_filename);
    fprintf('Duration: %.2f s, FPS: %.2f, Resolution: %dx%d, Frames: %d\n', duration, fps, width, height, frameCount);
    
    % Present a grey screen on both eyes during baseline
    ptb.choose_eye(screen_number, 0);  % Left eye
    bck.buffer();
    ptb.choose_eye(screen_number, 1);  % Right eye
    bck.buffer();
    ptb.flip(screen_number);
    
    % Wait for trigger to go low (high->low transition)
    if wait_for_start_trigger
        fprintf('Waiting for trigger (high->low)...\n');
        data = read(dq_digital);
        while data{1, 1} == 1
            pause(0.001);
            data = read(dq_digital);
        end
        fprintf('Trigger received!\n');
    end
    
    
    % One frame before video playback onset
    % Set photodiode to white (will start alternating pattern)
    pd.colour = 1;
    ptb.choose_eye(screen_number, 0);  % Left eye
    bck.buffer();
    pd.buffer();
    ptb.choose_eye(screen_number, 1);  % Right eye
    bck.buffer();
    ptb.flip(screen_number);
        
    % Start movie playback
    % rate=1 for normal speed, loop=0 for no loop, sound=1.0 for 100% volume
    Screen('PlayMovie', movie, 1, 0, 1.0);
    
    % Initialize timing variables
    frame_count = 0;
    dropped_frames = 0;
    start_time = GetSecs;
    frame_times = [];           % Display timestamps (when frame was shown)
    video_pts = [];             % Video presentation timestamps (which frame from video)
    frame_log = struct('display_frame', {}, 'video_pts', {}, 'display_time', {});
    
    % Video playback loop
    while 1
        % Get next movie frame - returns 0 if movie ended or no new frame ready
        % waitForImage=1 means we wait for a new frame
        % pts = presentation timestamp in seconds (video's internal timestamp)
        [tex, pts] = Screen('GetMovieImage', ptb.window(screen_number == ptb.screens), movie, 1);
        
        % Check if we got a valid texture (movie still playing)
        if tex <= 0
            % Movie finished
            break;
        end
        
        frame_count = frame_count + 1;

        % Select left eye for drawing (eye 0)
        ptb.choose_eye(screen_number, 0);
        
        % Draw the video frame to the left eye buffer
        Screen('DrawTexture', setup.window, tex);
        
        % Draw photodiode box (toggles every N frames)
        pd.colour = (mod(frame_count, 2*photodiode_toggle_every) < photodiode_toggle_every)*1.0;
        pd.buffer();
        
        % Flip to display and record timing
        ptb.flip(screen_number);
        display_time = GetSecs;
        
        % Log frame information for later analysis
        frame_times(end+1) = display_time;
        video_pts(end+1) = pts;
        frame_log(frame_count).display_frame = frame_count;
        frame_log(frame_count).video_pts = pts;
        frame_log(frame_count).display_time = display_time - start_time;  % Relative to start

        
        % Release the texture - important for memory management
        Screen('Close', tex);
        
        % Check for escape key
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('escape'))
            break;
        end
    end
    
    % Stop movie playback
    Screen('PlayMovie', movie, 0);
    
    % One frame after video playback offset
    ptb.choose_eye(screen_number, 0);  % Left eye
    bck.buffer();
    ptb.choose_eye(screen_number, 1);  % Right eye
    bck.buffer();
    ptb.flip(screen_number);
    
    % Calculate and display diagnostics
    end_time = GetSecs;
    total_time = end_time - start_time;
    actual_fps = frame_count / total_time;
    
    if show_diagnostics
        fprintf('\n=== Video Playback Diagnostics ===\n');
        fprintf('Total frames displayed: %d\n', frame_count);
        fprintf('Expected frames (video): %d\n', frameCount);
        fprintf('Frames dropped: %d (%.1f%%)\n', frameCount - frame_count, 100*(frameCount - frame_count)/frameCount);
        fprintf('Total playback time: %.3f s\n', total_time);
        fprintf('Target FPS (video): %.2f\n', fps);
        fprintf('Actual FPS (display): %.2f\n', actual_fps);
        fprintf('Display refresh rate: 60 Hz\n');
        fprintf('Frame rate ratio (video/display): %.2f\n', fps/60);
        fprintf('Frame time mean: %.3f ms\n', mean(diff(frame_times)) * 1000);
        fprintf('Frame time std: %.3f ms\n', std(diff(frame_times)) * 1000);
        if ~isempty(video_pts)
            fprintf('Video PTS range: %.3f to %.3f s\n', min(video_pts), max(video_pts));
            fprintf('Video PTS mean interval: %.3f ms (%.1f Hz)\n', mean(diff(video_pts)) * 1000, 1/mean(diff(video_pts)));
        end
        fprintf('==================================\n\n');
    end
    
    % Save frame log for later analysis
    frame_log_data.frame_log = frame_log;
    frame_log_data.video_filename = video_filename;
    frame_log_data.video_fps = fps;
    frame_log_data.video_frame_count = frameCount;
    frame_log_data.display_frame_count = frame_count;
    frame_log_data.start_time = start_time;
    
    % Generate filename with timestamp
    timestamp_str = datestr(now, 'yyyymmdd_HHMMSS');
    log_filename = sprintf('video_playback_log_%s.mat', timestamp_str);
    save(fullfile(script_dir, log_filename), 'frame_log_data');
    fprintf('Frame log saved to: %s\n', log_filename);
        fprintf('==================================\n\n');
    
    % Close movie
    Screen('CloseMovie', movie);
    
    ptb.stop();
    
    clear all
    
catch ME
    ME
    
    % Cleanup
    if exist('dq_analog', 'var') && dq_analog.Running
        stop(dq_analog);
    end
    if exist('fid_ai', 'var') && fid_ai ~= -1
        fclose(fid_ai);
    end
    ptb.stop();
    
    clearvars -except ME
    rethrow(ME);
end
