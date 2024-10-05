function myTry(inputFile, outputFile, energyThreshold, minSilenceDuration)
    % 输入参数：
    % inputFile: 输入音频文件名（例如：'input.wav'）
    % outputFile: 输出音频文件名（例如：'output.wav'）
    % energyThreshold: 能量阈值 (一般值范围在0到1之间)
    % minSilenceDuration: 最小静音持续时间 (秒)
    
    % 1. 读取音频信号
    [inputSignal, fs] = audioread(inputFile);
    inputSignal = inputSignal(:, 1); % 如果是立体声，取单声道信号

    % 2. 设定参数
    frameSize = 256;    % 帧大小
    hopSize = 128;      % 帧移
    numFrames = floor((length(inputSignal) - frameSize) / hopSize) + 1;
    
    % 3. 计算每帧的能量
    energy = zeros(numFrames, 1);
    for i = 1:numFrames
        frame = inputSignal((i-1)*hopSize + 1:(i-1)*hopSize + frameSize);
        energy(i) = sum(frame.^2); % 能量计算
    end
    
    % 归一化能量
    energy = energy / max(energy);
    
    % 4. 双门限检测
    silentFrames = energy < energyThreshold;
    
    % 5. 寻找语音的起始和结束帧
    startFrame = find(~silentFrames, 1, 'first'); % 第一个非静音帧
    endFrame = find(~silentFrames, 1, 'last');   % 最后一个非静音帧
    
    if isempty(startFrame) || isempty(endFrame)
        % 如果没有语音部分，返回原信号
        disp('未检测到语音段，输出原信号。');
        audiowrite(outputFile, inputSignal, fs);
        return;
    end
    
    % 6. 判断是否存在连续静音
    % 计算最小静音持续时间的帧数
    minSilentFrames = ceil(minSilenceDuration * fs / hopSize);
    
    % 检查在语音信号的开始前是否有静音
    if startFrame > minSilentFrames && all(silentFrames(1:startFrame-1))
        startFrame = startFrame - minSilentFrames; % 考虑静音段
    end
    
    % 检查在语音信号的结束后是否有静音
    if endFrame + minSilentFrames <= numFrames && all(silentFrames(endFrame+1:endFrame+minSilentFrames))
        endFrame = endFrame + minSilentFrames; % 考虑静音段
    end

    % 7. 提取有效的语音信号
    startSample = (startFrame - 1) * hopSize + 1;
    endSample = min((endFrame - 1) * hopSize + frameSize, length(inputSignal));
    speechSignal = inputSignal(startSample:endSample);

    % 8. 输出不含静音的语音信号
    audiowrite(outputFile, speechSignal, fs);
    
    % 9. 播放输出信号
    sound(speechSignal, fs);
    disp(['处理完成，输出文件: ', outputFile]);
end