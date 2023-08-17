% data collection for the force and pressure 
clc
clear all 
close all
delete(instrfind({'Port'},{'COM6'}));
due_serial = serial('COM6','BaudRate', 115200);
% set(due_serial, 'ReadAsyncMode','manual')
set(due_serial, 'InputBufferSize',80)  % 80
set_pressure
%% Set up camera
%use webcamlist to see webcams
cam = webcam("HD Web Camera");

% % Setup any camera settings
% cam.Resolution = '720x576';
% cam.Brightness = 0;
% cam.Saturation = 128;
% cam.Contrast = 128;

%% setup for the force sensor
global FT_Sensor
addpath('IIT_FT_17_Sensor','-end');
disp('initialise F/T sensor...')
inputBuffer=100;% This is the UDP buffer size
%  This is the structure of the sensor data
FT_SensorData = struct(...
        'ChRaw_Offs',int16(zeros(6,1)),...
        'FT',int32(zeros(6,1)),...
        'ChRaw',uint16(zeros(6,1)),...
        'tStamp',uint32(zeros(2,1)),...
        'filt_FT',int32(zeros(6,1)),...
        'UDP_PACKET_ID',uint32(zeros(1,1)),...
        'ft',double(zeros(6,1)),...
        'filt_ft',double(zeros(6,1)),...
        'ctime', double(0));
        
    FT_Sensor_Poll=struct(...
       'Data', FT_SensorData,...
        'Policy0',uint8(0),...
        'Policy1',uint8(0),...
        'UDPPolicy',uint16(0),...
        'BoardNumber',uint8(0),...
        'IP',uint8(16),...
        'Port',uint8(0),...
        'UDPHandle',double(0),...
        'UDPRecvBuff', uint8(zeros(inputBuffer,1)));

     
%     Create 2 instances of FT_Sensor_Poll structures FT_Sensor(1) and FT_Sensor(2)
%     This demonstrates how to get readings from an arbitrary number of sensors 
    for i=1:2   
    FT_Sensor=FT_Sensor_Poll;
    end
    
% Set the Policy0 and Policy1 members of FT_Sensor(1) structure
    FT_Sensor(1).Policy0=215;
    FT_Sensor(1).Policy1=0;
    
% Set the BoardNumber of the Sensor
FT_Sensor(1).BoardNumber=1;
    
  
%************************ Setup Plot **************************
Fx=double(0);
Fy=double(0);
Fz=double(0);
Tx=double(0);
Ty=double(0);
Tz=double(0);

% ****************************Setup UDP********************
echoudp('off')% first disable the Echo of the UDP
fclose('all')%close opened files and connections

echoudp('on',4012);

FT_Sensor(1).UDPHandle=udp('192.168.1.1',23);% IP Address and port of the sensor 
set(FT_Sensor(1).UDPHandle,'DatagramTerminateMode', 'off')
FT_Sensor(1).UDPHandle.Timeout =0.1;
FT_Sensor(1).UDPHandle.InputBufferSize=inputBuffer;

%Change the default "off" of enabling port sharing so the data can be read
FT_Sensor(1).EnablePortSharing = 'on';

%Open a UDP connection at the above IP and port.
fopen(FT_Sensor(1).UDPHandle);
% *********************************************************

%Call the other functions, give them command strings and they
%translate and create and populate appropriate datagrams. These datagrams
%are then sent to buffer and broadcast to the sensor.

% sets the mandatory policies
SendUDPcommand('SET_SINGLE_UDP_PACKET_POLICY',FT_Sensor(1));

SendUDPcommand('GET_SINGLE_UDP_PACKET',FT_Sensor(1));
 
SendUDPcommand('UDP_CALIBRATE_OFFSETS',FT_Sensor(1));

disp('initialisation of F/T sensor is complete')

%% serial setting for arduino due
time_duration = 10; % larger than initial duration
intial_time_duration = 10;
time_stamp = [0];
% send_pressure(due_serial,init_pressure);
% send_pressure(due_serial,init_pressure);
cmd_pressure = zeros(8,1);


desired_pressure = [];
fed_pressure = [];


readForce();
readForce(); 
readForce(); 

fopen(due_serial);

start_time = clock;
current_time = clock;
tic
number = 1;
initial_flag = 0;
initial_force_list = [];
%% collect initial force from gravity
disp(['implement pressure of ',num2str(rand_pressure)])
disp('collecting initial force')
while(time_stamp < intial_time_duration)
     cmd_pressure = [1,0,0,1,0,0,0,0];
