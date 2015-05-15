function varargout = doctest(what, mode, fid)
% Run examples embedded in documentation
%
% Usage
% =====
%
% doctest WHAT
% doctest WHAT normal
% doctest(WHAT, MODE, FID)
% SUCCESS = doctest(...)
% [NUM_TESTS_PASSED, NUM_TESTS, SUMMARY] = doctest(...)
%
% The parameter WHAT contains the name of the function or class for
% which to run the doctests. When running with Octave, WHAT can be the
% filename of a Texinfo file, in which case all @example blocks are processed.
% The parameter WHAT can also be a cell array of such items.
%
% The optional parameter MODE is always 'normal'. It exists for compatibility
% with Octave's test API.
%
% The optional parameter FID can be used to redirect all output to a file id
% other than stdout.
%
%
% When called with a single return value, return whether all tests have
% succeeded (SUCCESS).
%
% When called with two or more return values, return the number of tests
% passed (NUM_TESTS_PASSED), the total number of tests (NUM_TESTS) and a
% structure with the following fields:
%
%   SUMMARY.num_targets
%   SUMMARY.num_targets_passed
%   SUMMARY.num_targets_without_tests
%   SUMMARY.num_targets_with_extraction_errors
%   SUMMARY.num_tests
%   SUMMARY.num_tests_passed
%
% The field 'num_targets_with_extraction_errors' is probably only relevant
% when using Texinfo documentation on Octave, where it typically indicates
% malformed @example blocks.
%
%
% Description
% ===========
%
% Each time doctest runs a test, it's running a line of code and checking
% that the output is what you say it should be.  It knows something is an
% example because it's a line in help('your_function') that starts with
% '>>'.  It knows what you think the output should be by starting on the
% line after >> and looking for the next >>, two blank lines, or the end of
% the documentation.
%
%
% Examples
% ========
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
% Expecting an error
% ------------------
%
% doctest can deal with errors, a little bit.  For instance, this case is
% handled correctly:
%
% >> not_a_real_function(42)
% ??? ***ndefined ***
%
%
% (MATLAB spells this 'Undefined', while Octave uses 'undefined')
%
% But if the line of code will emit other output BEFORE the error message,
% the current version can't deal with that.  For more info see Issue #4 on
% the bitbucket site (below).  Warnings are different from errors, and they
% work fine.
%
%
% Wildcards
% ---------
%
% If you have something that has changing output, for instance line numbers
% in a stack trace, or something with random numbers, you can use a
% wildcard to match that part.
%
% >> datestr(now, 'yyyy-mm-dd')
% 2***
%
%
% Multiple lines of code
% ----------------------
%
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
% Shortcuts
% ---------
%
% You can optionally omit "ans = " when the output is unassigned.  But
% actual variable names (such as "x = " above) must be included.  Leading
% and trailing whitespace on each line of output will be discarded which
% gives some freedom to, e.g., indent the code output as you wish.
%
%
% Skipping tests
% --------------
%
% You can skip certain tests by marking them with a special comment.  This
% can be used, for example, for a test not expected to pass or to avoid
% opening a figure window during automated testing.
%
% >> a = 6         % doctest: +SKIP
% b = 42
% >> plot(...)     % doctest: +SKIP
%
%
% Limitations
% ===========
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
% Octave-specific notes
% =====================
%
% As Octave currently does not provide a evalc implementation, doctest
% implements a workaround based on the eval and diary functions. This has
% the unwanted side effect of all doctest output being echoed on stdout.
% As to not intermingle this "line noise" and doctest's progress reporting,
% doctest buffers the latter and prints it out after all tests have run
% (when running with Octave and if the FID parameter is stdout).
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
%
% Standalone Texinfo files can be tested using "doctest myfile.texinfo".
%
% FIXME: Instead of the current pre-parsing to add ">>" prompts, one could
% presumably refactor the testing code so that input lines are tried
% one-at-a-time checking the output after each.
%
%
% Terminology
% ===========
%
% A TARGET is a function, method, class or texinfo file.  Each TARGET comes
% with a docstring consisting of multiple DOCTESTS, i.e., question-answer
% snippets.
%
%
% History
% =======
%
% The original version was written by Thomas Smith and is available
% at http://bitbucket.org/tgs/doctest-for-matlab/src
%
% This modified version adds multiline and Octave support, among other things.
% It is available at https://github.com/catch22/octave-doctest
% See the CONTRIBUTORS file for a list of authors and contributors.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process parameters.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% print usage?
if nargin < 1
  help doctest;
  return;
end

% if given a single object, wrap it in a cell array
if ~iscell(what)
  what = {what};
end

% mode is always 'normal'
if nargin < 2
  mode = 'normal';
