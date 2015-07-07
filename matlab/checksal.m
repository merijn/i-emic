% CHECKSAL  - Checks salinity conservation%%  M. den Toom%function check = checksal(S,varx,vary,dfzT)%%% - ERROR CHECK -if (ndims(S)~=3)    error('The S field must be three dimensional')elseif (size(S,1)~=length(varx))    error('The longitudinal coordinate does not match the S fiels')elseif (size(S,2)~=length(vary))    error('The latitudinal coordinate does not match the S field')elseif (size(S,3)~=length(dfzT))    error('The derivative of the depth coordinate does not match the S field')end%% - SALINITY CHECK -check = 0.0;for i=1:size(S,1)for j=1:size(S,2)for k=1:size(S,3)   check = check + ...       S(i,j,k)*cos(vary(j))*dfzT(k);    endendenddx    = varx(2)-varx(1); dy = vary(2)-vary(1); dz = 1/length(dfzT);check = check*dx*dy*dz;