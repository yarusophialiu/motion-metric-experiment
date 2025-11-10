function [dotX, dotY] = get_dot_position(scene, index)
%GET_DOT_POSITION  Return [dotX, dotY] for a given scene.
%
% Usage:
%   [dotX, dotY] = get_dot_position(baseDir, scene)
%   [dotX, dotY] = get_dot_position(baseDir, scene, index)
%
% Inputs:
%   baseDir : root path containing all scene folders
%   scene   : e.g. 'attic', 'bistro_exterior', etc.
%   index   : optional, 1 or 2. If not given, chosen randomly.
%
% Output:
%   dotX, dotY : coordinates in video space (1280x720)
%

    % Pilot
    switch lower(scene)
        case 'bistro_interior'
            pos = {[490, 340], [50, 470], [55, 539]};
        case 'subway'
            pos = {[530, 229], [736, 455], [990, 70]}; 
        case 'zeroday'
            pos = {[601, 553], [618, 300], [430, 239]}; 
        otherwise
            error('Unknown scene name: %s', scene);
    end
    % switch lower(scene)
    %     case 'attic'
    %         pos = {[710,195], [316,352]};
    %     case 'bistro_exterior'
    %         pos = {[1219, 195], [704, 170]}; % [1146,334]
    %     case 'bistro_interior'
    %         pos = {[529, 341], [456, 215]}; % 452,456 420,197
    %     case 'classroom'
    %         pos = {[805,288], [1088,215]};
    %     case 'landscape'
    %         pos = {[735,353], [1045,192]};
    %     case 'marbles'
    %         pos = {[381,311], [487,315]};
    %     case {'pink_room', 'pinkroom'}
    %         pos = {[768, 395], [877, 515]}; % 993,331 [1217,252], [862,168]
    %     case 'subway'
    %         pos = {[727,172], [1103,414]};
    %     case 'zeroday'
    %         pos = {[462, 511], [553, 510]}; % [512,427], [453,405]
    %     otherwise
    %         error('Unknown scene name: %s', scene);
    % end

    % % Choose index (random if not provided)
    % if nargin < 3 || isempty(index)
    %     index = randi(2);  % random 1 or 2
    if index ~= 1 && index ~= 2 && index ~= 3
        error('Index must be 1 or 2 or 3');
    end

    % Return the chosen position
    posChosen = pos{index};
    dotX = posChosen(1);
    dotY = posChosen(2);
end
