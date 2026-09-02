clc
close all
clear

load("figure_plot_data.mat")

set(groot, 'defaultTextInterpreter', 'tex');
set(groot, 'defaultAxesTickLabelInterpreter', 'tex');
set(groot, 'defaultLegendInterpreter', 'tex');
set(groot, 'defaultAxesFontSize', 20);
set(groot, 'defaultTextFontSize', 20);
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

color_1 = okabeIto(1,:);
color_2 = okabeIto(3,:);


model = @(p,c) 1-exp(-p(1)*exp(-p(2)*c.^p(3)));
c_no_spray_fit = linspace(0,.25,1000);
c_no_plate_precool_fit = linspace(0,.25,1000);
f_no_spray_fit = model(fit_parameters_no_spray,c_no_spray_fit);
f_no_plate_precool_fit = model(fit_parameters_no_plate_precool,c_no_plate_precool_fit);

sd_no_spray = transitionConcentrationSD(c_no_spray_fit, f_no_spray_fit);
sd_no_plate_precool = transitionConcentrationSD( ...
    c_no_plate_precool_fit, f_no_plate_precool_fit);

figure(1)
title('a', 'Interpreter', 'latex', 'FontSize', 12)

subplot(1,2,1)
hold on

scatter(c_no_plate_precool, 1-f_no_plate_precool, ...
        10, color_2, "filled", 'Marker', 'd')
scatter(c_no_spray, 1-f_no_spray, ...
        10, color_1, "filled", 'Marker', 'd')

x_add = linspace(.25,.3);
y_add = zeros(length(x_add),1)';
plot([c_no_plate_precool_fit,x_add], ...
     [f_no_plate_precool_fit,y_add], ...
     "Color", color_2, LineWidth=1.5)

dx = sd_no_plate_precool;
fLo = model(fit_parameters_no_plate_precool,c_no_plate_precool_fit+dx);
fHi = model(fit_parameters_no_plate_precool,c_no_plate_precool_fit-dx);
fLo = max(fLo,0);
fHi = min(fHi,1);
patch(real([c_no_plate_precool_fit fliplr(c_no_plate_precool_fit)]), ...
      real([fLo fliplr(fHi)]), ...
      color_2, 'EdgeColor', 'none', 'FaceAlpha', 0.25);

dx = sd_no_spray;
fLo = model(fit_parameters_no_spray,c_no_spray_fit+dx);
fHi = model(fit_parameters_no_spray,c_no_spray_fit-dx);
fLo = max(fLo,0);
fHi = min(fHi,1);
patch(real([c_no_spray_fit fliplr(c_no_spray_fit)]), ...
      real([fLo fliplr(fHi)]), ...
      color_1, 'EdgeColor', 'none', 'FaceAlpha', 0.25);

plot([c_no_spray_fit,x_add], [f_no_spray_fit,y_add], ...
     "Color", color_1, LineWidth=1.5)

axis square
axis([.075 .28 -.05 1.15])
ylabel('Crystalized Fraction')
xlabel('EtOH Concentration (w/w)')
xticks([0,.05,.1,.15,.2,.25])
box on
grid on

subplot(1,2,2)
hold on

CCR_no_plate = 470209*exp(-c_no_plate_precool_fit*100*.40)*60;
x_no_plate_Fit = CCR_no_plate;
pdf_raw_no_plate_Fit = -[0 diff(f_no_plate_precool_fit)];
area_raw_no_plate_Fit = trapz(x_no_plate_Fit, pdf_raw_no_plate_Fit);
pdf_norm_no_plate_Fit = pdf_raw_no_plate_Fit/area_raw_no_plate_Fit;

CCR_no_spray = 470209*exp(-c_no_spray_fit*100*.406)*60;
x_no_spray_Fit = CCR_no_spray;
pdf_raw_no_spray = -[0 diff(f_no_spray_fit)];
area_raw_no_spray = trapz(x_no_spray_Fit, pdf_raw_no_spray);
pdf_no_spray_Fit = pdf_raw_no_spray/area_raw_no_spray;

sampleFromPDF = @(x,cum_pdf,N) interp1(cum_pdf,x,rand(N,1),'linear','extrap');
N = 1000000;

cum_sum_no_spray = cumtrapz(x_no_spray_Fit,pdf_no_spray_Fit);
cum_sum_no_spray_trimmed_I = find((cum_sum_no_spray<.99)&(cum_sum_no_spray>.02));
cum_sum_no_spray_trimmed = cum_sum_no_spray(cum_sum_no_spray_trimmed_I);
CR_no_spray_trimmed = x_no_spray_Fit(cum_sum_no_spray_trimmed_I);

cum_sum_no_plate = cumtrapz(x_no_plate_Fit,pdf_norm_no_plate_Fit);
cum_sum_no_plate_trimmed_I = find((cum_sum_no_plate<.99)&(cum_sum_no_plate>.02));
cum_sum_no_plate_trimmed = cum_sum_no_plate(cum_sum_no_plate_trimmed_I);
CR_no_plate_trimmed = x_no_plate_Fit(cum_sum_no_plate_trimmed_I);

rng(1)
samples_no_spray = sampleFromPDF(CR_no_spray_trimmed, cum_sum_no_spray_trimmed, N);
samples_no_plate = sampleFromPDF(CR_no_plate_trimmed, cum_sum_no_plate_trimmed, N);

data = [samples_no_spray, samples_no_plate];

ylim([-50000 2*10^5])
set(gca, 'YScale', 'linear');
yticks([0,50000,100000,150000,200000,250000])

vp = violinplot(data);
vp(1).FaceColor = color_1;
vp(2).FaceColor = color_2;
vp(1).FaceAlpha = .5;
vp(2).FaceAlpha = .5;

set(gca, 'XTick', [])
grid on

b = boxchart(data);
b.MarkerStyle = 'none';
b.BoxFaceColor = [0 0 0];
b.BoxFaceAlpha = 0.25;
b.WhiskerLineColor = [0 0 0];

ylabel('Cooling Rate Distribution (K min^{-1})', ...
       'Interpreter', 'tex', 'FontSize', 20)
legend('No Pre-cooling (100\mum orifice)', ...
       'Pre-cooling (100 \mum orifice)', ...
       'Interpreter', 'tex', 'FontSize', 20, 'Location', 'Southeast')
box on
axis square
hold off

ax = gca;
ax.YAxis.Exponent = 5;

function sigma = transitionConcentrationSD(c, f)
    weights = max(-[0 diff(f)], 0);
    weights = weights/sum(weights);
    mean_c = sum(c.*weights);
    sigma = sqrt(sum(weights.*(c-mean_c).^2));
end
