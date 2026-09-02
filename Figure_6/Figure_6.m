clear
close all

set(groot, 'defaultTextInterpreter', 'tex');
set(groot, 'defaultAxesTickLabelInterpreter', 'tex');
set(groot, 'defaultLegendInterpreter', 'tex');
set(groot, 'defaultAxesFontSize', 24);
set(groot, 'defaultTextFontSize', 24);
set(groot, 'defaultAxesFontName', 'Helvetica');
set(groot, 'defaultTextFontName', 'Helvetica');
set(groot, 'defaultLegendFontName', 'Helvetica');

%% Intracellular CPA concentration and normalized cell volume

v_bf = 0.35;              % Bound volume fraction
V_o = 1500;               % Initial cell volume [um^3]
L_pX = 2 * 0.11;          % Hydraulic conductivity [um/min/atm]
P_sX = 2 * 1.48 / 10000;  % Solute permeability [cm/min]
T = 277;                  % Temperature [K]
Me_sX = 3.05;             % External permeating solute osmolality [mol/kg]
Me_nX = 1.3;              % External non-permeating solute osmolality [mol/kg]
Mi_soX = 0;               % Initial intracellular permeating solute osmolality [mol/kg]
Mi_noX = 0.8;             % Initial intracellular non-permeating solute osmolality [mol/kg]
Vbar_sX = 0.071;          % Partial molar volume of glycerol [L/mol]
t_max = 60;               % Simulation time [s]
t_step = 0.0001;          % Time step [s]

figure(1)

output = shr_sw_2p(v_bf, V_o, L_pX, P_sX, T, Me_sX, Me_nX, ...
    Mi_soX, Mi_noX, Vbar_sX, t_max, t_step);

V_c = output.V_c;
V_w = output.V_w;
V_s = output.V_s;
t = output.t;

Vbar_s = Vbar_sX * 1e15;       % [um^3/mol]
n_s = V_s ./ Vbar_s;           % Intracellular CPA amount [mol]
V_aq = V_w + V_s;              % Intracellular aqueous solution volume [um^3]
C_s = n_s ./ (V_aq * 1e-15);   % Intracellular CPA concentration [mol/L]
V_n = V_c ./ V_o;              % Normalized cell volume

cBlack = [0 0 0];
cRed = [0.85 0 0];

yyaxis left
h1 = plot(t, C_s, '-', 'LineWidth', 2, 'Color', cBlack);
ylabel('Intracellular CPA concentration (M)')
ylim([0 max(C_s) * 1.1])

ax = gca;
ax.YColor = cBlack;

yyaxis right
h2 = plot(t, V_n, '--', 'LineWidth', 2, 'Color', cRed);
ylabel('Normalized cell volume')
ylim([0 1.1])

ax.YColor = cRed;
ax.LineWidth = 1.2;

xlabel('Time (s)')
xlim([0 t_max])

grid on
box on

lgd = legend([h1 h2], {'CPA concentration', 'Normalized volume'}, ...
    'Location', 'best');

lgd.FontSize = 24;
lgd.LineWidth = 1.2;


%% Viability versus exposure time

clearvars -except cBlack cRed
clc

set(groot, 'defaultTextInterpreter', 'tex');
set(groot, 'defaultAxesTickLabelInterpreter', 'tex');
set(groot, 'defaultLegendInterpreter', 'tex');
set(groot, 'defaultAxesFontSize', 24);
set(groot, 'defaultTextFontSize', 24);
set(groot, 'defaultAxesFontName', 'Helvetica');
set(groot, 'defaultTextFontName', 'Helvetica');
set(groot, 'defaultLegendFontName', 'Helvetica');

timeLabels = {'1', '5', '10', '20', '30'};
x = 1:numel(timeLabels);

% Individual experimental values
raw_control = [ ...
    100 98 99;
     99 98 97;
    100 96 98;
    100 100 98;
    100 100 97];

raw_TreOnly = [ ...
     99  99  99;
     97 100  98;
     97 100 100;
     96  99  95;
    100  99  97];

raw_PG_Tre = [ ...
    97 100 94;
    95  99 93;
    96  92 90;
    95  96 89;
    91  94 88];

% Means and sample SD calculated directly from the experimental replicates
means_control = mean(raw_control, 2).';
errs_control  = std(raw_control, 0, 2).';

means_TreOnly = mean(raw_TreOnly, 2).';
errs_TreOnly  = std(raw_TreOnly, 0, 2).';

means_PG_Tre = mean(raw_PG_Tre, 2).';
errs_PG_Tre  = std(raw_PG_Tre, 0, 2).';

% Plot colors
c_control = [0.34 0.71 0.91];
c_tre = [0.00 0.62 0.45];
c_pgtre = [0.84 0.37 0.00];

lighten = @(c, a) c + (1 - c) * a;
darken = @(c, a) c * (1 - a);

c_control = lighten(c_control, 0.15);
c_pgtre = darken(c_pgtre, 0.10);

Y = [means_control(:), means_TreOnly(:), means_PG_Tre(:)];

fig = figure('Color', 'w');
ax = axes(fig);
hold(ax, 'on');

bg = bar(ax, x, Y, 'grouped');

bg(1).FaceColor = c_control;
bg(1).EdgeColor = c_control;
bg(1).LineWidth = 1.2;

bg(2).FaceColor = c_tre;
bg(2).EdgeColor = c_tre;
bg(2).LineWidth = 1.2;

