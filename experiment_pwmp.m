function experiment_pwmp()
    % For the output CSV file, only look at refPath_A, testPath_A
    FULL_SCREEN_MODE = true; % true false
    TITANIUM = false; % true
    DEBUG = true; % print reference and test on the screen

    % userid = input('Enter user ID: ', 's');
    userid = 'test_id';
    session_time = datestr(now, 'yyyymmdd_HHMMSS');
    csv_folder = fullfile(pwd, 'results');
    csv_filename = fullfile(csv_folder, sprintf('fixed_%s_%s.csv', userid, session_time));
    fprintf('csv_filename %s', csv_filename);

    % --- Window setup ---
    Screen('Preference', 'SkipSyncTests', 1);
    KbName('UnifyKeyNames');
    screenNumber = 1; % min(screens); % Use 1 for LG, 0 for main 

    % % Below could fix high contrast issue for some GPU
    % % My PC may be loading an ICC profile or Psychtoolbox identity-gamma table at startup
    % % Some GPU probably may not
    % ENABLE_GAMMA_TABLE = false;
    % if ENABLE_GAMMA_TABLE
    %     gammaTab = repmat(linspace(0,1,256)', 1, 3);   % identity (linear) LUT
    %     Screen('LoadNormalizedGammaTable', screenNumber, gammaTab);
    % end

    if ~FULL_SCREEN_MODE
        rect = [100 100 900 700];
        [window, windowRect] = Screen('OpenWindow', screenNumber, 0, rect);
    else
        [window, windowRect] = Screen('OpenWindow', screenNumber, 0); % fullscreen
    end

    if TITANIUM
        gfxdisp_path = 'D:\gfxdisp';
        mm_project_path = 'D:\motion-metric';
    else
        gfxdisp_path = 'C:\Users\15142\Projects\gfxdisp';
        mm_project_path = 'C:\Users\15142\Projects\motion-metric';
    end
    video_path = fullfile(mm_project_path, 'test_all_sequences_videos');
    addpath(fullfile(pwd, 'utils'));
    addpath(fullfile(gfxdisp_path, 'ASAP'));
    parent_folder = fullfile(mm_project_path, 'test_all_sequences_videos');
    condition_table = build_ref_test_table(parent_folder);
    dot_pos_map = get_dot_positions(video_path);

    sch = PwcmpASAPScheduler(csv_filename, userid, condition_table, {'scene'}); % Ignore the warning thrown by PwcmpASAPScheduler
    [sch, N_left] = sch.get_pair_left();
    fprintf('%d pairwise comparisons in this batch\n', N_left);
    % num_tests = N_left * 4;
    num_tests = 1;
    

    for p = 1:num_tests
        watched_ref = false;
        watched_test1 = false;
        quit = false;
        selection_made = false;
        % returns two rows belonging to the same scene/path 1 2      
        [sch, iA, iB] = sch.get_next_pair(); 
        rowA = condition_table(iA,:);
        % rowB = condition_table(iB,:);

        fprintf('\nScene "%s"\n', rowA.scene{1});
        fprintf('Ref path "%s"\n', rowA.refPath{1});
        fprintf('Test path "%s"\n', rowA.testPath{1});

        try
            vid.paths  = { rowA.refPath{1}, rowA.testPath{1} };  
            vid.labels = { 'REFERENCE','TEST' };                
            vid.flash.enabled = true;
            vid.flash.duration = 1.0;   % seconds
            vid.flash.hz       = 4;     % flashes per second
            vid.flash.radius   = 12;    % pixels

            key = rowA.refPath{1};
            if isKey(dot_pos_map, key)
                pos = dot_pos_map(key);
                vid.flash.dotX = pos(1); % pixels windowRect(3) = display width, set to e.g. windowRect(3)/2
                vid.flash.dotY = pos(2); % pixels windowRect(4) = display height
            else
                error('Dot position not defined for video path:\n%s', key);
            end

            fprintf('dotX = %.2f, dotY = %.2f\n', vid.flash.dotX, vid.flash.dotY);
            fprintf('Window width  = %.2f\n', windowRect(3));
            fprintf('Window height = %.2f\n', windowRect(4));
            
            % must watch each video once before input is accepted
            must_watch_all = true;        
            [quit, selection_made, watched_ref, watched_test1, chosen_video] = ...
                play_single_video(window, windowRect, vid, p, num_tests, ...
                                  watched_ref, watched_test1, must_watch_all, DEBUG);
            if quit
                break;  % ESC key
            end
        
            if selection_made
                fprintf('chosen_video: %s\n', chosen_video);
                if strcmp(chosen_video, 'reference')
                    sch = sch.set_pair_result(1);  
                elseif strcmp(chosen_video, 'test')
                    sch = sch.set_pair_result(0);   
                else
                    sch = sch.set_pair_result(-1);  
                end
            end
        
        catch ME
            Screen('CloseAll');
            rethrow(ME);
        end
    end

    Screen('CloseAll');
    sca;
end


