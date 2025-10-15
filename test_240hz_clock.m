% function test_240hz_clock
% % Test if a monitor can sustain ~240 FPS using Psychtoolbox (no PsychImaging).
% % A clock hand completes a full rotation every 2 seconds. We flip every frame,
% % log timestamps, and analyze timing accuracy.
% 
% AssertOpenGL;
% 
% try
%     % ---- Experiment params ----
%     nCycles        = 3;          % number of 2s cycles to run
%     cycleDuration  = 2.0;        % seconds per full rotation
%     lineLenPx      = 200;
%     clockRadiusPx  = 220;
%     bgColor        = 128;
%     lineColor      = 255;
%     textColor      = 255;
%     abortKey       = KbName('ESCAPE');
% 
%     % ---- Screen setup (no PsychImaging) ----
%     oldVerb = Screen('Preference','Verbosity', 1);
%     % Screen('Preference','SkipSyncTests', 0);
% 
%     screens = Screen('Screens');
%     screenId = max(screens);
%     [win, winRect] = Screen('OpenWindow', screenId, bgColor);
%     [cx, cy] = RectCenter(winRect);
%     Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
% 
%     topPriority = MaxPriority(win); Priority(topPriority);
% 
%     % Query timing
%     ifi = Screen('GetFlipInterval', win);
%     nominalHz = Screen('NominalFrameRate', screenId);
%     targetHz = 1 / ifi;
%     waitframes = 1;
% 
%     % ---- Prepare ----
%     HideCursor; Screen('TextSize', win, 18);
% 
%     totalDuration = nCycles * cycleDuration;
%     estFrames = ceil(totalDuration / ifi) + 100;
% 
%     % Use growable buffer + exact count (avoids your error)
%     vblTimes = nan(estFrames,1);
%     count = 0;
%     growStep = 1000; % grow by this many if we run out
% 
%     omega = 2*pi / cycleDuration;   % rad/s
% 
%     vbl = Screen('Flip', win);
%     t0  = vbl;
% 
%     % ---- Main loop ----
%     abort = false;
%     while ~abort
%         t = GetSecs - t0;
%         if t >= totalDuration, break; end
% 
%         theta = omega * t; % rad
% 
%         x2 = cx + lineLenPx * cos(theta - pi/2);
%         y2 = cy + lineLenPx * sin(theta - pi/2);
% 
%         Screen('FillRect', win, bgColor);
%         Screen('FrameOval', win, lineColor, CenterRectOnPoint([0 0 2*clockRadiusPx 2*clockRadiusPx], cx, cy), 3);
%         tick = 8;
%         Screen('FillRect', win, lineColor, [cx-tick, cy-clockRadiusPx-2, cx+tick, cy-clockRadiusPx+2]); % 12
%         Screen('FillRect', win, lineColor, [cx+clockRadiusPx-2, cy-tick, cx+clockRadiusPx+2, cy+tick]); % 3
%         Screen('FillRect', win, lineColor, [cx-tick, cy+clockRadiusPx-2, cx+tick, cy+clockRadiusPx+2]); % 6
%         Screen('FillRect', win, lineColor, [cx-clockRadiusPx-2, cy-tick, cx-clockRadiusPx+2, cy+tick]); % 9
%         Screen('DrawLine', win, lineColor, cx, cy, x2, y2, 4);
% 
%         info1 = sprintf('Nominal Hz (OS): %g   Measured ifi: %.6f s (%.2f Hz)', nominalHz, ifi, targetHz);
%         info2 = sprintf('Elapsed: %.3f s   Cycle: %.1f / %d', t, floor(t/cycleDuration)+1, nCycles);
%         DrawFormattedText(win, info1, 20, 30, textColor);
%         DrawFormattedText(win, info2, 20, 55, textColor);
%         DrawFormattedText(win, 'Press ESC to abort', 20, 80, textColor);
% 
%         vbl = Screen('Flip', win, vbl + (waitframes - 0.5) * ifi);
% 
%         % ---- Safe logging with growth ----
%         count = count + 1;
%         if count > numel(vblTimes)
%             vblTimes(end+growStep,1) = NaN; % grow
%         end
%         vblTimes(count) = vbl;
% 
%         % Abort?
%         [down, ~, keyCode] = KbCheck;
%         if down && keyCode(abortKey), abort = true; end
%     end
% 
%     % ---- Trim EXACTLY to the number of valid flips ----
%     vblTimes = vblTimes(1:count);
% 
%     % ---- Analysis ----
%     dt = diff(vblTimes);
%     meanI = mean(dt);
%     medI  = median(dt);
%     stdI  = std(dt);
%     minI  = min(dt);
%     maxI  = max(dt);
%     measuredHz = 1/medI;
% 
%     expected240 = 1/240;
%     dropThresh = 1.5 * ifi;
%     dropped = sum(dt > dropThresh);
% 
%     k = (0:numel(vblTimes)-1)';
%     idealTimes240 = t0 + k*expected240;
%     absErr240 = abs(vblTimes - idealTimes240);
%     rmsErr240 = sqrt(mean(absErr240.^2));
%     maxErr240 = max(absErr240);
% 
%     idealTimesMeasured = t0 + k*ifi;
%     absErrMeas = abs(vblTimes - idealTimesMeasured);
%     rmsErrMeas = sqrt(mean(absErrMeas.^2));
%     maxErrMeas = max(absErrMeas);
% 
%     fprintf('\n==== Timing Report ====\n');
%     fprintf('Nominal (OS) refresh:      %g Hz\n', nominalHz);
%     fprintf('Measured ifi:              %.6f s (%.2f Hz)\n', ifi, 1/ifi);
%     fprintf('Frames presented:          %d\n', numel(vblTimes));
%     fprintf('Inter-flip: mean=%.6f  med=%.6f  std=%.6f  min=%.6f  max=%.6f (s)\n', ...
%         meanI, medI, stdI, minI, maxI);
%     fprintf('Estimated framerate:       %.2f Hz (from median dt)\n', measuredHz);
%     fprintf('Delayed frames (>1.5*ifi): %d\n', dropped);
%     fprintf('Err vs perfect 240Hz:      RMS=%.6f s  MAX=%.6f s\n', rmsErr240, maxErr240);
%     fprintf('Err vs measured ifi:       RMS=%.6f s  MAX=%.6f s\n', rmsErrMeas, maxErrMeas);
% 
%     pass240 = (measuredHz > 239) && (dropped == 0);
%     if pass240
%         fprintf('RESULT: Looks consistent with ~240 Hz without drops.\n');
%     else
%         fprintf('RESULT: Not consistently at 240 Hz (see stats above).\n');
%     end
% 
%     % ---- Cleanup ----
%     ShowCursor; Priority(0); Screen('CloseAll');
%     Screen('Preference','Verbosity', oldVerb);
% 
% catch ME
%     ShowCursor; Priority(0); Screen('CloseAll'); rethrow(ME);
% end
% end



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

    Priority(MaxPriority(win));
    ifi = Screen('GetFlipInterval', win);
    nominalHz = Screen('NominalFrameRate', screenId);
    waitframes = 1;

    HideCursor;  Screen('TextSize', win, 18);

    % Growable buffer for timestamps
    estFrames  = ceil(nRotations*cycleDuration/ifi) + 100;
    vblTimes   = nan(estFrames,1); count = 0; growStep = 1000;

    % Angular speed for 2s per full turn
    omega = 2*pi / cycleDuration;

    % Initial flip
    vbl = Screen('Flip', win); t0 = vbl;

    abort = false;
    while ~abort
        t = GetSecs - t0;
        theta = omega * t;                         % radians from start
        rotationsDone = floor(theta/(2*pi));       % completed rotations 0..n

        % Stop after EXACTLY 3 rotations
        if rotationsDone >= nRotations
            break;
        end

        % Hand endpoint (start at 12 o'clock)
        x2 = cx + lineLenPx * cos(theta - pi/2);
        y2 = cy + lineLenPx * sin(theta - pi/2);

        % Draw
        Screen('FillRect', win, bgColor);
        Screen('FrameOval', win, lineColor, CenterRectOnPoint([0 0 2*clockRadiusPx 2*clockRadiusPx], cx, cy), 3);
        tick = 8;
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

        % Flip
        vbl = Screen('Flip', win, vbl + (waitframes - 0.5) * ifi);

        % Log
        count = count + 1;
        if count > numel(vblTimes), vblTimes(end+growStep,1) = NaN; end
        vblTimes(count) = vbl;

        % Abort?
        [down, ~, keyCode] = KbCheck;
        if down && keyCode(abortKey), abort = true; end
    end

    % Trim
    vblTimes = vblTimes(1:count);

    % ---- Analysis ----
    dt = diff(vblTimes);
    meanI = mean(dt); medI = median(dt); stdI = std(dt);
    minI = min(dt); maxI = max(dt); measuredHz = 1/medI;
    dropThresh = 1.5 * ifi; dropped = sum(dt > dropThresh);

    k = (0:numel(vblTimes)-1)'; expected240 = 1/240; t0_est = vblTimes(1);
    ideal240 = t0_est + k*expected240;  absErr240 = abs(vblTimes - ideal240);
    rmsErr240 = sqrt(mean(absErr240.^2)); maxErr240 = max(absErr240);

    idealMeas = t0_est + k*ifi;          absErrMeas = abs(vblTimes - idealMeas);
    rmsErrMeas = sqrt(mean(absErrMeas.^2)); maxErrMeas = max(absErrMeas);

    fprintf('\n==== Timing Report (3 rotations) ====\n');
    fprintf('Frames: %d\n', numel(vblTimes));
    fprintf('ifi: %.6f s (%.2f Hz), median dt: %.6f s (%.2f Hz)\n', ifi, 1/ifi, medI, 1/medI);
    fprintf('Inter-flip: mean=%.6f  med=%.6f  std=%.6f  min=%.6f  max=%.6f (s)\n', ...
        meanI, medI, stdI, minI, maxI);
    fprintf('Delayed frames (>1.5*ifi): %d\n', dropped);
    fprintf('Err vs perfect 240Hz: RMS=%.6f s  MAX=%.6f s\n', rmsErr240, maxErr240);
    fprintf('Err vs measured ifi:  RMS=%.6f s  MAX=%.6f s\n', rmsErrMeas, maxErrMeas);

    % pass240 = (1/medI > 239) && (dropped == 0);
    % fprintf('RESULT: %s\n', tern(pass240,'Looks like ~240 Hz without drops.','Not consistently 240 Hz.'));

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