bg(3).FaceColor = c_pgtre;
bg(3).EdgeColor = c_pgtre;
bg(3).LineWidth = 1.2;

xC = bg(1).XEndPoints;
xTre = bg(2).XEndPoints;
xPG = bg(3).XEndPoints;

errorbar(ax, xC, means_control, errs_control, 'k', ...
    'LineStyle', 'none', 'LineWidth', .75, 'CapSize', 10);

errorbar(ax, xTre, means_TreOnly, errs_TreOnly, 'k', ...
    'LineStyle', 'none', 'LineWidth', .75, 'CapSize', 10);

errorbar(ax, xPG, means_PG_Tre, errs_PG_Tre, 'k', ...
    'LineStyle', 'none', 'LineWidth', .75, 'CapSize', 10);

point_offsets = [-0.025 0 0.025];

for i = 1:numel(x)

    scatter(ax, xC(i) + point_offsets, raw_control(i,:), ...
        25, 'k', 'filled', 'MarkerFaceAlpha', .5, ...
        'HandleVisibility', 'off');

    scatter(ax, xTre(i) + point_offsets, raw_TreOnly(i,:), ...
        25, 'k', 'filled', 'MarkerFaceAlpha', .5, ...
        'HandleVisibility', 'off');

    scatter(ax, xPG(i) + point_offsets, raw_PG_Tre(i,:), ...
        25, 'k', 'filled', 'MarkerFaceAlpha', .5, ...
        'HandleVisibility', 'off');
end

ax.XTick = x;
ax.XTickLabel = timeLabels;

xlabel(ax, 'Exposure Time (min)');
ylabel(ax, 'Viability (%)');

ax.YLim = [70 111];
ax.YTick = 70:10:100;
ax.LineWidth = 1.2;

box(ax, 'on');
grid(ax, 'on');

lgd = legend(ax, ...
    {'Control', '0.5M Trehalose', '2.5M PG + 1M Trehalose'}, ...
    'Location', 'northwest');

lgd.LineWidth = 1.0;


%% Weighted linear fits

clearvars -except cBlack cRed
clc

set(groot, 'defaultTextInterpreter', 'tex');
set(groot, 'defaultAxesTickLabelInterpreter', 'tex');
set(groot, 'defaultLegendInterpreter', 'tex');
set(groot, 'defaultAxesFontSize', 24);
set(groot, 'defaultTextFontSize', 24);
set(groot, 'defaultAxesFontName', 'Helvetica');
set(groot, 'defaultTextFontName', 'Helvetica');
set(groot, 'defaultLegendFontName', 'Helvetica');

tmin = [1 5 10 20 30]';

% Correct means and sample SDs from the raw n = 3 experiments
yTre = [ ...
    99.00000000;
    98.33333333;
    99.00000000;
    96.66666667;
    98.66666667];

eTre = [ ...
    0.000000000;
    1.527525232;
    1.732050808;
    2.081665999;
    1.527525232];

yPG = [ ...
    97.00000000;
    95.66666667;
    92.66666667;
    93.33333333;
    91.00000000];

ePG = [ ...
    3.000000000;
    3.055050463;
    3.055050463;
    3.785938897;
    3.000000000];

c_tre = [0.00 0.62 0.45];
c_pgtre = [0.84 0.37 0.00];

darken = @(c, a) c * (1 - a);
c_pgtre = darken(c_pgtre, 0.10);

X = [ones(size(tmin)) tmin];

wTre = 1 ./ max(eTre, 1e-6).^2;
wPG = 1 ./ max(ePG, 1e-6).^2;

bTre = lscov(X, yTre, wTre);
bPG = lscov(X, yPG, wPG);

tFine = linspace(min(tmin) - 1, 3 * max(tmin), 300)';

yTre_fit = bTre(1) + bTre(2) * tFine;
yPG_fit = bPG(1) + bPG(2) * tFine;

fig = figure('Color', 'w');
ax = axes(fig);
hold(ax, 'on');

hTre = plot(ax, tFine, yTre_fit, '-', ...
    'LineWidth', 3, 'Color', c_tre);

hPG = plot(ax, tFine, yPG_fit, '-.', ...
    'LineWidth', 3, 'Color', c_pgtre);

plot(ax, tmin, yTre, 'o', ...
    'MarkerSize', 8, ...
    'MarkerFaceColor', c_tre, ...
    'MarkerEdgeColor', 'k', ...
    'LineWidth', 1.2, ...
    'HandleVisibility', 'off');

plot(ax, tmin, yPG, 's', ...
    'MarkerSize', 8, ...
    'MarkerFaceColor', c_pgtre, ...
    'MarkerEdgeColor', 'k', ...
    'LineWidth', 1.2, ...
    'HandleVisibility', 'off');

xlabel(ax, 'Exposure Time (min)');
ylabel(ax, 'Viability (%)');

xlim(ax, [0 60]);
ylim(ax, [70 102]);

grid(ax, 'on');
box(ax, 'on');

ax.LineWidth = 1.2;
ax.GridAlpha = 0.15;
ax.MinorGridAlpha = 0.30;
ax.GridColor = [0.6 0.6 0.6];

legend(ax, [hTre hPG], ...
    {'0.5M Trehalose (linear fit)', ...
     '2.5M PG + 1M Trehalose (linear fit)'}, ...
    'Location', 'southwest')