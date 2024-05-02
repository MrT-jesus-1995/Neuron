% Get subject info
prompt = {'Subject', 'Session', 'Block', 'Sex', 'Age', 'Deadline (0.2-5; start 0.6)', 'EEG or not'};
defAns = {'10001', '1', '1', 'f', '39', '3', '0'};
box = inputdlg(prompt, 'Enter Subject Information...', 1, defAns);

if isempty(box) % Check if the user canceled input
    return; % Exit the script if input was canceled
end

p.subNum = str2double(box{1});
p.session_num = str2double(box{2});
p.runNum = str2double(box{3});
p.sex = box{4};
p.age = str2double(box{5});
p.rspdeadline = str2double(box{6});
p.EEG = str2double(box{7});

% Validate response deadline
if p.rspdeadline < 0.2 || p.rspdeadline > 5
    errordlg('Response deadline must be between 0.2 and 5 seconds.');
    return;
end

%% Serial Port connecting
if p.EEG == 1
    SerialPort = BioSemiSerialPort();
end

%%
p.s = round(sum(100*clock));
rand('state', p.s);

%%
ListenChar(2);

% build an output file name and check to make sure that it does not exist already
p.root = pwd;
if ~exist([p.root, '/data/'], 'dir')
    mkdir([p.root, '/data/']);
end

mkdir([p.root, '/data/s', num2str(p.subNum)]);
fName = [p.root, '/data/s', num2str(p.subNum), '/flanker_allages_EEG' '_sbj',  num2str(p.subNum), '_session', num2str(p.session_num),  '_block', num2str(p.runNum), '.mat'];
bName = [p.root, '/data/s', num2str(p.subNum), '/flanker_allages_EEG_code' '_sbj', num2str(p.subNum), '_session', num2str(p.session_num), '.mat'];

if exist(fName,'file')
    Screen('CloseAll');
    msgbox('File name already exists, please specify another', 'modal');
    ListenChar(0);
    return
end

%% load sound
%[x, countdownsound] = audioread(strcat(p.root, '/sound/Mario_Kart_Race_Start_-_Sound_Effect_HD.mp3')); 
%[y, rightsound] = audioread(strcat(p.root, '/sound/right.mp3')); 

abortKey = KbName('q');
%% load images
tgfolder = pwd;

FlushEvents;
% Enable UTF-8 character encoding
fontFile = 'Downloads\Niramit';
feature('DefaultCharacterSet', 'UTF8');

% Define colors and color strings
colors = [255, 0, 0; % Red
          0, 255, 0; % Green
          0, 0, 255; % Blue
          0, 0, 0]; % Black
colorStrings = {'RED', 'GREEN', 'BLUE', 'BLACK'};
colorStringsThai = {'แดง', 'เขียว', 'ฟ้า', 'ดำ'}; % Thai color strings
colorStringsMix = {colorStrings,colorStringsThai};

% Define correct responses based on key mappings
correctResponses = {'1!', '2@', '3#', '4$'}; % Key mappings for colors

% Set up screen
AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 0);
screen = max(Screen('Screens'));
[win, scr_rect] = PsychImaging('OpenWindow', screen, 128, round([-1, -1, 1921, 1081]));
[winWidth, winHeight] = Screen('WindowSize', win);

% Run trials
numTrials = 60;
numInconguentTrials = 5;
numCongruentTrials = 5;
numMixTrials = 5;
numBlock = 5;
% Proportion of incongruent trials (adjust as needed)
propIncongruent = 0.5; % 50% incongruent trials

% Calculate number of congruent and incongruent trials
numMixCongruentTrials = round(2 * (1 - propIncongruent));
numMixIncongruentTrials = round(numInconguentTrials * propIncongruent);

trialData = cell(numTrials, 5); % Change 5 to the number of fields you want to store

% init
init1 = imread([tgfolder, '/image/TF.png']);
init2 = imread([tgfolder, '/image/TF (2).png']);
init3 = imread([tgfolder, '/image/TF (3).png']);
init1 = Screen('MakeTexture', win, init1);
init2 = Screen('MakeTexture', win, init2);
init3 = Screen('MakeTexture', win, init3);
size(init1)


% Display the start page
Screen('DrawTexture', win, init1, [], [], []); % Display the first image
Screen('Flip', win);
KbStrokeWait;
Screen('DrawTexture', win, init2, [], [], []); % Display the second image
Screen('Flip', win);
KbStrokeWait;
Screen('DrawTexture', win, init3, [], [], []); % Display the third image
Screen('Flip', win);


