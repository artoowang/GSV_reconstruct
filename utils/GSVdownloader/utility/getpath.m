function p = genpath2depth(d, depth, maxDepth)
% Function GETPATH is modification of matlab GETPATH function. Its output P
% is the string containing paths to subridectories of folder D to the level 
% MAXDEPTH. The variable DEPTH ust be always equal to 0 and appears there to 
% avoid the the usage of global variable.
%
% Usage:
% >p=genpath2depth(mainPath, 0, 2);
% >addpath(p);
%
% This searches for subdirectories of the folder for the firs two levels.
%
% By Petr Gronat @2011
    p = '';           % path to be returned
    fprintf('Depth: %f \n', depth)
    if depth<maxDepth-1
        % Generate path based on given root directory
        files = dir(d);
        if isempty(files)
          return
        end
        % Add d to the path even if it is empty.
        p = [p d pathsep];
        % set logical vector for subdirectory entries in d
        isdir = logical(cat(1,files.isdir));
        dirid = find(isdir);
        %
        % Recursively descend through directories
        %
        if  3<=length(dirid)
            for i=3:length(dirid)
           dirname = files(dirid(i)).name;
                 p = [p genpath2depth(fullfile(d,dirname), depth+1, maxDepth)]; % recursive calling of this function.
            end% for
        end % if subdirs are included
    else
        files = dir(d);
        if isempty(files)
          return
        end
        p = [p d pathsep];
        isdir = logical(cat(1,files.isdir));
        dirid = find(isdir);
        if  3<=length(dirid)
            for i=3:length(dirid)
           dirname = files(dirid(i)).name;
                 p = [p d '/' dirname pathsep]; % recursive calling of this function.
            end% for
       end % if subdirs are included
    end% if maxDepth 
end 