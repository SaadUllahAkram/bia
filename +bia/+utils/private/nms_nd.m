function pick = nms_nd(boxes, overlap)
% does greedy NMS for 2D/3D/4D.
% 
%     boxes: [x1 y1 z1 t1 x2 y2 z2 t2 score]
%     overlap: 
% 

if isempty(boxes)
  pick = [];
  return;
end


if size(boxes, 2) == 5 % 2D 
    pick = nms(boxes, overlap, gpuDeviceCount > 0);
    return
elseif size(boxes, 2) >= 9 % 4D
    dims = 4;
else % 3D
    dims = 3;
end

if dims == 3
    x1  = boxes(:,1);
    y1  = boxes(:,2);
    z1  = boxes(:,3);
    x2  = boxes(:,4);
    y2  = boxes(:,5);
    z2  = boxes(:,6);
elseif dims == 4
    x1  = boxes(:,1);
    y1  = boxes(:,2);
    z1  = boxes(:,3);
    t1  = boxes(:,4);
    
    x2  = boxes(:,5);
    y2  = boxes(:,6);
    z2  = boxes(:,7);
    t2  = boxes(:,8);
end
s   = boxes(:,end);

if dims == 3
    area = (x2-x1+1) .* (y2-y1+1) .* (z2-z1+1);
elseif dims == 4
    area = (x2-x1+1) .* (y2-y1+1) .* (z2-z1+1) .* (t2-t1+1);
end

[~, I] = sort(s);

pick = s*0;
counter = 1;
while ~isempty(I)
  last = length(I);
  i = I(last);
  pick(counter) = i;
  counter = counter + 1;

  xx1 = max(x1(i), x1(I(1:last-1)));
  yy1 = max(y1(i), y1(I(1:last-1)));
  zz1 = max(z1(i), z1(I(1:last-1)));

  xx2 = min(x2(i), x2(I(1:last-1)));
  yy2 = min(y2(i), y2(I(1:last-1)));
  zz2 = min(z2(i), z2(I(1:last-1)));

  w = max(0.0, xx2-xx1+1);
  h = max(0.0, yy2-yy1+1);
  d = max(0.0, zz2-zz1+1);% depth

    if dims == 3
        inter = w.*h.*d;
    elseif dims == 4
        tt1 = max(t1(i), t1(I(1:last-1)));
        tt2 = min(t2(i), t2(I(1:last-1)));
        td  = max(0.0, tt2-tt1+1);% time depth
        inter = w.*h.*d.*td;
    end
  
  
  o = inter ./ (area(i) + area(I(1:last-1)) - inter);
  
  I = I(o<=overlap);
end

pick = pick(1:(counter-1));



end