% Wait for a key press to continue
KbStrokeWait;

% Display countdown
countdownTime = 3; % Set the countdown duration in seconds
Screen('TextSize', win, 80); % Set text size for countdown
Screen('TextFont', win, 'Arial'); % Set font for countdown
for countdown = countdownTime:-1:1
    DrawFormattedText(win, sprintf('%d', countdown), 'center', 'center', [255 255 255]); % Display countdown number
    Screen('Flip', win);
    WaitSecs(1); % Wait for 1 second
end

% Display "Go" message
DrawFormattedText(win, 'Go', 'center', 'center', [255 255 255]);
Screen('Flip', win);
WaitSecs(1); % Wait for 1 second

% Run congruent trials  
for trial = 1:numCongruentTrials
    trialData = runCongruentTrial(win, winWidth, winHeight, trial, numCongruentTrials, colors, colorStrings, colorStringsThai, correctResponses, p.rspdeadline, trialData, p, numBlock);
end

% Run incongruent trials
for trial = 1:numInconguentTrials
    trialData = runIncongruentTrial(win, winWidth, winHeight, trial, numInconguentTrials, colors, colorStrings, colorStringsThai, correctResponses, p.rspdeadline, trialData, p, numBlock);
numBlock = numBlock+1;
end

% Run incongruentEN trials
for trial = 1:numInconguentTrials
    trialData = runIncongruentTrialEN(win, winWidth, winHeight, trial, numInconguentTrials, colors, colorStrings, correctResponses, p.rspdeadline, trialData, p, numBlock);
numBlock = numBlock+1;
end

% Run congruentEN trials
for trial = 1:numCongruentTrials
    trialData = runCongruentTrialEN(win, winWidth, winHeight, trial, numCongruentTrials, colors, colorStrings, correctResponses, p.rspdeadline, trialData, p, numBlock);
numBlock = numBlock+1;
end

% Run incongruentTH trials
for trial = 1:numInconguentTrials
    trialData = runIncongruentTrialTH(win, winWidth, winHeight, trial, numInconguentTrials, colors, colorStrings, colorStringsThai, correctResponses, p.rspdeadline, trialData, p, numBlock);
numBlock = numBlock+1;
end

% Run congruentTH trials
for trial = 1:numCongruentTrials
    trialData = runCongruentTrialTH(win, winWidth, winHeight, trial, numCongruentTrials, colors, colorStrings, colorStringsThai, correctResponses, p.rspdeadline, trialData, p, numBlock);
numBlock = numBlock+1;
end

% RUN MIX trials
for trial = 1:numMixTrials

  % Randomly choose between congruent or incongruent trial
  numMixCongruentTrials = rand < (1 - propIncongruent);
  
  % Call appropriate trial function based on congruency
if numMixCongruentTrials
     trialData = runCongruentTrial(win, winWidth, winHeight, trial, numMixTrials, colors, colorStrings, colorStringsThai, correctResponses, p.rspdeadline, trialData, p, numBlock);
  else
     trialData = runIncongruentTrial(win, winWidth, winHeight, trial, numMixTrials, colors, colorStrings, colorStringsThai, correctResponses, p.rspdeadline, trialData, p, numBlock);
 end
  numBlock = numBlock+1;

end

% RUN MIXEN trials
for trial = 1:numMixTrials

  % Randomly choose between congruent or incongruent trial
  congruentTrial = rand < (1 - propIncongruent);
  
  % Call appropriate trial function based on congruency
  if numMixCongruentTrials
    trialData = runCongruentTrialEN(win, winWidth, winHeight, trial, numMixTrials, colors, colorStrings, correctResponses, p.rspdeadline, trialData, p, numBlock);
  else
    trialData = runIncongruentTrialEN(win, winWidth, winHeight, trial, numMixTrials, colors, colorStrings, correctResponses, p.rspdeadline, trialData, p, numBlock);
  end
  numBlock = numBlock+1;
end

