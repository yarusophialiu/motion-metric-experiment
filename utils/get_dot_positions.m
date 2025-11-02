function dotPosMap = get_dot_positions(baseDir)
    % Create a dictionary of video paths → flashing disc position [dotX, dotY]
    % baseDir: dir to video, e.g. 'C:\Users\15142\Projects\motion-metric\test_all_sequences_videos';

    dotPosMap = containers.Map();

    dotPosMap(fullfile(baseDir, 'attic', 'reference/video_1.mp4')) = [525, 131];
    dotPosMap(fullfile(baseDir, 'attic', 'reference/video_2.mp4')) = [525, 131];
    dotPosMap(fullfile(baseDir, 'bistro_exterior', 'reference/video_1.mp4')) = [880, 220];
    dotPosMap(fullfile(baseDir, 'bistro_interior', 'reference/video_1.mp4')) = [640, 180];
    dotPosMap(fullfile(baseDir, 'classroom', 'reference/video_1.mp4')) = [640, 180];
    dotPosMap(fullfile(baseDir, 'landscape', 'reference/video_1.mp4')) = [640, 180];
    dotPosMap(fullfile(baseDir, 'marbles', 'reference/video_1.mp4')) = [640, 180];
    dotPosMap(fullfile(baseDir, 'pink_room', 'reference/video_1.mp4')) = [640, 180];
    dotPosMap(fullfile(baseDir, 'subway', 'reference/video_1.mp4')) = [640, 180];
    dotPosMap(fullfile(baseDir, 'zeroday', 'reference/video_1.mp4')) = [640, 180];
end
