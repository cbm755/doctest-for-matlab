function varargout = doctest(varargin)
% Run examples embedded in documentation
%
% doctest func_name
% doctest('func_name')
% doctest class_name
% doctest('class_name')
% doctest class_name1 func_name2 class_name3 ...
%
% Example:
% Say you have a function that adds 7 to things:
%     function res = add7(num)
%         % >> add7(3)
%         %
%         % ans =
%         %
%         %      10
%         %
%         res = num + 7;
%     end
%
% Save that to 'add7.m'.  Now you can say 'doctest add7' and it will run
% 'add7(3)' and make sure that it gets back 'ans = 10'.  It prints out
% something like this:
%
%  add7: OK
%
% If the output of some function will change each time you call it, for
% instance if it includes a random number or a stack trace, you can put ***
% (three asterisks) where the changing element should be.  This acts as a
% wildcard, and will match anything.  See the example below.
%
% EXAMPLES:
%
% Running 'doctest doctest' will execute these examples and test the
% results.
%
% >> 1 + 3
%
% ans =
%
%      4
%
%
% Note the two blank lines between the end of the output and the beginning
% of this paragraph.  That's important so that we can tell that this
% paragraph is text and not part of the example!
%
% If there's no output, that's fine, just put the next line right after the
% one with no output.  If the line does produce output (for instance, an
% error), this will be recorded as a test failure.
%
% >> x = 3 + 4;
% >> x
%
% x =
%
%    7
%
%
% Exceptions:
% doctest can deal with errors, a little bit.  For instance, this case is
% handled correctly:
%
% >> not_a_real_function(42)
% ??? Undefined function
%
%
% But if the line of code will emit other output BEFORE the error message,
% the current version can't deal with that.  For more info see Issue #4 on
% the bitbucket site (below).  Warnings are different from errors, and they
% work fine.
%
% Wildcards:
% If you have something that has changing output, for instance line numbers
% in a stack trace, or something with random numbers, you can use a
% wildcard to match that part.
%
% >> dicomuid
% 1.3.6.1.4.1.***
%
%
% Multiple lines of code:
% Code spanning multiple lines of code can be entered by prefixing all
% subsequent lines with '..',  e.g.
%
% >> for i = 1:3
% ..   i
% .. end
%
% i = 1
% i = 2
% i = 3
%
%
% LIMITATIONS:
%
% The examples MUST END with either the END OF THE DOCUMENTATION or TWO
% BLANK LINES (or anyway, lines with just the comment marker % and nothing
% else).
%
% All adjacent white space is collapsed into a single space before
% comparison, so right now it can't detect anything that's purely a
% whitespace difference.
%
% When you're working on writing/debugging a Matlab class, you might need
% to run 'clear classes' to get correct results from doctests (this is a
% general problem with developing classes in Matlab).
%
% It doesn't say what line number/file the doctest error is in.  This is
% because it uses Matlab's plain ol' HELP function to extract the
% documentation.  It wouldn't be too hard to write our own comment parser,
% but this hasn't happened yet.  (See Issue #2 on the bitbucket site,
% below)
%
%
% OCTAVE-SPECIFIC NOTES:
%
% Octave m-files are commonly documented using Texinfo.  If you are running
% Octave and your m-file contains texinfo markup, then the rules noted above
% are slightly different.  First, text outside of "@example" ... "@end
% example" blocks is discarded.  As only examples are expected in those
% blocks, the two-blank-lines convention is not required.  A minor amount of
% reformatting is done (e.g., stripping the pagination hints "@group").
%
% Conventionally, Octave documentation indicates results with "@result{}"
% (which renders to an arrow).  If the text contains no ">>" prompts, we try
% to guess where they should be based on splitting around the "@result{}"
% indicators.  Additionally, all lines from the start of the "@example"
% block to the first "@result{}" are assumed to be commands.  These
% heuristics work for simple documentation but for more complicated
% examples, adding ">>" to the documentation may be necessary.
% FIXME: Instead of the current pre-parsing to add ">>" prompts, one could
% presumably refactor the testing code so that input lines are tried
% one-at-a-time checking the output after each.
%
%
% RETURN VALUES:
%
% [n, f, e] = doctest('class_name1', 'func_name1')
%
% Here 'n' is the number of test, 'f' is the number of failures and 'e' is
% the number of extract errors (probably only relevant when using Texinfo
% docs on Octave where it indicates malformed @example blocks).
%
%
% VERSIONS:
%
% The latest version from the original author, Thomas Smith, is available
% at http://bitbucket.org/tgs/doctest-for-matlab/src
%
% This version, created by Michael Walter for multiline and Octave
% support (among other things), is available at
% https://github.com/catch22/doctest-for-matlab

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Make a list of every method/function that we need to examine, in the
% to_test struct.
%