% RUN MIXTH trials
for trial = 1:numMixTrials

  % Randomly choose between congruent or incongruent trial
 congruentTrial = rand < (1 - propIncongruent);
  
  % Call appropriate trial function based on congruency
  if numMixCongruentTrials
    trialData = runCongruentTrialTH(win, winWidth, winHeight, trial, numMixTrials, colors, colorStrings, colorStringsThai, correctResponses, p.rspdeadline, trialData, p, numBlock);
  else
    trialData = runIncongruentTrialTH(win, winWidth, winHeight, trial, numMixTrials, colors, colorStrings, colorStringsThai, correctResponses, p.rspdeadline, trialData, p, numBlock);
  end
numBlock = numBlock+1;
  
end

% Convert cell array to table
trialTable = cell2table(trialData(1:end, :)); % Exclude header row

% Set new headers for the table
trialTable.Properties.VariableNames = {'Type', 'No', 'Color', 'Result', 'ResponseColor'};

% Write trial data to CSV file
csvFileName = [p.root, '/data/s', num2str(p.subNum), '/trial_data1.csv'];
writetable(trialTable, 'C:\Users\Toddy\Downloads\StroopTaskmunk\data\trial_data4.csv');

% Clean up
ListenChar(0);
sca;

%% Function to run incongruent trials
function trialData = runIncongruentTrial(win, winWidth, winHeight, trialNum, totalTrials, colors, colorStrings, colorStringsThai, correctResponses, rspdeadline, trialData, p, numBlock)
    % Display trial number
    Screen('TextSize', win, 36);
    DrawFormattedText(win, sprintf('Trial %d / %d', trialNum, totalTrials), 'center', winHeight - 50, [255 255 255]);
    
    % Randomly select color word (Thai or English) and ink color (ensure they are different)
    randSelection = rand;
    if randSelection < 0.5 % Randomly choose between English and Thai
        wordIndex = randi(length(colorStrings) + length(colorStringsThai)); % Include both English and Thai strings
        if wordIndex <= length(colorStrings)
            wordString = colorStrings{wordIndex};  % Use English string
        else
            wordIndex = wordIndex - length(colorStrings);  % Adjust index for Thai strings
            wordString = colorStringsThai{wordIndex};  % Use Thai string
        end
    else
        wordIndex = randi(length(colorStrings) + length(colorStringsThai)); % Include both English and Thai strings
        if wordIndex <= length(colorStrings)
            wordString = colorStrings{wordIndex};  % Use English string
        else
            wordIndex = wordIndex - length(colorStrings);  % Adjust index for Thai strings
            wordString = colorStringsThai{wordIndex};  % Use Thai string
        end
    end
    
    inkIndex = randi(size(colors, 1));
    while inkIndex == wordIndex
        inkIndex = randi(size(colors, 1));
    end
    
    % Set text color based on ink color
    textColor = colors(inkIndex, :); 
    
    % Display stimulus with text color
    Screen('TextSize', win, 256);
    Screen('TextFont', win, 'Cordia New');
    Screen('TextColor', win, textColor);
    Screen('TextStyle', win, 1);
    DispText = double(typecast(unicode2native(wordString, 'utf-16le'), 'uint16'));
    DrawFormattedText(win, DispText, 'center', 'center');
    Screen('Flip', win);

    % Record response time and accuracy
    respStart = GetSecs;
    keyPressed = false;
    while GetSecs - respStart < p.rspdeadline
        [keyIsDown, ~, keyCode] = KbCheck;
        
        if keyIsDown
            pressedKey = KbName(keyCode);
            
            if any(strcmpi(pressedKey, correctResponses))
                keyPressed = true;
                break;
            end
        end
    end

    if keyPressed
        fprintf('Answer Color: %s, Key Pressed: %s\n', colorStrings{inkIndex}, pressedKey);
    end
    
   % Handle response
    if keyPressed
        % Get the index of the pressed key in correctResponses
        responseIndex = find(strcmpi(pressedKey, correctResponses));

        if ~isempty(responseIndex)
            % Participant's response matches a correct response
            % Get the correct color index corresponding to the response
            correctColorIndex = responseIndex;

            % Check if displayed color matches correct response
            if correctColorIndex == inkIndex
                fprintf('Trial %d: Correct\n', trialNum);
                result = 'Correct'; 
                responseColor = colorStrings{correctColorIndex};
            else
                fprintf('Trial %d: Incorrect (Color mismatch)\n', trialNum);
                result = 'Incorrect';
                responseColor = colorStrings{correctColorIndex}; 
            end
        else
            % Participant'sresponse does not match any correct response
           fprintf('Trial %d: Incorrect (Invalid response)\n', trialNum);
           result = 'Invalid response';
           responseColor = responseIndex;
       end
    else
       % No response detected within response deadline
       fprintf('Trial %d: No response\n', trialNum);
       result  = 'No response';
       responseColor = '-'; 
    end

    trialData{trialNum+numBlock, 1} = 'InCongruent'; % Mark trial type
    trialData{trialNum+numBlock, 2} = trialNum; % Trial number
    trialData{trialNum+numBlock, 3} = colorStrings{inkIndex}; % Store accuracy information
    trialData{trialNum+numBlock, 4} = result; % Store ink color index
    trialData{trialNum+numBlock, 5} = responseColor; % Store accuracy information

    % Pause briefly before next trial
    WaitSecs(0.5);
