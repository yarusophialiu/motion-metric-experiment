function [quit, selection_made, watched_ref, watched_test1, chosen_video] = play_single_video( ...
    window, windowRect, vid, trial_num, num_trials, watched_ref, watched_test1, must_watch_all, debug)
    % Second version: play 2 videos fully, ask users to choose (with Back to replay and reshuffle videos)
    quit = false; 
    next_state = '';
    selection_made = false; 
    chosen_video = '';

    assert(numel(vid.paths) >= 2, 'vid.paths must contain {ref, test}.');

    show_trial_screen(window, windowRect, trial_num, num_trials, 500);

    % --- Shuffle test, reference videos ---
    order = randperm(2);
    idxVideo1 = order(1);
    idxVideo2 = order(2);

    lbls = {'VIDEO 1','VIDEO 2'};
    cols = {[255 255 255], [255 255 255]};

    % === Replay loop (allow reshuffle when pressing Back key) ===
    while true
        % ---------- Play Video 1 ----------
        movie1 = Screen('OpenMovie', window, vid.paths{idxVideo1}, [], 1, 0, 4);
        sub1 = ternary(idxVideo1 == 1, vid.labels{1}, vid.labels{2});
        maybe_flash_before_play(window, windowRect, movie1, get_flash_opts(vid), lbls{1}, sub1, debug);
        fprintf('\nvideo1: %s\n%s\n', sub1, vid.paths{idxVideo1});

        play_movie_once(window, windowRect, movie1, lbls{1}, sub1, cols{1}, debug);
        Screen('PlayMovie', movie1, 0);
        Screen('CloseMovie', movie1);
        if idxVideo1 == 1, watched_ref = true; else, watched_test1 = true; end

        show_noisy_screen(window, windowRect, 500);

        % ---------- Play Video 2 ----------
        movie2 = Screen('OpenMovie', window, vid.paths{idxVideo2}, [], 1, 0, 4);
        sub2 = ternary(idxVideo2 == 1, vid.labels{1}, vid.labels{2});
        maybe_flash_before_play(window, windowRect, movie2, get_flash_opts(vid), lbls{2}, sub2, debug);
        fprintf('video2: %s\n%s\n', sub2, vid.paths{idxVideo2});

        play_movie_once(window, windowRect, movie2, lbls{2}, sub2, cols{2}, debug);
        Screen('PlayMovie', movie2, 0);
        Screen('CloseMovie', movie2);
        if idxVideo2 == 1, watched_ref = true; else, watched_test1 = true; end

        % ---------- Choice screen ----------
        [quit, selection_made, next_state, chosen_video, replayRequested] = ...
            ask_choice(window, windowRect, debug, idxVideo1, idxVideo2, sub1, sub2);

        if quit || selection_made
            break; 
        elseif replayRequested
            % Reshuffle the order before replaying
            order = randperm(2);
            idxVideo1 = order(1);
            idxVideo2 = order(2);
            disp('Replaying with shuffled order:');
            disp(order);
            continue; 
        else
            continue;
        end
    end
end