% determine whether we are running octave or matlab
try
  OCTAVE_VERSION;
  running_octave = 1;
catch
  running_octave = 0;
end

% We include a link to the function where the docstring is going to come
% from, so that it's easier to navigate to that doctest.
to_test = [];
for i = 1:nargin
  func_or_class = varargin{i};

  % If it's a class, add the methods to to_test.
  if (~running_octave)
    theMethods = methods(func_or_class);
  else
    % Octave unhappy on methods(<non-class>)
    if (exist(func_or_class, 'file') || exist(func_or_class, 'builtin'))
      theMethods = [];
    else
      theMethods = methods(func_or_class);
    end
  end

  if (isempty(theMethods))
    this_test = [];
    this_test.name = func_or_class;
    this_test.func_name = func_or_class;
    this_test.link = sprintf('<a href="matlab:editorservices.openAndGoToLine(''%s'', 1);">%s</a>', ...
            which(func_or_class), func_or_class);
    to_test = [to_test; this_test];
  end

  for I = 1:length(theMethods) % might be 0
    this_test = [];

    this_test.func_name = theMethods{I};
    if (running_octave)
      this_test.name = sprintf('@%s/%s', func_or_class, theMethods{I});
    else
      this_test.name = sprintf('%s.%s', func_or_class, theMethods{I});
    end

    try
        this_test.link = sprintf('<a href="matlab:editorservices.openAndGoToFunction(''%s'', ''%s'');">%s</a>', ...
            which(func_or_class), this_test.func_name, this_test.name);
    catch
        this_test.link = this_test.name;
    end

    to_test = [to_test; this_test];
  end
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Examine each function/method for a docstring, and run any examples in
% that docstring
%

[red, yellow, reset] = terminal_escapes();

all_results = cell(1, length(to_test));
all_extract_err = zeros(1, length(to_test), 'logical');
all_extract_msgs = cell(1, length(to_test));

if running_octave
  disp('==========================================================================')
  disp('Start of temporary output (github.com/catch22/doctest-for-matlab/issues/6)');
  disp('==========================================================================')
end

for I = 1:length(to_test)
    if running_octave
      [docstring, err, msg] = octave_extract_doctests(to_test(I).name);
    else
      err = 0; msg = '';
      docstring = help(to_test(I).name);
    end

    these_results = doctest_run(docstring);


    if ~ isempty(these_results)
        [these_results.link] = deal(to_test(I).link);
    end

    all_extract_err(I) = err;
    all_extract_msgs{I} = msg;
    all_results{I} = these_results;
    % Print the results after each file
    %print_test_results(to_test(I), these_results, err, msg);
end

if running_octave
  disp('========================================================================')
  disp('End of temporary output (github.com/catch22/doctest-for-matlab/issues/6)');
  disp('========================================================================')
end

total_test = 0;
total_fail = 0;
for I=1:length(all_results);
  [count, numfail] = print_test_results(to_test(I), all_results{I}, all_extract_err(I), all_extract_msgs{I});
  total_test = total_test + count;
  total_fail = total_fail + numfail;
end

num_extract_err = nnz(all_extract_err < 0);

fprintf(1, 'doctest: ran %d tests: %d failed.  %d extraction errors\n', ...
        total_test, total_fail, num_extract_err);
if (nargout > 0)
  varargout = {total_test, total_fail, num_extract_err};
end
end


function [total, errors] = print_test_results(to_test, results, extract_err, extract_msg)

out = 1; % stdout
err = 2;

total = length(results);
errors = 0;
for i = 1:total
  if ~results(i).pass
    errors = errors + 1;
  end
end

[red, yellow, reset] = terminal_escapes();

if total == 0 && extract_err < 0
  fprintf(err, ['%s: ' yellow  'Warning: could not extract tests' reset '\n'], to_test.name);
  fprintf(err, '  %s\n', extract_msg);
elseif total == 0
  fprintf(err, '%s: NO TESTS\n', to_test.name);
elseif errors == 0
  fprintf(out, '%s: OK (%d tests)\n', to_test.name, length(results));
else
  fprintf(err, ['%s: ' red '%d ERRORS' reset '\n'], to_test.name, errors);
