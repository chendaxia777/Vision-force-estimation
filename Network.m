clear
%% Import datasets
load("DataSets/2023.5.19/with_y_minus/input_train.mat")
load("DataSets/2023.5.19/with_y_minus/target_train.mat")

load("DataSets/2023.5.19/with_y_minus/input_test.mat")
load("DataSets/2023.5.19/with_y_minus/target_test.mat")
disp("Finished importing data.")

A = exist('input_p_test');
if A == 1
    input_test = input_p_test;
    input_train = input_p_train;
end

%% 

lgraph = layerGraph();

tempLayers = [
    imageInputLayer([64 64 1],'Name','input_encoder','Normalization','none')
    convolution2dLayer(3, 64, 'Padding','same', 'Stride', 1, 'Name', 'conv1')
    reluLayer('Name','relu1')
    convolution2dLayer(2, 64, 'Padding','same', 'Stride', 1, 'Name', 'conv2')
    reluLayer('Name','relu2')
    convolution2dLayer(3, 64, 'Padding','same', 'Stride', 2, 'Name', 'conv4')
    reluLayer('Name','relu4')
    convolution2dLayer(3, 128, 'Padding','same', 'Stride', 2, 'Name', 'conv5')
    reluLayer('Name','relu5')
    convolution2dLayer(2, 256, 'Padding','same', 'Stride', 2, 'Name', 'conv6')
    reluLayer('Name','relu6')
    ];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    transposedConv2dLayer(1, 64, 'Cropping', 'same', 'Stride', 1, 'Name', 'traspos1')
    reluLayer('Name','ree1')
    transposedConv2dLayer(3, 256, 'Cropping', 'same', 'Stride', 2, 'Name', 'transpose1')
    reluLayer('Name','reelu1')
    transposedConv2dLayer(3, 128, 'Cropping', 'same', 'Stride', 2, 'Name', 'transpose2')
    reluLayer('Name','reflu2')
    dropoutLayer
    fullyConnectedLayer(3)
    regressionLayer("Name","regressionoutput")
    ];

lgraph = addLayers(lgraph,tempLayers);
clear tempLayers;
lgraph = connectLayers(lgraph,"relu6","traspos1");



% miniBatchSize  = 512;
miniBatchSize  = 256;




% inp =fileDatastore(fullfile('inp_val'),'ReadFcn',@load,'FileExtensions','.mat');
% out=fileDatastore(fullfile('out_val'),'ReadFcn',@load,'FileExtensions','.mat');
%
%
% inputt = transform(inp,@(data) rearrange_datastore_input(data));
% outputt = transform(out,@(data) rearrange_datastore_output(data));
%
%
% valData=combine(inputt,outputt);

% options = trainingOptions('adam', ...
%     'MiniBatchSize',miniBatchSize, ...
%     'MaxEpochs',10000, ...
%     'InitialLearnRate',0.5*1e-3, ...
%     'LearnRateSchedule','piecewise', ...
%     'LearnRateDropFactor',0.5, ...
%     'LearnRateDropPeriod',50, ...
%     'Shuffle','every-epoch', ...
%     'Plots','training-progress', ...
%     'ExecutionEnvironment','gpu',...
%     'Verbose',true);

options = trainingOptions('adam', ...
    'MiniBatchSize',miniBatchSize, ...
    'MaxEpochs',10000, ...
    'InitialLearnRate',0.5*1e-3, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropFactor',0.5, ...
    'LearnRateDropPeriod',50, ...
    'Shuffle','every-epoch', ...
    'Plots','training-progress', ...
    'ExecutionEnvironment','gpu',...
    'Verbose',true,...
    'ValidationData',{input_test, target_test},...
    'ValidationFrequency',30);



% here I defined my network architecture
% here I defined my training options

% [net,info]=trainNetwork(input, output, lgraph, options);
[net,info]=trainNetwork(input_train, target_train, lgraph, options);

%net=trainNetwork(trainData, layerGraph(net), options);
% for i=1:6
%     asd(i,:)=lagmatrix(asd(i,:),100);
% end
%asd(7:9,:)=repmat(asd(7:9,1),1,4999);
%asd(9,:)=linspace(0,4,4999);
%asd(1:6,:)=asd(1:6,1);

%% 

% ypred = predict(net,input);
ypred_train = predict(net, input_train);
ypred_test = predict(net, input_test);

target_train = squeeze(target_train);
target_train = permute(target_train, [2,1]);

