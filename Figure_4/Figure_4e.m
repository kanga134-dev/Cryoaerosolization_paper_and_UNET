clear
clc
close all

load("ln2_fig_data_CCR.mat")

set(groot, 'defaultTextInterpreter', 'tex');
set(groot, 'defaultAxesTickLabelInterpreter', 'tex');
set(groot, 'defaultLegendInterpreter', 'tex');
set(groot, 'defaultAxesFontSize', 24);
set(groot, 'defaultTextFontSize', 24);
set(groot, 'defaultAxesFontName', 'Helvetica');
set(groot, 'defaultTextFontName', 'Helvetica');
set(groot, 'defaultLegendFontName', 'Helvetica');

okabeIto = [0,0,0;
            230,159,0;
            86,180,233;
            0,158,115;
            240,228,66;
            0,114,178;
            213,94,0;
            204,121,167] ./ 255;

markerSize = 100;

figure
hold on
yyaxis left
hold on

errorbar(ln2_flow_50um, mean_cooling_rate_50um, ...
         cooling_rate_error_50um, cooling_rate_error_50um, ...
         'LineStyle', 'none', 'Color', okabeIto(1,:), ...
         'CapSize', 8, 'LineWidth', .75);
scatter(ln2_flow_50um, mean_cooling_rate_50um, markerSize, ...
        okabeIto(1,:), 'filled', 'd')

errorbar(ln2_flow_100um, mean_cooling_rate_100um, ...
         cooling_rate_error_100um, cooling_rate_error_100um, ...
         'LineStyle', 'none', 'Color', okabeIto(1,:), ...
         'CapSize', 8, 'LineWidth', .75);
scatter(ln2_flow_100um, mean_cooling_rate_100um, markerSize, ...
        okabeIto(1,:), 'filled', 'd')

plot(cooling_rate_trend_x, cooling_rate_trend_y, 'k--', LineWidth=1.5)
ylabel('Mean Cooling Rate (K min^{-1})')
xlabel('Liquid Nitrogen Flow Rate (g min^{-1})');
axis([-50 1000 0 2.6E5])
set(gca, 'YScale', 'linear')

yyaxis right
grid on
box on
plot(vitrification_trend_x, vitrification_trend_y, '--', ...
     LineWidth=1.5, Color=okabeIto(6,:))
ylabel('Vitrifiable CPA (w/w)')

ax = gca;
yyaxis left
ax.YColor = okabeIto(1,:);
yyaxis right
ax.YColor = okabeIto(6,:);

axis([-100 900 .15 .25])
yticks([.15,.17,.19,.21,.23,.25])
xticks([0 200 400 600 800 1000])
legend('', 'Mean Cooling Rate', '', '', ...
       'Cooling Rate Trendline', 'Vitrification Trendline');
set(legend, fontsize=24)
legend('Location', 'southeast');
