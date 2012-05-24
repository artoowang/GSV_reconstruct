%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION img = streetview_download_single_panorama (panoid, tmp_path, gzoom_def)
%
% 	Download a panorama according to a given panoID
%
% INPUTS:
%	panoid:		e.g., kmB3y5gq54UU67OtuOCvOA
%	tmp_path:	directory to put temporary files
%	gzoom_def:	zoom level (default :4)
%
% OUTPUTS:
%	img:		panorama image
%
% Author: M. Havlena
% Modified by: Chun-Po Wang, 2011 Cornell University
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function img = streetview_download_single_panorama (panoid, tmp_path, gzoom_def)

	if nargin<3
	  gzoom_def = 4;
	end

	server = 1;
	img = [];

	if(~exist(tmp_path, 'dir'))
		fprintf('Temporary output path %s does not exist', tmp_path);
		return;
	end

	gzoom = gzoom_def;
	imtile = fetch_im(gzoom, 0, 0, panoid, server, tmp_path);

	if(isempty(imtile)) % not found at gzoom==3, trying gzoom==2
		fprintf('Panorama is not found at gzoom = %d', gzoom);
		return;
	end

	switch(gzoom)
		case 3
			tilex = 0:6; tiley = 0:3; tilew = 512; tileh = 512; imw = 6.5*512;
		case 4
			tilex = 0:12; tiley = 0:6; tilew = 512; tileh = 512; imw = 13*512;
	end

	notfound = false;
	im = uint8(zeros(length(tiley)*tileh,length(tilex)*tilew,3));
	for i=tilex
		for j=tiley
			if((i~=0) || (j~=0))
				imtile = fetch_im(gzoom, i, j, panoid, server, tmp_path); 
			end;
			if(~isempty(imtile))
				im(j*tileh+1:(j+1)*tileh,i*tilew+1:(i+1)*tilew,:) = imresize(imtile,[tileh tilew]);
			else
				notfound = true;
			end;
		end
	end

	if notfound
		fprintf(1,'Pano %s may be incomplete!\n',panoid);
	end;

	img = im(1:imw/2,1:imw,:);
end

function imtile = fetch_im (gzoom, i, j, panoid, server, tmp_path)
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
