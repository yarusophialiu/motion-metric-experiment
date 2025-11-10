% --- Setup (no PsychImaging) ---
AssertOpenGL;
ListenChar(2); HideCursor;

addpath(fullfile(pwd, 'utils'));
screenId = max(Screen('Screens'));
% 0 = black background
[win, winRect] = Screen('OpenWindow', screenId, 0);
% Enable alpha blending if you want antialiased/transparent drawing
Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
ifi = Screen('GetFlipInterval', win);


% --- Config ---
mm_project_path = 'D:\motion-metric';
video_path = fullfile(mm_project_path, 'all_sequences_videos');
videoRect = [0 0 1280 720];
dstRect   = winRect;                 % stretch-to-fill (your current choice)
dotRadius = 16;
flashDuration = 3.0;                 % seconds
flashHz       = 4;                   % on/off rate
halfCycle     = 0.5 / flashHz;

% Define the scenes you want to loop through
scenes = { ...
    'attic', 'bistro_exterior', 'bistro_interior', 'classroom', ...
    'landscape', 'marbles', 'pink_room', 'subway', 'zeroday'};
scenes = {'bistro_interior', 'pink_room', 'zeroday'};

abortAll = false;

for s = 1:numel(scenes)
    scene = scenes{s};
    dotColor = get_dot_color(scene);

    for idx = 1:2   % index 1 and 2

        % --- Position from scene & index (your helper: get_dot_position(scene, idx)) ---
        [dotX, dotY] = get_dot_position(scene, idx);
        fprintf('scene %s, index %d → dot position (%.1f, %.1f)\n', scene, idx, dotX, dotY);

        % Map 1280x720 coords to current screen (your helper: map_dot_to_screen)
        [scaledX, scaledY] = map_dot_to_screen(dotX, dotY, winRect, videoRect);

        % --- Open movie for this scene ---
        moviePath = fullfile(video_path, scene, 'reference', 'video_0.mp4');
        try
            [movie, ~, ~, fps] = Screen('OpenMovie', win, moviePath);
        catch ME
            fprintf('Failed to open %s (%s). Skipping.\n', moviePath, ME.message);
            continue;
        end

        % --- Grab one frame to annotate (first frame) ---
        Screen('PlayMovie', movie, 1, 1, 1);  % start
        tex = [];
        while isempty(tex)
            tex = Screen('GetMovieImage', win, movie, 1);
            [keyDown, ~, keyCode] = KbCheck;
            if keyDown && keyCode(KbName('ESCAPE')), abortAll = true; break; end
        end
        Screen('PlayMovie', movie, 0);        % pause
        if abortAll, Screen('CloseMovie', movie); break; end

        % --- Flash the dot over the still frame ---
        vbl = Screen('Flip', win);
        tStart = vbl;
        isOn = true;

        while (GetSecs - tStart) < flashDuration
            % Draw frame stretched to fill window
            Screen('DrawTexture', win, tex, [], dstRect, [], 1);

            % Dot
            if isOn
                dotRect = CenterRectOnPoint([0 0 2*dotRadius 2*dotRadius], scaledX, scaledY);
                Screen('FillOval', win, dotColor, dotRect);
            end

            vbl = Screen('Flip', win, vbl + 0.5*ifi);
            WaitSecs(halfCycle);
            isOn = ~isOn;

            % ESC to abort all
            [keyDown, ~, keyCode] = KbCheck;
            if keyDown && keyCode(KbName('ESCAPE')), abortAll = true; break; end
        end

        Screen('Close', tex);  % release still frame texture
        if abortAll, Screen('CloseMovie', movie); break; end

        % --- Normal playback ---
        Screen('PlayMovie', movie, 1); % play forward
        vbl = Screen('Flip', win);

        while true
            frameTex = Screen('GetMovieImage', win, movie, 1);
            if frameTex <= 0, break; end
            Screen('DrawTexture', win, frameTex, [], dstRect, [], 1);
            Screen('Flip', win);
            Screen('Close', frameTex);

            [keyDown, ~, keyCode] = KbCheck;
            if keyDown && keyCode(KbName('ESCAPE')), abortAll = true; break; end
        end

        % --- Cleanup for this movie ---
        Screen('PlayMovie', movie, 0);
        Screen('CloseMovie', movie);

        if abortAll, break; end
    end
    if abortAll, break; end
