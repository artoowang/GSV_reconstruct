function path = getpathByPanoIdx(panoIdx, folderPath, filesPerFolder, digitsPerFolder)
% Function GETPATHBYPANOIDX generates the path to the folder containing 
% particular panorama or cutout image respectively defined by PANOIDX. 
% FOLDERPATH is the absolute path to the folder containig 'xxx/' subdirectories
% where xxx is N-digit format of subfolder name. FILESPERFOLDER defines number
% of panoramas saved in each folder except the last one, DIGITSPERFOLDER defines number
% of digits of subfolder filenames g.e. 'myFolder/045/' holds 3 digits format.
%
% By Petr Gronat @ 2011

folderID = (panoIdx-mod(panoIdx, filesPerFolder))/filesPerFolder;
    path = num2strdigits(folderID, digitsPerFolder);
    path = [folderPath path '/'];
end