end

% Function to run congruent trials
function trialData = runCongruentTrial(win, winWidth, winHeight, trialNum, totalTrials, colors, colorStrings, colorStringsThai, correctResponses, rspdeadline, trialData, p, numBlock)
    % Display trial number
    Screen('TextSize', win, 36);
    DrawFormattedText(win, sprintf('Trial %d / %d', trialNum, totalTrials), 'center', winHeight - 50, [255 255 255]);

    % Randomly select color word (Thai or English) and ink color (ensure they are the same)
    randSelection = rand;
    
    if randSelection < 0.5 % Randomly choose between English and Thai
        wordIndex = randi(length(colorStrings)); % Select English color word index
        wordString = colorStrings{wordIndex};  % Use English string
    else
        wordIndex = randi(length(colorStringsThai)); % Select Thai color word index
        wordString = colorStringsThai{wordIndex};  % Use Thai string
    end
    
    inkIndex = wordIndex; % Ensure ink color matches word color
    
    % Set text color based on ink color
    textColor = colors(inkIndex, :); 
    
    % Display stimulus with text color
    Screen('TextSize', win, 256);
    Screen('TextFont', win, 'Cordia New');
    Screen('TextColor', win, textColor);
    Screen('TextStyle', win, 1);
    DispText = double(typecast(unicode2native(wordString, 'utf-16le'), 'uint16'));
    DrawFormattedText(win, DispText, 'center', 'center');
    Screen('Flip', win);

    % Record response time and accuracy
    respStart = GetSecs;
    keyPressed = false;
    while GetSecs - respStart < p.rspdeadline
        [keyIsDown, ~, keyCode] = KbCheck;
        
        if keyIsDown
            pressedKey = KbName(keyCode);
            
            if any(strcmpi(pressedKey, correctResponses))
                keyPressed = true;
                break;
            end
        end
    end

    if keyPressed
        fprintf('Answer Color: %s, Key Pressed: %s\n', colorStrings{inkIndex}, pressedKey);
    end
    
  % Handle response
    if keyPressed
        % Get the index of the pressed key in correctResponses
        responseIndex = find(strcmpi(pressedKey, correctResponses));

        if ~isempty(responseIndex)
            % Participant's response matches a correct response
            % Get the correct color index corresponding to the response
            correctColorIndex = responseIndex;

            % Check if displayed color matches correct response
            if correctColorIndex == inkIndex
                fprintf('Trial %d: Correct\n', trialNum);
                result = 'Correct'; 
                responseColor = colorStrings{correctColorIndex};
            else
                fprintf('Trial %d: Incorrect (Color mismatch)\n', trialNum);
                result = 'Incorrect';
                responseColor = colorStrings{correctColorIndex}; 
            end
        else
            % Participant'sresponse does not match any correct response
           fprintf('Trial %d: Incorrect (Invalid response)\n', trialNum);
           result = 'Invalid response';
           responseColor = responseIndex;
       end
    else
       % No response detected within response deadline
       fprintf('Trial %d: No response\n', trialNum);
       result  = 'No response';
       responseColor = '-'; 
    end

    trialData{trialNum, 1} = 'Congruent'; % Mark trial type
    trialData{trialNum, 2} = trialNum; % Trial number
    trialData{trialNum, 3} = colorStrings{inkIndex}; % Store accuracy information
    trialData{trialNum, 4} = result; % Store ink color index
    trialData{trialNum, 5} = responseColor; % Store accuracy information
    % Pause briefly before next trial
    WaitSecs(0.5);
end

