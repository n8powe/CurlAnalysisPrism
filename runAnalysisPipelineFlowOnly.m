function runAnalysisPipelineFlowOnly(worldVideoPath)
    %% Run analysis pipeline on participant data.  
    %close all;
    %clear all;
    
    runFlowVisualization = true;
    runDeeperAnalyses = false;
    
    
    plotOpticFlow = true;
    plotRetinalFlow = false;
    
    useFixationForRF = false;
    
    plotGaze = false;
    showWorldVideo = true;
    resizeWorld = true;
    runDeepFlow = true;
    createNewMats = false; % default should be false
    saveFlowVideo = true;
    objectSegmentationView = false;
    plotBothOpticRetinalFlow = false;
    makeSceneVideoWithGaze = false;
    makeSceneVideo = false;
    makeSegmentationVideo = false;
    
    %% List all the file paths
    if runFlowVisualization
        %gazeFilePath = 'drone_capture_GatedPath.txt';
        gazeFilePath = 'DEBUG_drone_capture_P_GatedPathless.txt';
        jsonPath = "P_210820135308/S001/Flight Data_1_GatedPath_Block_2/GaiaTest3_2021-08-20-14-00-13_FlightData/000/info.player.json";
        %controlsFilePath = 'gazeDataFolder/drone_positions.txt';
        %obstacleDataPath = 'gazeDataFolder/obstacle_data.txt';
        gateCollisionDataPath = 'gate_data_gatedPath.txt';
        %worldVideoPath = videoName;%'63_FloorOnly_PrismLeft.mp4';%'gazeDataFolder/000/world.mp4';
        fixationDataPath = 'P_210820135308/S001/Flight Data_1_GatedPath_Block_2/GaiaTest3_2021-08-20-14-00-13_FlightData/000/exports/001/fixations.csv';
        %worldVideoPath = 'gazeDataFolder/000/exports/002/world.mp4';
        %worldVideoPath = 'removedFrames.mp4';
        OpticFlowFilesFolder = 'opticFlowFiles';
    
        %% Read in all of the data for the paths listed above. 
        if makeSceneVideoWithGaze || plotRetinalFlow || runDeeperAnalyses
            %gazeData = readEyeTrackingData(gazeFilePath, false, 0.1, false, 0);

            gazeDataFull = readtable(gazeFilePath, 'ReadVariableNames', true, 'HeaderLines', 0, 'Delimiter', '\t');
            gazeData = [gazeDataFull.Gaze_Viewport_Space_x, gazeDataFull.Gaze_Viewport_Space_y];
            if useFixationForRF
                fixationData = readFixationData(fixationDataPath);
                fixationData = findFixationTimingInPositionFile(gazeDataFull, fixationData, jsonPath, fixationDataPath);
            else
                fixationData = gazeData;
            end

        end
        %controlData = readControlData(controlsFilePath);  % controller data
        %gateCollisionData = readControlData(gateCollisionDataPath);  % controller data
        %obstacleData = readControlData(obstacleDataPath);  % controller data
        worldVideoObject = readWorldVideo(worldVideoPath);



        maxFrames = 9999;

        if makeSceneVideoWithGaze
            createSceneVideo(worldVideoPath, true, gazeData,'sceneVideoWithGazeOverlay')
        end

        if makeSceneVideo
            createSceneVideo(worldVideoPath, false, gazeData,'sceneVideo')
        end


        % Resize the world video if the resolution is too high. Makes OF
        % estimation faster. 
        if runFlowVisualization
            if resizeWorld && ~isfile('NewWorldVideo.mp4')
                resizeWorldVideo(worldVideoObject, 1,  'World');
                worldVideoObject = readWorldVideo('NewWorldVideo.mp4');
            elseif resizeWorld && isfile('NewWorldVideo.mp4')
                worldVideoObject = readWorldVideo(worldVideoPath);
            end

            
            removeDuplicateFrames('NewWorldVideo.mp4');
            

            %% Calculate Optic Flow for the world video
            if ~exist('opticFlowFiles', 'dir')
                %calculateOpticFlow(worldVideoObject, OpticFlowFilesFolder, runDeepFlow, 'duplicateFramesRemoved.mp4', maxFrames);
                calculateOpticFlow(readWorldVideo('duplicateFramesRemoved.mp4'), OpticFlowFilesFolder, runDeepFlow, 'duplicateFramesRemoved.mp4', maxFrames);
                createNewMats = false;
            end


            %% Plot the optic flow
            if plotOpticFlow
                %worldVideoObject = readWorldVideo('duplicateFramesRemoved.mp4');
                worldVideoObject = readWorldVideo('NewWorldVideo.mp4');
                if runDeepFlow
                    plotFlow('opticFlowFiles//NewWorldVideo//OpticFlow//', showWorldVideo, worldVideoObject, plotGaze,...
                    0, createNewMats, saveFlowVideo, 0, true, worldVideoPath);
                else
                    plotFlow('opticFlowFiles', showWorldVideo, worldVideoObject, plotGaze,...
                    gazeData, false, saveFlowVideo, 0, false, worldVideoPath);
                end
            end
            if exist('opticFlowFiles', 'dir')
                if useFixationForRF
                    retinalFlowGazeData = correctGazePosition(gazeData, fixationData, OpticFlowFilesFolder);
                end
            end
            %% Calculate & Plot the Retinal Flow
            if plotRetinalFlow
                if useFixationForRF
                    calculateRetinalFlow(retinalFlowGazeData, readWorldVideo('NewWorldVideo.mp4'), createNewMats, worldVideoPath)
                else
                    calculateRetinalFlow(gazeData, readWorldVideo('NewWorldVideo.mp4'), createNewMats, worldVideoPath)
                end
            end % change it to plot the padded video and the entire optic flow array. 

            if plotBothOpticRetinalFlow
                makeOpticAndOpticFlowVideo('estimatedOpticFlowVideo.mp4','estimatedRetinalFlowVideo.mp4');
            end

            if makeSegmentationVideo
                gazeData = readEyeTrackingData(gazeFilePath, false, 0.1, true, controlsFilePath);
                objectSegmentationVisualization( 'SegmentationImages',gazeData)
            end        

        end

    end

    
    if runDeeperAnalyses
       
       subjectFile = 'DroneExperimentData/P_210930142529_100/S001/';
       
       positionDataList = {'Flight Data_0_GatedPath_Block_1', 'Flight Data_1_GatedPath_Block_2', 'Flight Data_2_GatedPath_Block_4', ...
           'Flight Data_3_GatedPath_Block_6', 'Flight Data_4_GatedPath_Block_8', 'Flight Data_5_GatedPath_Block_10', ...
           'Flight Data_6_GatedPath_Block_12', 'Flight Data_7_GatedPath_Block_14', 'Flight Data_8_GatedPath_Block_16', ...
           'Flight Data_9_GatedPath_Block_18', 'Flight Data_10_GatedPath_Block_20', 'Flight Data_11_GatedPath_Block_22', ...
           'Flight Data_12_GatedPath_Block_24', 'Flight Data_13_GatedPath_Block_26', 'Flight Data_14_GatedPath_Block_28'};
       
       dataStructForAnalysis = struct;
       
       dataStructForAnalysis.PathOnlyIndices = [1,2, 11, 12, 13, 14, 23, 24, 25, 26];
       dataStructForAnalysis.HoopOnlyIndices = [5,6,7,8,17,18,19,20,27,28];
       dataStructForAnalysis.PathAndHoopOnlyIndices = [3,4,9,10,15,16,21,22,29,30];
       
       
       dataStructForAnalysis.meanMagnitudeGazeDistance = 0;
       dataStructForAnalysis.GazeDistanceVectors = struct;
       dataStructForAnalysis.GazeDistanceVectors = cell(1,15);
       dataStructForAnalysis.timeSpentFixatingHoops = 0;
       dataStructForAnalysis.timeSpentFixatingHoopsCenter = 0;
       dataStructForAnalysis.timeSpentFixatingTrees = 0;
       dataStructForAnalysis.timeSpentFixatingOther = 0;
       dataStructForAnalysis.timeSpentFixatingPath = 0;
       dataStructForAnalysis.meanHoopFixatedDistance = 0;
       dataStructForAnalysis.averagePathDev = 0;
       dataStructForAnalysis.avgSpdPerCond = 0;
       
       
       dataStructForAnalysis.ciMagnitudeGazeDistance = 0;
       dataStructForAnalysis.citimeSpentFixatingHoops = 0;
       dataStructForAnalysis.citimeSpentFixatingHoopsCenter = 0;
       dataStructForAnalysis.citimeSpentFixatingTrees = 0;
       dataStructForAnalysis.citimeSpentFixatingOther = 0;
       dataStructForAnalysis.citimeSpentFixatingPath = 0;
       dataStructForAnalysis.ciHoopFixatedDistance = 0;
       dataStructForAnalysis.ciPathDev = 0;
       dataStructForAnalysis.ciSpdPerCond = 0;      
       
       
       dataStructForAnalysis.meanGazeTimebetweenHoops = 0;
       dataStructForAnalysis.ciGazeTimebetweenHoops = 0;
       
       id = 1;
       for i=1:15
           i
           gazeData = readControlData(strcat(subjectFile, positionDataList{i}, '/GaiaTest3/drone_capture.txt'));
           
           %controlData = 0;
           obstacleData = readControlData(strcat(subjectFile, positionDataList{i}, '/GaiaTest3/obstacle_data.txt'));
           GateData = readControlData(strcat(subjectFile, positionDataList{i}, '/GaiaTest3/gate_data.txt'));
           %runCrossCorrelation(gazeData);
           for lap=0:1
               gazeDataLap = gazeData(gazeData.Lap_Number==lap, :);
               dataStructForAnalysis = runDeeperAnalysis(id, dataStructForAnalysis, gazeDataLap, obstacleData, GateData);%, opticFlow, retinalFlow, segmentationData); 
               
               id = id+1;
           end
       end
       
       
       
       
       visualizeExperimentData(dataStructForAnalysis, gazeData);
       
    end
    
    
