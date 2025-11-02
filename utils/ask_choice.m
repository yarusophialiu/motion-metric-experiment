function [quit, selection_made, next_state, chosen_video, replayRequested] = ...
    ask_choice(window, windowRect, debug, idxVideo1, idxVideo2, sub1, sub2)

    quit = false; selection_made = false; replayRequested = false;
    next_state = ''; chosen_video = '';

    KbName('UnifyKeyNames');
    names1 = {'1!','1','KP_1','Numpad1','1 End','1 (KP)'};
    names2 = {'2@','2','KP_2','Numpad2','2 Down','2 (KP)'};
    codes1 = unique(safeKbNames(names1));
    codes2 = unique(safeKbNames(names2));

    escCode  = safeKbName('ESCAPE');
    backCode = safeKbName('BackSpace');
    bCode    = safeKbName('b');
    allowed  = unique([escCode, backCode, bCode, codes1(:).', codes2(:).']);
    allowed  = allowed(allowed>0);
    RestrictKeysForKbCheck(allowed);

    % Prompt screen
    Screen('FillRect', window, 0, windowRect);
    Screen('TextSize', window, 60);
    DrawFormattedText(window, 'Which one is better?', 'center', windowRect(4)*0.30, [255 255 255]);
    Screen('TextSize', window, 48);
    if debug
        DrawFormattedText(window, sprintf('First one (press 1) [%s]', sub1), 'center', 'center', [200 200 200]);
        DrawFormattedText(window, sprintf('Second one (press 2) [%s]', sub2), 'center', windowRect(4)*0.60, [200 200 200]);
    else
        DrawFormattedText(window, 'First one (press 1)', 'center', 'center', [200 200 200]);
        DrawFormattedText(window, 'Second one (press 2)', 'center', windowRect(4)*0.60, [200 200 200]);
    end
    Screen('TextSize', window, 28);
    DrawFormattedText(window, 'Press Backspace to replay (order reshuffles)', ...
        'center', windowRect(4)*0.85, [160 160 160]);
    Screen('Flip', window);

    % Wait for keypress
    prevDown = false;
    while true
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown && ~prevDown
            if escCode>0 && keyCode(escCode)
                quit = true; next_state = 'ESCAPE'; break;
            elseif (backCode>0 && keyCode(backCode)) || (bCode>0 && keyCode(bCode))
                replayRequested = true; break;
            elseif any(keyCode(codes1))
                chosen_video   = ternary(idxVideo1 == 1, 'reference', 'test');
                selection_made = true; next_state = 'next_trial'; break;
            elseif any(keyCode(codes2))
                chosen_video   = ternary(idxVideo2 == 1, 'reference', 'test');
                selection_made = true; next_state = 'next_trial'; break;
            end
        end
        prevDown = keyIsDown;
        WaitSecs(0.01);
    end

    RestrictKeysForKbCheck([]);
    t0 = GetSecs; 
    while KbCheck
        if GetSecs - t0 > 0.5, break; end
        WaitSecs(0.02);
    end
end

function codes = safeKbNames(nameList)
    codes = zeros(1, numel(nameList));
    for i = 1:numel(nameList)
        codes(i) = safeKbName(nameList{i});
    end
    codes = codes(~isnan(codes));
end

function code = safeKbName(nameStr)
    try
        code = KbName(nameStr);
        if isempty(code), code = NaN; end
    catch
        code = NaN;
    end
end
