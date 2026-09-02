function fig4_voag()
% FIG4_VOAG  Reproduce VOAG cooling-rate figure (MATLAB)

%% ----- Styling (journal-ready) -----
set(groot,'defaultAxesFontName','Helvetica');
set(groot,'defaultTextFontName','Helvetica');
set(groot,'defaultLegendFontName','Helvetica');
set(0,'defaultTextInterpreter','tex');
set(0,'defaultAxesFontSize',16);
try
    set(0,'defaultAxesLabelFontSizeMultiplier',1.2);
    set(0,'defaultAxesTitleFontSizeMultiplier',1.35);
catch
end
set(0,'defaultLineLineWidth',1.2);
set(0,'defaultAxesLineWidth',1.0);
set(0,'defaultAxesTickLength',[0.012 0.012]);

%% ----- Helpers (inline) -----
pl_hz_to_mL_hr = @(VpL,f) (VpL.*f.*60./1e9.*60); % (pL/Hz)→mL/h
Cs_to_Cmin     = @(x) x.*60;                     % °C/s→°C/min
D_voag         = @(Q,f,C) (6.*Q.*C./(pi.*f)).^(1/3);   % VOAG drop diameter

% Cooling (convective) [K/s]
cooling_conv = @(D,v) arrayfun(@(Di) local_cooling_conv(Di,v), D);

% Latent enhancement Phi(D,v)
Phi = @(D,v,M3,M4,M5,rho_ln2,h_vap,U_rel,dT,eta_eff) ...
    arrayfun(@(Di) local_Phi(Di,v,M3,M4,M5,rho_ln2, ...
    h_vap,U_rel,dT,eta_eff), D);

% Total cooling [K/s]
cooling_total = @(D,v,M3,M4,M5,rho_ln2,h_vap,U_rel,dT,eta_eff) ...
    cooling_conv(D,v) .* ...
    (1 + Phi(D,v,M3,M4,M5,rho_ln2,h_vap,U_rel,dT,eta_eff));

%% ----- Constants / LN2 latent model constants -----
rho_ln2 = 807;     % kg/m^3 (liquid N2)
h_vap   = 2e5;     % J/kg (effective latent)
dT      = 196;     % K

% LN2 droplet distribution parameters (fixed)
D_g_ln2   = 500e-6;   % m geometric mean
sigma_ln2 = 1.8;      % geometric std dev
lnsig2 = log(sigma_ln2)^2;

% Helper to compute lognormal moments M3-M5 for a given Ntot
logn_moments = @(Ntot) deal( ...
    Ntot*D_g_ln2^3*exp((3^2)*lnsig2/2), ...
    Ntot*D_g_ln2^4*exp((4^2)*lnsig2/2), ...
    Ntot*D_g_ln2^5*exp((5^2)*lnsig2/2) );

%% ----- Experimental scatter points -----
akiyama = [ pl_hz_to_mL_hr(200,50), Cs_to_Cmin(7200);  ...
            pl_hz_to_mL_hr( 40,50), Cs_to_Cmin(22000); ...
            pl_hz_to_mL_hr( 40,50), Cs_to_Cmin(37000) ];
demirci = [ 9e-3*60, 50000;  7.5*60, 1800 ];
devries = [ 4*60, 9600 ];
zhan    = [ 0.6*60, 1.75e4;  2.4*60, 9000 ];
your    = [ 0.6*60, 1.0e5;   0.6*60, 1.3e5;  0.6*60, 1.6e5; ...
            3.8*60, 7.0e4;   2.2*60, 7.0e4 ];
no_coflow = [ 2.2*60, 1.5e4 ];

pts_all = [
    add_group(akiyama, 'Akiyama et al. (conduction)')
    add_group(demirci, 'Demirci et al. (convection)')
    add_group(devries, 'de Vries et al. (convection)')
    add_group(zhan,    'Zhan et al. (conduction)')
    add_group(your,    'This work: LN_2 co-flow (convection)')
    add_group(no_coflow, 'This work: no LN_2 co-flow (convection)')
];

%% ----- Flow axis & VOAG droplet size -----
flow_mLph = logspace(-2.5, 3, 400);     % mL/h  (match python density)
flow_m3s  = flow_mLph * 1e-6 / 3600;    % m^3/s
f_Hz      = 5000;
C_param   = 1;
D = D_voag(flow_m3s, f_Hz, C_param);    % m

%% ----- shaded band -----
v_air  = 0.02;   % m/s   (fixed)
U_rel  = 5.0;    % m/s   (fixed)
N_list = [1e2, 3e2, 1e3, 3e3, 1e4, 3e4, 1e5, 2e5];
eta_eff_list = [0.01, 1.0];

phi_curves = zeros(numel(N_list)*numel(eta_eff_list), numel(D));
curve_idx = 0;