%% Function to run incongruent trials
function trialData = runIncongruentTrialEN(win, winWidth, winHeight, trialNum, totalTrials, colors, colorStrings, correctResponses, rspdeadline, trialData, p, numBlock)
    % Display trial number
    Screen('TextSize', win, 36);
    DrawFormattedText(win, sprintf('Trial %d / %d', trialNum, totalTrials), 'center', winHeight - 50, [255 255 255]);

    % Select color word (English) and ink color (ensure they are different)
    wordIndex = randi(length(colorStrings));
    wordString = colorStrings{wordIndex};

    inkIndex = randi(size(colors, 1));
    while inkIndex == wordIndex
        inkIndex = randi(size(colors, 1));
    end

    % Set text color based on ink color
    textColor = colors(inkIndex, :);

    % Display stimulus with text color
    Screen('TextSize', win, 256);
    Screen('TextFont', win, 'Cordia New');
    Screen('TextColor', win, textColor);
    Screen('TextStyle', win, 1);
    DispText = double(typecast(unicode2native(wordString, 'utf-16le'), 'uint16'));
    DrawFormattedText(win, DispText, 'center', 'center');
    Screen('Flip', win);

    % Record response time and accuracy
    respStart = GetSecs;
    keyPressed = false;
    while GetSecs - respStart < p.rspdeadline
        [keyIsDown, ~, keyCode] = KbCheck;

        if keyIsDown
            pressedKey = KbName(keyCode);

            if any(strcmpi(pressedKey, correctResponses))
                keyPressed = true;
                break;
            end
        end
    end

    if keyPressed
        fprintf('Answer Color: %s, Key Pressed: %s\n', colorStrings{inkIndex}, pressedKey);
    end

% Handle response
    if keyPressed
        % Get the index of the pressed key in correctResponses
        responseIndex = find(strcmpi(pressedKey, correctResponses));

        if ~isempty(responseIndex)
            % Participant's response matches a correct response
            % Get the correct color index corresponding to the response
            correctColorIndex = responseIndex;

            % Check if displayed color matches correct response
            if correctColorIndex == inkIndex
                fprintf('Trial %d: Correct\n', trialNum);
                result = 'Correct'; 
                responseColor = colorStrings{correctColorIndex};
            else
                fprintf('Trial %d: Incorrect (Color mismatch)\n', trialNum);
                result = 'Incorrect';
                responseColor = colorStrings{correctColorIndex}; 
            end
        else
            % Participant'sresponse does not match any correct response
           fprintf('Trial %d: Incorrect (Invalid response)\n', trialNum);
           result = 'Invalid response';
           responseColor = responseIndex;
       end
    else
       % No response detected within response deadline
       fprintf('Trial %d: No response\n', trialNum);
       result  = 'No response';
       responseColor = '-'; 
    end

    trialData{trialNum+numBlock, 1} = 'InCongruentEN'; % Mark trial type
    trialData{trialNum+numBlock, 2} = trialNum; % Trial number
    trialData{trialNum+numBlock, 3} = colorStrings{inkIndex}; % Store accuracy information
    trialData{trialNum+numBlock, 4} = result; % Store ink color index
    trialData{trialNum+numBlock, 5} = responseColor; % Store accuracy information
    % Pause briefly before next trial
    WaitSecs(0.5);
end

