clear all
close all
clc

path = 'C:\Users\user\Desktop\Neck Injury\Gy-Analysis\ExcelData\'; % Path to Excel Files (Will vary from system to system)
filenamesCellC = dir([path,'\Cell C\*.xlsx']);
filenamesCellF = dir([path,'\Cell F\*.xlsx']);
filenames = [filenamesCellC(1:30,1);filenamesCellF];

% Enter Initial Slopes given by the curve fitting.
slopeFy = 2.948;
slopeFzcomp = 6.487;
slopeFztens = 7.16;
slopeMz = 8.351;

og = [2.948 6.487 7.16 8.351];
slopes = [og(1),og(2),og(3),og(4)];

loading = VectorizedCode;
x0 = struct('loading',loading,'Slopes',slopes)

% [diff,RiskFunction,RiskFunctionUpper,RiskFunctionLower,location,scale,mlower,mupper,slower,supper] = FunctionTest(x0)

lb = [0,0,0,0];
ub = 3*og;

options = optimset('Display','iter','PlotFcns',@optimplotfval);
[diff,fval,exitflag,output,lambda,grad,hessian] = fmincon(@FunctionTest,slopes,[],[],[],[],lb,ub,[],options)

figure
x = linspace(0,2.5, 250);

plot(x, RiskFunction, x, RiskFunctionUpper, x, RiskFunctionLower)
legend('RiskFunction','RiskFunctionUpper','RiskFunctionLower')
grid on
xlabel('Max MANIC(Gy) value')
ylabel('AIS 2+ Risk')
ylim([0 1])
xlim([0 2.5])
hold on
plot(human,no_injury,'*')
hold on 
plot(pmhs, inj, '*')