for k = 1:numel(N_list)
    [M3, M4, M5] = logn_moments(N_list(k));

    for j = 1:numel(eta_eff_list)
        curve_idx = curve_idx + 1;
        phi_curves(curve_idx,:) = cooling_total( ...
            D, v_air, M3, M4, M5, rho_ln2, h_vap, ...
            U_rel, dT, eta_eff_list(j)) * 60;
    end
end
phi_min = min(phi_curves, [], 1);
phi_max = max(phi_curves, [], 1);

%% ----- Plot -----
figure('Color','w','Position',[100 100 800 540]); hold on;


% Colors/markers per group 
groups = {'Akiyama et al. (conduction)','Demirci et al. (convection)','de Vries et al. (convection)', ...
          'Zhan et al. (conduction)','This work: LN_2 co-flow (convection)','This work: no LN_2 co-flow (convection)'};
mk = containers.Map;
mk('Akiyama et al. (conduction)')   = 'o';
mk('Demirci et al. (convection)')   = 'v';
mk('de Vries et al. (convection)')  = 'x';
mk('Zhan et al. (conduction)')      = 'd';
mk('This work: LN_2 co-flow (convection)')        = 'p';
mk('This work: no LN_2 co-flow (convection)')     = 'h';

cols = lines(numel(groups));
cmap = containers.Map(groups, mat2cell(cols, ones(1,numel(groups)), 3));

% Scatter points
for gi = 1:numel(groups)
    gname = groups{gi};
    mask  = strcmp(pts_all(:,3), gname);
    xg = cell2mat(pts_all(mask,1));
    yg = cell2mat(pts_all(mask,2));
    c  = cmap(gname);

    h = loglog(xg, yg, mk(gname), ...
        'MarkerFaceColor', c, 'MarkerEdgeColor', c, ...
        'MarkerSize', 10, 'LineStyle', 'none');
    set(h, 'DisplayName', gname);
end

fill_between_loglog(flow_mLph, phi_min, phi_max, [70 130 180]/255, 0.40);

fit_y = 9.8e4 .* (flow_mLph .^ (-0.51));
plot(flow_mLph, fit_y, '--', 'Color','k', 'LineWidth', 1.4, ...
     'DisplayName', 'Literature cooling rate trendline:  CR = 9.8e+04  Q^{-0.51}');


set(gca,'XScale','log','YScale','log');
xlabel('Volumetric flow rate (mL / h)', 'FontSize',20);
ylabel('Cooling rate (K min^{-1})', 'FontSize',20);
xlim([5e-3, 1e3]);
ylim([1e3, 5e6]);
grid off; box on;

legend('Location','southwest'); legend boxoff;

% Tight layout & save
set(gca,'LooseInset', max(get(gca,'TightInset'), 0.02*[1 1 1 1]));
try
    exportgraphics(gcf, 'Figure_1.png', 'Resolution', 800);
catch
    print(gcf,'-dpng','-r800','Figure_1.png');
end

end

%% ===== Local helper functions =====
function out = local_cooling_conv(D, v)
% Convective cooling rate [K/s] for droplet of diameter D at speed v
    rho_g = 1.2;
    rho_D = 1000;
    k = 0.026;
    mu = 1.76e-5;
    Pr = 0.72;

    h = h_coeff_scalar(D, v, rho_g, k, mu, Pr);
    A = pi*D^2;
    m = rho_D*(pi/6)*D^3;
    cp = 4184;
    dT = 273-77;

    out = h*A*dT/(m*cp);
end

function h = h_coeff_scalar(D, v, rho, k, mu, Pr)
% External flow over small sphere (Ranz–Marshall correlation)
    Re = rho*v*D/mu;
    Nu = 2 + 0.6*sqrt(Re)*Pr^(1/3);
    h  = Nu*k/D;
end

function out = local_Phi(D, v, M3, M4, M5, ...
    rho_ln2, h_vap, U_rel, dT, eta_eff)
% Dimensionless latent enhancement factor
    h = h_coeff_scalar(D, v, 1.2, 0.026, 1.76e-5, 0.72);
    term = M3 + 2*M4/D + M5/(D^2);
    out = eta_eff * ...
        (pi*rho_ln2*U_rel*h_vap)/(24*h*dT) * term;
end

function tbl = add_group(arr, name)
    n = size(arr,1);
    tbl = [ num2cell(arr(:,1)), num2cell(arr(:,2)), repmat({name}, n, 1) ];
end

function fill_between_loglog(x, y1, y2, color, alpha, dispname)
    xx = [x, fliplr(x)];
    yy = [y1, fliplr(y2)];
    p = fill(xx, yy, color, 'LineStyle','none', 'FaceAlpha', alpha);
    set(get(get(p,'Annotation'),'LegendInformation'), 'IconDisplayStyle', 'off');
    if nargin >= 6 && ~isempty(dispname)
        plot(NaN, NaN, 's', 'MarkerFaceColor', color, 'MarkerEdgeColor', color, ...
             'MarkerSize', 8, 'DisplayName', dispname);
    end
end
