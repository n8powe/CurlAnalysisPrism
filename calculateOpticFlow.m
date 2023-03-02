function flow = calculateOpticFlow(vidReader, OpticFlowFilesFolder, runDeepFlow, videoName,...
    maxFrames)
    
    H = vidReader.Height;
    W = vidReader.Width;

    maxZeros = numel(num2str(maxFrames)) - 1;

    if runDeepFlow
        
        callDeepFlowInPython(videoName, 'OpticFlow', H, W);
    
    else
        mkdir(OpticFlowFilesFolder);

        opticFlow = opticalFlowFarneback;


        %opticFlowStruct = struct;

        id = 1;
        while hasFrame(vidReader)
            id
            %opticFlowStruct.Frame(id) = struct('flow', 0);

            frameRGB = readFrame(vidReader);
            frameGray = rgb2gray(frameRGB);  
            flow = estimateFlow(opticFlow,frameGray);
            %opticFlowStruct.Frame(id).flow = flow;
            %opticFlowStruct.Frame(id).dy = flow.dy;
            if id < maxFrames
               subLength = (numel(num2str(id)) - 1); 
               numZeros = maxZeros -  subLength;
               e = '';
               for j=1:numZeros
                   numZerosStr = strcat(e,num2str(0));
                   e = numZerosStr;
               end
            end
            
            save(strcat('opticFlowFiles/opticFlowFrame', numZerosStr ,num2str(id),'.mat'), 'flow');
            id = id + 1;
        end
        %flow = opticFlowStruct;
    end
    
end