function T = build_ref_test_table(rootDir)
% Create a table of (scene, subfolder, refPath, testPath)
% Pair: reference/video_*.mp4 vs distortion/<level>/video_*.mp4 under the same scene
    rows_scene  = {};
    rows_ref    = {};
    rows_test   = {};

    scenes = dir(rootDir);
    scenes = scenes([scenes.isdir]);
    scenes = scenes(~ismember({scenes.name},{'.','..'}));  % only scene folders

    for s = 1:numel(scenes)
        sceneName = scenes(s).name;
        scenePath = fullfile(rootDir, sceneName);

        % ---- reference videos directly under <scene>\reference
        refDir = fullfile(scenePath, 'reference');
        if ~isfolder(refDir)
            warning('No reference folder: %s', refDir);
            continue;
        end
        refFiles = dir(fullfile(refDir, 'video_*.mp4'));
        if isempty(refFiles)
            warning('No reference videos in %s', refDir);
            continue;
        end

        refMap = containers.Map('KeyType','char','ValueType','char');
        for i = 1:numel(refFiles)
            refMap(refFiles(i).name) = fullfile(refDir, refFiles(i).name);
        end

        % distortion folders (everything except "reference")
        distFolders = dir(scenePath);
        distFolders = distFolders([distFolders.isdir]);
        distFolders = distFolders(~ismember({distFolders.name},{'.','..','reference'}));

        for d = 1:numel(distFolders)
            distPath = fullfile(scenePath, distFolders(d).name);

            % subfolders under distortion (e.g., level0, level1, ...) subFolders(L).name
            subFolders = dir(distPath);
            subFolders = subFolders([subFolders.isdir]);
            subFolders = subFolders(~ismember({subFolders.name},{'.','..'}));

            if isempty(subFolders)
                % if no subfolder, use the distortion folder itself subFolders(L).name
                addPairsFromFolder(distPath);
            else
                for L = 1:numel(subFolders)
                    lvlPath = fullfile(distPath, subFolders(L).name);
                    addPairsFromFolder(lvlPath);
                end
            end
        end
    end

    % Build output table
    T = table(string(rows_scene'), string(rows_ref'), string(rows_test'), ...
        'VariableNames', {'scene', 'refPath','testPath'});

    function addPairsFromFolder(folderPath)
        testFiles = dir(fullfile(folderPath, 'video_*.mp4'));
        if isempty(testFiles)
            return;
        end
        for t = 1:numel(testFiles)
            name = testFiles(t).name; % e.g., "video_1.mp4"
            if isKey(refMap, name)
                rows_scene{end+1}  = sceneName;
                rows_ref{end+1}    = refMap(name);
                rows_test{end+1}   = fullfile(folderPath, name);
            end
        end
    end
end
