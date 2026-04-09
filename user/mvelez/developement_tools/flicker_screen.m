screen_name             = 'mp_300';
screen_number           = 3;        % s
ptb                     = PsychoToolbox();
setup                   = SetupInfo(ptb, screen_name, screen_number);
bck                     = Background(setup);
duration                = 10;


%%
ptb.start(screen_number);
bck.buffer();
ptb.flip(screen_number);

min_val = 0;
max_val = 1;

try
    
    for frame_i = 1 : round(duration/ptb.ifi)
        colour = min_val + (max_val-min_val)*mod(frame_i, 2);
        bck.colour = colour;
        bck.buffer();
        ptb.flip(screen_number);
    end
    
    ptb.stop();
    
catch ME
    
    ptb.stop();
    rethrow(ME);
end