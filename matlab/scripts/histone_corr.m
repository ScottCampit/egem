%% histone_corr calculates the correlation value between various histone 
...markers and the metabolic flux obtained from the iMAT algorithm
function [rho, pval] = histone_corr(model, compartment, mode, epsilon, epsilon2, rho, kappa, minfluxflag)
%% INPUTS:
    % model: Initial genome scale model
    % compartment: Subcellular compartment of interest
    % mode: for constrain flux regulation
    % epsilon: for constrain flux regulation
    % epsilon2: obj coef weight for reaction of interest
    % rho: for constrain flux regulation
    % kappa: for constrain flux regulation
    % minfluxflag: for parsimonious flux balance analysis
%% OUTPUTS:
    % correl: correlation values associated with each histone marker/rxn 
    % pval: the p-value associated with correl
    % cell_line_match: cell lines that matched between gene expression and
    % proteomics
    % heatmap that visualizes the correlation values
%% histone_corr
load ./../vars/supplementary_software_code celllinenames_ccle1 ccleids_met ccle_expression_metz 
% contains CCLE cellline names for gene exp, enzymes encoding specific metabolites,
...and gene expression data (z-transformed)

% New variables
path = './../new_var/';
vars = {...
    [path 'h3_ccle_names.mat'], [path 'h3_marks.mat'],...
    [path 'h3_media.mat'], [path 'h3_relval.mat']...
    }; % contains CCLE cellline names for H3 proteomics, corresponding
...marker ids, growth media, relative H3 proteomics
for kk = 1:numel(vars) 
    load(vars{kk})
end

% impute missing values using KNN. Maybe try other functions if the results
% look like shit. 
%h3_relval = knnimpute(h3_relval);      Error: kmnimpute does not work on
...double data type
h3_relval = fillmissing(h3_relval, 'nearest');  % no error

% old variables but slightly modified
path = './../vars/';
vars = {[path 'metabolites.mat']};
for kk = 1:numel(vars)  
    load(vars{kk})
end

idx = find(ismember(h3_ccle_names, celllinenames_ccle1));
tmp = length(idx);

% get relevant data
h3_relval = h3_relval(idx, :);
h3_ccle_names = h3_ccle_names(idx,1);

idx = find(ismember(celllinenames_ccle1, h3_ccle_names));
for i = 1:tmp
    model2 = model;

    % Takes in genes that are differentially expressed from Z-score scale
    ongenes = unique(ccleids_met(ccle_expression_metz(:,idx(i)) >= 2));
    offgenes = unique(ccleids_met(ccle_expression_metz(:,idx(i)) <= -2));
    
    % Keep the genes that match with the metabolic model.
    ongenes = intersect(ongenes, model2.rxns);
    offgenes = intersect(offgenes, model2.rxns);
    
    % set medium conditions unique to each cell line
    model2 = media(model2, h3_media(i));
    disp(i)
    
    % Get the reactions corresponding to on- and off-genes
    [~,~,onreactions,~] =  deleteModelGenes(model2, ongenes);
    [~,~,offreactions,~] =  deleteModelGenes(model2, offgenes);

    % Get the flux redistribution values associated with different media component addition and deletion
<<<<<<< HEAD
    %[fluxstate_gurobi, grate_ccle_exp_dat(i,1), solverobj_ccle(i,1)] =...
    %   constrain_flux_regulation(model2, onreactions, offreactions,...
    %    kappa, rho, epsilon, mode, [], minfluxflag);

    % Add demand reactions from the metabolite list to the metabolic model
    %for m = 1:length(metabolites(:,1))
    %    tmpname = char(metabolites(m,1));
        
    % limit methionine levels for all reactions in the model; it has to be non limiting
    model3 = model2;
    [ix, pos]  = ismember({'EX_met_L(e)'}, model3.rxns);
    model3.lb(pos) = -0.5;
    rxnname = char(metabolites(:, 1)); % reaction positions of interest
    rxnpos = [find(ismember(model3.rxns, rxnname))];
    model3.c(rxnpos) = epsilon2(:,1); 

    % get the flux values from iMAT
    [fluxstate_gurobi] =  constrain_flux_regulation(model3,...
        onreactions, offreactions, kappa, rho, epsilon, mode ,[],...
        minfluxflag);
    grate_ccle_exp_dat(:,i) = fluxstate_gurobi(rxnpos);
    %model3.c(rxnpos) = 0; 
    
end

% Calculate the pearson correlation coefficients for every demand reaction
% w.r.t to H3 expression
grate_ccle_exp_dat = grate_ccle_exp_dat';
[rho, pval] = corr(grate_ccle_exp_dat, h3_relval);
rxns = metabolites(:,3);
=======
    [fluxstate_gurobi, grate_ccle_exp_dat(i,1), solverobj_ccle(i,1)] = ...
        constrain_flux_regulation(model2, onreactions, offreactions,...
        kappa, rho, epsilon, mode, [], minfluxflag);
