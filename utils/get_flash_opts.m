function flash = get_flash_opts(vid)
    if isfield(vid, 'flash')
        flash = vid.flash;
    else
        flash = [];
    end
end