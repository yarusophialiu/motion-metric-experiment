function maybe_flash_before_play(window, windowRect, movie, flash, labelText, subLabelText, debug)
%   Grabs one frame from 'movie', flashes a red dot on it, then starts playback.
%   If flash.enabled is false/missing, it just starts playback.
%   (0,0) is at the top left, x-axis increases to the right, y-axis
%   increases downward. 
%
%   flash fields (with defaults):
%   .hz       (4)      - flashes per second (on/off)
%   .dotX     (center) - pixel X in window coords (increase to right)
%   .dotY     (center) - pixel Y in window coords (increase to downward)
%   .radius   (12)     - dot radius in pixels

    % If flashing disabled, just play from t=0 and return
    if isempty(flash) || ~isfield(flash, 'enabled') || ~flash.enabled
        Screen('SetMovieTimeIndex', movie, 0);
        Screen('PlayMovie', movie, 1);
        return;
    end

    % Defaults
    if ~isfield(flash,'duration'), flash.duration = 1.0; end
    if ~isfield(flash,'hz'),       flash.hz       = 4;   end
    if ~isfield(flash,'dotX'),     flash.dotX     = windowRect(3)/2; end
    if ~isfield(flash,'dotY'),     flash.dotY     = windowRect(4)/2; end
    if ~isfield(flash,'radius'),   flash.radius   = 12;  end

    marginX = 20;
    marginY = 20;
    labelColor = [255 255 255];

    % Grab a single frame as a texture
    Screen('SetMovieTimeIndex', movie, 0);
    Screen('PlayMovie', movie, 1);
    tex = -1;
    while tex <= 0
        tex = Screen('GetMovieImage', window, movie, 1); % 1 = wait for next frame
        if tex == 0
            WaitSecs(0.001);
        end
    end
    Screen('PlayMovie', movie, 0); % pause while we flash

    halfCycle = 0.5 / max(flash.hz, eps);
    isOn = true;
    tStart = Screen('Flip', window);

    % Draw the still frame with a flashing red dot
    while (GetSecs - tStart) < flash.duration
        % Draw the grabbed frame stretched to windowRect (match your playback)
        Screen('DrawTexture', window, tex, [], windowRect);

        if isOn
            dotRect = CenterRectOnPoint([0 0 2*flash.radius 2*flash.radius], flash.dotX, flash.dotY);
            Screen('FillOval', window, [255 0 0 255], dotRect);
        end

        % label
        if nargin >= 5 && ~isempty(labelText)
            Screen('TextSize', window, 50);
            Screen('DrawText', window, labelText, marginX, marginY, labelColor);
            if debug
                Screen('TextSize', window, 50);
                Screen('DrawText', window, subLabelText, marginX, marginY + 60, labelColor);
            end
        end

        Screen('Flip', window);
        WaitSecs(halfCycle);
        isOn = ~isOn;

        % Optional: allow abort of flash with ESC
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown && keyCode(KbName('ESCAPE'))
            break;
        end
    end

    % Clean up the grabbed texture
    Screen('Close', tex);

    % Start normal playback from the beginning
    Screen('SetMovieTimeIndex', movie, 0);
    Screen('PlayMovie', movie, 1);
end
