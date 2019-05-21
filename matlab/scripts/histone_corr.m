%% histone_corr calculates the correlation value between various histone markers and the metabolic flux obtained from the iMAT algorithm
function [correl, pval, cell_line_match] = histone_corr(model, compartment, mode, epsilon, epsilon2, rho, kappa, minfluxflag)
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
load supplementary_software_code celllinenames_ccle1 ccleids_met ccle_expression_metz % contains CCLE cellline names for gene exp, enzymes encoding specific metabolites, and gene expression data (z-transformed)

% New variables
path = './../new_var/';
vars = {...
    [path 'h3_ccle_names.mat'], [path 'h3_marks.mat'],...
    [path 'h3_media.mat'], [path 'h3_relval.mat']...
    }; % contains CCLE cellline names for H3 proteomics, corresponding marker ids, growth media, relative H3 proteomics
for kk = 1:numel(vars)
    load(vars{kk})
end

% impute missing values using KNN. Maybe try other functions if the results
% look like shit. 
h3_relval = knnimpute(h3_relval);

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

    % Takes in genes that are differentially expression from Z-score
    % scale
    ongenes = unique(ccleids_met(ccle_expression_metz(:,idx(i)) >= 2));
    offgenes = unique(ccleids_met(ccle_expression_metz(:,idx(i)) <= -2));
    
    % Keep the genes that match with the metabolic model.
    ongenes = intersect(ongenes, model2.rxns);
    offgenes = intersect(offgenes, model2.rxns);
    
    %medium = string(h3_media(i,1));
    % set medium conditions unique to each cell line
    model2 = media(model2, h3_media(i));
    disp(i)
    % Get the reactions corresponding to on- and off-genes
    [~,~,onreactions,~] =  deleteModelGenes(model2, ongenes);
    [~,~,offreactions,~] =  deleteModelGenes(model2, offgenes);

    % Get the flux redistribution values associated with different media component addition and deletion
    [fluxstate_gurobi, grate_ccle_exp_dat(i,1), solverobj_ccle(i,1)] =...
        constrain_flux_regulation(model2, onreactions, offreactions,...
        kappa, rho, epsilon, mode, [], minfluxflag);

    % Add demand reactions from the metabolite list to the metabolic model
    for m = 1:length(metabolites(:,1))
        %tmp_met = char(metabolites(m,2));
        %tmp = [tmp_met '[' compartment '] -> '];
        tmpname = char(metabolites(m,1));
        %model3 = addReaction(model, tmpname, 'reactionFormula', tmp);
        
        % limit methionine levels for all reactions in the model; it has to be non limiting
        model3 = model2;
        [ix, pos]  = ismember({'EX_met_L(e)'}, model3.rxns);
        model3.lb(pos) = -0.5;
        %model3.c(3743) = 0;
        rxnpos = [find(ismember(model3.rxns, tmpname))];
        model3.c(rxnpos) = epsilon2; 

        % get the flux values from iMAT
        [fluxstate_gurobi] =  constrain_flux_regulation(model3,...
            onreactions, offreactions, kappa, rho, epsilon, mode ,[],...
            minfluxflag);
        grate_ccle_exp_dat(i,1+m) = fluxstate_gurobi(rxnpos);
        model3.c(rxnpos) = 0; 
    end
end


% Calculate the pearson correlation coefficients for every demand reaction
[row, col] = size(grate_ccle_exp_dat);

test = interp1(1:numel(grate_ccle_exp_dat), grate_ccle_exp_dat,...
    linespace(1, numel(grate_ccle_exp_dat), numel(h3_relval)));
for i = 1:length(h3_relval(:,1))
    [correl, pval] = corr(grate_ccle_exp_dat(i,:), h3_relval(i,:));
end

for i = 1:length(h3_ccle_names)
    tmp1 = grate_ccle_exp_dat(i,:);
    tmp2 = h3_relval(i,:);
    [correl, pval] = corr(tmp1, tmp2);
    tmp3 = diag(correl);
end


correl = correl';

% Make a heatmap of correlation coefficients versus histone markers for
% several demand reactions
rxns = metabolites(:,1);

fig = figure;
heatmap(correl)
ax = gca;
ax.XData = h3_marks;
ax.YData = h3_ccle_names;
ax.Title = 'Histone markers and metabolic flux correlation'
xlabel(ax, 'Histone Markers');
ylabel(ax, 'Cancer Cell Lines (CCLE)'
saveas(fig, ['./../figures/fig/histone_mark_corr.fig']);
end 