function varieties = allVarieties(varargin)
%ALLVARIETIES Set or get all the varieties on which we are working.
%
% Syntax:
%   V = allVarieties()
%       Get the set of all the varieties on which we are working.
%
%   allVarieties(V)
%       Set the varieties on which we are working to V.

% Copyright 2023 Acadèmia de su Sardu APS
persistent storedVarieties

assert(nargin>=0 & nargin<=1, ...
    "This function can only be called with zero or one argument.");

if nargin==0
    varieties = storedVarieties;
    assert(~isempty(varieties), ...
        "You should first set the varieties by calling 'allVarieties' with an input");
end
if nargin==1
    argument = varargin{1};
    assert( ...
        (isstring(argument) | iscellstr(argument)) & length(argument)>1, ...
        "Input should be an array of strings or a cell array containing chars with more than one element.");
    storedVarieties = unique(string(argument));
end
end

