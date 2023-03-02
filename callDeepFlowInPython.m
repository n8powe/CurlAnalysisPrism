function callDeepFlowInPython(videoFilePath, flowType, H,W)
   
    if strcmp(flowType, 'OpticFlow')
        pythonCall = "python";
        pythonScriptName = "openCVOF2.py";
        exportDir = "opticFlowFiles";
        visualize = 0;
        maxFrames = "9999";
        dims = strcat(num2str(H),'x',num2str(W));
    elseif strcmp(flowType, 'RetinalFlow')
        pythonCall = "python";
        pythonScriptName = "openCVOF2.py";
        exportDir = "retinalFlowFiles";
        visualize = 0;
        maxFrames = "9999";
        dims = strcat(num2str(H),'x',num2str(W));
    end
    
    arguments = [pythonCall, pythonScriptName, exportDir, videoFilePath, maxFrames , dims, visualize];
    system(join(arguments));


end