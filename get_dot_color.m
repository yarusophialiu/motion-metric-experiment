function color = get_dot_color(scene)
%GET_DOT_COLOR  Return RGB color for the flashing dot based on scene name.
%
% Usage:
%   color = get_dot_color(scene)
%
% Output:
%   color = [R G B]  (values 0–255)
%
% All scenes → red
% Special scenes → neon green:

    scene = lower(strtrim(scene));

    % Default color: red
    color = [255, 0, 0];

    % Special cases: neon green
    if ismember(scene, {'bistro_exterior', 'pink_room', 'pinkroom', 'subway'})
        color = [57, 255, 20];   % neon green RGB
    end
end