end


function dataStructForAnalysis = runDeeperAnalysis(i, dataStructForAnalysis, gazeData, obstacleData, GateData)    %, opticFlow, retinalFlow, segmentationData, gateCollisionData)
    
    [dataStructForAnalysis.meanMagnitudeGazeDistance(i), dataStructForAnalysis.ciMagnitudeGazeDistance(i), magnitudeGazeDistance] = avgDistanceFixated(gazeData);

    
    
    %find distance fixated per block/condition
    
    dataStructForAnalysis.GazeDistanceVectors{1,i} = FixatedDistances(gazeData);

    
    % Find the average distance to hoop fixated. 
    
    dataStructForAnalysis.meanHoopFixatedDistance(i) = findHoopFixatedDistance(gazeData, magnitudeGazeDistance);
    
    % Time spent fixating through hoops compared to on their edges
    
    [dataStructForAnalysis.meanGazeTimebetweenHoops(i), dataStructForAnalysis.ciGazeTimebetweenHoops(i)] = findTimingFromOneGazeToTheNext(gazeData);
    
    % Find average switch from one gate/gate center to the next. 
    
    [dataStructForAnalysis.timeSpentFixatingHoops(i), ...
       dataStructForAnalysis.timeSpentFixatingHoopsCenter(i), ...
       dataStructForAnalysis.timeSpentFixatingOther(i), ...
       dataStructForAnalysis.timeSpentFixatingTrees(i), ...
       dataStructForAnalysis.timeSpentFixatingPath(i) ] = findTimeSpentFixatingObjectCategories(gazeData);
   
   % describe the collision data
    findCollisionObjectCategories(gazeData);
   
   %%
    
    [dataStructForAnalysis.averagePathDev(i), dataStructForAnalysis.ciPathDev(i)] = averagePathDeviation(gazeData);
    
    [dataStructForAnalysis.avgSpdPerCond(i), ~, dataStructForAnalysis.ciSpdPerCond(i), ~] = getAverageSpeedAndTimeperLap(gazeData);
end

