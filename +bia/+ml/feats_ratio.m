function f = feats_ratio(f1, f2)
% computes ratio of 2 feature vectors
m = max(abs(f1),abs(f2));
m(m == 0) = 1;
f = abs(f1-f2)./m;
% f = f1./f2;
end