end

% --- Final cleanup ---
sca;
ShowCursor; ListenChar(0);

% % --- Open movie ---
% % moviePath = 'D:\motion-metric-experiment\data\videos\reference\attic\attic_ref_240fps_start0_2s_crf5_yuv420.mp4';
% mm_project_path = 'D:\motion-metric';
% video_path = fullfile(mm_project_path, 'all_sequences_videos');
% scene = 'attic';
% [dotX, dotY] = get_dot_position(scene, 1);
% 
% % dot_pos_map = get_dot_positions(video_path);
% % key = fullfile(video_path, scene, 'reference', fname);
% % pos = dot_pos_map(key);
% % dotX = pos(1); % pixels windowRect(3) = display width, set to e.g. windowRect(3)/2
% % dotY = pos(2); % pixels windowRect(4) = display height
% videoRect = [0 0 1280 720];
% % Map 1280x720 coordinates to current screen
% [scaledX, scaledY] = map_dot_to_screen(dotX, dotY, winRect, videoRect);
% 
% moviePath = fullfile(video_path, scene, 'reference', 'video_0.mp4');
% [movie, ~, ~, fps] = Screen('OpenMovie', win, moviePath);
% 
% % --- Grab one frame to annotate (e.g., first frame) ---
% Screen('PlayMovie', movie, 1, 1, 1);  % start (loop=1, rate=1)
% tex = [];
% while isempty(tex)
%     tex = Screen('GetMovieImage', win, movie, 1); % returns a texture handle
% end
% Screen('PlayMovie', movie, 0);  % pause

% % --- Red dot position (pixels in window coords) ---
% % dotX = winRect(3)/2;
% % dotY = winRect(4)/2;
% disp('dotX');
% disp(dotX);
% disp(dotY);
% dotRadius = 12;
% 
% % --- Flashing parameters ---
% flashDuration = 3.0;   % seconds
% flashHz       = 4;     % on/off rate
% halfCycle     = 0.5 / flashHz;
% 
% % --- Draw the still frame and flash the dot ---
% vbl = Screen('Flip', win);
% tStart = vbl;
% isOn = true;
% 
% % If you need scaling, compute a dstRect. Here we just center the movie frame:
% % srcRect = Screen('Rect', tex);
% % dstRect = CenterRectOnPoint(srcRect, winRect(3)/2, winRect(4)/2);
% 
% while (GetSecs - tStart) < flashDuration
%     % Draw the captured frame
%     % Screen('DrawTexture', win, tex, [], dstRect);
%     dstRect = winRect;
%     % bilinear filtering: filterMode = 1
%     Screen('DrawTexture', win, tex, [], dstRect, [], 1);
% 
%     % Draw flashing dot
%     if isOn
%         % dotRect = CenterRectOnPoint([0 0 2*dotRadius 2*dotRadius], dotX, dotY);
%         dotRect = CenterRectOnPoint([0 0 2*dotRadius 2*dotRadius], scaledX, scaledY);
%         Screen('FillOval', win, [255 0 0 255], dotRect);
%     end
%     vbl = Screen('Flip', win, vbl + 0.5*ifi);
% 
%     WaitSecs(halfCycle);
%     isOn = ~isOn;
% 
%     % Optional: ESC to abort
%     [keyDown, ~, keyCode] = KbCheck;
%     if keyDown && keyCode(KbName('ESCAPE')), break; end
% end
% 
% % --- Start normal playback ---
% Screen('PlayMovie', movie, 1); % play forward
% vbl = Screen('Flip', win);
% 
% while true
%     frameTex = Screen('GetMovieImage', win, movie, 1);
%     if frameTex <= 0
%         break; % end of movie or error
%     end
%     % Screen('DrawTexture', win, frameTex);
%     Screen('DrawTexture', win, frameTex, [], dstRect, [], 1);  % <-- use dstRect
%     Screen('Flip', win);
%     Screen('Close', frameTex); % important to avoid leaks
% end
% 
% % --- Cleanup ---
% Screen('PlayMovie', movie, 0);
% Screen('CloseMovie', movie);
% sca;
% ShowCursor; ListenChar(0);
