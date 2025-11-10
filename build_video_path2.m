function p = build_video_path2(base_dir, scene, method, param, idx)
    if iscell(method), method = method{1}; end
    if isstring(method), method = char(method); end

    if iscell(param), param = param{1}; end
    if isstring(param), param = char(param); end
    if isnumeric(param), param = num2str(param); end

    fname = sprintf('video_%d.mp4', idx);

    if strcmpi(strtrim(method), 'reference')
        % video_path/scene/reference/video_0.mp4
        p = fullfile(base_dir, scene, method, fname);
    else
        % video_path/scene/restir/level0/video_0.mp4
        p = fullfile(base_dir, scene, method, param, fname);
    end
end