%% I created this section, because it's before the printing of numbers 2-885
    % Add demand reactions from the metabolite list to the metabolic model
    for m = 1:length(metabolites(:,1))  
        %tmp_met = char(metabolites(m,2));
        %tmp = [tmp_met '[' compartment '] -> '];
        tmpname = char(metabolites(m,1));
        
        % limit methionine levels for all reactions in the model; it has to be non limiting
        model3 = model2;
        [~, pos]  = ismember({'EX_met_L(e)'}, model3.rxns);
        model3.lb(pos) = -0.5;
        %model3.c(3743) = 0;
        rxnpos = find(ismember(model3.rxns, tmpname));
        
        % LF created an if-branch
        if rxnpos ~= []
            model3.c(rxnpos) = epsilon2;
            
            % get the flux values from iMAT
            [fluxstate_gurobi] =  constrain_flux_regulation(model3,...
                onreactions, offreactions, kappa, rho, epsilon, mode ,[],...
                minfluxflag);
            grate_ccle_exp_dat(i,1+m) = fluxstate_gurobi(rxnpos);
            model3.c(rxnpos) = 0;
        end
% =======
%         rxnpos = [find(ismember(model3.rxns, tmpname))];
%         model3.c(rxnpos) = epsilon2; 
% 
%         % get the flux values from iMAT
%         [fluxstate_gurobi] =  constrain_flux_regulation(model3,...
%             onreactions, offreactions, kappa, rho, epsilon, mode ,[],...
%             minfluxflag);
%         grate_ccle_exp_dat(i,1+m) = fluxstate_gurobi(rxnpos);
%         model3.c(rxnpos) = 0; 
% >>>>>>> 5c15a54a070a7bdf1d569795eb445600f9381482
    end
end

% Calculate the pearson correlation coefficients for every demand reaction
[row, col] = size(grate_ccle_exp_dat);

test = interp1(1:numel(grate_ccle_exp_dat), grate_ccle_exp_dat,...
    linspace(1, numel(grate_ccle_exp_dat), numel(h3_relval)));
% LF: For each gene, calculate correl & pval across all cell lines
for i = 1:length(h3_relval(:,1))
    [correl, pval] = corr(grate_ccle_exp_dat(i,:), h3_relval(i,:));
end
% LF: For each cell line, calculate correl and pval between flux data and
% expression level for all genes?

%% I created this section. (I did not write new code)
c=zeros(length(h3_ccle_names), size(h3_relval,2));
for i = 1:length(h3_ccle_names)
    tmp1 = grate_ccle_exp_dat(i,:);
    tmp2 = h3_relval(i,:);
    [correl, pval] = corr(tmp1, tmp2);
    c(i,:)=correl;
    %tmp3 = diag(correl);        % Why? What used for?
end

% correl is only the correlation values for the last cell line. I commented
% below out. 
%correl = correl';

% Make a heatmap of correlation coefficients versus histone markers for
% several demand reactions
rxns = metabolites(:,1);

fig = figure;
%heatmap(correl)
heatmap(c)
% =======
% % w.r.t to H3 expression
% [rho, pval] = corr(grate_ccle_exp_dat, h3_relval);
% rxns = metabolites(:,3);
% rxns = [{'Biomass'}; rxns];

%% Save data in Excel
% filename1 = './../tables/eGEMn_prot_stats.xlsx';
% colname = rxns';
% rowname = h3_marks;
% 
% % Rho
% xlswrite(filename1, colname, string(epsilon2), 'B1:AQ1');
% xlswrite(filename1, rowname, string(epsilon2), 'A2:A22');
% xlswrite(filename1, rho, string(epsilon2), 'B2:U22');
% 
% % P-value
% xlswrite(filename1, colname, string(epsilon2), 'B24:AQ24');
% xlswrite(filename1, rowname, string(epsilon2), 'A25:A45');
% xlswrite(filename1, pval, string(epsilon2), 'B25:U45');
% 
% %% Make Figures
% 
% ax = gca;
% ax.Colormap = parula;
% ax.XData = h3_marks;
%<<<<<<< HEAD
ax.YData = h3_ccle_names;
ax.Title = 'Histone markers and metabolic flux correlation';
xlabel(ax, 'Histone Markers');
ylabel(ax, 'Cancer Cell Lines (CCLE)');
%saveas(fig, ['./../figures/fig/histone_mark_corr.fig']); %no "fig" folder. I saved it to "figures" folder
%saveas(fig, './../figures/histone_mark_corr.fig');
%=======
ax.YData = rxns;
xlabel(ax, 'Histone Markers');
ylabel(ax, 'Demand Reactions');
base = strcat('./../figures/corr/histone_mark_corr_', string(epsilon2)); 
fig_str = strcat(base, '.fig');
%saveas(fig, fig_str);
%>>>>>>> 5c15a54a070a7bdf1d569795eb445600f9381482
end 