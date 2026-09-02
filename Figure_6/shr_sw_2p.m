
% Shrink-swell simulation (2-parameter transport formalism)
% Last edited 2023-03-26
% Nikolas Zuchowicz zucho008@umn.edu

% Mainly based on Kleinhans 1998
% https://doi.org/10.1006/cryo.1998.2135

function output = shr_sw_2p(v_bf,V_o,L_pX,P_sX,T,Me_sX,Me_nX,Mi_soX,Mi_noX,Vbar_sX,t_max,t_step)

% INPUT CONSTANTS
% X denotes conventional units that will be rescaled for uniformity

% v_bf                          % [dimless]         Bound volume fraction
% L_pX                          % [um/min/atm]      Hydraulic conductivity
% P_sX                          % [cm/min]          Solute permeability
% T                             % [K]               Temperature
% Me_sX                         % [mol/kg]          External permeating solute osmolality
% Me_nX                         % [mol/kg]          External non-permeating solute osmolality

R           = 8.2057E13;        % [um^3∙atm/mol/K]  Gas constant
% Vbar_watX                     % [L/mol]           Partial molar volume of water (with glycerol: Egorov 2013)
% Vbar_sX                       % [L/mol]           Partial molar volume of glycerol (with water: Egorov 2013)

% t_max                         % [s]               Run time of simulation
% t_step                        % [s]               Time step length


% INPUT INITIAL CONDITIONS

% V_o                           % [um^3]            Initial cell volume
% Mi_soX                        % [mol/kg]          Initial internal permeating solute osmolality
% Mi_noX                        % [mol/kg]          Initial internal non-permeating solute osmolality


% CALCULATED CONSTANTS

L_p         = L_pX/60;          % [um/s/atm]        Hydraulic conductivity
P_s         = P_sX/60*1E4;      % [um/s]            Solute permeability
%Vbar_wat    = Vbar_watX*1E15;   % [um^3/mol]        Partial molar volume of water
Vbar_s      = Vbar_sX * 1E15;   % [um^3/mol]        Partial molar volume of permeating solute
Me_s        = Me_sX / 1E15;     % [mol/um^3]        External permeating solute osmolality
Me_n        = Me_nX / 1E15;     % [mol/um^3]        External non-permeating solute osmolality
Mi_so       = Mi_soX / 1E15;    % [mol/um^3]        Initial internal permeating solute osmolality
Mi_no       = Mi_noX / 1E15;    % [mol/um^3]        Initial internal non-permeating solute osmolality

V_b         = V_o * v_bf;       % [um^3]            Bound volume
A           = (36*pi)^(1/3) * V_o^(2/3);
                                % [um^2]            Cell area


% CALCULATED VARIABLES

n           = 1+t_max/t_step;   % [dimless]         Number of time steps
t           = 0:t_step:t_max;   % [s]               Time vector
V_w         = zeros(1,n);       % [um^3]            Internal water volume
V_w(1,1)    = V_o * (1 - v_bf);
Mi_s        = zeros(1,n);       % [mol/kg]          Internal permeating solute osmolality
Mi_s(1,1)   = Mi_so;
Mi_n        = zeros(1,n);       % [mol/kg]          Internal non-permeating solute osmolality
Mi_n(1,1)   = Mi_no;
N_s         = zeros(1,n);       % [mol]             Internal osmoles of permeating solute
N_s(1,1)    = Mi_so;

% SIMULATION

for i = 2:n
   % Increment the two governing equations
   V_w(1,i) = V_w(1,i-1) - L_p * A * R * T * (Me_s + Me_n - Mi_s(1,i-1) - Mi_n(1,i-1)) * t_step;
   N_s(1,i) = N_s(1,i-1) + P_s * A * (Me_s - Mi_s(1,i-1)) * t_step;

   % Update subsidiary equations
   Mi_s(1,i) = N_s(1,i) / V_w(1,i);
   Mi_n(1,i) = Mi_n(1,1) * (V_w(1,1) / V_w(1,i));
end


% WRAP-UP AND OUTPUT

tX          = t / 60;           % [min]             Time in minutes
Me          = Me_s + Me_n;      % [mol/um^3]        External total osmolality
MeX         = Me * 1E15;        % [mol/kg]          External total osmolality
Mi          = Mi_s + Mi_n;      % [mol/um^3]        Internal total osmolality
MiX         = Mi * 1E15;        % [mol/kg]          Internal total osmolality
Mi_sX       = Mi_s * 1E15;      % [mol/kg]          Internal total osmolality
Mi_nX       = Mi_n * 1E15;      % [mol/kg]          Internal total osmolality
V_s         = N_s * Vbar_s;     % [um^3]            Internal permeating solute volume at t
V_c         = V_w + V_s + V_b;  % [um^3]            Total cell volume at t
v_n         = V_c./V_o;         % [dimless]         Normalized cell volume at t

% Vectors
output.t    = t;
output.tX   = tX;
output.V_c  = V_c;
output.v_n  = v_n;
output.V_w  = V_w;
output.V_s  = V_s;
output.N_s  = N_s;
output.Mi   = Mi;
output.MiX  = MiX;
output.Mi_s = Mi_s;
output.Mi_sX= Mi_sX;
output.Mi_n = Mi_n;
output.Mi_nX= Mi_nX;

% Scalars
output.Me   = Me;
output.MeX  = MeX;

end
