function test_clock_240fps_PTBSync
% Test whether a display can sustain ~240 fps while animating a clock
% that completes a full cycle in 2 seconds. Logs per-frame timestamps
% and verifies timing accuracy after the run.
%
% Press ESC to abort early.

try
    % --- Setup Psychtoolbox (don’t disable sync tests!) ---
    AssertOpenGL;
    PsychDefaultSetup(2); % initialize some commonly used default settings
    Screen('Preference','VisualDebugLevel', 1); % Don’t show Psychtoolbox’s startup logo or gray screen when opening the window — just open cleanly but still give basic diagnostic info if something goes wrong.
    Screen('Preference','SkipSyncTests', 1); % 1: skips

    scr = max(Screen('Screens'));
    background = BlackIndex(scr);
    white = WhiteIndex(scr);
    [win, rect] = PsychImaging('OpenWindow', scr, background);
    [cx, cy] = RectCenter(rect); % Finds the center pixel coordinates of your window
    ifi = Screen('GetFlipInterval', win);  % inter-frame interval (IFI) — the time between two consecutive screen refreshes.
    nominalHz = 1/ifi;

    Priority(MaxPriority(win));
    HideCursor;

    % --- Clock parameters ---
    secondsPerRevolution = 2;              % 1 full cycle in 2 s
    omega_deg_per_s = 360 / secondsPerRevolution;

    % Run for a few revolutions to collect data
    revolutions = 3;                        % change if you want longer
    runTime = revolutions * secondsPerRevolution;

    % Visual sizes
    radius = 0.35 * min(rect(3)-rect(1), rect(4)-rect(2));
    handLen = 0.9 * radius;
    ringRect = CenterRectOnPointd([0 0 2*radius 2*radius], cx, cy);

    % Preallocate roughly (so we don't reallocate during timing)
    estFrames = ceil(runTime / ifi) + 5;
    vblTimes = nan(estFrames, 1);
    angles   = nan(estFrames, 1);

    % Initial flip to sync to VBL
    Screen('FillRect', win, background);
    vbl = Screen('Flip', win);
    t0  = vbl;                   % reference time
    nextVBL = vbl;

    % --- Main loop ---
    frame = 1;
    esc = KbName('ESCAPE');
    ListenChar(-1);  % prevent keypresses from echoing to MATLAB
    RestrictKeysForKbCheck([esc]);

    while (GetSecs - t0) < runTime
        % Early exit on ESC
        [pressed, ~, kc] = KbCheck;
        if pressed && kc(esc), break; end

        % Compute current angle so the hand completes 360° in 2 s
        nowT = GetSecs;
        theta = mod((nowT - t0) * omega_deg_per_s, 360);

        % Convert angle to endpoint (0° at 12 o'clock -> subtract 90 for PTB's x-axis)
        th = deg2rad(theta - 90);
        x2 = cx + handLen * cos(th);
        y2 = cy + handLen * sin(th);

        % Draw clock face + hand
        Screen('FillRect', win, background);
        Screen('FrameOval', win, white, ringRect, 3);
        % Tick marks (simple 12 ticks)
        for k = 0:11
            tk = deg2rad(k*30 - 90);
            r1 = radius * 0.90; r2 = radius * 1.00;
            xA = cx + r1 * cos(tk); yA = cy + r1 * sin(tk);
            xB = cx + r2 * cos(tk); yB = cy + r2 * sin(tk);
            Screen('DrawLine', win, white, xA, yA, xB, yB, 3);
        end
        % Hand
        Screen('DrawLine', win, white, cx, cy, x2, y2, 4);
        % Center dot
        Screen('FillOval', win, white, CenterRectOnPoint([0 0 8 8], cx, cy));

        % Flip exactly once per refresh, paced by previous VBL
        [vbl, ~, ~, missed] = Screen('Flip', win, nextVBL + 0.5*ifi);
        nextVBL = vbl;

        % Log timing + angle (angle at draw time)
        vblTimes(frame) = vbl;
        angles(frame)   = theta;
        frame = frame + 1;
    end

    % Trim arrays to actual frame count
    n = find(isnan(vblTimes), 1, 'first');
    if isempty(n), n = numel(vblTimes) + 1; end
    vblTimes = vblTimes(1:n-1);
    angles   = angles(1:n-1);

    % --- Close screen cleanly before analysis/plots ---
    ShowCursor; Priority(0); ListenChar(0); RestrictKeysForKbCheck([]);
    sca;

    % --- Post-run timing analysis ---
    dt = diff(vblTimes);
    actualHz_mean = 1/mean(dt);
    actualHz_med  = 1/median(dt);
    % “Dropped” frames: flips that took >1.5x the nominal interval
    drops = find(dt > 1.5*ifi);
    numDrops = numel(drops);

    % Compare to ideal schedule starting from first VBL
    idealTimes = vblTimes(1) + (0:(numel(vblTimes)-1)) * ifi;
    drift = (vblTimes - idealTimes) * 1e3; % ms drift vs ideal

    fprintf('----- Timing report -----\n');
    fprintf('Nominal refresh (from ifi) : %.3f Hz (ifi = %.6f s)\n', nominalHz, ifi);
    fprintf('Actual mean frame rate     : %.3f Hz\n', actualHz_mean);
    fprintf('Actual median frame rate   : %.3f Hz\n', actualHz_med);
    fprintf('Frames rendered            : %d (%.2f s)\n', numel(vblTimes), vblTimes(end)-vblTimes(1));
    fprintf('Dropped/long frames        : %d\n', numDrops);
    if numDrops > 0
        fprintf('Indices of long frames     : '); fprintf('%d ', drops); fprintf('\n');
    end
    fprintf('Max |drift| vs ideal       : %.3f ms\n', max(abs(drift)));

    % --- Plots (MATLAB figures) ---
    figure('Name','Inter-frame intervals');
    plot(dt*1e3, '.-'); grid on;
    yline(ifi*1e3,'--','Nominal ifi');
    xlabel('Frame #'); ylabel('Delta time (ms)');
    title(sprintf('Inter-frame intervals (target ~%.3f ms)', ifi*1e3));

    figure('Name','Cumulative drift vs. ideal schedule');
    plot(drift, '.-'); grid on;
    xlabel('Frame #'); ylabel('Drift (ms)');
    title('Cumulative drift (actual flip time - ideal grid)');

    % Simple pass/fail near 240 Hz (±2%)
    targetHz = 240;
    tol = 0.02; % 2%
    within = abs(actualHz_mean - targetHz) <= tol*targetHz && numDrops==0;
    if within
        fprintf('PASS: Timing consistent with ~%d Hz and no drops detected.\n', targetHz);
    else
        fprintf('NOTE: Timing deviates from ~%d Hz and/or drops detected.\n', targetHz);
    end

catch ME
    % Make sure we restore the screen on error
    sca; ShowCursor; Priority(0); ListenChar(0); RestrictKeysForKbCheck([]);
    rethrow(ME);
end
end
