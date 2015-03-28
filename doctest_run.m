function results = doctest_run(docstring)
%DOCTEST_RUN - used internally by doctest
%
% Usage:
%   doctest_run(docstring)
%       Runs all the examples in the given docstring and returns a
%       structure with the results from running.
%
% The return value is a structure with the following fields:
%
% results.source:   the source code that was run
% results.want:     the desired output
% results.got:      the output that was recieved
% results.pass:     whether .want and .got match each other according to
%       doctest_compare.
%

% start with Examples: ..., end before "\nSee also ..." (if any)
[~,~,~,~,matches] = regexp(docstring, 'Examples:\s*\n(.*)\n\s*See also ');
if length(matches) > 0
  docstring = matches{1}{1};
end

% loosely based on Python 2.6 doctest.py, line 510
example_re = '(?m)(?-s)(?:^ *>> )(.*(\n *\.\. .*)*)\n((?:(?:^ *$\n)?(?!\s*>>).*\S.*\n)*)';
[~,~,~,~,examples] = regexp(docstring, example_re);

for i = 1:length(examples)
  % split into lines
  lines = textscan(examples{i}{1}, '%s', 'delimiter', sprintf('\n'));
  lines = lines{1};

  % replace initial '..' by '  ' in subsequent lines
  examples{i}{1} = lines{1,1};
  for j=2:length(lines)
    examples{i}{1} = sprintf('%s\n     %s', examples{i}{1}, lines{j,1}(4:end));
  end
end

% run tests and store results
all_outputs = DOCTEST__evalc(examples);
results = [];
for i = 1:length(examples)
  want_unspaced = regexprep(examples{i}{2}, '\s+', ' ');
  got_unspaced = regexprep(all_outputs{i}, '\s+', ' ');
  results(i).source = examples{i}{1};
  results(i).want = strtrim(want_unspaced);
  results(i).got = strtrim(got_unspaced);
  results(i).pass = doctest_compare(want_unspaced, got_unspaced);
end

end


% the following function is used to evaluate all lines of code in same
% namespace (the one of this invocation of DOCTEST__evalc)
function DOCTEST__results = DOCTEST__evalc(DOCTEST__examples_to_run)

% Octave has [no evalc command](https://savannah.gnu.org/patch/?8033).
have_evalc = true;
try
  evalc('');
catch
  have_evalc = false;
end

% structure adapted from a StackOverflow answer by user Amro, see
% http://stackoverflow.com/questions/3283586 and
% http://stackoverflow.com/users/97160/amro
DOCTEST__results = cell(size(DOCTEST__examples_to_run));
for DOCTEST__i = 1:numel(DOCTEST__examples_to_run)
  try
    if (have_evalc)
      DOCTEST__results{DOCTEST__i} = evalc( ...
          DOCTEST__examples_to_run{DOCTEST__i}{1});
    else
      DOCTEST__results{DOCTEST__i} = doctest_fake_evalc( ...
          DOCTEST__examples_to_run{DOCTEST__i}{1});
    end
  catch DOCTEST__exception
    DOCTEST__results{DOCTEST__i} = DOCTEST__format_exception(DOCTEST__exception);
  end
end

end


function formatted = DOCTEST__format_exception(ex)

  try
    OCTAVE_VERSION;
    running_octave = 1;
  catch
    running_octave = 0;
  end

  if running_octave
      formatted = ['??? ' ex.message];
      return
  end

if strcmp(ex.stack(1).name, 'DOCTEST__evalc')
    % we don't want the report, we just want the message
    % otherwise it'll talk about evalc, which is not what the user got on
    % the command line.
    formatted = ['??? ' ex.message];
else
    formatted = ['??? ' ex.getReport('basic')];
end

end


function s = doctest_fake_evalc(cmd)
%DOCTEST_FAKE_EVALC
%   A helper routine to (poorly) emulate evalc using diary and a temp
%   file.  Octave has no evalc command (as of 2015-02).
%   FIXME: this spams stdout as well as capturing.

  tf = tmpnam();
  diary(tf)
  % could have escaped newlines?  No, eval doesn't like them.
  %cmd = strrep(cmd, '\n', sprintf('\n'))
  evalin('caller', cmd);
  diary off
  s = fileread(tf);
  unlink(tf);
end
