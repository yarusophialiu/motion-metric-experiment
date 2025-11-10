function dot_pos_map = get_dot_positions(baseDir, index)
%GET_DOT_POSITIONS Create a dictionary of video paths → flashing dot position [dotX, dotY]
%
% Usage:
%   dot_pos_map = get_dot_positions(baseDir)          % random pick
%   dot_pos_map = get_dot_positions(baseDir, index)   % index = 1 or 2 (fixed)
%
% baseDir: directory to all videos (e.g. 'C:\...\test_all_sequences_videos')
% index:   optional, 1 or 2. If provided, selects that position instead of random.

    mp4name = 'reference/video_0.mp4';
    dot_pos_map = containers.Map();

    % Helper to choose one of two positions
    function pos = choose(p1, p2)
        if nargin < 2
            error('Need two positions');
        end
        if exist('index', 'var') && ~isempty(index)
            if index == 1
                pos = p1;
            elseif index == 2
                pos = p2;
            else
                error('index must be 1 or 2');
            end
        else
            % Random pick if no index
            if rand < 0.5
                pos = p1;
            else
                pos = p2;
            end
        end
    end

    % Scene positions
    dot_pos_map(fullfile(baseDir, 'attic', mp4name))            = choose([710,195], [316,352]);
    dot_pos_map(fullfile(baseDir, 'bistro_exterior', mp4name))  = choose([1213,151], [1146,334]);
    dot_pos_map(fullfile(baseDir, 'bistro_interior', mp4name))  = choose([452,456], [420,197]);
    dot_pos_map(fullfile(baseDir, 'classroom', mp4name))        = choose([805,288], [1088,215]);
    dot_pos_map(fullfile(baseDir, 'landscape', mp4name))        = choose([573,423], [1045,192]);
    dot_pos_map(fullfile(baseDir, 'marbles', mp4name))          = choose([335,269], [487,315]);
    dot_pos_map(fullfile(baseDir, 'pinkroom', mp4name))         = choose([993,331], [862,168]);
    dot_pos_map(fullfile(baseDir, 'subway', mp4name))           = choose([813,915], [1103,414]);
    dot_pos_map(fullfile(baseDir, 'zeroday', mp4name))          = choose([512,427], [453,405]);
end

% function dot_pos_map = get_dot_positions(baseDir)
% % Create a dictionary of video paths → flashing disc position [dotX, dotY]
% % baseDir: dir to video, e.g. 'C:\...\test_all_sequences_videos'
% % Each scene has TWO candidate positions; one is chosen at random (per call).
%     mp4name = 'reference/video_0.mp4';
%     dot_pos_map = containers.Map();
% 
%     % helper: pick one of two [x y] positions at random
%     pick = @(p1, p2) ( (rand < 0.5) * p1 + (rand >= 0.5) * p2 );
% 
%     % attic
%     dot_pos_map(fullfile(baseDir, 'attic', mp4name)) = pick([710,195], [316,352]);
% 
%     % bistro_exterior
%     dot_pos_map(fullfile(baseDir, 'bistro_exterior', mp4name)) = pick([1213,151], [1146,334]);
% 
%     % bistro_interior
%     dot_pos_map(fullfile(baseDir, 'bistro_interior', mp4name)) = pick([452,456], [420,197]);
% 
%     % classroom
%     dot_pos_map(fullfile(baseDir, 'classroom', mp4name)) = pick([805,288], [1088,215]);
% 
%     % landscape
%     dot_pos_map(fullfile(baseDir, 'landscape', mp4name)) = pick([573,423], [1045,192]);
% 
%     % marbles
%     dot_pos_map(fullfile(baseDir, 'marbles', mp4name)) = pick([335,269], [487,315]);
% 
%     % pink room
%     dot_pos_map(fullfile(baseDir, 'pinkroom',  mp4name)) = pick([993,331], [862,168]);
% 
%     % subway
%     dot_pos_map(fullfile(baseDir, 'subway', mp4name)) = pick([813,915], [1103,414]);
% 
%     % zeroday
%     dot_pos_map(fullfile(baseDir, 'zeroday', mp4name)) = pick([512,427], [453,405]);
% end


% function dot_pos_map = get_dot_positions(baseDir)
%     % Create a dictionary of video paths → flashing disc position [dotX, dotY]
%     % baseDir: dir to video, e.g. 'C:\Users\15142\Projects\motion-metric\test_all_sequences_videos';
% 
%     dot_pos_map = containers.Map();
%     mp4name = 'reference/video_0.mp4';
%     dot_pos_map(fullfile(baseDir, 'attic', mp4name)) = [525, 131];
%     % dot_pos_map(fullfile(baseDir, 'attic', mp4name)) = [525, 131];
%     dot_pos_map(fullfile(baseDir, 'bistro_exterior', mp4name)) = [880, 220];
%     dot_pos_map(fullfile(baseDir, 'bistro_interior', mp4name)) = [640, 180];
%     dot_pos_map(fullfile(baseDir, 'classroom', mp4name)) = [640, 180];
%     dot_pos_map(fullfile(baseDir, 'landscape', mp4name)) = [640, 180];
%     dot_pos_map(fullfile(baseDir, 'marbles', mp4name)) = [640, 180];
%     dot_pos_map(fullfile(baseDir, 'pink_room', mp4name)) = [640, 180];
%     dot_pos_map(fullfile(baseDir, 'subway', mp4name)) = [640, 180];
%     dot_pos_map(fullfile(baseDir, 'zeroday', mp4name)) = [640, 180];
% end
