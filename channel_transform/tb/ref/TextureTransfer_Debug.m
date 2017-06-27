% Run the whole process: color transfer and texture transfer

close all;
disp('Run the whole process: color transfer and texture transfer');

% Target:
I = im2double(imread('EiffelTower.bmp'));
I = floor(I*256);

[h, w, ch] = size(I);
subplot(2,2,1); imshow(I/256); title('Target');

I_src = im2double(imread('PurpleFlower.jpg'));
I_src = floor(I_src*256);
subplot(2,2,2); imshow(I_src/256); title('Source');

LOCAL_X = 3; LOCAL_Y = 3; P=1;  % P not used here
wL = 32;                                          % wL determines the similarity and resolution of result
                                            % wL increases, similarity increases and resolution decreases
ITERS = 1;
%I_text = myStyleTransfer(I_src, I, LOCAL_X, LOCAL_Y, P, wL, ITERS);

%{
disp('Color Transfer');
I_color = colorTransfer(I, I_src, 512); % 512 here is meaningless
subplot(2,2,3); imshow(I_color/256); title('Color Transfer');

disp('Texture Transfer');
I_text = mytextureTransfer_for_Test(I_src, I, LOCAL_X, LOCAL_Y, P, wL, ITERS, 9);   % The last parameter 9 is for random value bits
subplot(2,2,4); imshow(I_text/256); title('Texture Transfer');
figure(2); imshowpair(I/256, I_text/256,'montage'); title('Target vs Result');

I_text_ref = mytextureTransfer(I_src, I, LOCAL_X, LOCAL_Y, P, wL, ITERS);
figure(3); imshowpair(I_text/256, I_text_ref/256, 'montage'); title('TRG-changed v.s. SRC-changed');
%}

I_down = I(100:104, 150:154, :);
I_down = floor(I_down*256)/256;
%disp('Target');
%I_down*256
%I_gray = myRGB2gray(I_down)*256
figure(4);
subplot(2,2,1); imshow(I_down/256); title('Target');
I_src_down = I_src(100:104, 150:154, :);
I_src_down = floor(I_src_down*256)/256;
disp('Source');
%I_src_down*256
%I_gray_src = myRGB2gray( I_src_down )*256
subplot(2,2,2); imshow(I_src_down/256); title('Source');


I_down_RGBnGray = zeros(25, 2);
I_down_RGBnGray(1:25, 1) = reshape(transpose(I_down(:, :, 1)*256 + I_down(:, :, 2)), 25, 1);
I_down_RGBnGray(1:25, 2) = reshape(transpose(I_down(:, :, 3)*256 + I_gray(:, :)), 25, 1)


I_src_down = I_src_down
I_down = I_down

tmp = colorTransfer(I_src_down, I_down)

fprintf('end color transform.....')
I_gray = myRGB2gray_Test(I_down)
I_gray_src = myRGB2gray_Test(I_src_down)
% I_text_down = mytextureTransfer_for_Test(I_src_down, I_down, LOCAL_X, LOCAL_Y, P, wL, ITERS, 2);
% I_text_down = I_text_down/256;

%{
I_text_down = mytextureTransfer_for_Test(I_src_down, I_down, LOCAL_X, LOCAL_Y, P, wL, ITERS);
I_text_down = I_text_down;
%}

%I_src_down = I_src_down*256;
%I_down = I_down*256;
%I_gray = I_gray*256;
%I_gray_src = I_gray_src*256;

I_src_down_RGBnGray = zeros(25, 2);
I_src_down_RGBnGray(1:25, 1) = reshape(transpose(I_src_down(:, :, 1)*256 + I_src_down(:, :, 2)), 25, 1);
I_src_down_RGBnGray(1:25, 2) = reshape(transpose(I_src_down(:, :, 3)*256 + I_gray_src(:, :)), 25, 1)

subplot(2,2,3); imshow(I_text_down); title('Result');
I_text_down = I_text_down*256


% Grayscale Transform:
% stats

SRC_gray_Mean = mean(I_gray_src(:))
SRC_gray_Std = std(I_gray_src(:))
TRG_gray_Mean = mean(I_gray(:))
TRG_gray_Std = std(I_gray(:))

SRC_gray_Mean_f = (sfi(SRC_gray_Mean, 32, 8)) 
bin(SRC_gray_Mean_f)

SRC_gray_Std_f = (sfi(SRC_gray_Std, 32, 8))
bin(SRC_gray_Std_f)

TRG_gray_Mean_f = (sfi(TRG_gray_Mean, 32, 8))
bin(TRG_gray_Mean_f)

TRG_gray_Std_f = (sfi(TRG_gray_Std, 32, 8))
bin(TRG_gray_Std_f)

% normalize SRC by TRG - yields better results
I_gray_src_GrayTrans = floor((TRG_gray_Std/SRC_gray_Std)*(I_gray_src-SRC_gray_Mean) + TRG_gray_Mean)

[I_Gray_src,I_Gray,SRC_avg,TRG_avg] = myGetGrayscales_Test(I_src, I, LOCAL_X,LOCAL_Y);

figure(5);
subplot(2,2,1); imshow(I_src/256);
subplot(2,2,2); imshow(I_Gray_src/256);
max(max(I_Gray_src))
min(min(I_Gray_src))