target_test = squeeze(target_test);
target_test = permute(target_test, [2,1]);

% l2 error
error_train = (ypred_train - target_train);
error_train_x = error_train(:,1);
error_train_y = error_train(:,2);
error_train_z = error_train(:,3);

l2_train = norm(error_train, 2);
l2_train_x = norm(error_train_x, 2);
l2_train_y = norm(error_train_y, 2);
l2_train_z = norm(error_train_z, 2);
[train_size , ~] = size(error_train);
disp(['Training set Avg Error: ', num2str(l2_train/train_size)])
disp(['Average error on x direction:', num2str(mean(abs(error_train_x)))])
disp(['Average error on y direction:', num2str(mean(abs(error_train_y)))])

error_test = (ypred_test - target_test);
error_test_x = error_test(:,1);
error_test_y = error_test(:,2);
error_test_z = error_test(:,3);

l2_test = norm(error_test, 2);
l2_test_x = norm(error_test_x, 2);
l2_test_y = norm(error_test_y, 2);
l2_test_z = norm(error_test_z, 2);
[test_size, ~] = size(error_test);
disp(['Test set Avg Error: ', num2str(l2_test/test_size)])
disp(['Average error on x direction:', num2str(mean(abs(error_test_x)))])
disp(['Average error on y direction:', num2str(mean(abs(error_test_y)))])



%% plot
[i,~] = size(error_test);
x = linspace(1,i,i);
% plot(x,error_test_x)
% title('test error')
% hold on
% plot(x,error_test_y)
% plot(x,error_test_z)
% legend({'x','y','z'})
% hold off
figure(1)
% plot(x,ypred_test(:,1))
% hold on
% plot(x,target_test(:,1))
fig_x = bar([ypred_test(:,1) target_test(:,1)]);
legend({'predict_x','target_x'})
% hold off
figure(2)
% plot(x,ypred_test(:,2))
% hold on
% plot(x,target_test(:,2))
fig_y = bar([ypred_test(:,2) target_test(:,2)]);
legend({'predict_y','target_y'})
hold off

%% scatter plot

line_x = linspace(min(target_test(:,1))-0.1,max(target_test(:,1))+0.1);
line_y = linspace(min(target_test(:,2))-0.1,max(target_test(:,2))+0.1);
figure(3)
% scatter x direction
scatter(target_test(:,1), ypred_test(:,1))
hold on
plot(line_x,line_x)
xlabel('Target force')
ylabel('Predict force')
title('X direction')
hold off
figure(4)
% scatter y direction
scatter(target_test(:,2), ypred_test(:,2))
hold on
plot(line_y,line_y)
xlabel('Target force(N)')
ylabel('Predict force(N)')
title('Y direction')
hold off

figure(5)
subplot(1,2,1)
scatter(target_test(:,1), ypred_test(:,1))
hold on
plot(line_x,line_x)
xlabel('Target force(N)')
ylabel('Predict force(N)')
title('X direction')
hold off
subplot(1,2,2)
scatter(target_test(:,2), ypred_test(:,2))
hold on
plot(line_y,line_y)
xlabel('Target force(N)')
ylabel('Predict force(N)')
title('Y direction')
hold off
%%
% asd=read (input);
%ypred = predict(net,asd.XTrain(:,:,:,1:900));
%deepNetworkDesigner(layers);

%imresize(ypred,[512 512]);

% act1 = activations(net,image(:,:,:,1:900),'transpose5');
%reshape(act1,128,128,1,900*64);


%
%act1 = activations(net,asd.XTrain(:,:,:,1:900),'Decoder-Stage-2-Conv-3');

%act1 = activations(net,XTrain(:,:,:,1:900),'Decoder-Stage-2-Conv-3');
% reshape(act1,128,128,1,900*64);
%asd=ans(:,:,1,69:64:end);



% 
% A=[ypred ypred2 YTrain];
% v = VideoWriter('res_train.avi');
% 
% open(v)
% 
% %A=[];
% %A=cat(4,A,[ypred;YTrain]);
% writeVideo(v,mat2gray(A(:,:,:,:)));
% 
% %writeVideo(v,mat2gray(A(:,:,:,1:3000)));
% 
% close(v)
% 
% 
% v = VideoWriter('vid.avi');
% open(v)
% 
% 
% writeVideo(v,mat2gray(YTrain(:,:,:,:)));
% 
% 
% 
% close(v)