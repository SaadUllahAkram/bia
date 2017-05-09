function f1 = f1score(precision, recall)
% Takes predicted and ground truth labels and computes [tp, fp, fn, tn, recall, precision, f1 score, accuracy]
% Inputs:
% 
% Outputs:
% 
f1 = 2*precision*recall/(precision+recall);


% res.tp = sum(pred_labels == 1 & test_labels == 1); % tp
% res.fp = sum(pred_labels == 1 & test_labels == 0); % fp
% res.fn = sum(pred_labels == 0 & test_labels == 1); % fn
% res.tn = sum(pred_labels == 0 & test_labels == 0); % tn
% 
% res.recall      = res.tp/(res.tp+res.fn);
% res.precision   = res.tp/(res.tp+res.fp);
% res.f1 = 2*res.recall*res.precision/(res.recall+res.precision);
% 
% res.accuracy = 100-100*sum(abs(test_labels-pred_labels))/length(test_labels);
end