%% Code to run modules
initCobraToolbox;
changeCobraSolver('gurobi');

% load different models
load model % eGEM model

load recon1
model = metabolicmodel;

load supplementary_software_code acetylation_model
model = acetylation_model; %Shen et al., 2019

%% Correlation values between histone markers and metabolic flux
%histone_corr(model, 'amet', [], 'n', 1, 1E-2, 1, 1E-3, 0);
%rxnpos  = [find(ismember(model.rxns, 'EX_KAC'));];

%% Heatmap of metabolic reactions vs excess/depletion of medium coponents

% Use params for testing 
compartment = 'n';
epsilon2 = 1E-3;
scaling = [];

[excess_flux, depletion_flux, excess_redcost, depletion_redcost,...
    excess_shadow, depletion_shadow] = make_heatmap(model, 'n',...
    epsilon2, []);

% input filename for saving
filename = 

epsilon2 = [1E-4, 1E-3, 1E-2, 0.1, 1, 1E4];
for n=1:length(epsilon2)
    [excess_flux, depletion_flux, excess_redcost, depletion_redcost,...
    excess_shadow, depletion_shadow] = make_heatmap(model, 'n',...
    epsilon2, []);
    %filename = 'acetylationmodel-nucleus.xlsx';
    %xlswrite(filename, excess_flux, string(epsilon2(n)), 'A1:S50');
    %xlswrite(filename, depletion_flux, string(epsilon2(n)), 'V1:AR50');
    %xlswrite(filename, excess_redcost, string(epsilon2(n)), 'A52:S102');
    %xlswrite(filename, depletion_redcost, string(epsilon2(n)), 'V52:AR102');
    %xlswrite(filename, excess_shadow, string(epsilon2(n)), 'A104:S154');
    %xlswrite(filename, depletion_shadow, string(epsilon2(n)), 'V104:AR154');
end