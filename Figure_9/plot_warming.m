clear
close all

% Load the preprocessed Figure 9 data from the same folder as this script.
% Only this script and figure_9_data.mat are required.
scriptPath = mfilename('fullpath');
if isempty(scriptPath)
    scriptDir = pwd;
else
    scriptDir = fileparts(scriptPath);
end

dataPath = fullfile(scriptDir, 'figure_9_data.mat');
if ~isfile(dataPath)
    error('Could not find Figure 9 data file: %s', dataPath);
end

data = load(dataPath, 'ans1', 'ans2', 'ans3', 'ans4', 'ans5', 'ans6');
requiredVariables = {'ans1','ans2','ans3','ans4','ans5','ans6'};
if ~all(isfield(data, requiredVariables))
    error('figure_9_data.mat must contain ans1 through ans6.');
end

ans1 = data.ans1; %#ok<NASGU>
ans2 = data.ans2;
ans3 = data.ans3;
ans4 = data.ans4; %#ok<NASGU>
ans5 = data.ans5;
ans6 = data.ans6;

set(groot, 'defaultTextInterpreter', 'tex');
set(groot, 'defaultAxesTickLabelInterpreter', 'tex');
set(groot, 'defaultLegendInterpreter', 'tex');
set(groot, 'defaultAxesFontSize', 24);
set(groot, 'defaultTextFontSize', 24);
set(groot, 'defaultAxesFontName', 'Helvetica');
set(groot, 'defaultTextFontName', 'Helvetica');
set(groot, 'defaultLegendFontName', 'Helvetica');

figure(1)
plot(ans2.t_s, ans2.T_K, 'k')
hold on
plot(ans3.t_s, ans3.T_K, 'b--')
axis([-0.0001 0.05 70 315])
xlabel('Time (s)')
ylabel('Temperature (K)')
legend('Droplet interior temperature', ...
       'External fluid temperature (5 \mum from surface)', ...
       'Location', 'southeast', 'FontSize', 20)
grid on
set(gca, 'GridAlpha', 0.1)

figure(2)
plot(ans5.t_s, ans5.T_K, 'k')
hold on
plot(ans6.t_s, ans6.T_K, 'b--')
axis([-0.0001 0.05 70 315])
xlabel('Time (s)')
ylabel('Temperature (K)')
legend('Droplet interior temperature', ...
       'External fluid temperature (5 \mum from surface)', ...
       'Location', 'southeast', 'FontSize', 20)
grid on
set(gca, 'GridAlpha', 0.1)
