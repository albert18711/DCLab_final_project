function CHo = myColorTransform_16b(CHs,CHt)

src_mean = sum(sum(CHs));
% src_mean = floor(src_mean*256)/256;
src_mean = src_mean/(size(CHs,1)*size(CHs,2));
src_mean_f = sfi(src_mean, 16, 8)
% src_mean = fimath('ProductMode','SpecifyPrecision','ProductWordLength',16,'ProductFractionLength',8);
% src_mean = src_mean_f/sfi(size(CHs,1)*size(CHs,2), 16, 8);
% src_mean = floor(src_mean*256)/256;

trg_mean = sum(sum(CHt));
% trg_mean = floor(trg_mean*256)/256;
trg_mean = trg_mean/(size(CHs,1)*size(CHs,2));
trg_mean_f = sfi(trg_mean, 16, 8)
% trg_mean = trg_mean/(size(CHt,1)*size(CHt, 2));
% trg_mean = trg_mean_f/sfi(size(CHt,1)*size(CHt, 2), 16, 8);
% trg_mean = floor(trg_mean*256)/256;

% src_std = CHs - src_mean;
src_std = sfi(CHs, 16, 8) - src_mean_f;
% src_std = floor(src_std*256)/256;
% trg_std = CHt - trg_mean;
trg_std = sfi(CHt, 16, 8) - trg_mean_f;
% trg_std = floor(trg_std*256)/256;

src_std = sqrt( sum(sum(src_std.*src_std))/sfi(size(src_std,1)*size(src_std,2)) );
src_std = sfi(src_std, 16, 8)
% src_std = floor(src_std*256)/256;
trg_std = sqrt( sum(sum(trg_std.*trg_std))/sfi(size(trg_std,1)*size(trg_std,2)) );
trg_std = sfi(trg_std, 16, 8)
% trg_std = floor(trg_std*256)/256;

% CHo = sfi(CHs, 16, 8);
% CHo = CHs;
CHo = sfi(CHs, 16, 8);
CHo = CHo - src_mean_f;
CHo = sfi(CHo, 16, 8);
% CHo = floor(CHo * 256)/256;
CHo = (CHo*trg_std/src_std) + trg_mean_f;
CHo = sfi(CHo, 16, 8);
% CHo = floor(CHo * 256)/256;

end