%% Function to run congruent trials
function trialData = runCongruentTrialEN(win, winWidth, winHeight, trialNum, totalTrials, colors, colorStrings, correctResponses, rspdeadline, trialData, p, numBlock)
    % Display trial number
    Screen('TextSize', win, 36);
    DrawFormattedText(win, sprintf('Trial %d / %d', trialNum, totalTrials), 'center', winHeight - 50, [255 255 255]);

    % Select color word (English) and ink color (ensure they are the same)
    wordIndex = randi(length(colorStrings));
    wordString = colorStrings{wordIndex};
    inkIndex = wordIndex; % Ensure ink color matches word color

    % Set text color based on ink color
    textColor = colors(inkIndex, :);

    % Display stimulus with text color
    Screen('TextSize', win, 256);
    Screen('TextFont', win, 'Cordia New');
    Screen('TextColor', win, textColor);
    Screen('TextStyle', win, 1);
    DispText = double(typecast(unicode2native(wordString, 'utf-16le'), 'uint16'));
    DrawFormattedText(win, DispText, 'center', 'center');
    Screen('Flip', win);

    % Record response time and accuracy
    respStart = GetSecs;
    keyPressed = false;
    while GetSecs - respStart < p.rspdeadline
        [keyIsDown, ~, keyCode] = KbCheck;

        if keyIsDown
            pressedKey = KbName(keyCode);

            if any(strcmpi(pressedKey, correctResponses))
                keyPressed = true;
                break;
            end
        end
    end

    if keyPressed
        fprintf('Answer Color: %s, Key Pressed: %s\n', colorStrings{inkIndex}, pressedKey);
    end

       % Handle response
    if keyPressed
        % Get the index of the pressed key in correctResponses
        responseIndex = find(strcmpi(pressedKey, correctResponses));

        if ~isempty(responseIndex)
            % Participant's response matches a correct response
            % Get the correct color index corresponding to the response
            correctColorIndex = responseIndex;

            % Check if displayed color matches correct response
            if correctColorIndex == inkIndex
                fprintf('Trial %d: Correct\n', trialNum);
                result = 'Correct'; 
                responseColor = colorStrings{correctColorIndex};
            else
                fprintf('Trial %d: Incorrect (Color mismatch)\n', trialNum);
                result = 'Incorrect';
                responseColor = colorStrings{correctColorIndex}; 
            end
        else
            % Participant'sresponse does not match any correct response
           fprintf('Trial %d: Incorrect (Invalid response)\n', trialNum);
           result = 'Invalid response';
           responseColor = responseIndex;
       end
    else
       % No response detected within response deadline
       fprintf('Trial %d: No response\n', trialNum);
       result  = 'No response';
       responseColor = '-'; 
    end

    trialData{trialNum+numBlock, 1} = 'CongruentEN'; % Mark trial type
    trialData{trialNum+numBlock, 2} = trialNum; % Trial number
    trialData{trialNum+numBlock, 3} = colorStrings{inkIndex}; % Store accuracy information
    trialData{trialNum+numBlock, 4} = result; % Store ink color index
    trialData{trialNum+numBlock, 5} = responseColor; % Store accuracy information
    % Pause briefly before next trial
    WaitSecs(0.5);
end

%% Function to run incongruent trials
function trialData = runIncongruentTrialTH(win, winWidth, winHeight, trialNum, totalTrials, colors, colorStrings, colorStringsThai, correctResponses, rspdeadline, trialData, p, numBlock)
    % Display trial number
    Screen('TextSize', win, 36);
    DrawFormattedText(win, sprintf('Trial %d / %d', trialNum, totalTrials), 'center', winHeight - 50, [255 255 255]);

    % Select color word (English) and ink color (ensure they are different)
    wordIndex = randi(length(colorStringsThai));
    wordString = colorStringsThai{wordIndex};

    inkIndex = randi(size(colors, 1));
    while inkIndex == wordIndex
        inkIndex = randi(size(colors, 1));
    end

    % Set text color based on ink color
    textColor = colors(inkIndex, :);

    % Display stimulus with text color
    Screen('TextSize', win, 256);
    Screen('TextFont', win, 'Cordia New');
    Screen('TextColor', win, textColor);
    Screen('TextStyle', win, 1);
    DispText = double(typecast(unicode2native(wordString, 'utf-16le'), 'uint16'));
    DrawFormattedText(win, DispText, 'center', 'center');
    Screen('Flip', win);

    % Record response time and accuracy
    respStart = GetSecs;
    keyPressed = false;
    while GetSecs - respStart < p.rspdeadline
        [keyIsDown, ~, keyCode] = KbCheck;

        if keyIsDown
            pressedKey = KbName(keyCode);

            if any(strcmpi(pressedKey, correctResponses))
                keyPressed = true;
                break;
            end
        end
    end

    if keyPressed
        fprintf('Answer Color: %s, Key Pressed: %s\n', colorStrings{inkIndex}, pressedKey);
    end

     % Handle response
    if keyPressed
        % Get the index of the pressed key in correctResponses
        responseIndex = find(strcmpi(pressedKey, correctResponses));

        if ~isempty(responseIndex)
            % Participant's response matches a correct response
            % Get the correct color index corresponding to the response
            correctColorIndex = responseIndex;

            % Check if displayed color matches correct response
            if correctColorIndex == inkIndex
                fprintf('Trial %d: Correct\n', trialNum);
                result = 'Correct'; 
                responseColor = colorStrings{correctColorIndex};
            else
                fprintf('Trial %d: Incorrect (Color mismatch)\n', trialNum);
                result = 'Incorrect';
                responseColor = colorStrings{correctColorIndex}; 
            end
        else
            % Participant'sresponse does not match any correct response
           fprintf('Trial %d: Incorrect (Invalid response)\n', trialNum);
           result = 'Invalid response';
           responseColor = responseIndex;
       end
    else
       % No response detected within response deadline
       fprintf('Trial %d: No response\n', trialNum);
       result  = 'No response';
       responseColor = '-'; 
    end

    trialData{trialNum+numBlock, 1} = 'InCongruentTH'; % Mark trial type
    trialData{trialNum+numBlock, 2} = trialNum; % Trial number
    trialData{trialNum+numBlock, 3} = colorStringsThai{inkIndex}; % Store accuracy information
    trialData{trialNum+numBlock, 4} = result; % Store ink color index
    trialData{trialNum+numBlock, 5} = responseColor; % Store accuracy information
    % Pause briefly before next trial
    WaitSecs(0.5);
