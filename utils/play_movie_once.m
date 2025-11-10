function play_movie_once(window, windowRect, movie, labelText, subLabelText, labelColor, debug)
    if nargin < 7, debug = false; end
    if nargin < 6 || isempty(labelColor), labelColor = [255 255 255]; end

    Screen('SetMovieTimeIndex', movie, 0);
    Screen('PlayMovie', movie, 1);

    KbName('UnifyKeyNames');
    RestrictKeysForKbCheck([KbName('ESCAPE')]); 

    marginX = 20;
    marginY = 20;

    while true
        tex = Screen('GetMovieImage', window, movie);
        if tex <= 0
            if tex == -1
                break; % finish playing
            else
                WaitSecs(0.001);
                continue;
            end
        end
        
        % Screen('DrawTexture', window, tex, [], windowRect);
        dstRect = windowRect;
        % bilinear filtering: filterMode = 1
        % DrawTexture(window, tex, srcRect, dstRect, rot, filterMode, ...)
        Screen('DrawTexture', window, tex, [], dstRect, [], 0);

        Screen('TextSize', window, 50);
        Screen('DrawText', window, labelText, marginX, marginY, labelColor);

        if debug
            Screen('TextSize', window, 50);
            Screen('DrawText', window, subLabelText, marginX, marginY + 60, labelColor);
        end

        Screen('Flip', window);
        Screen('Close', tex);

        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown && keyCode(KbName('ESCAPE'))
            break;
        end
    end

    RestrictKeysForKbCheck([]);
end
