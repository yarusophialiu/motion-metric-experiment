function out = ternary(cond, a, b)
    % returns a if cond is true, else b
    if cond
        out = a;
    else
        out = b;
    end
end