else
  mode = validatestring(mode, {'normal'}, 'doctest', 'mode');
end

% by default, print to stdout
if nargin < 3
  fid = 1;
end

% get terminal color codes
[color_ok, color_err, color_warn, reset] = doctest_colors(fid);

% print banner
fprintf(fid, 'Doctest v0.4.0-dev: this is Free Software without warranty, see source.\n');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Collect all targets to be tested.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
targets = [];
for i=1:numel(what)
  targets = [targets; doctest_collect(what{i})];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run all doctests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
summary = struct;
summary.num_targets = length(targets);
summary.num_targets_passed = 0;
summary.num_targets_without_tests = 0;
summary.num_targets_with_extraction_errors = 0;
summary.num_tests = 0;
summary.num_tests_passed = 0;

% if running with octave and printing to stdout: buffer all output to work around issue #6
run_buffered = is_octave() && fid == stdout;
if run_buffered
  progress_buffer = '';
end

% print warning banner to stdout when running octave
if is_octave()
  fprintf('\n======================================================================\n');
  fprintf('Start of temporary output (github.com/catch22/octave-doctest/issues/6)\n');
  fprintf('======================================================================\n');
end

% run all tests
for i=1:numel(targets)
  % run doctests for target and update statistics
  target = targets(i);
  progress_printf('%s %s ', target.name, repmat('.', 1, 55 - numel(target.name)));

  % extraction error?
  if target.error
    summary.num_targets_with_extraction_errors = summary.num_targets_with_extraction_errors + 1;
    progress_printf([color_err  'EXTRACTION ERROR' reset '\n\n']);
    progress_printf('    %s\n\n', target.error);
    continue;
  end

  % run doctest
  results = doctest_run(target.docstring);

  % determine number of tests passed
  num_tests = numel(results);
  num_tests_passed = 0;
  for j=1:num_tests
    if results(j).passed
      num_tests_passed = num_tests_passed + 1;
    end
  end

  % update summary
  summary.num_tests = summary.num_tests + num_tests;
  summary.num_tests_passed = summary.num_tests_passed + num_tests_passed;
  if num_tests_passed == num_tests
    summary.num_targets_passed = summary.num_targets_passed + 1;
  end
  if num_tests == 0
    summary.num_targets_without_tests = summary.num_targets_without_tests + 1;
  end

  % pretty print outcome
  if num_tests == 0
    progress_printf('NO TESTS\n');
  elseif num_tests_passed == num_tests
    progress_printf([color_ok 'PASS %4d/%-4d' reset '\n'], num_tests_passed, num_tests);
  else
    progress_printf([color_err 'FAIL %4d/%-4d' reset '\n\n'], num_tests - num_tests_passed, num_tests);
    for j = 1:num_tests
      if ~results(j).passed
        progress_printf('   >> %s\n\n', results(j).source);
        progress_printf([ '      expected: ' '%s' '\n' ], results(j).want);
        progress_printf([ '      got     : ' color_err '%s' reset '\n' ], results(j).got);
        progress_printf('\n');
      end
    end
  end
end

% print warning banner to stdout when running octave
if is_octave()
  fprintf('====================================================================\n');
  fprintf('End of temporary output (github.com/catch22/octave-doctest/issues/6)\n');
  fprintf('====================================================================\n\n');
end

% if running with octave, flush output buffer
if run_buffered
  fprintf(fid, '%s', progress_buffer);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Report summary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(fid, '\nSummary:\n\n');
if (summary.num_tests_passed == summary.num_tests)
  fprintf(fid, ['   ' color_ok 'PASS %4d/%-4d' reset '\n\n'], summary.num_tests_passed, summary.num_tests);
else
  fprintf(fid, ['   ' color_err 'FAIL %4d/%-4d' reset '\n\n'], summary.num_tests - summary.num_tests_passed, summary.num_tests);
end

fprintf(fid, '%d/%d targets passed, %d without tests', summary.num_targets_passed, summary.num_targets, summary.num_targets_without_tests);
if summary.num_targets_with_extraction_errors > 0
  fprintf(fid, [', ' color_err '%d with extraction errors' reset], summary.num_targets_with_extraction_errors);
end
fprintf(fid, '.\n\n');

if nargout == 1
  varargout = {summary.num_targets_passed == summary.num_targets};
elseif nargout > 1
  varargout = {summary.num_tests_passed, summary.num_tests, summary};
end


function progress_printf(template, varargin)
  str = sprintf(template, varargin{:});
  if run_buffered
    progress_buffer = strcat({progress_buffer}, {str});
    progress_buffer = progress_buffer{1};
  else
    fprintf(fid, str);
  end
end

end
