function result = test_method(obj, varargin)
%
% >> m = test_class; test_method(m)
% ans = My name is 42 years old.

result = sprintf('%s is %d years old.', obj.name, obj.age);

end
