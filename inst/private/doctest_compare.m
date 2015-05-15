function match = doctest_compare(want, got)
% Matches two strings together... they should be identical, except that the
% first one can contain '***', which matches anything in the second string.


% This looks bad, like hardcoding for lower-case "a href"
% and a double quote... but that's what MATLAB looks for too.
got = regexprep(got, '<a +href=".*?>', '');
got = regexprep(got, '</a>', '');

% WHY do they need backspaces?  huh.
got = regexprep(got, '.\x08', '');

want = strtrim(want);
got = strtrim(got);

if isempty(got) && (isempty(want) || strcmp(want, '***'))
    match = 1;
    return
end

want_escaped = regexptranslate('escape', want);
want_re = regexprep(want_escaped, '(\\\*){3}', '.*');
want_re = ['^' want_re '$'];


result = regexp(got, want_re, 'once');

match = ~ isempty(result);

end
