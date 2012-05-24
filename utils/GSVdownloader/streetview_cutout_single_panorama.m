%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION cutout_img = streetview_cutout_single_panorama (img, img_rel_yaw, img_rel_pitch)
%
%	Generates perspective view cutouts from equirectangular
%	panoramas downloaded from Google Street View.
%
% INPUTS:
%	img:			Google Street View image downloaded by
%					streetview_download_panorama.m
%	img_rel_yaw:	Relative yaw of the cutout (the center of the img is
%					yaw == 0)
%	img_rel_pitch:	Relative pitch of the cutout (only support -4 and -28)
%
% OUTPUTS:
%	cutout_img:		Output cutout image
%
% Author: M. Havlena
% Modified by: Chun-Po Wang, 2011 Cornell University
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cutout_img = streetview_cutout_single_panorama (img, img_rel_yaw, img_rel_pitch)

addpath('./utility/');

%% Perspective view parameters
iimh=3328;  iimw=6656;      % input  image size
% Note: if image width or hfov is changed, remember to change the default focal lengths written to list.new.txt
oimh=537;   oimw=936;       % output image size
hfov=1.5;                   % horizontal filed of view [rad]

f=oimw/(2*tan(hfov/2));     % focal length [pix]
ouc=(oimw+1)/2; ovc=(oimh+1)/2;             % output image center
iuc=(iimw+1)/2; ivc=(iimh+1)/2;             % input image center    

%% Tangent plane to unit sphere mapping
[X Y] = meshgrid(1:oimw, 1:oimh);
    X = X-ouc;   Y = Y-ovc;             % shift origin to the image center
    Z = f+0*X;
  PTS = [X(:)'; Y(:)'; Z(:)'];
% Transformation for oitch angle -04
  pitch = -04;
   Tx = expm([0     0           0        ;...
              0     0       pitch/180*pi;
              0 -pitch/180*pi   0           ]);
 PTSt = Tx*PTS;                         % rotation w.r.t x-axis about pitch angle
    Xt=reshape(PTSt(1,:),oimh, oimw);
    Yt=reshape(PTSt(2,:),oimh, oimw);
    Zt=reshape(PTSt(3,:),oimh, oimw);
    
 Theta.pitch04 = atan2(Xt, Zt);                 % cartesian to spherical
   Phi.pitch04 = atan(Yt./sqrt(Xt.^2+Zt.^2));
% Transformation for oitch angle -28
     pitch = -28;
   Tx = expm([0     0           0        ;...
              0     0        pitch/180*pi;
              0 -pitch/180*pi   0           ]);
 PTSt = Tx*PTS;                         % rotation w.r.t x-axis about pitch angle
    Xt=reshape(PTSt(1,:),oimh, oimw);
    Yt=reshape(PTSt(2,:),oimh, oimw);
    Zt=reshape(PTSt(3,:),oimh, oimw);

 Theta.pitch28 = atan2(Xt, Zt);                 % cartesian to spherical
   Phi.pitch28 = atan(Yt./sqrt(Xt.^2+Zt.^2));

%% Generating cutouts
% Image shifting w.r.t. yaw and mapping from unit sphere grid to cylinder
sw=iimw/2/pi;
sh=iimh/pi;
yaw=img_rel_yaw/180*pi;
if img_rel_pitch==-04, THETA=Theta.pitch04; PHI=Phi.pitch04; end;
if img_rel_pitch==-28, THETA=Theta.pitch28; PHI=Phi.pitch28; end;
THETA = THETA+yaw;
idx  =  find(THETA<pi );  THETA(idx) =  THETA(idx)+2*pi;    % out of the left bound of pano image
idx  =  find(THETA>=pi);  THETA(idx) =  THETA(idx)-2*pi;    % out of the right bound of pano image
U=sw*THETA+iuc; 
V=sh*PHI  +ivc;
           
cutout_img=iminterpnn(img, U,V);

end
