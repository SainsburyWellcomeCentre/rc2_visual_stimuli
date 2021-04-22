%experiment order SW200727
%% 1 Turn all projectors off
%light on and off interleaved2
run_rc2_black_sw;
%% 2 Turn on projectors
%grey backround with light on and off interleaved
run_rc2_grey_sw;
%% 3 Both Projectors on : Visual stimulation 
run_rc2_sf_tf_sw;
%% 4 Left Projector on only (from mouse view); Visual stimulation 
run_rc2_sf_tf_sw
%% 5 Right Projector on only (from mouse view); Visual stimulation 
%SWITCH PHOTODIODE to other side 
run_rc2_sf_tf_sw;


