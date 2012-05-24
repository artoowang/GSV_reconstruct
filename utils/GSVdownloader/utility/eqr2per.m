function oim=eqr2per(iim, pitch, yaw)
%% Perspective view parameters
iimh=size(iim,1);           % input  image size
iimw=size(iim,2);
oimh=537;                   % output image size
oimw=936;
hfov=1.5;                   % horizontal filed of view [rad]

f=oimw/(2*tan(hfov/2));     % focal length [pix]
uc=(oimw+1)/2;              % image center
vc=(oimh+1)/2;
xc=(iimw+1)/2;              % image center
yc=(iimh+1)/2;    
%% Tangent plane grid to unit sphere
[X Y]=meshgrid(1:oimw, 1:oimh);
    X = X-uc;
    Y = Y-vc;
    Z = f+0*X;
  PTS = [X(:)'; Y(:)'; Z(:)'];
   Tx = expm([0     0           0        ;...
              0     0       -pitch/180*pi;
              0 pitch/180*pi    0           ]);
 PTSt = Tx*PTS;
    Xt=reshape(PTSt(1,:),oimh, oimw);
    Yt=reshape(PTSt(2,:),oimh, oimw);
    Zt=reshape(PTSt(3,:),oimh, oimw);
    Dt=sqrt(Xt.^2+Yt.^2+Zt.^2);

 THETA = atan2(Xt, Zt);
   PHI = atan(Yt./sqrt(Xt.^2+Zt.^2));

%% %% Image shifting w.r.t. yaw and mapping the unit sphere grid to cylinder
 sw=iimw/2/pi;
 sh=iimh/pi;
yaw=yaw/180*pi;
THETA = THETA+yaw;
      idx  =  find(THETA<pi);        % out of the left bound of pano image
THETA(idx) =  THETA(idx)+2*pi;
      idx  =  find(THETA>=pi   );    % out of the right bound of pano image
THETA(idx) =  THETA(idx)-2*pi;  

U=sw*THETA; V=sh*PHI;
%% Nearest neighbour interpolation
oim=interpnn(iim, U+xc, V+yc);

end

function oim=interpnn(iim, U, V);

    U=int16(round(U)); V=int16(round(V));
    oimR=0*U;   oimG=0*U;   oimB=0*U;
    for i=1:numel(U)
        if  0<V(i) && V(i)<=size(iim,1) && 0<U(i) && U(i)<=size(iim,2)
            oimR(i)=iim(V(i),U(i),1);
            oimG(i)=iim(V(i),U(i),2);
            oimB(i)=iim(V(i),U(i),3);
        else % out of image bounds
            oimR(i)=0;
            oimG(i)=0;
            oimB(i)=0;  
        end
    end
        oim(:,:,1)=oimR;
        oim(:,:,2)=oimG;
        oim(:,:,3)=oimB;
        oim=uint8(oim);
end