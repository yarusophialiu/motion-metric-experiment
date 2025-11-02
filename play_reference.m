function play_reference()
% play 240 FPS video
FULL_SCREEN_MODE = false;
MAX_LOOPS = 2;  % <-- number of times to loop the entire video before exiting automatically

KbName('UnifyKeyNames');
Screen('Preference', 'SkipSyncTests', 1); % disable sync test for debugging
ref_path = 'C:\Users\15142\Projects\motion-metric\all_sequences\attic\out_240fps_2s_h265_lossless_yuv444.mkv';
% if exist('config.mat','file')
%     cfg = load('config.mat');
%     ref_path = cfg.ref_path;
% else
%     error('config.mat not found. Please create it on this machine.');
% end
assert(exist(ref_path,'file')==2, 'File not found: %s', ref_path);
screenNumber = max(Screen('Screens'));

try
    % Open fullscreen window (black background)
    if ~FULL_SCREEN_MODE
        rect = [100 100 900 700];
        [window, windowRect] = Screen('OpenWindow', screenNumber, 0, rect);
    else
        [window, windowRect] = Screen('OpenWindow', screenNumber, 0); % fullscreen
    end
    % % ifi: expected frame interval
    % [ifi, ~, ~] = Screen('GetFlipInterval', window, 60);
    % nominalHz = 1 / ifi;

    % Open and start movie
    movie = Screen('OpenMovie', window, ref_path);
    Screen('SetMovieTimeIndex', movie, 0);
    Screen('PlayMovie', movie, 1);

    % Raise priority for smoother playback
    oldPriority = Priority;
    Priority(MaxPriority(window));
    
    % -------- Timestamp logging --------
    flipTimes = [];  % will store timestamps of each Screen('Flip')
    missedFlags = [];
    loopCount = 1;

    fprintf('Playing video for up to %d loops...\n', MAX_LOOPS);

    while true
        tex = Screen('GetMovieImage', window, movie);

        if tex <= 0
            % Video reached end — loop again or exit
            if loopCount >= MAX_LOOPS
                disp('Reached max loop count.');
                break;
            end
            loopCount = loopCount + 1;
            Screen('SetMovieTimeIndex', movie, 0);
            Screen('PlayMovie', movie, 1);
            WaitSecs(0.005);
            continue;
        end

        % Draw current frame and flip
        Screen('DrawTexture', window, tex, [], windowRect);
        % missed → a flag telling you whether the flip missed its scheduled VBL deadline.
        [vbl, ~, ~, missed] = Screen('Flip', window);
        flipTimes(end+1) = vbl;
        missedFlags(end+1) = missed > 0;  % 1 if you missed the VBL deadline
        Screen('Close', tex);

        % ESC to quit
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown && keyCode(KbName('ESCAPE'))
            disp('Exiting playback...');
            KbReleaseWait;
            break;
        end

        WaitSecs(0.001);
    end

    % Cleanup
    Screen('PlayMovie', movie, 0);
    Screen('CloseMovie', movie);
    Priority(oldPriority);
    Screen('CloseAll');

    % -------- Compute & print refresh stats --------
    if numel(flipTimes) > 1
        dt = diff(flipTimes);             % seconds between flips
        instHz = 1 ./ dt;                 % instantaneous Hz
        avgHz  = 1 / mean(dt);
        fprintf('\n=== Frame Timing Statistics ===\n');
        fprintf('Frames shown: %d\n', numel(flipTimes));
        fprintf('Loops completed:       %d\n', loopCount);
        % fprintf('Nominal refresh (Hz):  %.4f\n', nominalHz);
        fprintf('Average refresh rate: %.4f Hz\n', avgHz);
        fprintf('Median refresh rate:  %.4f Hz\n', median(instHz));
        fprintf('Missed flips:          %d (%.2f%%)\n', sum(missedFlags), 100*sum(missedFlags)/numel(missedFlags));
        % fprintf('Avg frame interval (s): %.6f (nominal ifi: %.6f)\n', mean(dt), ifi);
        fprintf('Avg frame interval (s): %.6f\n', mean(dt));
        fprintf('===============================\n\n');
    else
        fprintf('No frame timestamps recorded.\n');
    end

catch ME
    % In case of crash, close all screens safely
    Screen('CloseAll');
    Priority(0);
    rethrow(ME);
end

end
