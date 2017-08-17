function [ diff,RiskFunction,RiskFunctionUpper,RiskFunctionLower,location,scale,mlower,mupper,slower,supper ] = SlopesToMANIC( x0 )
% Survival Analysis for Subjects under Gy Acceleration
%   This function takes slopes from curves correlating the critical value
%   to weight and uses them to calculate a MANIC value which is then used
%   to construct a Risk Function. This is in an effort to find more
%   accurate critical values.

path = 'C:\Users\user\Desktop\Neck Injury\Gy-Analysis\ExcelData\';
filenamesCellC = dir([path,'\Cell C\*.xlsx']);
filenamesCellF = dir([path,'\Cell F\*.xlsx']);

m = [2.948 x0(1) x0(2) x0(3) 8.351 8.351 19.25 x0(4)];
b = [115.2 115.2 253.9 281.4 -240.4 -240.5 -558.5 -240.4];

%% MANIC(Gy) Value Calculation

SubWtC = [233,152,160,237,185,191,180,155,145,220,250,190,167,213,180,168,210,137,177,237,140,160,132,160,128,205,185,188,133,140,154]; % Lbs
SubWtF = [227,132,140,193,135,155,164,170,156,206,190,215,230,140,160,180,210,160,155,165,204,167,140,180,188];

loading = VectorizedCode;
cellc = zeros(1,30);
for i = 1:length(filenamesCellC)
    pathC = 'C:\Users\user\Desktop\Neck Injury\Gy-Analysis\ExcelData\Cell C\';
    testc = filenamesCellC(i).name;
    [numC,~,~] = xlsread([pathC,testc]);
    
    % Critical Value selection based on previously obtained linear
    % equations
    
    Fx_crit = SubWtC(i)*m(1) + b(1);
    Fy_crit = SubWtC(i)*m(2) + b(2);
        if numC(:, 3) < 0 
            Fz_crit = SubWtC(i)*m(3) + b(3);
        else
            Fz_crit = SubWtC(i)*m(4) + b(4);
        end
        if numC(:, 6) < 0
            My_crit = SubWtC(i)*m(6) + b(6);
        else
            My_crit = SubWtC(i)*m(7) + b(7);
        end
    Mz_crit = SubWtC(i)*m(8) + b(8);
        
    Fx = numC(:, 2);
    Fy = numC(:, 3);
    Fz = numC(:, 4);
    My = numC(:, 6);
    Mz = numC(:, 7);
    
    cellc(i) = max(sqrt((Fx./Fx_crit).^2 + (Fy./Fy_crit).^2 + (Fz./Fz_crit).^2 + (My./My_crit).^2 + (Mz./Mz_crit).^2));
end
 clear Fx Fy Fz My Mz Fx_crit Fy_crit Fz_crit My_crit Mz_crit

cellf = zeros(1,25);
for i = 1:length(filenamesCellF)
    pathF = 'C:\Users\user\Desktop\Neck Injury\Gy-Analysis\ExcelData\Cell F\';
    testf = filenamesCellF(i).name;
    [numF,~,~] = xlsread([pathF,testf]);
    
    % Critical Value selection based on previously obtained linear
    % equations
    
    Fx_crit = SubWtF(i)*m(1) + b(1);
    Fy_crit = SubWtF(i)*m(2) + b(2);
        if numF(:, 3) < 0 
            Fz_crit = SubWtF(i)*m(3) + b(3);
        else
            Fz_crit = SubWtF(i)*m(4) + b(4);
        end
        if numF(:, 6) < 0
            My_crit = SubWtF(i)*m(6) + b(6);
        else
            My_crit = SubWtF(i)*m(7) + b(7);
        end
    Mz_crit = SubWtF(i)*m(8) + b(8);
        
    Fx = numF(:, 2);
    Fy = numF(:, 3);
    Fz = numF(:, 4);
    My = numF(:, 6);
    Mz = numF(:, 7);
    
    cellf(i) = max(sqrt((Fx./Fx_crit).^2 + (Fy./Fy_crit).^2 + (Fz./Fz_crit).^2 + (My./My_crit).^2 + (Mz./Mz_crit).^2));
end
human = [cellc cellf];

%% Data For R
pmhs = [0.85 1.99 0.63 0.41 0.72 0.27 1.60 0.27 0.35]; % Need raw acceleration data to calculate with MANIC function
inj = [1 1 1 0 0 0 1 1 0]; % AIS 2+ 
no_injury = zeros(1,55);

% Write data to csv files to be read by R script 
csvwrite('human.csv',human(:));
csvwrite('pmhs.csv',pmhs(:));
% Run R through a batch script on the CMD. Must have absolute path to file
% with R. 
system('"C:\Program Files\R\R-3.4.1\bin\R" CMD BATCH SurvivalAnalysis.R Output.txt')

MANIC = [human pmhs];
INJ = [no_injury inj];

%% Retrieve Data from R
testparams = csvread('testparams.csv');
testparamstruct = struct('mu',testparams(1,1),'sigma',testparams(2,1));
location = testparamstruct.mu;
scale = testparamstruct.sigma;

% 95% Conf. Intervals.
mlower = testparams(1,3);
mupper = testparams(1,4);
slower = testparams(2,3);
supper = testparams(2,4);

%% Risk Function Construction
x = linspace(0,2.5, 250);
RiskFunction = 1./(1 + exp(-(x - location)./scale));
RiskFunctionUpper = 1./(1 + exp(-(x - mupper)./supper));
RiskFunctionLower = 1./(1 + exp(-(x - mlower)./slower));

%% Optimization 
survival = struct('MANIC',MANIC,'Injury',INJ);

min_inj = min(survival.MANIC(survival.Injury == 1));
max_noninj = max(survival.MANIC(survival.Injury == 0));

diff = max_noninj - min_inj;
end

