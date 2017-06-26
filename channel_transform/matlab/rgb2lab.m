function lab = rgb2lab(double_rgb)

% Original part:
%{
cform = makecform('srgb2xyz');
xyz = applycform(double_rgb,cform);

cform = makecform('xyz2lab','WhitePoint',whitepoint('d65'));
lab = applycform(xyz,cform);
%}


% Use matrix and log to implement RGB to L, A, B
%%{
[h, w, ch] = size(double_rgb);

lab = zeros(h,w,ch);

A = [1/sqrt(3), 0, 0; 0, 1/sqrt(6), 0; 0, 0, 1/sqrt(2)];
B = [1, 1, 1; 1, 1, -2; 1, -1, 0];
RGB2LMS = [0.3811, 0.5783, 0.0402; 0.1967, 0.7244, 0.0782; 0.0241, 0.1288, 0.8444];

for x = 1:w
    for y = 1:h
        lab(y ,x, :) = reshape(RGB2LMS*reshape(256*double_rgb(y, x, :), ch, 1), 1, 1, ch);
        %lab(y, x, :) = log10(lab(y, x, :));
        lab(y, x, :) = log2(lab(y, x, :));
        lab(y,x,:) = max(lab(y,x,:), 0);
        lab(y, x, :) = reshape(A*B*reshape(lab(y, x, :), ch, 1), 1, 1, ch);
    end
end
%}

end

