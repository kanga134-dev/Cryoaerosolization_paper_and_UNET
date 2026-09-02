% Interfacial stresses vs. relaxation time with Weber transition band
clear; clc; close all
set(groot,'defaultAxesFontSize',20);
set(groot,'defaultTextFontSize',20);
set(groot,'defaultAxesFontName','Helvetica');
set(groot,'defaultTextFontName','Helvetica');
set(groot,'defaultLegendFontName','Helvetica');

% ---------------- Inputs ----------------
Q_a    = linspace(0,5,200);      % dispersion air flow [L/min]
Da     = 1e-3;                   % dispersion-air aperture diameter [m]
d_drop = 190e-6;                 % droplet diameter [m] (≈ 1.9*Do for Do = 100 µm)
Cd     = 0.8;                    % drag coefficient (order unity)

% Aerodynamic / Weber params
sigma  = 0.050;                  % surface tension [N/m]
k_slip = 1.0;                    % initial slip fraction: U_slip0 = k_slip * U_a

% Upper-bound (high-Re friction) coefficient
Cf_mid = 0.015;                  % skin-friction coefficient (order 1e-2)

% Liquid properties for Oh-based transition guidance
mu_liq  = 9.1e-3;                % liquid viscosity [Pa·s] (e.g., 9.1 cP PG)
rho_liq = 1000;                  % liquid density [kg/m^3]

% ---------------- Constants ----------------
Aa      = pi*(Da/2)^2;           % aperture area [m^2]
Qa_m3s  = Q_a/1000/60;           % [L/min] -> [m^3/s]
Ua      = Qa_m3s ./ Aa;          % air speed [m/s]
mu_air  = 1.8e-5;                % air viscosity [Pa·s]
rho_air = 1.2;                   % air density [kg/m^3]

% ---------------- Base quantities ----------------
% Lower-bound interfacial shear (viscous, uses peak slip ~ U_a at exit)
tau_lower = mu_air .* Ua ./ d_drop;                   % τ_i lower [Pa]
p_dyn     = 0.5 * rho_air .* Ua.^2;                   % aerodynamic normal stress [Pa]
tau_rel   = (4/3) * (rho_liq/rho_air) .* (d_drop./(Cd*Ua));  % relaxation time [s]

% Upper-bound (high-Re) interfacial shear
tau_upper_fric = 0.5 * rho_air .* Ua.^2 * Cf_mid;     % τ_i upper (friction) [Pa]

% Slip-based Weber number (worst case: U_slip0 = k_slip * U_a)
Uslip0 = k_slip .* Ua;
We     = rho_air .* (Uslip0.^2) .* d_drop ./ sigma;

% ---------------- Transition window (start/end) ----------------
Oh = mu_liq / sqrt(rho_liq * sigma * d_drop);
We_end   = 12 * (1 + 0.2 * Oh^0.8);   % ~breakup onset (≈ 12 for low–moderate Oh)
We_start = 0.65 * We_end;             % deformation becomes significant (≈ 8)

% Convert We thresholds to Q_a (L/min) for a vertical band
Ua_crit_start = sqrt(We_start * sigma/(rho_air*d_drop)) / max(k_slip,eps);
Ua_crit_end   = 100*sqrt(We_end   * sigma/(rho_air*d_drop)) / max(k_slip,eps);
Qa_shade_start = Ua_crit_start * Aa * 60*1000;   % -> L/min
Qa_shade_end   = max(Q_a);   % for plot shading of high We regime -> L/min

% ---------------- Build upper curve with smooth blending ----------------
% Smoothstep weight w in [0,1] over We in [We_start, We_end]
x = (We - We_start) ./ max(We_end - We_start, eps);
x = min(max(x,0),1);                      % clamp to [0,1]
w = x.^2 .* (3 - 2*x);                    % C1 smoothstep

tau_upper = tau_lower;                     % default: lower = upper
mask_blend = (We >= We_start) & (We < We_end);
mask_high  = (We >= We_end);

tau_upper(mask_blend) = (1 - w(mask_blend)).*tau_lower(mask_blend) + ...
                         w(mask_blend).*tau_upper_fric(mask_blend);
tau_upper(mask_high)  = tau_upper_fric(mask_high);

% Shaded fill between lower & upper only from the bifurcation onward
mask_shade = (We >= We_start) & (Ua > 0);  % avoid log(0) at Qa=0
Q_shade    = Q_a(mask_shade);
y_lower    = tau_lower(mask_shade);
y_upper    = tau_upper(mask_shade);

% Ensure upper >= lower (safety)
swap = y_upper < y_lower;
tmp  = y_upper(swap); y_upper(swap) = y_lower(swap); y_lower(swap) = tmp;

% ---------------- Plot ----------------
figure('Color','w');

yyaxis left; cla; hold on

% 1) Vertical transition band (We_start..We_end), drawn behind
yl_for_band = [1 1e4];  %
band = fill([Qa_shade_start Qa_shade_end Qa_shade_end Qa_shade_start], ...
            [yl_for_band(1) yl_for_band(1) yl_for_band(2) yl_for_band(2)], ...
            [0.8 0.8 0.8], 'EdgeColor','none', 'FaceAlpha',0.25, ...
            'HandleVisibility','off');
uistack(band,'bottom');

% 2) Shaded region between lower and (blended/upper) curve starting at bifurcation
if ~isempty(Q_shade)
    fb = fill([Q_shade, fliplr(Q_shade)], [y_lower, fliplr(y_upper)], ...
              [0.30 0.60 1.00], 'FaceAlpha',0.35, ...
              'EdgeColor','none', 'HandleVisibility','on');
    uistack(fb,'bottom');
else
    fb = [];
end

% Curves
p1 = plot(Q_a, tau_lower, 'Color',[0.30 0.60 1.00],'LineStyle','-',  'LineWidth', 2);      % τ_i lower (viscous)
p2 = plot(Q_a, p_dyn,'Color',[0.30 0.60 1.00],'LineStyle','-.', 'LineWidth', 2);      % p_dyn
p3 = plot(Q_a, tau_upper, 'Color',[0.30 0.60 1.00],'LineStyle','-', 'LineWidth', 2);      % τ_i upper (blend → friction)

set(gca,'YScale','log'); ylabel('Stress [Pa]');
axis([0 5 1 1e4]); grid on

yyaxis right                    
p4 = plot(Q_a, 1e3*tau_rel, 'r--', 'LineWidth', 2);    % τ_rel
ylabel('Relaxation Time [ms]');
axis([0 5 0 25]);

xlabel('Dispersion Air Flow [L/min]');

% Legend (minimal, no extra reference lines)
    legend([p1 p2 p4], ...
       {'$\tau_i$', '$p_{\mathrm{dyn}}$', '$\tau_{\mathrm{rel}}$'}, ...
       'Interpreter','latex','Location','northwest');

box on
axis square
