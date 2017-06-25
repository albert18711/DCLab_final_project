function rgb = lab2rgb(double_lab)

% Original code:
%{
cform = makecform('lab2xyz','WhitePoint',whitepoint('d65'));
xyz = applycform(double_lab,cform);

cform = makecform('xyz2srgb');
rgb = applycform(xyz,cform);
%}

% L, A, B to RGB using exp and matices
%%{
[h, w, ch] = size(double_lab);
rgb = zeros(h,w,ch);
ch

A = [1, 1, 1; 1, 1, -1; 1, -2, 0];
B = [1/sqrt(3), 0, 0; 0, 1/sqrt(6), 0; 0, 0, 1/sqrt(2)];
LMS2RGB = [4.4679, -3.5873, 0.1193; -1.2186, 2.3809, -0.1624; 0.0497, -0.2439, 1.2045];

for x = 1:w
    for y = 1:h
        rgb(y, x, :) = reshape(A*B*reshape(double_lab(y, x, :), ch, 1), 1, 1, ch);
        %rgb(y, x, :) = 10.^(rgb(y, x, :));
        rgb(y, x, :) = 2.^(rgb(y, x, :));
        rgb(y ,x, :) = reshape(LMS2RGB*reshape(rgb(y, x, :), ch, 1), 1, 1, ch);
        
    end
end
rgb = rgb/256;
%}
end

