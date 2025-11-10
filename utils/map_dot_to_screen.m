function [scaledX, scaledY] = map_dot_to_screen(dotX, dotY, winRect, videoRect)
%MAPDOTTOSCREEN  Map a (dotX, dotY) from video space to window space.
%
% Inputs:
%   dotX, dotY   - Coordinates in original video space (e.g., 1280×720)
%   winRect      - [left top right bottom] of Psychtoolbox window
%   videoRect    - [0 0 videoWidth videoHeight], e.g. [0 0 1280 720]
%
% Outputs:
%   scaledX, scaledY - Corresponding coordinates in window space
    [winW, winH]   = RectSize(winRect);
    [vidW, vidH]   = RectSize(videoRect);

    % Stretch-to-fill scaling
    scaleX = winW / vidW;
    scaleY = winH / vidH;
    scaledX = winRect(1) + dotX * scaleX;
    scaledY = winRect(2) + dotY * scaleY;
end
