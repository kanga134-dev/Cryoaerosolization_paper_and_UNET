clc; clear; close all

% --- Figure layout ---
tiledlayout(2,1,'Padding','compact','TileSpacing','compact');

% =========================
% =  TOP: Viability chart =
% =========================
flows = [0 1 3 5 10];
flow_labels = compose('%g L/min', flows);

% Viability (rows = orifice sizes, cols = flows)
vals3_35  = [0.98 0.97 0.99 0.9433333333 0.6866666667];
vals3_50  = [0.97 0.9566666667 0.9666666667 0.9533333333 0.8433333333];
vals3_100 = [0.9933333333 0.9666666667 0.97 0.9833333333 0.93];
vals3_150 = [0.99 0.99 0.94 0.96 0.94];

sd3_35  = [0.0346410162 0.0264575131 0.0173205081 0.0404145188 0.1604161255];
sd3_50  = [0.0360555128 0.0351188458 0.0208166600 0.0230940108 0.0896288644];
sd3_100 = [0.0057735027 0.0351188458 0.0173205081 0.0115470054 0.0360555128];
sd3_150 = [0.01 0.01 0.0435889894 0.0360555128 0.0435889894];

exp1 = [
    100 100 100 98 84;
    100 99 99 98 89;
    99 100 96 99 96;
    99 100 99 97 96
];

exp2 = [
    100 96 97 95 52;
    93 96 96 94 90;
    100 97 99 97 94;
    100 99 92 99 97
];

exp3 = [
    94 95 100 90 70;
    98 92 95 94 74;
    99 93 96 99 89;
    98 98 91 92 89
];

raw = cat(3,exp1,exp2,exp3);

toPct = @(x) x*100;
vals = toPct([vals3_35; vals3_50; vals3_100; vals3_150]);  % 4 x 5
se   = toPct([sd3_35;  sd3_50;  sd3_100;  sd3_150]);       % 4 x 5

% --- Green gradient for dispersion air (light -> dark) ---
greens = [
    230 225 240;
    186 178 210;
    140 130 190;
    102  90 165;
    65   25 120
] / 255;


% Plot top
ax1 = nexttile(1);
b = bar(vals,'grouped'); hold on
[nGroups, nBars] = size(vals);

% Apply gradient colors by series (each series = a flow)
for i = 1:nBars
    b(i).FaceColor  = greens(i,:);
    b(i).EdgeColor  = 'none';
end

% Error bars
groupwidth = min(0.8, nBars/(nBars + 1.5));
for i = 1:nBars
    x = (1:nGroups) - groupwidth/2 + (2*i-1)*groupwidth/(2*nBars);
    errorbar(x, vals(:,i), se(:,i), 'k', 'LineStyle','none', 'LineWidth',.5);

    for g = 1:nGroups
        scatter(x(g) + [-0.025 0 0.025], squeeze(raw(g,i,:))', ...
            10, 'k','filled', 'HandleVisibility','off');
    end
end

set(ax1,'XTick',1:nGroups,'XTickLabel',{'35','50','100','150'},'FontSize',16);
xlabel('Orifice Size (\mum)','FontSize',16)
ylabel('Viability (%)','FontSize',16)

% Horizontal legend below top plot
lgd = legend(flow_labels, 'Orientation','horizontal', 'Location','southoutside', ...
             'FontSize',16, 'Box','off');
title(lgd, 'Dispersion Air');

% Clean grid/ticks
grid(ax1,'on'); ax1.XGrid = 'off'; ax1.YGrid = 'on';
ax1.TickLength = [0 0];
box on;
yticks(0:20:100); ylim([0 135])
xlim(ax1,[0.5 nGroups+0.5])

% =========================================
% =  BOTTOM: Cooling rate & Throughput    =
% =========================================
xpos = 1:nGroups;
orifice_labels = {'35','50','100','150'};

cooling_rate   = [300000 250000 100000 60000];
throughput_min = [0.3 0.6 2.2 5.0];
throughput_hr  = throughput_min * 60;

ax2 = nexttile(2); hold(ax2,'on')

yyaxis left
clr = [0,114,178]/255;

x = xpos;
y = cooling_rate;

% Define asymmetric error bars
y_upper = [75000, 60000, 35000, 40000];
y_lower = [75000, 60000, 35000, 20000];

yhi = y + y_upper;
ylo = y - y_lower;

% Shaded region (error band)
fill([x fliplr(x)], [yhi fliplr(ylo)], clr, ...
    'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility','off');
hold on

% Main line + markers
p1 = plot(x, y, '-o', 'LineWidth', 2.2, 'Color', clr, 'MarkerFaceColor','w');
ylabel('Cooling Rate (K min^{-1})','FontSize',20)
grid on

p1.MarkerFaceColor = 'w';
ylabel('Cooling Rate (K min^{-1})','FontSize',20)
ylim([0 .390*10^6]); grid on
yticks([0 100000 200000 300000])

yyaxis right
p2 = plot(xpos, throughput_hr, '-.s', ...
    'LineWidth', 2, ...
    'Color', [117,112,179]/255, ...
    'MarkerFaceColor', 'w');
ylabel('Volumetric Throughput (mL/hr)', 'FontSize', 16)
ylabel('Volumetric Throughput (mL/hr)','FontSize',16)
ylim([0 390])

set(ax2,'XTick',xpos,'XTickLabel',orifice_labels,'FontSize',16)
yticks([0 100 200 300])
xlabel('Orifice Size (\mum)','FontSize',16)

lgd2 = legend([p1 p2], {'Cooling Rate','Throughput'}, 'Orientation','horizontal', ...
              'FontSize',16, 'Box','off');
lgd2.Position(1) = 0.5 - lgd2.Position(3)/2;
lgd2.Position(2) = ax2.Position(2) + ax2.Position(4) - lgd2.Position(4);
p1.Color = [60 120 180]/255;
p2.Color = [200 140 0]/255;
yyaxis right
ax = gca;
ax.YColor = [200 140 0]/255;

box on
xlim(ax2, xlim(ax1));
linkaxes([ax1 ax2],'x');