%% mySmoothed - written by Tim Morin 06/29/2015
%Standard smoothing function. Takes a spikey data set and smooths it over a
%number of points as a running average. length of var must be divisible by
%period
%
%var - variable the user wants smoothed
%period - number of points to be smoothed (running average over period)
%varSmoothed - smoothed variable

function [varSmoothed]=mySmoothed(var,period)
% varSmoothed=lowpass(var,1/period);

% B = [1,1];  % transfer function numerator
% A = 1;      % transfer function denominator
A=1; B=ones(1,period)/period;
leftOver=mod(length(var),period);
if leftOver==0
    varSmoothed = filter(B, A, var);
else
    varSmoothed1=[filter(B,A,var(1:length(var)-leftOver));nan(leftOver,1)];
    varSmoothed2=[nan(leftOver,1);filter(B,A,var(leftOver+1:length(var)))];
    varSmoothed=nanmean([varSmoothed1 varSmoothed2],2);
end
% 
% N=10;       % length of test input signal
% x = 1:N;    % test input signal (integer ramp)
% B = [1,1];  % transfer function numerator
% A = 1;      % transfer function denominator
% 
% y = filter(B,A,x);