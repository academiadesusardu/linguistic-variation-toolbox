function categories = allCategories(varargin)
%ALLCATEGORIES Set or get all the categories on which we are working.
%
% Syntax:
%   V = allCategories()
%       Get the set of all the categories on which we are working.
%
%   allCategories(V)
%       Set the categories on which we are working to V.

% Copyright 2023 Acadèmia de su Sardu APS
persistent storedCategories

assert(nargin>=0 & nargin<=1, ...
    "This function can only be called with zero or one argument.");

if nargin==0
    categories = storedCategories;
    assert(~isempty(categories), ...
        "You should first set the categories by calling 'allCategories' with an input");
end
if nargin==1
    argument = varargin{1};
    assert( ...
        (isstring(argument) | iscellstr(argument)) & length(argument)>1, ...
        "Input should be an array of strings or a cell array containing chars with more than one element.");
    storedCategories = unique(string(argument));
end
end

