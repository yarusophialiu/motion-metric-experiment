function condition_table = create_condition_table(scene)
%CREATE_CONDITION_TABLE  Generate a condition table for selected rendering methods and parameters.
%
%   condition_table = CREATE_CONDITION_TABLE(scene)
%
%   Input:
%       scene — cell array of scene names, e.g. {'zeroday','bistro_interior','subway'}
%
%   Output:
%       condition_table — table with columns:
%           'scene', 'method', 'param_idx'
%
%   The table includes:
%       restir level0
%       temporal-resolution-multiplexing level0, level1
%       motion_noise level0
%       motion_resolution level0
%       dlss_rr maxquality_12_multiplier
%       noise_color blue
%       and idx = 0, 1, 2 (combined into param_idx, e.g. level0_0)

    % Define method → parameter mapping
    method_param_map = { ...
        'restir',                       {'level0'}; ...
        'temporal-resolution-multiplexing', {'level0', 'level1'}; ...
        'motion_noise',                 {'level0'}; ...
        'motion_resolution',            {'level0'}; ...
        'dlss_rr',                      {'maxquality_12_multiplier'}; ...
        'noise_color',                  {'blue'}};

    idx_values = 0:2;

    % Build table rows
    rows = {};
    for s = 1:numel(scene)
        for k = 1:size(method_param_map,1)
            method = method_param_map{k,1};
            params = method_param_map{k,2};
            for p = 1:numel(params)
                for idx = idx_values
                    scene_idx = sprintf('%s_%d', scene{s}, idx);
                    rows(end+1,:) = {scene_idx, method, params{p}};
                end
            end
        end
    end

    % Create final table
    condition_table = cell2table(rows, ...
        'VariableNames', {'scene_idx','method','param'});
end