%     cmd_pressure = rand_pressure;
    % set the maxinum pressure as 1.5 bar
    cmd_pressure(cmd_pressure<=0)=0;
    cmd_pressure(cmd_pressure>=1.5)=1.5;
    send_pressure(due_serial,cmd_pressure);    
    % update force
    fed_pressure = read_pressure(due_serial);
    measured_f = readForce();
    initial_force_list = [initial_force_list; measured_f];
    time_second = toc;
    time_stamp = [time_stamp time_second];
end
intial_force = median(initial_force_list);
disp(['initial force applied by gravity: ', num2str(intial_force)])

%% main function

while(time_stamp < time_duration)
%      cmd_pressure = [1,0,0,0,0,0,0,0];
%     cmd_pressure = rand_pressure;
    % set the maxinum pressure as 1.5 bar
    cmd_pressure(cmd_pressure<=0)=0;
    cmd_pressure(cmd_pressure>=1.5)=1.5;
    send_pressure(due_serial,cmd_pressure);    
    % update force
    fed_pressure = read_pressure(due_serial);
    measured_f = readForce() - intial_force;

    % capture the initial shape
    if initial_flag == 0
%         % allow robot to reach target
%         pause(0.5)
%         send_pressure(due_serial,cmd_pressure);    
        pause(0.5)
        send_pressure(due_serial,cmd_pressure); 
        disp('Initial Frame Captured')
        % update force
%         measured_f = intial_force - intial_force; 
        fed_pressure = read_pressure(due_serial);
        % capture image
        frame = snapshot(cam);
        % store initial shape
        Store(number).pressures = fed_pressure;
        Store(number).forces = measured_f; 
        Store(number).frames = frame;
        number = number+1;
        initial_flag = 1;
        time_second = toc;
        time_stamp = [time_stamp time_second];
        % discard noise force
        pause(0.5)
        send_pressure(due_serial,cmd_pressure);    
        pause(0.5)
        disp('start apply force')
        disp(['tuned force: ', num2str(measured_f)])
        continue
    end

    % capture frame only when force applied
    if max(abs(measured_f)) >= 0.1
        % capture image
        frame = snapshot(cam);
        % store shape
        Store(number).pressures = fed_pressure;
        Store(number).forces = measured_f; 
        Store(number).frames = frame;
        number = number+1;
        time_second = toc;
        time_stamp = [time_stamp time_second];
        pause(0.5)
        continue
    end

    time_second = toc;
    time_stamp = [time_stamp time_second];
    pause(0.5)
end
send_pressure(due_serial,zeros(8,1));
fclose(due_serial);
delete(due_serial);

%% Save to folder
disp('saving data to folder')
currDate = strrep(datestr(datetime), ':', '_');
mkdir('Datas',currDate)
[m,n] = size(Store);
ImageFolder = strcat('Datas\',currDate);
% saving images to folder
% for jj = 1:n
%     img = Store(jj).frames;
%     file_name = sprintf('Image%d.png', jj);
%     fullFileName = fullfile(ImageFolder, file_name);
%     imwrite(img, fullFileName);
% end
% save whole data set
save(ImageFolder,'Store')
%% 

% save tip_block_step_force.mat time_stamp measured_fz desired_pressure fed_pressure cmd_force
% read the force 
function fed_force = readForce()
global FT_Sensor

FT_Sensor(1) = GetFTsensorData(FT_Sensor(1));
fed_force(1) = FT_Sensor(1).Data.ft(1);
fed_force(2) = FT_Sensor(1).Data.ft(2);
fed_force(3) = -FT_Sensor(1).Data.ft(3); 

end

% send the desired pressure
function send_pressure(serial_port, cmd_pressure)
formatSpec = '%.2f';
str_cmd_pressure = num2str(cmd_pressure(1),formatSpec) + "," + num2str(cmd_pressure(2),formatSpec) + "," +...
                   num2str(cmd_pressure(3),formatSpec) + "," + num2str(cmd_pressure(4),formatSpec) + "," +...
                   num2str(cmd_pressure(5),formatSpec) + "," + num2str(cmd_pressure(6),formatSpec) + "," +...
                   num2str(cmd_pressure(7),formatSpec) + "," + num2str(cmd_pressure(8),formatSpec) + "\n";
fprintf(serial_port,str_cmd_pressure)
end

% read the feedback pressure 
function fed_pressure = read_pressure(serial_port)
    fed_pressure = fscanf(serial_port);
    fed_pressure = split(fed_pressure,',');
    fed_pressure = cellfun(@str2num,fed_pressure,'un',0);
    fed_pressure = cell2mat(fed_pressure);
end
