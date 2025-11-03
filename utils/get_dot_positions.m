function dot_pos_map = get_dot_positions(baseDir)
    % Create a dictionary of video paths → flashing disc position [dotX, dotY]
    % baseDir: dir to video, e.g. 'C:\Users\15142\Projects\motion-metric\test_all_sequences_videos';

    dot_pos_map = containers.Map();
    mp4name = 'reference/video_0.mp4';
    dot_pos_map(fullfile(baseDir, 'attic', mp4name)) = [525, 131];
    % dot_pos_map(fullfile(baseDir, 'attic', mp4name)) = [525, 131];
    dot_pos_map(fullfile(baseDir, 'bistro_exterior', mp4name)) = [880, 220];
    dot_pos_map(fullfile(baseDir, 'bistro_interior', mp4name)) = [640, 180];
    dot_pos_map(fullfile(baseDir, 'classroom', mp4name)) = [640, 180];
    dot_pos_map(fullfile(baseDir, 'landscape', mp4name)) = [640, 180];
    dot_pos_map(fullfile(baseDir, 'marbles', mp4name)) = [640, 180];
    dot_pos_map(fullfile(baseDir, 'pink_room', mp4name)) = [640, 180];
    dot_pos_map(fullfile(baseDir, 'subway', mp4name)) = [640, 180];
    dot_pos_map(fullfile(baseDir, 'zeroday', mp4name)) = [640, 180];
end
