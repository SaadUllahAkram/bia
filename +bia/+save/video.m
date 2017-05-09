function video(ims, file_path, frame_rate, opts)
% saves video given a set of RGB/grayscale images
% 
% Inputs:
%     ims (uint8): cell array of images which have to be saved
%     file_path : compete file path including extension where file will be saved
%     frame_rate (Optional): Frame Rate (default: 1)
%     opts:
% 

opts_default = struct('max_size', [1080 1920]);
if nargin < 4
    opts = opts_default;
else
    opts = bia.utils.updatefields(opts_default, opts);
end
if nargin < 3
    frame_rate = 1;
end

max_size = opts.max_size;
T = length(ims);
sz = size(ims{1});
scale = min([1, max_size./sz(1:2)]);
sz_out = round(sz(1:2)*scale);
if isunix || contains(file_path, '.avi')% not possible to save mp4 on linux
    video_obj = VideoWriter(file_path);
    video_obj.Quality = 95;
else
    video_obj = VideoWriter(file_path,'MPEG-4');
    video_obj.Quality = 100;
end
video_obj.FrameRate = frame_rate;
open(video_obj);
for t=1:T
    im = ims{t};
    if ~isequal(sz_out, [size(im,1) size(im,2)])
        im = imresize(im, sz_out);
    end
    writeVideo(video_obj,im);
end
close(video_obj);

end