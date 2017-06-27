function CHo = myColorTransform(CHs,CHt)

src_mean = sum(sum(CHs));
src_mean = src_mean/(size(CHs,1)*size(CHs,2))

trg_mean = sum(sum(CHt));
trg_mean = trg_mean/(size(CHt,1)*size(CHt, 2))

src_std = CHs - src_mean;
trg_std = CHt - trg_mean;

src_std = sqrt( sum(sum(src_std.*src_std))/(size(src_std,1)*size(src_std,2)) )
trg_std = sqrt( sum(sum(trg_std.*trg_std))/(size(trg_std,1)*size(trg_std,2)) )

CHo = CHs;
CHo = CHo - src_mean;
CHo = (CHo*trg_std/src_std) + trg_mean;

end

