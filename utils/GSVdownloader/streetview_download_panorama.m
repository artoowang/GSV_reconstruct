%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION num_panos = streetview_download_panorama (path, dfname, tmp_path, gzoom_def)
%
% 	Download panoramas according to a given list of panorama IDs
%
% INPUTS:
%	path:		path to the directory storing downloaded panoramas 
%				(e.g., pano)
%	dfname:		path to the list file of panorama IDs (e.g., 
%				/cucs/web/w8/cpwang/public_html/Landmarks3/GSVScraper/data/0016.1339.0)
%				The file format is:
%				<seq_id>	<pano_id>	<latitude(deg)>	<longitude(deg)>
%	tmp_path:	directory to put temporary files
%	gzoom_def:	zoom level (default :4)
%
% OUTPUTS:
%	num_panos:	number of panoramas downloaded
%
% Author: M. Havlena
% Modified by: Chun-Po Wang, 2011 Cornell University
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function num_panos = streetview_download_panorama (path, dfname, tmp_path, gzoom_def)

if nargin<4
  gzoom_def = 4;
end

server = 1;

if(~exist(path, 'dir'))
	mkdir(path);
end

opath = pwd;
fid = fopen(dfname,'r');
num_panos = 0;

for idx=0:999999
  tline = fgetl(fid);
  if ~ischar(tline), break, end;
  if exist([path filesep sprintf('%.3d',floor(idx/1000)) filesep sprintf('%.6d',idx) '.jpg'],'file'), continue, end;
  tokens = regexp(tline, '^[0-9]+\s+(\S+)\s+', 'tokens');
  panoid = tokens{1}{1};

  gzoom = gzoom_def;
  imtile = fetch_im(gzoom,0,0,panoid,server,tmp_path);  
  
  if isempty(imtile) % not found at gzoom==4, trying gzoom==3
    gzoom = gzoom_def-1;
    imtile = fetch_im(gzoom,0,0,panoid,server,tmp_path);
  end

  switch gzoom
    case 3
      tilex = 0:6; tiley = 0:3; tilew = 512; tileh = 512; imw = 6.5*512;
    case 4
      tilex = 0:12; tiley = 0:6; tilew = 512; tileh = 512; imw = 13*512;
  end

  notfound = false;
  im = uint8(zeros(length(tiley)*tileh,length(tilex)*tilew,3));
  for i=tilex
    for j=tiley
      if (i~=0) || (j~=0), imtile = fetch_im(gzoom,i,j,panoid,server,tmp_path); end;
      if ~isempty(imtile), im(j*tileh+1:(j+1)*tileh,i*tilew+1:(i+1)*tilew,:) = imresize(imtile,[tileh tilew]); else notfound = true; end;
    end
  end
  if notfound, fprintf(1,'Pano %.6d may be incomplete!\n',idx); end;
  im = im(1:imw/2,1:imw,:);
  if gzoom < gzoom_def, im = imresize(im,2); end;
  if ~exist([path filesep sprintf('%.3d',floor(idx/1000))],'dir'), mkdir(path,sprintf('%.3d',floor(idx/1000))), end;
  imwrite(im, [path filesep sprintf('%.3d',floor(idx/1000)) filesep sprintf('%.6d',idx) '.jpg']);

  num_panos = num_panos + 1;
end

fclose(fid);
cd(opath);

end

function imtile = fetch_im(gzoom,i,j,panoid,server,tmp_path)
  fprintf('%d %d %d %s\n', gzoom,i,j,panoid);
  fn = sprintf('cbk?output=tile&zoom=%d&x=%d&y=%d&cb_client=maps_sv&fover=2&onerr=3&panoid=%s',gzoom,i,j,panoid);
  fn_path = sprintf('%s/%s', tmp_path, fn);
  cmd = sprintf('wget -nd -nH -q -nc -O ''%s'' "http://cbk%d.google.com/%s"', fn_path, server, fn);
  trials = 1; system(cmd); pause(0.1);
  while ~exist(fn_path,'file') && (trials < 3)
    pause(5); trials = trials + 1; system(cmd); pause(0.1);
  end
  if exist(fn_path,'file')
	try
    	imtile = imread(fn_path);
	catch err
		fprintf('imread() failed: %s. Skip\n', err.identifier);
		imtile = [];
	end
    delete(fn_path);
    if size(imtile,3) == 1, imtile = repmat(imtile,[1 1 3]); end; % B/W fix
  else
    imtile = [];
  end
end
