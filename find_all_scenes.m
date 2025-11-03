function scene = find_all_scenes(root_path)
% FIND_ALL_SCENES  Return all subfolder names under a given path as a cell array.
% scene = find_all_scenes('C:\your\folder\path');
% scene = {'A', 'B', 'C'}
    if nargin < 1 || ~isfolder(root_path)
        error('Please provide a valid folder path.');
    end
    entries = dir(root_path);

    % Keep only subfolders (exclude '.' and '..')
    is_subfolder = [entries.isdir];
    subfolders = entries(is_subfolder);
    subfolders = subfolders(~ismember({subfolders.name}, {'.', '..'}));

    % Create cell array of subfolder names
    scene = {subfolders.name};
end
