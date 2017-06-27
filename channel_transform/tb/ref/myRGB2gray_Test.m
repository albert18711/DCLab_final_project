function I_gray = myRGB2gray(I)

grayVector = [0.299 0.587 0.114];
[H, W, ch] = size(I);
I_gray = zeros(H, W);
for x = 1:W
    for y = 1:H
        %I_gray(y, x) = floor(grayVector*reshape(I(y, x, :), 3, 1));
        I_gray(y, x) = (floor(grayVector*reshape(I(y, x, :), 3, 1)));
    end
end

end

