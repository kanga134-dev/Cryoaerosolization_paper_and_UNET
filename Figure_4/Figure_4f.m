clc
close all
clear

load("spray_figure_data.mat")

set(groot, 'defaultTextInterpreter', 'tex');
set(groot, 'defaultAxesTickLabelInterpreter', 'tex');
set(groot, 'defaultLegendInterpreter', 'tex');
set(groot, 'defaultAxesFontSize', 20);
set(groot, 'defaultTextFontSize', 20);
set(groot, 'defaultAxesFontName', 'Helvetica');
set(groot, 'defaultTextFontName', 'Helvetica');
set(groot, 'defaultLegendFontName', 'Helvetica');

color_1 = [0 32 96]/255;
color_2 = [0 91 187]/255;
color_3 = [173 216 255]/255;

c_low = concentration_low;
c_mod = concentration_moderate;
c_high = concentration_high;


model = @(p,c) 1-exp(-p(1)*exp(-p(2)*c.^p(3)));
c_low_fit = linspace(0,.25,1000);
c_mod_fit = linspace(0,.25,1000);
c_high_fit = linspace(0,.25,1000);
f_low_fit = model(fit_parameters_low,c_low_fit);
f_mod_fit = model(fit_parameters_moderate,c_mod_fit);
f_high_fit = model(fit_parameters_high,c_high_fit);

figure(1)
subplot(2,1,1)
hold on

scatter(c_low, f_low, 10, color_1, "filled", 'Marker', 'd')
scatter(c_mod, f_mod, 10, color_2, "filled", 'Marker', 'd')
scatter(c_high, f_high, 10, color_3, "filled", 'Marker', 'd')

plot(c_low_fit, f_low_fit, "Color", color_1, "LineWidth", 2)
dx = .0019;
fLo = model(fit_parameters_low,c_low_fit+dx);
fHi = model(fit_parameters_low,c_low_fit-dx);
fLo = max(fLo,0);
fHi = min(fHi,1);
patch([c_low_fit fliplr(c_low_fit)], [fLo fliplr(fHi)], ...
      color_1, 'EdgeColor', 'none', 'FaceAlpha', 0.25);

plot(c_mod_fit, f_mod_fit, "Color", color_2, "LineWidth", 2)
dx = .0027;
fLo = model(fit_parameters_moderate,c_mod_fit+dx);
fHi = model(fit_parameters_moderate,c_mod_fit-dx);
fLo = max(fLo,0);
fHi = min(fHi,1);
patch([c_mod_fit fliplr(c_mod_fit)], [fLo fliplr(fHi)], ...
      color_2, 'EdgeColor', 'none', 'FaceAlpha', 0.25);

plot(c_high_fit, f_high_fit, "Color", color_3, "LineWidth", 2)
dx = .002;
fLo = model(fit_parameters_high,c_high_fit+dx);
fHi = model(fit_parameters_high,c_high_fit-dx);
fLo = max(fLo,0);
fHi = min(fHi,1);
patch([c_high_fit fliplr(c_high_fit)], [fLo fliplr(fHi)], ...
      color_3, 'EdgeColor', 'none', 'FaceAlpha', 0.25);

box on
hold off
grid on
axis([.1 .2 -.05 1.05])
xlabel('EtOH Concentration (w/w)', 'FontSize', 20)
ylabel('Crystalized Fraction', 'FontSize', 20)
axis square

CCR_etoh_low = 470209*exp(-c_low_fit*100*.402)*60;
CCR_etoh_mod = 470209*exp(-c_mod_fit*100*.402)*60;
CCR_etoh_high = 470209*exp(-c_high_fit*100*.402)*60;

area_low = trapz(CCR_etoh_low,[0,diff(f_low_fit)]);
area_mod = trapz(CCR_etoh_mod,[0,diff(f_mod_fit)]);
area_high = trapz(CCR_etoh_high,[0,diff(f_high_fit)]);

pdf_low = -([0,diff(f_low_fit)])/area_low;
pdf_mod = -([0,diff(f_mod_fit)])/area_mod;
pdf_high = -([0,diff(f_high_fit)])/area_high;

subplot(2,1,2)
hold on

sampleFromPDF = @(x,cum_pdf,N) interp1(cum_pdf,x,rand(N,1),'linear','extrap');

cum_sum_low = cumtrapz(CCR_etoh_low,-pdf_low);
cum_sum_low_trimmed_I = find((cum_sum_low<.99)&(cum_sum_low>.01));
cum_sum_low_trimmed = cum_sum_low(cum_sum_low_trimmed_I);
CR_low_trimmed = CCR_etoh_low(cum_sum_low_trimmed_I);

cum_sum_mod = cumtrapz(CCR_etoh_mod,-pdf_mod);
cum_sum_mod_trimmed_I = find((cum_sum_mod<.99)&(cum_sum_mod>.01));
cum_sum_mod_trimmed = cum_sum_mod(cum_sum_mod_trimmed_I);
CR_mod_trimmed = CCR_etoh_mod(cum_sum_mod_trimmed_I);

cum_sum_high = cumtrapz(CCR_etoh_high,-pdf_high);
cum_sum_high_trimmed_I = find((cum_sum_high<.99)&(cum_sum_high>.01));
cum_sum_high_trimmed = cum_sum_high(cum_sum_high_trimmed_I);
CR_high_trimmed = CCR_etoh_high(cum_sum_high_trimmed_I);

plot(CR_low_trimmed, cum_sum_low_trimmed);
plot(CR_mod_trimmed, cum_sum_mod_trimmed);
plot(CR_high_trimmed, cum_sum_high_trimmed);
hold off

N = 100000;
rng(1)
samples_low = sampleFromPDF(CR_low_trimmed, cum_sum_low_trimmed, N);
samples_mod = sampleFromPDF(CR_mod_trimmed, cum_sum_mod_trimmed, N);
samples_high = sampleFromPDF(CR_high_trimmed, cum_sum_high_trimmed, N);

data = [samples_low, samples_mod, samples_high];

vp = violinplot(data);
vp(1).FaceColor = color_1;
vp(2).FaceColor = color_2;
vp(3).FaceColor = color_3;
vp(1).FaceAlpha = .5;
vp(2).FaceAlpha = .5;
vp(3).FaceAlpha = .5;
vp(1).SeriesIndex = 'none';

hold on
b = boxchart(data);
b.MarkerStyle = 'none';
b.BoxFaceColor = [0 0 0];
b.BoxFaceAlpha = 0.25;
b.WhiskerLineColor = [0 0 0];

set(gca, 'XTick', [])
grid on
set(gca, 'YScale', 'linear')
ylim([0 3.5e5])
yticks([0,50000,100000,150000,200000,250000,300000])

ax = gca;
ax.YAxis.Exponent = 5;
ylabel('Cooling rate Distribution (K min^{-1})')
xlabel('')
box on
axis square
hold off

legend({ ...
    '$\dot{m}_{LN_2} = 269\ \mathrm{g\ min^{-1}}$', ...
    '$\dot{m}_{LN_2} = 537\ \mathrm{g\ min^{-1}}$', ...
    '$\dot{m}_{LN_2} = 808\ \mathrm{g\ min^{-1}}$' ...
    }, ...
    'FontSize', 20, 'Interpreter', 'Latex')
