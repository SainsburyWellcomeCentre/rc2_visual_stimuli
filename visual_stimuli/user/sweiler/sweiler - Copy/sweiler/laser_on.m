
d=daq.createSession('ni');
d.addAnalogOutputChannel('Dev1', 'ao0', 'Voltage');
d.Rate=1000;
d.IsContinuous=true;

data1=linspace(0,0,d.Rate)';
data2=linspace(0,3,d.Rate)';

queueOutputData(d,[data1]);
startBackground(d)
pause(1);


%  data=cos(linspace(0,3*pi,d.Rate)');
% d.Rate=4000
 queueOutputData(d,[data2])
 startBackground(d)
 pause(2)
 outputSingleScan(d,[0]);

% 
%  data=linspace(0,3,100)';
%  queueOutputData(d,[data])
%  
%   d.IsContinuous=false
%  startBackground(d)
%  
%    outputSingleScan(d,[0]);
% outputSingleScan(d,[0]);
%              