function laser_mod(d,data1,data2)
t0=clock;
            while etime(clock,t0)<1
           outputSingleScan(d,[0]);
            end
  t1=clock;
            while etime(clock,t1)<2
           outputSingleScan(d,[2]);
            end    
             outputSingleScan(d,[0])
end