end

%% Function to run congruent trials
function trialData = runCongruentTrialTH(win, winWidth, winHeight, trialNum, totalTrials, colors, colorStrings, colorStringsThai, correctResponses, rspdeadline, trialData, p, numBlock)
    % Display trial number
    Screen('TextSize', win, 36);
    DrawFormattedText(win, sprintf('Trial %d / %d', trialNum, totalTrials), 'center', winHeight - 50, [255 255 255]);

    % Select color word (English) and ink color (ensure they are the same)
    wordIndex = randi(length(colorStringsThai));
    wordString = colorStringsThai{wordIndex};
    inkIndex = wordIndex; % Ensure ink color matches word color

    % Set text color based on ink color
    textColor = colors(inkIndex, :);

    % Display stimulus with text color
    Screen('TextSize', win, 256);
    Screen('TextFont', win, 'Cordia New');
    Screen('TextColor', win, textColor);
    Screen('TextStyle', win, 1);
    DispText = double(typecast(unicode2native(wordString, 'utf-16le'), 'uint16'));
    DrawFormattedText(win, DispText, 'center', 'center');
    Screen('Flip', win);

    % Record response time and accuracy
    respStart = GetSecs;
    keyPressed = false;
    while GetSecs - respStart < p.rspdeadline
        [keyIsDown, ~, keyCode] = KbCheck;

        if keyIsDown
            pressedKey = KbName(keyCode);

            if any(strcmpi(pressedKey, correctResponses))
                keyPressed = true;
                break;
            end
        end
    end

    if keyPressed
        fprintf('Answer Color: %s, Key Pressed: %s\n', colorStrings{inkIndex}, pressedKey);
    end

       % Handle response
    if keyPressed
        % Get the index of the pressed key in correctResponses
        responseIndex = find(strcmpi(pressedKey, correctResponses));

        if ~isempty(responseIndex)
            % Participant's response matches a correct response
            % Get the correct color index corresponding to the response
            correctColorIndex = responseIndex;

            % Check if displayed color matches correct response
            if correctColorIndex == inkIndex
                fprintf('Trial %d: Correct\n', trialNum);
                result = 'Correct'; 
                responseColor = colorStrings{correctColorIndex};
            else
                fprintf('Trial %d: Incorrect (Color mismatch)\n', trialNum);
                result = 'Incorrect';
                responseColor = colorStrings{correctColorIndex}; 
            end
        else
            % Participant'sresponse does not match any correct response
           fprintf('Trial %d: Incorrect (Invalid response)\n', trialNum);
           result = 'Invalid response';
           responseColor = responseIndex;
       end
    else
       % No response detected within response deadline
       fprintf('Trial %d: No response\n', trialNum);
       result  = 'No response';
       responseColor = '-'; 
    end

    trialData{trialNum+numBlock, 1} = 'CongruentTH'; % Mark trial type
    trialData{trialNum+numBlock, 2} = trialNum; % Trial number
    trialData{trialNum+numBlock, 3} = colorStringsThai{inkIndex}; % Store accuracy information
    trialData{trialNum+numBlock, 4} = result; % Store ink color index
    trialData{trialNum+numBlock, 5} = responseColor; % Store accuracy information
    % Pause briefly before next trial
    WaitSecs(0.5);
end