end
for I = 1:length(results)
  if ~results(I).pass
    fprintf(out, '  >> %s\n\n', results(I).source);
    fprintf(out, '     expected: %s\n', results(I).want);
    fprintf(out, '     got     : %s\n', results(I).got);
  end
end


end



function [docstring, err, msg] = octave_extract_doctests(name)
%OCTAVE_EXTRACT_DOCTESTS

  err = 1; msg = '';

  [docstring, form] = get_help_text(name);

  if (~strcmp(form, 'texinfo'))
    err = 1;  msg = 'not texinfo';
    return
  end

  %% Just convert to plain text
  % Matlab parser unhappy with underscore, hide inside eval
  %docstring = eval('__makeinfo__(docstring, "plain text")');

  % strip @group, and escape sequences
  docstring = regexprep(docstring, '^\s*@group\n', '\n', 'lineanchors');
  docstring = regexprep(docstring, '@end group\n', '');
  docstring = strrep(docstring, '@{', '{');
  docstring = strrep(docstring, '@}', '}');
  docstring = strrep(docstring, '@@', '@');

  % no example block, bail out
  if (isempty(strfind(docstring, '@example')))
    err = 0;  msg = 'no @example blocks';
    docstring = '';
    return
  end
  % Leave the @example lines in, may need them later
  T = regexp(docstring, '(@example.*?@end example)', 'tokens');
  if (isempty(T))
    err = -1;  msg('malformed @example blocks');
    docstring = '';
    return
  else
    % flatten
    for i=1:length(T)
      assert(length(T{i}) == 1)
      T{i} = T{i}{1};
    end
    docstring = strjoin(T, '\n');
  end

  if (isempty(docstring) || ~isempty(regexp(docstring, '^\s*$')))
    err = -1;  msg = 'empty @example blocks';
    docstring = '';
    return
  end

  if (~isempty(strfind(docstring, '>>')))
    %% Has '>>' indicators
    err = 1;  msg = 'used >>';
  else
    %% No '>>', split on @result
    err = 2;  msg = 'used @result splitting';
    L = strsplit (docstring, '\n');

    % mask for lines with @result in them
    [S, ~, ~, ~, ~, ~, ~] = regexp(L, '@result\s*{}');
    Ires = ~cellfun(@isempty, S);
    if (nnz(Ires) == 0)
      docstring
      err = -2;  msg = 'has @example blocks but neither ">>" nor "@result{}"';
      docstring = '';
      return
    end
    if Ires(1)
      err = -4;  msg = 'no command: @result on first line?';
      return
    end
    for i=1:length(L)
      if (length(S{i}) > 1)
        err = -3;  msg = 'more than one @result on one line';
        docstring = '';
        return
      end
    end

    % mask for lines with @example in them
    Iex_start = ~cellfun(@isempty, regexp(L, '@example'));
    Iex_end = ~cellfun(@isempty, regexp(L, '@end example'));

    % build a new mask for lines which we think are commands
    I = zeros(size(Ires), 'logical');
    start_of_block = false;
    for i=1:length(L)-1
      if Iex_start(i)
        start_of_block = true;
      end
      if (start_of_block)
        I(i) = true;
      end
      if Ires(i+1)
        % Next line has an @result so mark this line with '>>'
        I(i) = true;
        start_of_block = false;
      end
    end
    % remove @example/@end lines from commands
    I(Iex_start) = false;
    I(Iex_end) = false;

    for i=1:length(L)
      if (I(i) && ~isempty(L{i}) && isempty(regexp(L{i}, '^\s+$', 'match')))
        L{i} = ['>> ' L{i}];
      end
    end
    docstring = strjoin(L, '\n');
    docstring = [docstring sprintf('\n')];
  end
  docstring = regexprep(docstring, '^\s*@example\n', '', 'lineanchors');
  docstring = regexprep(docstring, '^\s*@end example\n', '', 'lineanchors');
  docstring = regexprep(docstring, '@result\s*{}', '');
end


function [red, yellow, reset] = terminal_escapes()

  try
    OCTAVE_VERSION;
    running_octave = 1;
  catch
    running_octave = 0;
  end

  if (running_octave)
    % terminal escapes for Octave colour, hide from Matlab inside eval
    red = eval('"\033[1;40;31m"');
    yellow = eval('"\033[1;40;33m"');
    reset = eval('"\033[m"');
  else
    red = '';
    yellow = '';
    reset = '';
  end
end
