function [scene, idx] = parse_scene_idx(scene_idx)
%PARSE_SCENE_IDX  Split 'scene_idx' string(s) into scene name and numeric index.
%   Input:
%       scene_idx — "pink_room_2" or {'zeroday_1', 'bistro_interior_0'}
%   Example:
%       [scene, idx] = parse_scene_idx("pink_room_2"); or 
%       [scene, idx] = parse_scene_idx({'pink_room_2','zeroday_10'})
%       % scene = ["pink_room", "zeroday"]
%       % idx   = [2, 10]

    % Ensure input is cell array for uniform processing
    if ischar(scene_idx) || isstring(scene_idx)
        scene_idx = cellstr(scene_idx);
    end

    scene = strings(size(scene_idx));
    idx = zeros(size(scene_idx));

    for i = 1:numel(scene_idx)
        str = scene_idx{i};
        underscore_pos = find(str == '_', 1, 'last');

        if isempty(underscore_pos)
            scene(i) = string(str);
            idx(i) = NaN;
        else
            scene(i) = string(str(1:underscore_pos-1));          % before last underscore
            idx(i) = str2double(str(underscore_pos+1:end));      % after last underscore
        end
    end
end
