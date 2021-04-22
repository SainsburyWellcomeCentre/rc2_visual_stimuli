% Script to load a schedule and estimate how long it will take.
% file where protocol is saved
%prot_fname = 'opticflow_rc2_20201214';
prot_fname = 'opticflow2scr_rc2_20201214';

% Seconds.
baseline_duration       = 10;        % s
drift_duration          = 2.5;      % s
isi_duration            = 2.5;      % s

% load protocol
load(prot_fname, 'schedule');

duration_session = baseline_duration * 2 + ...
                   schedule.n_stim_per_session * (baseline_duration + isi_duration);
               
duration_total = duration_session * ...
                 schedule.n_sessions;

duration_session = seconds(duration_session);
duration_total = seconds(duration_total);

duration_session.Format = 'hh:mm:ss';
duration_total.Format = 'hh:mm:ss';

disp(duration_session)
disp(duration_total)