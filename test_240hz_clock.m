function test_240hz_clock_3rot
% Run exactly 3 full rotations; log every Flip time; check timing.
% No PsychImaging.

AssertOpenGL;

try
    % ---- Params ----
    nRotations     = 3;          % <— EXACTLY 3 rotations
    cycleDuration  = 2.0;        % seconds per full rotation
    lineLenPx      = 200;
    clockRadiusPx  = 220;
    bgColor        = 128;
    lineColor      = 255;
    textColor      = 255;
    abortKey       = KbName('ESCAPE');

    % ---- Screen (no PsychImaging) ----
    oldVerb = Screen('Preference','Verbosity', 1);
    screens = Screen('Screens');  screenId = max(screens);
    [win, winRect] = Screen('OpenWindow', screenId, bgColor);
    [cx, cy] = RectCenter(winRect);
    Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    % prioritize matlab execution
    Priority(MaxPriority(win));
    % inter-frame interval: time difference between 2 frames
    % returns the average time between two consecutive screen refreshes
    ifi = Screen('GetFlipInterval', win);
    nominalHz = Screen('NominalFrameRate', screenId);
    waitframes = 1;

    HideCursor;  Screen('TextSize', win, 18);

    % Growable buffer for timestamps, i.e. array of timestamps
    estFrames  = ceil(nRotations*cycleDuration/ifi) + 100;
    vblTimes   = nan(estFrames,1); count = 0; growStep = 1000;

    % Angular speed for 2s per full turn
    % i.e. how many degree does each second rotate
    omega = 2*pi / cycleDuration;

    % Initial flip, vbl is the timestamp of refreshing, t0 is start time
    vbl = Screen('Flip', win); t0 = vbl;

    abort = false;
    while ~abort
        t = GetSecs - t0;
        theta = omega * t;                         % current radians/angle
        rotationsDone = floor(theta/(2*pi));       % completed rotations 0..n

        % Stop after EXACTLY 3 rotations
        if rotationsDone >= nRotations
            break;
        end

        % Hand endpoint (start at 12 o'clock)
        x2 = cx + lineLenPx * cos(theta - pi/2);
        y2 = cy + lineLenPx * sin(theta - pi/2);

        % Draw background, clock...
        Screen('FillRect', win, bgColor);
        Screen('FrameOval', win, lineColor, CenterRectOnPoint([0 0 2*clockRadiusPx 2*clockRadiusPx], cx, cy), 3);
        tick = 8;
        % draw 12/3/6/9 
        Screen('FillRect', win, lineColor, [cx-tick, cy-clockRadiusPx-2, cx+tick, cy-clockRadiusPx+2]); % 12
        Screen('FillRect', win, lineColor, [cx+clockRadiusPx-2, cy-tick, cx+clockRadiusPx+2, cy+tick]); % 3
        Screen('FillRect', win, lineColor, [cx-tick, cy+clockRadiusPx-2, cx+tick, cy+clockRadiusPx+2]); % 6
        Screen('FillRect', win, lineColor, [cx-clockRadiusPx-2, cy-tick, cx-clockRadiusPx+2, cy+tick]); % 9
        Screen('DrawLine', win, lineColor, cx, cy, x2, y2, 4);

        info1 = sprintf('Nominal Hz (OS): %g   ifi: %.6f s (%.2f Hz)', nominalHz, ifi, 1/ifi);
        info2 = sprintf('Elapsed: %.3f s   Rotations: %d / %d', t, rotationsDone, nRotations);
        DrawFormattedText(win, info1, 20, 30, textColor);
        DrawFormattedText(win, info2, 20, 55, textColor);
        DrawFormattedText(win, 'Press ESC to abort', 20, 80, textColor);

        % Flip，vbl is the system time (in seconds) when the last Screen('Flip') finished displaying frame on screen
        % vbl = "time of last screen refresh." 
        % ifi ≈ 1/240 = 0.00417 s 
        % waitframes = 1 → flip every frame (full speed, 240 FPS)
        % tell Psychtoolbox to start preparing half a frame early
        % To give MATLAB enough time to prepare the buffer and not miss the upcoming refresh.
        vbl = Screen('Flip', win, vbl + (waitframes - 0.5) * ifi);
        if count > 0
            frameInterval = vbl - vblTimes(count);  % time since last frame (seconds)
            fprintf('Frame %d interval: %.6f s (%.2f Hz)\n', count, frameInterval, 1/frameInterval);
        end

        % Log
        count = count + 1;
        % ensures array vblTimes never runs out of space
        if count > numel(vblTimes), vblTimes(end+growStep,1) = NaN; end
        vblTimes(count) = vbl;

        % Abort?
        [down, ~, keyCode] = KbCheck;
        if down && keyCode(abortKey), abort = true; end
    end

    % Trim
    vblTimes = vblTimes(1:count);

    % ---- Analysis ----
    % vblTimes is array of timestamps that displays every frame
    % dt is array of time interval between each frame, should be close to 1/240 = 0.00417 
    dt = diff(vblTimes);
    meanI = mean(dt); medI = median(dt); stdI = std(dt);
    minI = min(dt); maxI = max(dt); measuredHz = 1/medI;

    k = (0:numel(vblTimes)-1)'; expected240 = 1/240; t0_est = vblTimes(1);
    ideal240 = t0_est + k*expected240;  absErr240 = abs(vblTimes - ideal240);
    rmsErr240 = sqrt(mean(absErr240.^2)); maxErr240 = max(absErr240);

    idealMeas = t0_est + k*ifi;          absErrMeas = abs(vblTimes - idealMeas);
    rmsErrMeas = sqrt(mean(absErrMeas.^2)); maxErrMeas = max(absErrMeas);

    fprintf('\n==== Timing Report (3 rotations) ====\n');
    fprintf('Frames: %d\n', numel(vblTimes));
    % 1/240 = 0.00417 s 
    fprintf('ifi: %.6f s (%.2f Hz), median dt: %.6f s (%.2f Hz)\n', ifi, 1/ifi, medI, 1/medI);
    fprintf('Inter-flip: mean=%.6f  med=%.6f  std=%.6f  min=%.6f  max=%.6f (s)\n', ...
        meanI, medI, stdI, minI, maxI);
    fprintf('Delayed frames (>1.5*ifi): %d\n', dropped);
    fprintf('Err vs perfect 240Hz: RMS=%.6f s  MAX=%.6f s\n', rmsErr240, maxErr240);
    fprintf('Err vs measured ifi:  RMS=%.6f s  MAX=%.6f s\n', rmsErrMeas, maxErrMeas);


    % ==== Timing Report (3 rotations) ====
    % Frames: 1327
    % ifi: 0.004170 s (239.81 Hz), median dt: 0.004274 s (233.96 Hz)
    % Inter-flip: mean=0.004499  med=0.004274  std=0.000668  min=0.003418  max=0.008914 (s)
    % Delayed frames (>1.5*ifi): 39
    % Err vs perfect 240Hz: RMS=0.254786 s  MAX=0.441283 s
    % Err vs measured ifi:  RMS=0.252250 s  MAX=0.436853 s

    % Cleanup
    ShowCursor; Priority(0); Screen('CloseAll');
    Screen('Preference','Verbosity', oldVerb);

catch ME
    ShowCursor; Priority(0); Screen('CloseAll'); rethrow(ME);
end
end

function out = tern(cond,a,b)
if cond, out=a; else, out=b; end
end
