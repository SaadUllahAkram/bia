function [test_pred, test_scores, model_out] = train(opts, test_feats, test_labels, train_feats_, train_labels_, model_out)
if isempty(test_feats)
    do_test = false;
else
    do_test = true;
    nfeats_default = ceil(sqrt(size(test_feats,1)));
end
if isempty(train_feats_)
    do_train = false;
else
    do_train = true;
    nfeats_default = ceil(sqrt(size(train_feats_,1)));
end

opts_default = struct('trees',100,'leaf_sz',1,'nfeats',nfeats_default,...
    'balanced',0, 'binary',0, 'norm_type',2, 'train_samples',1,...
    'verbose',1,'plot_num_trees',0);
opts = bia.utils.updatefields(opts_default, opts);

nfeats  = opts.nfeats;
trees  = opts.trees;
leaf_sz = opts.leaf_sz;
binary  = opts.binary;
balanced= opts.balanced;
norm_type  = opts.norm_type;
train_samples= opts.train_samples;
verbose = opts.verbose;
plot_num_trees = opts.plot_num_trees;

t_start = tic;

if do_train
    if ismember(-1, unique(train_labels_))
        train_feats_(train_labels_ == -1, :) = [];% delete neutral training samples
        train_labels_(train_labels_ == -1)    = [];
    end
end
if binary
    if do_train
        train_labels_(train_labels_ ~= 1) = 0;
    end
    if do_test
        test_labels(test_labels ~= 1)   = 0;
    end
end

if do_train
    if balanced% only for binary labels
        n_pos = sum(train_labels_ == 1);
        n_neg = sum(train_labels_ == 0);
        if train_samples <= 1
            train_samples = round(train_samples*min(n_pos, n_neg));
        else
            train_samples = min( round(train_samples/2), min(n_pos, n_neg));
        end
        idx_pos       = find(train_labels_==1);
        idx_neg       = find(train_labels_==0);
        train_idx     = [idx_pos(randperm(length(idx_pos), train_samples));   idx_neg(randperm(length(idx_neg), train_samples))];
    else
        if train_samples <= 1
            train_samples = round(train_samples*size(train_feats_, 1));
        else
            train_samples = min(train_samples, size(train_feats_, 1));
        end
        train_idx       = randperm(size(train_feats_, 1), train_samples);
    end
    val_idx             = setdiff(1:size(train_feats_,1), train_idx);

    train_feats         = train_feats_(train_idx, :);
    val_feats           = train_feats_(val_idx, :);

    train_labels        = train_labels_(train_idx);
    val_labels          = train_labels_(val_idx);
    max_samples = 300000;
    if size(train_feats, 1) > max_samples
        fprintf('Reducing Training feats from : %d to %dk\n', round(size(train_feats,1)/1000), round(max_samples/1000))
        idxnn = randperm(size(train_feats,1), max_samples);
        train_feats  = train_feats(idxnn, :);
        train_labels  = train_labels(idxnn, :);
    end
end


if do_train
    if norm_type == 1
        m1 = min(train_feats,[],1);
        m2 = max(train_feats,[],1)-m1;
        m2(m2==0) = eps;
    elseif norm_type == 2
        m1 = mean(train_feats,1);
        m2 = std(train_feats,0,1)+eps;
    else
        m1 = 0;
        m2 = 0;
    end
    model_out = struct('m1',m1,'m2',m2);
end

if ismember(norm_type, [1 2])
    if do_train
        train_feats = bsxfun(@rdivide, bsxfun(@minus, train_feats, model_out.m1), model_out.m2);
    end
    if do_test
        test_feats  = bsxfun(@rdivide, bsxfun(@minus, test_feats , model_out.m1), model_out.m2);
    end
end

options = statset('UseParallel',true,'UseSubstreams',false);
if do_train
    if nfeats== -1
        model = TreeBagger(trees, train_feats, train_labels, 'OOBPrediction', 'On', 'MinLeafSize', leaf_sz, 'options', options);
    else
        model = TreeBagger(trees, train_feats, train_labels, 'OOBPrediction', 'On', 'MinLeafSize', leaf_sz, 'NumPredictorsToSample', nfeats, 'options', options);
    end

    if verbose
        train_error = oobError(model);
        fprintf('Training: %1.1fs, Train Accu:%1.4f, ', toc(t_start), 1-train_error(end))
    end

    if plot_num_trees
        oobErrorBaggedEnsemble = oobError(model);
        figure(99)
        plot(oobErrorBaggedEnsemble)
        xlabel('Number of grown trees');
        ylabel('Out-of-bag classification error');
        drawnow
        fprintf('Val: %1.1f s\n', toc(t_start))
    end

    model = compact(model);
    if ~isempty(val_feats)
        [val_pred, val_scores] = predict(model, val_feats);
        val_pred = str2num(cell2mat(val_pred));
        bia.ml.eval_pred(val_labels, val_pred, 'Val  ', verbose);
    end
    model_out.model = model;
else
    model = model_out.model;
end

if do_test
    [test_pred, test_scores] = predict(model, test_feats);
    test_pred = str2num(cell2mat(test_pred));
    bia.ml.eval_pred(test_labels, test_pred, 'Test ', verbose);
else
    test_pred = [];
    test_scores = [];
end

if verbose
    fprintf('Eval: %1.1fs, ', toc(t_start))
end

end