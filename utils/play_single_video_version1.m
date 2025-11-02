function [next_state, quit, selection_made, watched_ref, watched_test1, chosen_video] = play_single_video_version1( ...
    window, windowRect, vid, trial_num, num_trials, watched_ref, watched_test1, must_watch_all, debug)
    
    % First version: users press left and right arrow to switch videos
    % LeftArrow → jump to Video 1 and restart from the beginning
    % RightArrow → jump to Video 2 and restart from the beginning
    quit = false; next_state = ''; selection_made = false; 
    chosen_video = ''; 
    last_choice_tag = NaN;     % 1 => chose Video 1, 2 => chose Video 2 (pending SPACE)
    assert(numel(vid.paths) >= 2, 'vid.paths must contain {ref, test}.');

    % Optional labels/colors
    lbls = {'VIDEO 1','VIDEO 2'};
    cols = {[255 255 255], [255 255 255]}; % white

    % Randomly assign which actual file is Video 1 and Video 2
    % vid.paths{1} is reference, vid.paths{2} is test (original indices)
    % If idxVideo1 == 1, Video 1 is the reference video.
    % If idxVideo1 == 2, Video 1 is the test video.
    order = randperm(2);
    idxVideo1 = order(1);   % original index (1=ref, 2=test)
    idxVideo2 = order(2);   

    % For tracking completion (seen end once)
    seen1 = false;  % for the actual video currently assigned as "Video 1"
    seen2 = false;  % for the actual video currently assigned as "Video 2"

    % Start on Video 1, keeps track of which video is currently active
    curTag = 1;  % 1 => "Video 1", 2 => "Video 2"
    % whether the participant has to fully watch the current video once before being allowed to switch
    first_pass = must_watch_all;

    % Helper to map tag -> original vid index (1=ref, 2=test)
    % input tag == 1 -> ref, tag == 2 -> test
    tag2orig = @(tag) (tag==1)*idxVideo1 + (tag==2)*idxVideo2;

    % Open first movie
    % if origIdx = 1 -> ref, if origIdx = 2 -> test
    origIdx = tag2orig(curTag);
    movie = Screen('OpenMovie', window, vid.paths{origIdx}, [], 1, 0, 4);
    Screen('SetMovieTimeIndex', movie, 0);
    show_trial_screen(window, windowRect, trial_num, num_trials, 500); 
    % % Replace KbReleaseWait with a timed drain:
    % t0 = GetSecs;
    % while KbCheck
    %     if GetSecs - t0 > 0.5, break; end
    %     WaitSecs(0.01);
    % end

    Screen('PlayMovie', movie, 1);

    maybe_flash_before_play(window, windowRect, movie, getFlashOpts(vid));

    while true
        
        tex = Screen('GetMovieImage', window, movie);
        if tex <= 0
            % End of this movie -> mark seen and loop
            if curTag == 1, seen1 = true; else, seen2 = true; end
            if tag2orig(curTag) == 1, watched_ref = true; else, watched_test1 = true; end

            Screen('SetMovieTimeIndex', movie, 0);
            Screen('PlayMovie', movie, 1);

            if first_pass, first_pass = false; end
            continue;
        end

        dstRect = windowRect;
        % bilinear filtering: filterMode = 1
        % DrawTexture(window, tex, srcRect, dstRect, rot, filterMode, ...)
        Screen('DrawTexture', window, tex, [], dstRect, [], 1);
        % Screen('DrawTexture', window, tex, [], windowRect);

        Screen('TextSize', window, 50);
        Screen('DrawText', window, lbls{curTag}, 20, 20, cols{curTag});
        if debug
            Screen('DrawText', window, vid.labels{origIdx}, 20, 70, cols{curTag});
        end
        Screen('Flip', window);
        Screen('Close', tex);

        % [keyIsDown, ~, keyCode] = KbCheck;
        KbName('UnifyKeyNames');
        allowed = [KbName('ESCAPE') KbName('LeftArrow') KbName('RightArrow') KbName('SPACE')];
        RestrictKeysForKbCheck(allowed);

        prevKeyDown = false; 
        % % While first_pass == true, the loop continues before any of the key cases run
        % if first_pass
        %     continue
        % end
        [keyIsDown, ~, keyCode] = KbCheck;
        
        % ESC always allowed (edge-triggered)
        if keyIsDown && keyCode(KbName('ESCAPE')) && ~prevKeyDown
            quit = true; next_state = 'ESCAPE'; break;
        end
        % During first pass: warn on any other key but keep the movie running
        disp('first_pass');
        disp(first_pass);
        disp(keyIsDown);
        if first_pass
            if keyIsDown
                % show_warning(window, windowRect, 'Please finish watching this video before interacting!', 600);
                if debug
                    show_warning(window, windowRect, 'finish this one', 500);
                else
                    show_warning(window, windowRect, 'Please finish watching this video!', 500);
                end
                % KbReleaseWait;
            end
            prevKeyDown = keyIsDown;   % remember state for edge-triggering
            continue;                  % ignore other input until first pass done
        end


        if keyIsDown && ~prevKeyDown
            if keyCode(KbName('ESCAPE'))
                quit = true; next_state = 'ESCAPE'; break;

            elseif keyCode(KbName('LeftArrow'))
                % --- Go to "Video 1" from the beginning
                if curTag ~= 1
                    show_noisy_screen(window, windowRect, 500);
                    Screen('PlayMovie', movie, 0);
                    Screen('CloseMovie', movie);

                    curTag = 1;
                    origIdx = tag2orig(curTag);
                    first_pass = must_watch_all;   % enforce full watch for newly opened video if needed

                    disp('LeftArrow');
                    disp(vid.paths{origIdx});
                    movie = Screen('OpenMovie', window, vid.paths{origIdx}, [], 1, 0, 4);
                end
                
                maybe_flash_before_play(window, windowRect, movie, getFlashOpts(vid));

                Screen('SetMovieTimeIndex', movie, 0);
                Screen('PlayMovie', movie, 1);
                last_choice_tag = 1;

            elseif keyCode(KbName('RightArrow'))
                % --- Go to "Video 2" from the beginning
                if curTag ~= 2
                    show_noisy_screen(window, windowRect, 500);
                    Screen('PlayMovie', movie, 0);
                    Screen('CloseMovie', movie);

                    curTag = 2;
                    origIdx = tag2orig(curTag);
                    first_pass = must_watch_all;

                    disp('RightArrow');
                    disp(vid.paths{origIdx});
                    movie = Screen('OpenMovie', window, vid.paths{origIdx}, [], 1, 0, 4);
                end

                maybe_flash_before_play(window, windowRect, movie, getFlashOpts(vid));

                Screen('SetMovieTimeIndex', movie, 0);
                Screen('PlayMovie', movie, 1);
                last_choice_tag = 2;

            elseif keyCode(KbName('SPACE'))
                % Require both actual videos to be seen at least once
                both_seen = (seen1 || (idxVideo1==1 && watched_ref) || (idxVideo1==2 && watched_test1)) && ...
                            (seen2 || (idxVideo2==1 && watched_ref) || (idxVideo2==2 && watched_test1));
            
                if ~both_seen
                    if debug
                        show_warning(window, windowRect, 'view both', 500);
                    else
                        show_warning(window, windowRect, 'Please view both videos before choosing!', 500);
                    end
                    continue;
                end
            
                if isnan(last_choice_tag)
                    show_warning(window, windowRect, 'Please make a choice (Left=Video 1, Right=Video 2) first!', 500);
                    continue;
                end
            
                % Map pending choice to 'reference' or 'test'
                if last_choice_tag == 1
                    chosen_video = ternary(idxVideo1 == 1, 'reference', 'test');
                else % last_choice_tag == 2
                    chosen_video = ternary(idxVideo2 == 1, 'reference', 'test');
                end
            
                % show_trial_screen(window, windowRect, trial_num, num_trials, 500);
                selection_made = true;
                next_state = 'next_trial';
                break;
            end
        end
        prevKeyDown = keyIsDown;  % update at end of loop
    end

    Screen('PlayMovie', movie, 0);
    Screen('CloseMovie', movie);
    RestrictKeysForKbCheck([]); 
    % KbReleaseWait;
    % --- with this:
    t0 = GetSecs;
    while KbCheck
        if GetSecs - t0 > 1.0   % 1 second timeout
            break
        end
        WaitSecs(0.02);
    end
end


