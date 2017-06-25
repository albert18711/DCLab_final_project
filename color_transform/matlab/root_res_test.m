clear;clc;

source = imread('source.bmp');
target = imread('target.jpg');

source = double(source);
source_16b = sfi(source, 16, 8);
target = double(target);
target_16b = sfi(target, 16, 8);

RES_16b = colorTransfer_16b(source_16b, target_16b, 0);

% RES_16b = RES_16b / 256;

RES = colorTransfer(source, target, 0);
RES = RES / 256;

% imshow(RES)