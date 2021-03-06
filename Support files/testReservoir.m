function [genotype,testStates,testSequence] = testReservoir(genotype,config)

statesExt = config.assessFcn(genotype,config.trainInputSequence,config);
statesExtval = config.assessFcn(genotype,config.valInputSequence,config);

if config.evolveOutputWeights %if W_out are evolved instead of trained
    outputSequence = statesExt*genotype.outputWeights;
    outputValSequence = statesExtval*genotype.outputWeights;
    genotype.trainError = calculateError(outputSequence,config.trainOutputSequence,config.nForgetPoints,config.errType);
    genotype.valError = calculateError(outputValSequence,config.valOutputSequence,config.nForgetPoints,config.errType);
else
    
    % Find best reg parameter
    regTrainError = [];
    regValError =[];regWeights=[];
    regParam = [10e-1 10e-3 10e-5 10e-7 10e-9];
    
    for i = 1:length(regParam)
        %Train: tanspose is inversed compared to equation
        outputWeights = config.trainOutputSequence(config.nForgetPoints+1:end,:)'*statesExt*inv(statesExt'*statesExt + regParam(i)*eye(size(statesExt'*statesExt)));
        
        % Calculate trained output Y
        outputSequence = statesExt*outputWeights';
        regTrainError(i,:)  = calculateError(outputSequence,config.trainOutputSequence,config.nForgetPoints,config.errType);
        
        % Calculate trained output Y
        outputValSequence = statesExtval*outputWeights';
        regValError(i,:)  = calculateError(outputValSequence,config.valOutputSequence,config.nForgetPoints,config.errType);
        regWeights(i,:,:) =outputWeights';
    end
    
    [~, regIndx]= min(sum(regValError,2));
    genotype.trainError = sum(regTrainError(regIndx,:));
    genotype.valError = sum(regValError(regIndx,:));  
    genotype.outputWeights =reshape(regWeights(regIndx,:,:),size(regWeights,2),size(regWeights,3));

    %remove NaNs
    genotype.outputWeights(isnan(genotype.outputWeights)) = 0;
end

%% Evaluate on test data
testStates = config.assessFcn(genotype,config.testInputSequence,config);
testSequence = testStates*genotype.outputWeights;
genotype.testError = sum(calculateError(testSequence,config.testOutputSequence,config.nForgetPoints,config.errType));

end