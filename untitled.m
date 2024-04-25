% Get subject info
prompt = {'Subject', 'Session', 'Block', 'Sex', 'Hand', 'Age', 'Deadline (0.2-2; start 0.6)', 'EEG or not'};
defAns = {'10001', '1', '1', 'f', 'r', '39', '2', '0'};
box = inputdlg(prompt, 'Enter Subject Information...', 1, defAns);

if isempty(box) % Check if the user canceled input
    return; % Exit the script if input was canceled
end

p.subNum = str2double(box{1});
p.session_num = str2double(box{2});
p.runNum = str2double(box{3});
p.sex = box{4};
p.hand = box{5};
p.age = str2double(box{6});
p.rspdeadline = str2double(box{7});
p.EEG = str2double(box{8});

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
% Enable UTF-8 character encoding
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
numInconguentTrials = 20;
numCongruentTrials = 20;

% Run congruent trials
for trial = 1:numCongruentTrials
    runCongruentTrial(win, winWidth, winHeight, trial, numCongruentTrials, colors, colorStrings, colorStringsThai, correctResponses, p.rspdeadline);
end

% Run incongruent trials
for trial = 1:numInconguentTrials
    runInconguentTrial(win, winWidth, winHeight, trial, numInconguentTrials, colors, colorStrings, colorStringsThai, correctResponses, p.rspdeadline);
end

% Run incongruent trials
for trial = 1:numInconguentTrials
    runInconguentTrial(win, winWidth, winHeight, trial, numInconguentTrials, colors, colorStrings, colorStringsThai, correctResponses, p.rspdeadline);
end

% Clean up
ListenChar(0);
sca;

%% Function to run incongruent trials
function runInconguentTrial(win, winWidth, winHeight, trialNum, totalTrials, colors, colorStrings, colorStringsThai, correctResponses, rspdeadline)
   
    % Display trial number
    Screen('TextSize', win, 36);
    DrawFormattedText(win, sprintf('Trial %d / %d', trialNum, totalTrials), 'center', winHeight - 50, [255 255 255]);
    
    % Randomly select color word (Thai or English) and ink color (ensure they are different)
    wordIndex = randi(length(colorStrings) + length(colorStringsThai)); % Include both English and Thai strings
    if wordIndex <= length(colorStrings)
        wordString = colorStrings{wordIndex};  % Use English string
    else
        wordIndex = wordIndex - length(colorStrings);  % Adjust index for Thai strings
        wordString = colorStringsThai{wordIndex};  % Use Thai string
    end
    inkIndex = randi(size(colors, 1));
    while inkIndex == wordIndex
        inkIndex = randi(size(colors, 1));
    end

    % Set text color based on ink color
    textColor = colors(inkIndex, :); 
    
    % Display stimulus with text color
    Screen('TextSize', win, 256);
    Screen('TextFont', win, 'Arial');
    % Set the text color and alpha-blending for smooth rendering
    Screen('TextColor', win, textColor);
    Screen('TextStyle', win, 1);
    DrawFormattedText(win, colorStrings{wordIndex}, 'center', 'center');
    Screen('Flip', win);

    % Record response time and accuracy
    respStart = GetSecs;
    keyPressed = false;
    while GetSecs - respStart < rspdeadline
        [keyIsDown, ~, keyCode] = KbCheck;
        
        if keyIsDown
            % Get the name of the key that is pressed
            pressedKey = KbName(keyCode);
            
            % Check if any of the correctResponses match the pressed key
            if any(strcmpi(pressedKey, correctResponses))
                keyPressed = true;
                break;
            end
        end
    end

     % Show the answer color and the key pressed
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
            else
                fprintf('Trial %d: Incorrect (Color mismatch)\n', trialNum);
            end
        else
            % Participant's response does not match any correct response
            fprintf('Trial %d: Incorrect (Invalid response)\n', trialNum);
        end
    else
        % No response detected within response deadline
        fprintf('Trial %d: No response\n', trialNum);
    end
    
    % Pause briefly before next trial
    WaitSecs(0.5);
end

%% Function to run congruent trials
function runCongruentTrial(win, winWidth, winHeight, trialNum, totalTrials, colors, colorStrings, colorStringsThai, correctResponses, rspdeadline)
    % Display trial number
    Screen('TextSize', win, 36);
    DrawFormattedText(win, sprintf('Trial %d / %d', trialNum, totalTrials), 'center', winHeight - 50, [255 255 255]);
    
    % Randomly select color word and ink color, ensuring they are the same
    wordIndex = randi(length(colorStrings));
    inkIndex = wordIndex;

    % Set text color based on ink color
    textColor = colors(inkIndex, :); 
    
    % Display stimulus with text color
    Screen('TextSize', win, 256);
    Screen('TextFont', win, 'Arial');
    % Set the text color and alpha-blending for smooth rendering
    Screen('TextColor', win, textColor);
    Screen('TextStyle', win, 1);
    DrawFormattedText(win, colorStrings{wordIndex}, 'center', 'center');
    Screen('Flip', win);

    % Record response time and accuracy
    respStart = GetSecs;
    keyPressed = false;
    while GetSecs - respStart < rspdeadline
        [keyIsDown, ~, keyCode] = KbCheck;
        
        if keyIsDown
            % Get the name of the key that is pressed
            pressedKey = KbName(keyCode);
            
            % Check if any of the correctResponses match the pressed key
            if any(strcmpi(pressedKey, correctResponses))
                keyPressed = true;
                break;
            end
        end
    end

   % Show the answer color and the key pressed
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
            else
                fprintf('Trial %d: Incorrect (Color mismatch)\n', trialNum);
            end
        else
            % Participant'sresponse does not match any correct response
           fprintf('Trial %d: Incorrect (Invalid response)\n', trialNum);
       end
   else
       % No response detected within response deadline
       fprintf('Trial %d: No response\n', trialNum);
    end
   
   % Pause briefly before next trial
   WaitSecs(0.5);
end