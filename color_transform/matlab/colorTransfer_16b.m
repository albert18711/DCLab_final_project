function RES = colorTransfer_16b(SRC, TRG, b)


% Convert SRC(source) and TRG(target) 
%from (RGB) domain to (L, alpha, beta) domain:
LAB_SRC = rgb2lab(SRC);
Ls = LAB_SRC(:,:,1);
as = LAB_SRC(:,:,2);
bs = LAB_SRC(:,:,3);

LAB_TRG = rgb2lab(TRG);
Lt = LAB_TRG(:,:,1);
at = LAB_TRG(:,:,2);
bt = LAB_TRG(:,:,3);

% Use the paper method to do transfer:
Lo = myColorTransform_16b(Ls, Lt);
ao = myColorTransform_16b(as, at);
bo = myColorTransform_16b(bs, bt);
% Lo = myColorTransform(Ls, Lt);
% ao = myColorTransform(as, at);
% bo = myColorTransform(bs, bt);
% Original Code:
%{
Lo = chan_trans(Ls,Lt,b);
ao = chan_trans(as,at,b);
bo = chan_trans(bs,bt,b);
%}

% RES = cat(3,Lo,ao,bo);
RES(:, :, 1) = double(Lo);
RES(:, :, 2) = double(ao);
RES(:, :, 3) = double(bo);
% RES = [Lo; ao; bo];
RES = lab2rgb(RES);
% RES = laab2rgb(RES);

end