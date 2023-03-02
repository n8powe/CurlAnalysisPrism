function calculateFlowCurl()
    runPipeline = false;
    videoNameShort = '24_FloorOnly_FixationRight.mp4';

    subjectName = 'yo';

    trialPositionData = matchVideoWithPositionData_CurlAnalysis(videoNameShort, subjectName);

    startTime = trialPositionData.time(1);
    endTime = trialPositionData.time(end);

    timeDifference = endTime - startTime;

    numPositionPoints = size(trialPositionData,1);

    videoName = "PrismVids/yo/04072022_192341/24_FloorOnly_FixationRight.mp4";
    
    if runPipeline
        
        runAnalysisPipelineFlowOnly(videoNameShort);
    end

    videoName = 'duplicateFramesRemoved';
    
    flowFilesFolder = strcat('opticFlowFiles/',videoName,'/OpticFlow');
    videoFilePath = strcat(videoName,'.mp4');
    
    [fileNames, numFrames] = readFolder(flowFilesFolder, false);

    intervalSize = 50;
    
    worldVideoObjectFullRes = readWorldVideo(videoFilePath);

    numVideoFrames = worldVideoObjectFullRes.NumFrames;
    videoFrameRate = worldVideoObjectFullRes.FrameRate;

    f = figure(1);
    figH = 1800;
    figW = 1300;
    set(f, 'Position',  [10, 10, figH, figW])

    v1 = VideoWriter('CurlDivVisualization2', 'Uncompressed AVI');
    open(v1);

    indexNum = 1;
    for i=1:numFrames
        fullResFrame = readFrame(worldVideoObjectFullRes);


        subplot(3,4,1)
        
        if mod(i, 2.5)==0
            plot(trialPositionData.Camera_PosZ(1:indexNum), trialPositionData.Camera_PosY(1:indexNum), 'b-')
            hold on;
            plot(trialPositionData.Camera_PosX(1:indexNum), trialPositionData.Camera_PosY(1:indexNum), 'r-')
            hold off;
            indexNum = indexNum + 1;
        end


        flowData = load(fileNames{i});
        dxReshape = flowData.dx';
        dyReshape = flowData.dy';
        U = dxReshape; %flowData.dx;
        V = dyReshape; %flowData.dy;

        %[U, V] = normalizeFlow(X, Y, 1, 30);

        [X, Y] = meshgrid(1:size(U,2), 1:size(U,1));

        [flowCurlz, cav] = curl(X(1:intervalSize:end, 1:intervalSize:end),Y(1:intervalSize:end,...
            1:intervalSize:end),U(1:intervalSize:end, 1:intervalSize:end), ...
            V(1:intervalSize:end, 1:intervalSize:end));
    
        div = divergence(X(1:intervalSize:end, 1:intervalSize:end),Y(1:intervalSize:end,...
            1:intervalSize:end),U(1:intervalSize:end, 1:intervalSize:end), ...
            V(1:intervalSize:end, 1:intervalSize:end)) ;

        subplot(3,4,[2, 3])

        imshow(flip(fullResFrame, 1))

        hold on;
        quiver(X(1:intervalSize:end, 1:intervalSize:end),Y(1:intervalSize:end,...
            1:intervalSize:end),U(1:intervalSize:end, 1:intervalSize:end), ...
            V(1:intervalSize:end, 1:intervalSize:end), 'r');
        hold off;

        camroll(-180)

        title('Raw Video With Flow')

        
        subplot(3,4,5)


        imagesc(cav)
        hold on;
        %quiver(X(1:intervalSize:end, 1:intervalSize:end),Y(1:intervalSize:end,...
        %    1:intervalSize:end),U(1:intervalSize:end, 1:intervalSize:end), ...
        %    V(1:intervalSize:end, 1:intervalSize:end), 'k');
        hold off;
        %colorbar; 
        clim([-0.05 0.05])
        camroll(180)
        title('Curl')
        set(gca,'XTick',[])
        set(gca,'YTick',[])

        subplot(3,4,6)
        plot(flip(sum(cav, 2)), 'r-')
        ylim([-1 1])
        camroll(270)

        subplot(3,4,9)
        plot(flip(sum(cav, 1)), 'r-')
        ylim([-1 1])

%         subplot(1,2,2)
%         imagesc(flowCurlz)
%         colorbar;

        subplot(3,4,7)
        imagesc(div);
        %colorbar; 
        clim([-0.1 0.1])
        camroll(180)
        title('Divergence')
        set(gca,'XTick',[])
        set(gca,'YTick',[])

        subplot(3,4,8)
        plot(flip(sum(div, 2)), 'r-')
        ylim([-1 1])
        camroll(270)

        subplot(3,4,11)
        plot(flip(sum(div, 1)), 'r-')
        ylim([-1 1])

        drawnow;
        gcf = getframe(f);
        writeVideo(v1, gcf);


    end

    close(v1);


end

function [type_, numFiles] = readFolder(folderName, createNewMats)        
    
    directoryInfo = dir(fullfile(folderName, strcat('*', '.mat')));

    numFiles = length({directoryInfo.name});

    type_ = cell(numFiles, 1);
    
    for i=1:numFiles
        currFile = strcat(folderName,'/', directoryInfo(i).name);
        
        if createNewMats
            currMat = load(currFile);
            newOFMat = opticalFlow(currMat.dx, currMat.dy);
            save(currFile, 'newOFMat');
        end
        
        
        type_(i, 1) = {currFile};
    end
    
end

function [newDx, newDy] = normalizeFlow(dx, dy, dt, frameRate)

    
    mags = sqrt((dx.^2) + (dy.^2));
    targetMag = (mags./dt).*(1/frameRate);
    newDx = dx .* (targetMag./mags);
    newDy = dy .* (targetMag./mags);

    
    
    
end
