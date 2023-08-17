clear

%% load all mat file

% name_list_x = dir('2023.5.12_x+/*.mat');
% name_list_y = dir('2023.5.12_y+/*.mat');
% 
% [x_length, ~] = size(name_list_x);
% [y_length, ~] = size(name_list_y);
% 
% % initialize 
% input_set(1).frames = 0;
% input_set(1).pressures = 0;
% output_set(1).forces = 0;
% 
% % read all mat files in folder
% for i = 1:x_length
%     file_name{i} = strcat('2023.5.12_x+/', name_list_x(i).name);
%     temp = importdata(file_name{i});
%     input_set = Combineinput(input_set,temp);
%     output_set = Combineoutput(output_set,temp);
% end
% 
% for i = 1:y_length
%     file_name{i} = strcat('2023.5.12_y+/', name_list_y(i).name);
%     temp = importdata(file_name{i});
%     input_set = Combineinput(input_set,temp);
%     output_set = Combineoutput(output_set,temp);
% end
% 
% output_set(1) = [];
% input_set(1) = [];

%% Load datasets

% initialize 
input_set(1).frames = 0;
input_set(1).pressures = 0;
output_set(1).forces = 0;

name_lists = ["dataStore/Video_string/*.mat"];

[~, fol_length] = size(name_lists);
for i = 1:fol_length
    disp(['Importing the number ',num2str(i),' data folder ......'])
    name_list = dir(name_lists(i));
    [data_length, ~] = size(name_list);
    folder_name = extractBefore(name_lists(i),"*.mat");

    for j = 1:data_length
        file_name{j} = strcat(folder_name, name_list(j).name);
        temp = importdata(file_name{j});
        input_set = Combineinput(input_set,temp);
        output_set = Combineoutput(output_set,temp);
    end
end

output_set(1) = [];
input_set(1) = [];
disp('Data imported. ')

%% data processing
% [m,n] = size(Store);
[~, length] = size(input_set);
images = [];
pressures = [];
gray_images = [];

for i = 1 : length
    asd = rgb2gray(input_set(i).frames);
    asd = im2double(imresize(asd,[64 64]));
    images(:,:,:,i) = asd;
    temp_pressures = input_set(i).pressures ;
    pressure_mat = repmat(temp_pressures,[8,64]);
    input(:,:,1,i) = asd;
%     input(:,:,2,i) = pressure_mat/1.2;%pressure range to 1.2bar
    forces(1,1,:,i) = output_set(i).forces;
end
% for i = 1: n
%     asd=rgb2gray(Store(i).frames);
%     asd = imresize(asd,[64 64]);
%     images(:,:,:,i) = asd;
% %     gray_images = [gray_images; rgb2gray(Store(i).frames)];
% %     pressures = [pressures; Store(i).pressures];
%     forces(1,1,:,i) = Store(i).forces;
% end
% 

target = forces;

% % shuffle the dataset
% [~, ~, ~, data_num] = size(input);
% data_idx = randperm(data_num);
% input = input(:,:,:,data_idx);
% target = target(:,:,:,data_idx);

% % split
% train_num = round(data_num * 0.9);
% 
% input_train = input(:,:,:,1:train_num);
% input_test = input(:,:,:,train_num+1:end);
% target_train = target(1,1,:,1:train_num);
% target_test = target(1,1,:,train_num+1:end);

input_test = input;
target_test = target;
%% Save training and test data
disp('Saving the processed datasets')
save('dataSet/All_1camera/no_pressure/video_string/input_test',"input_test","-v7.3")
save('dataSet/All_1camera/no_pressure/video_string/target_test',"target_test","-v7.3")

%% functions to merge files
function s1 = Combineinput(s1, s2)
    [~, n] = size(s1);
    [~, m] = size(s2);

    for i = 1:m
        s1(n+i).pressures = s2(i).pressures;
        s1(n+i).frames = s2(i).frames;
    end
end

function s1 = Combineoutput(s1, s2)
    [~, n] = size(s1);
    [~, m] = size(s2);

    for i = 1:m
        s1(n+i).forces = s2(i).forces;
    end
end
