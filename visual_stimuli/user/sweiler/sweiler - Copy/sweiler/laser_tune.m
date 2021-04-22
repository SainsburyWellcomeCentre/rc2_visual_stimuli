%Laser output
d=daq.createSession('ni');
d.addAnalogOutputChannel('Dev1', 'ao0', 'Voltage');
%% 
d.Rate=1000;
T=2;
ti=-2:1/d.Rate:2;
data1=rectpuls(ti,T)*3
%% 

%% 

d.IsContinuous=true;


%% 
tic
queueOutputData(d,data1') 
startBackground(d)
%outputSingleScan(d,[0])
d.wait(5000)
stop(d)
toc
%% 
d.IsContinuous=false;
 tic
 queueOutputData(d,data1') 
 startForeground(d)
 outputSingleScan(d,[0])
 
 toc



% %data2=linspace(0,3,d.Rate)';
% %outputSingleScan(d,[0]);
% lh = addlistener(d,'DataRequired', ...
%         @(src,event) src.queueOutputData(data1));
% queueOutputData(d,data1) 
% startBackground(d); 
% 
% outputSingleScan(d,[3])
% stop(d)
% release(d)